// ARQUIVO: lib/providers/financeiro_provider.dart
// DESCRIÇÃO: Provider para gerenciar o estado da tela de histórico financeiro.

import 'package:flutter/material.dart';
import '../models/fatura.dart';
import '../services/financeiro_service.dart';

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

  FinanceiroProvider(this._financeiroService) {
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    _state = FinanceiroState.loading;
    notifyListeners();

    try {
      final rawInvoices = await _financeiroService.fetchInvoices();
      // Converte o JSON para uma lista de Faturas
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
        f.dataPagamento!.isAfter(now.subtract(const Duration(days: 365)))
    );

    for (var invoice in paidInvoices) {
      final month = invoice.dataPagamento!.month;
      _monthlyTotals.update(month, (value) => value + invoice.valor, ifAbsent: () => invoice.valor);
    }
  }

  Future<void> solicitarDesbloqueio(BuildContext context) async {
    try {
      // Mostra um loading/snack enquanto processa
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
            content: const Text("Desbloqueio de confiança realizado.\nSua conexão será reativada em até 5 minutos.\n\nLembre-se de pagar a fatura em até 48h para evitar novo bloqueio."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
            ],
          ),
        );
      }
      // Atualiza a lista para refletir possíveis mudanças
      fetchHistory();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    }
  }
}
