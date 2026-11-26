import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../pages/customer/invoice_document_page.dart';

import '../models/fatura.dart';
import '../providers/financeiro_provider.dart';
import '../utils/app_formatters.dart';
import 'vibe_tokens.dart';

/// Leitura de uma fatura nos termos do layout aprovado: situação, selo e os
/// textos de vencimento usados por cada tela (objeto `S` do protótipo).
class VibeInvoiceView {
  VibeInvoiceView(this.invoice, {DateTime? today, this.asOf})
      : _today = _dateOnly(today ?? DateTime.now());

  final Fatura invoice;
  final DateTime _today;

  /// Hora dos dados quando ainda não foram confirmados pelo provedor
  /// (vieram do aparelho ou a última atualização falhou). Nulo = atuais.
  final DateTime? asOf;

  /// Fatura de exemplo, só para dar ao esqueleto o tamanho real do cartão
  /// (valor típico, Pix e boleto). Nunca é mostrada: os valores ficam
  /// cobertos e os botões sem toque.
  factory VibeInvoiceView.placeholder({DateTime? today}) {
    final now = today ?? DateTime.now();
    return VibeInvoiceView(
        Fatura(
          numero: '',
          valor: 199.90,
          vencimento: DateTime(now.year, now.month, now.day)
              .add(const Duration(days: 10)),
          status: 'pendente',
          pixCopiaECola: '-',
          urlBoleto: '-',
        ),
        today: now);
  }

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

  /// Fatura em aberto sem link do boleto: o app pede o PDF ao provedor
  /// (IXC com carteira Sicredi/Santander, por exemplo). Se o provedor não
  /// emitir, a tela do documento avisa e indica a central/suporte.
  bool get canIssuePdf =>
      !paid && !hasBoleto && invoice.numero.trim().isNotEmpty;
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

  /// Há uma lista para mostrar (da consulta ou guardada no aparelho).
  bool get hasData => finance.hasResult;

  /// Primeira consulta, ainda sem nada para mostrar: esqueleto.
  bool get loading => !hasData && finance.state != FinanceiroState.error;

  /// Consulta falhou e não há nada guardado: erro no lugar do cartão.
  bool get failed => !hasData && finance.state == FinanceiroState.error;

  /// Dados prontos para usar (inclusive os guardados, enquanto atualiza).
  bool get ready => hasData;

  /// Atualizando com dados já na tela.
  bool get refreshing => finance.refreshing;

  /// A última atualização falhou; os dados na tela são de [asOf].
  bool get refreshFailed => hasData && finance.state == FinanceiroState.error;

  /// Hora dos dados mostrados quando ainda não confirmados pelo provedor.
  DateTime? get asOf => finance.isStale ? finance.lastUpdated : null;

  VibeInvoiceView? get main {
    final invoice = open.isNotEmpty
        ? open.first
        : paid.isNotEmpty
            ? paid.first
            : null;
    return invoice == null ? null : view(invoice);
  }

  VibeInvoiceView? get next => open.length > 1 ? view(open[1]) : null;

  VibeInvoiceView view(Fatura invoice) =>
      VibeInvoiceView(invoice, today: _today, asOf: asOf);

  /// Cartão de exemplo para o esqueleto e para o erro sem dados.
  VibeInvoiceView get placeholder => VibeInvoiceView.placeholder(today: _today);

  bool get overdue =>
      open.any((i) => VibeInvoiceView(i, today: _today).overdue);

  double get openTotal => open.fold(0, (sum, i) => sum + i.valor);
}

/// Ações de pagamento com retorno ao assinante (toasts `T` do protótipo).
class VibeInvoiceActions {
  static Future<void> copyPix(BuildContext context, Fatura invoice,
          {DateTime? asOf}) =>
      _copy(
          context,
          invoice.pixCopiaECola,
          asOf == null
              ? 'Código Pix copiado. Cole no app do seu banco para pagar.'
              : 'Código Pix copiado. ${staleNote(asOf)}');

  static Future<void> copyLine(BuildContext context, Fatura invoice,
          {DateTime? asOf}) =>
      _copy(
          context,
          invoice.linhaDigitavel,
          asOf == null
              ? 'Código de barras copiado. Cole no app do seu banco para pagar.'
              : 'Código de barras copiado. ${staleNote(asOf)}');

  /// Aviso ao copiar um código de dados ainda não confirmados: a fatura pode
  /// ter sido paga depois disso.
  static String staleNote(DateTime asOf) =>
      'Dados de ${vibeAsOf(asOf)}: confira se a fatura ainda está em aberto.';

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

  static Future<void> openBoleto(BuildContext context, Fatura invoice) =>
      openInvoiceDocument(context, invoice);
}

/// "14:32" para hoje, "ontem, 14:32" ou "12/11, 14:32".
String vibeAsOf(DateTime at, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final hm = DateFormat('HH:mm').format(at);
  final d0 = DateTime(today.year, today.month, today.day);
  final d1 = DateTime(at.year, at.month, at.day);
  final days = d0.difference(d1).inDays;
  if (days <= 0) return hm;
  if (days == 1) return 'ontem, $hm';
  return '${DateFormat('dd/MM').format(at)}, $hm';
}
