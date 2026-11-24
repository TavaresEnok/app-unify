import 'package:flutter/material.dart';

import '../../../vibe/vibe_controls.dart';
import '../../../vibe/vibe_home_parts.dart';
import '../../../vibe/vibe_icon.dart';
import '../../../vibe/vibe_invoice.dart';
import '../../../vibe/vibe_text.dart';
import '../../../vibe/vibe_tokens.dart';
import '../../invoice_detail_page.dart';
import 'vibe_home_data.dart';

/// Blocos comuns aos cinco Inícios do layout aprovado.

/// Formato do cartão de fatura do Início, usado para manter exatamente a
/// mesma altura e anatomia do cartão enquanto a consulta está em andamento.
enum VibeInvoiceSlotVariant { sheet, blocks, ribbon, centered }

/// Situação da consulta de faturas no lugar do cartão (carregando, erro ou
/// sem fatura). Devolve `null` quando há fatura para mostrar.
Widget? vibeInvoiceSlotState(
  BuildContext context,
  VibeHomeData data, {
  bool onBrand = false,
  VibeInvoiceSlotVariant variant = VibeInvoiceSlotVariant.sheet,
}) {
  final t = VibeTokens.of(context);
  final billing = data.billing;
  final color = onBrand ? t.on : t.ink;
  final muted = onBrand ? t.on.withValues(alpha: .85) : t.mut;
  if (billing.main != null && !billing.failed) return null;
  if (billing.loading && billing.main == null) {
    return _vibeInvoiceLoading(
      context,
      variant: variant,
      onBrand: onBrand,
      color: color,
      muted: muted,
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

Widget _vibeInvoiceLoading(
  BuildContext context, {
  required VibeInvoiceSlotVariant variant,
  required bool onBrand,
  required Color color,
  required Color muted,
}) {
  final t = VibeTokens.of(context);
  final Widget child = switch (variant) {
    VibeInvoiceSlotVariant.sheet => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Text('Consultando suas faturas…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: vibeText(t, 13, 600, color: color)),
            ),
            const SizedBox(width: 8),
            VibeShimmerBar(
                width: 78, height: 26, radius: 13, onBrand: onBrand),
          ]),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: VibeShimmerBar(
                width: 175, height: 44, radius: 10, onBrand: onBrand),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: VibeShimmerBar(
                width: 160, height: 18, radius: 6, onBrand: onBrand),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
                child:
                    VibeShimmerBar(height: 48, radius: 14, onBrand: onBrand)),
            const SizedBox(width: 8),
            Expanded(
                child:
                    VibeShimmerBar(height: 48, radius: 14, onBrand: onBrand)),
          ]),
        ],
      ),
    VibeInvoiceSlotVariant.blocks => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Text('Consultando suas faturas…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: vibeText(t, 15, 700, color: color)),
            ),
            const SizedBox(width: 8),
            VibeShimmerBar(
                width: 78, height: 26, radius: 13, onBrand: onBrand),
          ]),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: VibeShimmerBar(
                width: 165, height: 40, radius: 10, onBrand: onBrand),
          ),
          const SizedBox(height: 14),
          Row(children: [
            VibeShimmerBar(
                width: 115, height: 18, radius: 6, onBrand: onBrand),
            const Spacer(),
            VibeShimmerBar(
                width: 120, height: 40, radius: 12, onBrand: onBrand),
          ]),
        ],
      ),
    VibeInvoiceSlotVariant.ribbon => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Text('Consultando suas faturas…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: vibeText(t, 13, 600, color: muted)),
            ),
            const SizedBox(width: 8),
            VibeShimmerBar(
                width: 78, height: 26, radius: 13, onBrand: onBrand),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            VibeShimmerBar(
                width: 135, height: 32, radius: 8, onBrand: onBrand),
            const Spacer(),
            VibeShimmerBar(
                width: 120, height: 40, radius: 12, onBrand: onBrand),
          ]),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: VibeShimmerBar(
                width: 165, height: 18, radius: 6, onBrand: onBrand),
          ),
        ],
      ),
    VibeInvoiceSlotVariant.centered => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Consultando suas faturas…',
              textAlign: TextAlign.center,
              style: vibeText(t, 13, 600, color: color)),
          const SizedBox(height: 8),
          Center(
            child: VibeShimmerBar(
                width: 185, height: 48, radius: 10, onBrand: onBrand),
          ),
          const SizedBox(height: 12),
          Center(
            child: VibeShimmerBar(
                width: 86, height: 26, radius: 13, onBrand: onBrand),
          ),
          const SizedBox(height: 8),
          Center(
            child: VibeShimmerBar(
                width: 155, height: 18, radius: 6, onBrand: onBrand),
          ),
          const SizedBox(height: 16),
          VibeShimmerBar(height: 48, radius: 14, onBrand: onBrand),
        ],
      ),
  };
  return Semantics(
    label: 'Consultando suas faturas',
    liveRegion: true,
    child: child,
  );
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
        LayoutBuilder(builder: (context, constraints) {
          if (boleto == null) return pay;
          final scaler = MediaQuery.textScalerOf(context);
          double textWidth(String text) {
            final painter = TextPainter(
              text: TextSpan(
                  text: text, style: vibeText(t, 13, 700, height: 1.1)),
              textDirection: Directionality.of(context),
              textScaler: scaler,
              maxLines: 1,
            )..layout();
            final width = painter.width;
            painter.dispose();
            return width;
          }

          final boletoWidth = textWidth('Boleto') + 20 + 6 + 24;
          final pixWidth =
              constraints.maxWidth - boletoWidth - 10 - 20 - 6 - 24;
          final pixText = TextPainter(
            text: TextSpan(
                text: 'Copiar Pix de ${view.month}',
                style: vibeText(t, 13, 700, height: 1.1)),
            textDirection: Directionality.of(context),
            textScaler: scaler,
            maxLines: 2,
          )..layout(maxWidth: pixWidth.clamp(0, double.infinity));
          final mustStack = pixText.didExceedMaxLines;
          pixText.dispose();
          if (mustStack) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  pay,
                  const SizedBox(height: 8),
                  boleto,
                ]);
          }
          return Row(children: [
            Expanded(child: pay),
            const SizedBox(width: 10),
            boleto
          ]);
        }),
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
