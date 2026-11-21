import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/fatura.dart';
import '../providers/financeiro_provider.dart';
import '../utils/app_formatters.dart';
import 'vibe_tokens.dart';

/// Leitura de uma fatura nos termos do layout aprovado: situação, selo e os
/// textos de vencimento usados por cada tela (objeto `S` do protótipo).
class VibeInvoiceView {
  VibeInvoiceView(this.invoice, {DateTime? today})
      : _today = _dateOnly(today ?? DateTime.now());

  final Fatura invoice;
  final DateTime _today;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool get paid => invoice.isPago;
  DateTime get _due => _dateOnly(invoice.vencimento);
  bool get dueToday => !paid && _due == _today;
  bool get overdue => !paid && _due.isBefore(_today);

  VibeTone get tone => paid
      ? VibeTone.ok
      : overdue
          ? VibeTone.bad
          : dueToday
              ? VibeTone.warning
              : VibeTone.neutral;

  String get chip => paid
      ? 'Paga'
      : overdue
          ? 'Vencida'
          : dueToday
              ? 'Vence hoje'
              : 'Em aberto';

  /// Mês da fatura por extenso, em minúsculas ("novembro").
  String get month => DateFormat('MMMM', 'pt_BR').format(invoice.vencimento);

  String get monthTitle =>
      month.isEmpty ? month : '${month[0].toUpperCase()}${month.substring(1)}';

  String _short(DateTime d) => DateFormat('dd/MM').format(d);

  /// "Vence em 20/11/2026", "Vence hoje, 20/11/2026", "Venceu em …",
  /// "Paga em …".
  String get dueFull {
    if (paid) {
      final at = invoice.dataPagamento;
      return at == null ? 'Paga' : 'Paga em ${AppFormatters.date(at)}';
    }
    final date = AppFormatters.date(invoice.vencimento);
    if (dueToday) return 'Vence hoje, $date';
    return overdue ? 'Venceu em $date' : 'Vence em $date';
  }

  /// "Vence em 20/11", "Vence hoje", "Venceu em 20/11", "Paga em 18/11".
  String get dueShort {
    if (paid) {
      final at = invoice.dataPagamento;
      return at == null ? 'Paga' : 'Paga em ${_short(at)}';
    }
    if (dueToday) return 'Vence hoje';
    return '${overdue ? 'Venceu' : 'Vence'} em ${_short(invoice.vencimento)}';
  }

  /// "Vence em 20 de novembro" (tela Dock).
  String get dueLong {
    String long(DateTime d) => DateFormat("d 'de' MMMM", 'pt_BR').format(d);
    if (paid) {
      final at = invoice.dataPagamento;
      return at == null ? 'Paga' : 'Paga em ${long(at)}';
    }
    if (dueToday) return 'Vence hoje, ${long(invoice.vencimento)}';
    return '${overdue ? 'Venceu' : 'Vence'} em ${long(invoice.vencimento)}';
  }

  /// Observação mostrada no dia do vencimento (`.nt` no protótipo). O app
  /// não calcula multa e juros: o valor é o informado pelo provedor.
  String? get note =>
      dueToday ? 'Pelo Pix, a confirmação sai em minutos.' : null;

  bool get hasPix => !paid && invoice.pixCopiaECola?.trim().isNotEmpty == true;
  bool get hasBoleto => invoice.urlBoleto?.trim().isNotEmpty == true;
  bool get hasLine =>
      !paid && invoice.linhaDigitavel?.trim().isNotEmpty == true;
  bool get hasPaymentData => hasPix || hasBoleto || hasLine;
}

/// Faturas da conta organizadas como o Início do protótipo: a primeira em
/// aberto por vencimento é a principal e a seguinte aparece logo abaixo.
class VibeBilling {
  VibeBilling(this.finance, {DateTime? today})
      : open = finance.invoices.where((i) => !i.isPago).toList()
          ..sort((a, b) => a.vencimento.compareTo(b.vencimento)),
        paid = finance.invoices.where((i) => i.isPago).toList()
          ..sort((a, b) => b.vencimento.compareTo(a.vencimento)),
        _today = today;

  final FinanceiroProvider finance;
  final List<Fatura> open;
  final List<Fatura> paid;
  final DateTime? _today;

  bool get loading => finance.state == FinanceiroState.loading;
  bool get failed => finance.state == FinanceiroState.error;
  bool get ready => finance.state == FinanceiroState.success;

  VibeInvoiceView? get main {
    final invoice = open.isNotEmpty
        ? open.first
        : paid.isNotEmpty
            ? paid.first
            : null;
    return invoice == null ? null : VibeInvoiceView(invoice, today: _today);
  }

  VibeInvoiceView? get next =>
      open.length > 1 ? VibeInvoiceView(open[1], today: _today) : null;

  bool get overdue =>
      open.any((i) => VibeInvoiceView(i, today: _today).overdue);

  double get openTotal => open.fold(0, (sum, i) => sum + i.valor);
}

/// Ações de pagamento com retorno ao assinante (toasts `T` do protótipo).
class VibeInvoiceActions {
  static Future<void> copyPix(BuildContext context, Fatura invoice) => _copy(
      context,
      invoice.pixCopiaECola,
      'Código Pix copiado. Cole no app do seu banco para pagar.');

  static Future<void> copyLine(BuildContext context, Fatura invoice) => _copy(
      context,
      invoice.linhaDigitavel,
      'Código de barras copiado. Cole no app do seu banco para pagar.');

  static Future<void> _copy(
      BuildContext context, String? value, String message) async {
    final text = value?.trim() ?? '';
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (text.isEmpty) {
      messenger?.showSnackBar(const SnackBar(
          content:
              Text('Dados de pagamento indisponíveis. Consulte o suporte.')));
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  static Future<void> openBoleto(BuildContext context, Fatura invoice) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final uri = Uri.tryParse(invoice.urlBoleto?.trim() ?? '');
    final valid =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    try {
      if (valid && await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      // A plataforma pode recusar um endereço válido.
    }
    messenger?.showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o boleto.')));
  }
}
