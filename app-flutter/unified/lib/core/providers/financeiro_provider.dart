// ARQUIVO: lib/core/providers/financeiro_provider.dart
// DESCRIÇÃO: Provider para gerenciar o estado da tela financeiro.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fatura.dart';
import '../services/account_data_cache.dart';
import '../services/financeiro_service.dart';
import '../../core/providers/providers.dart';

// --- RIVERPOD MIGRATION ---

// Provider do Serviço (depende de config e auth)
final financeiroServiceProvider =
    Provider.autoDispose<FinanceiroService?>((ref) {
  final config = ref.watch(configurationProvider).providerConfig;
  final usuario = ref.watch(authNotifierProvider).value;

  if (config == null || usuario == null) return null;

  return FinanceiroService(
    apiUrl: '${config.apiUrl}/get-invoices',
    cpfCnpjUnformatted: usuario.cpfCnpj.replaceAll(RegExp(r'[^0-9]'), ''),
    providerId: config.id,
    contratoId: usuario.contratoId,
  );
});

// Provider do Estado (ViewModel)
final financeiroViewModelProvider =
    ChangeNotifierProvider.autoDispose<FinanceiroProvider>((ref) {
  final service = ref.watch(financeiroServiceProvider);
  // Se o serviço não estiver pronto (ex.: corrida de auth/config ou hot reload
  // perdendo o estado), o provider é criado em estado de erro em vez de lançar
  // dentro do builder — a UI mostra a mensagem e permite tentar de novo.
  final provider = FinanceiroProvider(service);
  // Auto-fetch ao criar
  provider.fetchHistory();
  return provider;
});

enum FinanceiroState { idle, loading, success, error }

/// Faturas da conta, com o último resultado guardado no aparelho.
///
/// Ciclo: ao abrir, mostra na hora as faturas salvas da última consulta
/// (se houver) e consulta o provedor por trás. Uma atualização que falha
/// nunca apaga o que já estava na tela: [state] vira `error`, [lastError]
/// guarda o motivo e as faturas continuam valendo, marcadas como
/// desatualizadas ([isStale]).
class FinanceiroProvider with ChangeNotifier {
  /// Nulo quando o serviço não pôde ser construído (login/config ausente).
  /// Nesse caso o provider entra em estado de erro em vez de lançar durante a
  /// construção — lançar no builder vira erro não tratado na árvore de widgets.
  final FinanceiroService? _financeiroService;
  final AccountDataCache _cache;

  bool _disposed = false;
  Future<void>? _fetch;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  FinanceiroState _state = FinanceiroState.idle;
  List<Fatura> _invoices = [];
  Map<int, double> _monthlyTotals = {};
  String _errorMessage = '';
  int _incompleteInvoices = 0;
  bool _hasResult = false;
  bool _fromCache = false;
  DateTime? _lastUpdated;

  FinanceiroState get state => _state;

  /// Serviço da conta (boleto em PDF usa a mesma sessão das faturas).
  FinanceiroService? get service => _financeiroService;
  List<Fatura> get invoices => _invoices;
  Map<int, double> get monthlyTotals => _monthlyTotals;
  String get errorMessage => _errorMessage;
  int get incompleteInvoices => _incompleteInvoices;

  /// Já existe uma lista para mostrar (da consulta ou do cache), mesmo que
  /// vazia. Enquanto for falso, a tela mostra o esqueleto.
  bool get hasResult => _hasResult || _state == FinanceiroState.success;

  /// Consulta em andamento com dados já na tela.
  bool get refreshing => hasResult && _state == FinanceiroState.loading;

  /// Os dados na tela vieram do aparelho e o provedor ainda não confirmou
  /// (consulta em andamento ou falhou).
  bool get isStale =>
      hasResult && (_fromCache || _state == FinanceiroState.error);

  /// Quando os dados na tela foram obtidos do provedor.
  DateTime? get lastUpdated => _lastUpdated;

  /// Motivo da última atualização que falhou (com dados na tela).
  String? get lastError =>
      _state == FinanceiroState.error && hasResult ? _errorMessage : null;

  /// Faturas pendentes (não pagas)
  List<Fatura> get pendingInvoices => invoices.where((f) => !f.isPago).toList();

  /// Faturas pagas
  List<Fatura> get paidInvoices => invoices.where((f) => f.isPago).toList();

  FinanceiroProvider(this._financeiroService, {AccountDataCache? cache})
      : _cache = cache ?? AccountDataCache.instance;

  /// Carrega as faturas do servidor
  Future<void> fetchHistory() {
    if (_disposed) return Future.value();
    return _fetch ??= _loadHistory().whenComplete(() => _fetch = null);
  }

  Future<void> _loadHistory() async {
    final service = _financeiroService;
    if (service == null) {
      _errorMessage =
          'Não foi possível carregar suas faturas. Entre novamente e tente de novo.';
      _state = FinanceiroState.error;
      notifyListeners();
      return;
    }

    // Primeiro o que já está no aparelho: memória (síncrono, antes do
    // primeiro quadro) e depois o disco.
    final key = service.cacheKey;
    final generation = _cache.generation;
    if (!_hasResult) {
      final hot = _cache.peek(key);
      if (hot != null) _apply(hot.data, hot.savedAt, fromCache: true);
    }
    _state = FinanceiroState.loading;
    notifyListeners();
    // A consulta sai já; o disco é lido enquanto ela anda.
    final network = service.fetchInvoices();
    // Marca o erro como tratado até o await abaixo (evita "unhandled").
    unawaited(network.then((_) {}, onError: (_) {}));
    if (!_hasResult) {
      // Sem esperar o disco: se a consulta chegar antes, ela vale.
      unawaited(_cache.read(key).then((saved) {
        if (_disposed || saved == null || _hasResult) return;
        _apply(saved.data, saved.savedAt, fromCache: true);
        notifyListeners();
      }, onError: (_) {}));
    }

    try {
      final rawInvoices = await network;
      if (_disposed) return;
      _apply(rawInvoices, DateTime.now(), fromCache: false);
      _state = FinanceiroState.success;
      unawaited(_cache.write(key, rawInvoices, generation: generation));
    } catch (e) {
      if (_disposed) return;
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _state = FinanceiroState.error;
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  void _apply(Object? raw, DateTime at, {required bool fromCache}) {
    final rawInvoices = raw is List ? raw : const [];
    final validInvoices = <Fatura>[];
    var incompleteInvoices = 0;
    for (final rawInvoice in rawInvoices) {
      try {
        if (rawInvoice is! Map) {
          throw const FormatException('Fatura inválida');
        }
        validInvoices
            .add(Fatura.fromJson(Map<String, dynamic>.from(rawInvoice)));
      } on FormatException {
        incompleteInvoices++;
      } on TypeError {
        incompleteInvoices++;
      }
    }
    _invoices = validInvoices;
    _incompleteInvoices = incompleteInvoices;

    // Ordena as faturas da mais recente para a mais antiga
    _invoices.sort((a, b) => b.vencimento.compareTo(a.vencimento));

    _calculateMonthlyTotals();
    _hasResult = true;
    _fromCache = fromCache;
    _lastUpdated = at;
  }

  void _calculateMonthlyTotals() {
    _monthlyTotals = {};
    final now = DateTime.now();

    // Considera apenas faturas pagas nos últimos 12 meses para o gráfico
    final paidInvoices = _invoices.where((f) =>
        f.status == 'pago' &&
        f.dataPagamento != null &&
        f.dataPagamento!.isAfter(now.subtract(const Duration(days: 365))));

    for (var invoice in paidInvoices) {
      final month = invoice.dataPagamento!.month;
      _monthlyTotals.update(month, (value) => value + invoice.valor,
          ifAbsent: () => invoice.valor);
    }
  }

  /// Solicita desbloqueio de confiança
  Future<void> solicitarDesbloqueio(BuildContext context) async {
    final service = _financeiroService;
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Sessão indisponível. Entre novamente e tente de novo.')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitando desbloqueio... Aguarde.')),
      );

      await service.solicitarDesbloqueioConfianca();

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Pedido enviado"),
            content: const Text(
                "Solicitação de liberação realizada. As condições e o prazo são definidos pelo seu provedor."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
            ],
          ),
        );
      }
      fetchHistory();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceFirst("Exception: ", "")),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}
