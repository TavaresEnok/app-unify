import 'package:flutter/material.dart';

import '../../../vibe/vibe_home_parts.dart';
import '../../../vibe/vibe_icon.dart';
import '../../../vibe/vibe_invoice.dart';
import '../../../vibe/vibe_text.dart';
import '../../../vibe/vibe_tokens.dart';
import '../../invoice_detail_page.dart';
import 'vibe_home_data.dart';

/// Blocos comuns aos cinco Inícios do layout aprovado.

/// Situação da consulta de faturas no lugar do cartão (carregando, erro ou
/// sem fatura). Devolve `null` quando há fatura para mostrar.
Widget? vibeInvoiceSlotState(BuildContext context, VibeHomeData data,
    {bool onBrand = false}) {
  final t = VibeTokens.of(context);
  final billing = data.billing;
  final color = onBrand ? t.on : t.ink;
  final muted = onBrand ? t.on.withValues(alpha: .85) : t.mut;
  if (billing.main != null && !billing.failed) return null;
  if (billing.loading && billing.main == null) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text('Consultando suas faturas…',
          style: vibeText(t, 14, 600, color: color)),
    );
  }
  if (billing.failed) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Não foi possível carregar suas faturas.',
          style: vibeText(t, 15, 700, color: color)),
      const SizedBox(height: 10),
      VibeButton(
        label: 'Tentar novamente',
        icon: 'g-refresh',
        size: VibeButtonSize.small,
        kind: onBrand ? VibeButtonKind.white : VibeButtonKind.primary,
        onPressed: billing.finance.fetchHistory,
      ),
    ]);
  }
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Sem fatura emitida', style: vibeText(t, 18, 750, color: color)),
    const SizedBox(height: 4),
    Text(
        billing.finance.incompleteInvoices > 0
            ? 'Algumas faturas estão com dados incompletos. Consulte o provedor.'
            : 'A próxima mensalidade aparecerá aqui.',
        style: vibeText(t, 14, 500, color: muted)),
  ]);
}

/// Aviso de dados incompletos abaixo do cartão da fatura.
Widget? vibeIncompleteNote(BuildContext context, VibeHomeData data,
    {bool onBrand = false}) {
  if (data.billing.finance.incompleteInvoices == 0 ||
      data.billing.main == null) {
    return null;
  }
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: VibeNoteLine(
        text:
            'Algumas faturas estão com dados incompletos. Consulte o provedor.',
        tone: VibeTone.warning,
        onBrand: onBrand,
        icon: 'alert'),
  );
}

/// Botão principal de pagamento (`P(s)` do protótipo): Pix quando existe,
/// senão boleto ou linha digitável; "Ver fatura" quando já está paga.
Widget vibePayButton(
  BuildContext context,
  VibeInvoiceView view, {
  required VibeButtonKind kind,
  VibeButtonKind? paidKind,
  VibeButtonSize size = VibeButtonSize.regular,
  String pixLabel = 'Copiar código Pix',
  bool onBrand = false,
  bool dense = false,
}) {
  final invoice = view.invoice;
  if (view.paid) {
    return VibeButton(
      label: 'Ver fatura',
      icon: 'file',
      kind: paidKind ?? (onBrand ? VibeButtonKind.tinted : kind),
      size: size,
      onBrand: onBrand,
      dense: dense,
      onPressed: () => openSubscriberInvoice(context, invoice),
    );
  }
  if (view.hasPix) {
    return VibeButton(
      label: pixLabel,
      icon: 'pix',
      kind: kind,
      size: size,
      onBrand: onBrand,
      dense: dense,
      onPressed: () => VibeInvoiceActions.copyPix(context, invoice),
    );
  }
  if (view.hasBoleto) {
    return VibeButton(
      label: 'Ver boleto',
      icon: 'bar',
      kind: kind,
      size: size,
      onBrand: onBrand,
      dense: dense,
      onPressed: () => VibeInvoiceActions.openBoleto(context, invoice),
    );
  }
  if (view.hasLine) {
    return VibeButton(
      label: 'Copiar código de barras',
      icon: 'copy',
      kind: kind,
      size: size,
      onBrand: onBrand,
      dense: dense,
      onPressed: () => VibeInvoiceActions.copyLine(context, invoice),
    );
  }
  return VibeButton(
    label: 'Ver fatura',
    icon: 'file',
    kind: kind,
    size: size,
    onBrand: onBrand,
    dense: dense,
    onPressed: () => openSubscriberInvoice(context, invoice),
  );
}

/// Boleto ao lado do Pix (`B(s)`), só quando a fatura tem os dois.
Widget? vibeBoletoButton(BuildContext context, VibeInvoiceView view,
    {required VibeButtonKind kind,
    VibeButtonSize size = VibeButtonSize.regular,
    bool onBrand = false,
    bool dense = false,
    String label = 'Ver boleto'}) {
  if (view.paid || !view.hasPix || !view.hasBoleto) return null;
  return VibeButton(
    label: label,
    icon: 'bar',
    kind: kind,
    size: size,
    onBrand: onBrand,
    dense: dense,
    onPressed: () => VibeInvoiceActions.openBoleto(context, view.invoice),
  );
}

/// Segunda fatura em aberto (`.old`): valor, prazo e as duas formas de
/// pagar a própria fatura.
class VibeNextInvoiceCard extends StatelessWidget {
  const VibeNextInvoiceCard({super.key, required this.view});

  final VibeInvoiceView view;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final pay = vibePayButton(context, view,
        kind: VibeButtonKind.primary,
        size: VibeButtonSize.small,
        dense: true,
        pixLabel: 'Copiar Pix de ${view.month}');
    final boleto = vibeBoletoButton(context, view,
        kind: VibeButtonKind.outline,
        size: VibeButtonSize.small,
        dense: true,
        label: 'Boleto');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${view.monthTitle} também está em aberto',
                  style: vibeText(t, 14, 700)),
              const SizedBox(height: 2),
              Text(view.dueFull, style: vibeText(t, 12.5, 500, color: t.mut)),
              Text(view.overdue ? 'Vencida' : 'Ainda no prazo',
                  style: vibeText(t, 12.5, 500,
                      color: view.overdue ? t.bad : t.mut)),
            ]),
          ),
          const SizedBox(width: 10),
          VibeAmount(view.invoice.valor, size: 22, color: t.ink),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: pay),
          if (boleto != null) ...[const SizedBox(width: 10), boleto],
        ]),
      ]),
    );
  }
}

/// Avisos abaixo do cartão (`AL(s)` e `TR(s)`): internet suspensa ou a
/// próxima fatura em aberto, a rede do celular e a liberação por confiança.
List<Widget> vibeHomeAlerts(BuildContext context, VibeHomeData data,
    {double gap = 10}) {
  final billing = data.billing;
  final main = billing.main;
  final next = billing.next;
  final out = <Widget>[];
  if (data.suspended) {
    out.add(VibeAlertBox(
      title: 'Internet suspensa',
      text: main != null && main.overdue
          ? 'A fatura de ${main.month} está vencida. Pague para liberar o acesso.'
          : 'Consulte suas faturas ou fale com o provedor.',
      onTap: data.can('invoices') ? () => data.onNavigate('invoices') : null,
    ));
  }
  if (next != null && data.can('invoices')) {
    if (out.isNotEmpty) out.add(SizedBox(height: gap));
    out.add(VibeNextInvoiceCard(view: next));
  }
  if (data.can('network_diagnostic')) {
    if (out.isNotEmpty) out.add(SizedBox(height: gap));
    out.add(
        VibeConnectionPill(network: data.network, onTap: data.openDiagnostic));
  }
  if (data.suspended && billing.overdue && data.can('invoices')) {
    out.add(SizedBox(height: gap));
    out.add(VibeActionCard(
      icon: 'unlock',
      title: 'Liberar por confiança',
      text: 'Libera a internet por 24 horas',
      onTap: () => data.onNavigate('trust_unlock'),
    ));
  }
  return out;
}

/// Ajuda quando há fatura vencida (`LATE(s)`).
Widget? vibeLateHelp(VibeHomeData data) {
  if (!data.billing.overdue) return null;
  return VibeLateHelp(
    suspended: data.suspended,
    onAction: data.can('support') ? () => data.onNavigate('support') : null,
  );
}

/// Lembrete da situação abaixo dos atalhos (`.rm` do layout Faixa e fatura).
Widget? vibeReminder(BuildContext context, VibeInvoiceView? view) {
  if (view == null) return null;
  final t = VibeTokens.of(context);
  final (String icon, String text)? content = view.paid
      ? ('check', 'Pagamento confirmado. Sua conta está em dia.')
      : view.dueToday
          ? ('bolt', 'Vence hoje. Pelo Pix, a confirmação sai em minutos.')
          : view.overdue
              ? ('alert', 'Pague agora para evitar a suspensão do acesso.')
              : null;
  if (content == null) return null;
  final ok = view.paid;
  final bg = ok
      ? t.okb
      : t.dark
          ? t.wab
          : const Color(0xFFFFF4E5);
  final fg = ok
      ? t.ok
      : t.dark
          ? t.wa
          : const Color(0xFF7A4300);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      VibeIcon(content.$1, size: 16, color: fg),
      const SizedBox(width: 10),
      Expanded(child: Text(content.$2, style: vibeText(t, 13, 600, color: fg))),
    ]),
  );
}
