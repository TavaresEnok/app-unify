// ARQUIVO: lib/core/providers/financeiro_provider.dart
// DESCRIÇÃO: Provider para gerenciar o estado da tela financeiro.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fatura.dart';
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
    senha: usuario.senha,
    sgpParams: {
      'token': config.config.integrations.apiToken,
      'app': config.config.integrations.appName,
      'sgpBaseUrl': config.config.integrations.sgpBaseUrl,
    },
  );
});

// Provider do Estado (ViewModel)
final financeiroViewModelProvider =
    ChangeNotifierProvider.autoDispose<FinanceiroProvider>((ref) {
  final service = ref.watch(financeiroServiceProvider);
  // Se o serviço não estiver pronto (ex: sem login), retorna provider vazio ou lida com erro
  // Como estamos dentro do AuthGate, o usuário deve existir.
  if (service == null) {
    // Fallback seguro ou lance erro se preferir
    // Em dev, isso pode acontecer se hot reload perder estado de auth.
    throw Exception(
        'Serviço Financeiro não pôde ser inicializado (Login/Config ausente)');
  }

  final provider = FinanceiroProvider(service);
  // Auto-fetch ao criar
  provider.fetchHistory();
  return provider;
});

enum FinanceiroState { idle, loading, success, error }

class FinanceiroProvider with ChangeNotifier {
  final FinanceiroService _financeiroService;

  FinanceiroState _state = FinanceiroState.idle;
  List<Fatura> _invoices = [];
  Map<int, double> _monthlyTotals = {};
  String _errorMessage = '';

  FinanceiroState get state => _state;
  List<Fatura> get invoices => _invoices;
  Map<int, double> get monthlyTotals => _monthlyTotals;
  String get errorMessage => _errorMessage;

  /// Faturas pendentes (não pagas)
  List<Fatura> get pendingInvoices =>
      _invoices.where((f) => !f.isPago).toList();

  /// Faturas pagas
  List<Fatura> get paidInvoices => _invoices.where((f) => f.isPago).toList();

  FinanceiroProvider(this._financeiroService);

  /// Carrega as faturas do servidor
  Future<void> fetchHistory() async {
    _state = FinanceiroState.loading;
    notifyListeners();

    try {
      final rawInvoices = await _financeiroService.fetchInvoices();
      _invoices = rawInvoices.map((json) => Fatura.fromJson(json)).toList();

      // Ordena as faturas da mais recente para a mais antiga
      _invoices.sort((a, b) => b.vencimento.compareTo(a.vencimento));

      _calculateMonthlyTotals();

      _state = FinanceiroState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _state = FinanceiroState.error;
    } finally {
      notifyListeners();
    }
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
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitando desbloqueio... Aguarde.')),
      );

      await _financeiroService.solicitarDesbloqueioConfianca();

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("✅ Sucesso!"),
            content: const Text(
                "Desbloqueio de confiança realizado.\nSua conexão será reativada em até 5 minutos.\n\nLembre-se de pagar a fatura em até 48h para evitar novo bloqueio."),
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
