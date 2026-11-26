import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../vibe/vibe_home_parts.dart';
import '../../../vibe/vibe_invoice.dart';
import '../../../vibe/vibe_skeleton.dart';
import '../../../vibe/vibe_text.dart';
import '../../../vibe/vibe_tokens.dart';
import 'vibe_home_blocks.dart';
import 'vibe_home_data.dart';

/// 4º lugar — Faixa e fatura (layout_05, `D[1]` no protótipo).
///
/// A faixa da marca traz a saudação; o cartão da fatura fica sobre ela,
/// com o plano no rodapé. Os serviços deslizam na horizontal.
class VibeRibbonHome extends ConsumerWidget {
  const VibeRibbonHome({super.key, required this.onNavigate, this.onRefresh});

  final ValueChanged<String> onNavigate;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VibeTokens.of(context);
    final data = VibeHomeData.watch(ref, onNavigate);
    final inset = MediaQuery.paddingOf(context).top;
    final slot = VibeInvoiceSlot(data.billing);
    final empty = vibeEmptyInvoice(context, data);
    final main = slot.view;
    final realMain = data.billing.main;
    final incomplete = vibeIncompleteNote(context, data);
    final stale = vibeStaleNote(context, data);

    Widget planFooter() {
      final suspended = data.suspended;
      return Container(
        margin: const EdgeInsets.only(top: 14),
        child: Column(children: [
          CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _DashedLine(color: t.line)),
          const SizedBox(height: 14),
          Row(children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: suspended ? t.bad : const Color(0xFF16A34A),
                  shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: data.plan.isEmpty ? 'Seu plano' : data.plan,
                      style: vibeText(t, 13, 700)),
                  TextSpan(
                      text: suspended ? ' suspensa' : ' ativa',
                      style: vibeText(t, 13, 500)),
                ]),
                maxLines: 2,
              ),
            ),
            if (data.can('contract'))
              InkWell(
                onTap: () => data.onNavigate('contract'),
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Align(
                      widthFactor: 1,
                      child: Text('Detalhes do plano',
                          style: vibeText(t, 13, 650)),
                    ),
                  ),
                ),
              ),
          ]),
        ]),
      );
    }

    final card = slot.semantics(Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF101828).withValues(alpha: .3),
              offset: const Offset(0, 12),
              blurRadius: 30,
              spreadRadius: -14),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: VibeRefreshEdge(
        active: data.billing.refreshing,
        top: -18,
        inset: -18,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (!data.can('invoices'))
            Text('Olá, ${data.firstName}!', style: vibeText(t, 18, 750))
          else if (empty != null)
            empty
          else if (main != null) ...[
            Row(children: [
              Expanded(
                  child: Text('Fatura de internet',
                      style: vibeText(t, 13, 600, color: t.mut))),
              VibeStatusChip(
                  tone: slot.failed ? VibeTone.warning : main.tone,
                  label: slot.chipLabel(main),
                  redacted: slot.redacted),
            ]),
            const SizedBox(height: 10),
            if (slot.failed)
              VibeInvoiceSlot.overlay(
                _amountRow(context, main),
                Row(children: [
                  Expanded(
                    child: Text(VibeInvoiceSlot.failedMessage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: vibeText(t, 14, 700, height: 1.25)),
                  ),
                  const SizedBox(width: 10),
                  VibeButton(
                      label: 'Tentar de novo',
                      icon: 'g-refresh',
                      kind: VibeButtonKind.primary,
                      size: VibeButtonSize.small,
                      onPressed: slot.retry),
                ]),
              )
            else
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  slot.value(
                      VibeAmount(main.invoice.valor, size: 32, color: t.ink)),
                  slot.actions(vibePayButton(context, main,
                      kind: VibeButtonKind.primary,
                      paidKind: VibeButtonKind.tinted,
                      size: VibeButtonSize.small,
                      pixLabel: 'Copiar Pix')),
                ],
              ),
            const SizedBox(height: 10),
            slot.due(
              VibeDueLine(
                  text: main.dueFull,
                  tone: main.tone,
                  paid: main.paid,
                  redacted: slot.redacted),
              slow: const VibeDueLine(
                  text: VibeInvoiceSlot.slowMessage,
                  tone: VibeTone.neutral,
                  icon: 'clock',
                  maxLines: 1),
            ),
            if (main.note != null) ...[
              const SizedBox(height: 6),
              VibeNoteLine(text: main.note!, tone: main.tone, icon: 'bolt'),
            ],
            if (incomplete != null) incomplete,
            VibeReveal(child: stale ?? const SizedBox(width: double.infinity)),
          ],
          planFooter(),
        ]),
      ),
    ));

    final promos = data.promos(context);
    final reminder = vibeReminder(context, realMain);
    final late = vibeLateHelp(data);
    final list = ListView(
      padding: const EdgeInsets.only(bottom: 28),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          color: t.ac,
          padding: EdgeInsets.fromLTRB(20, inset + 8, 20, 8),
          child: VibeProfileHeader(
            initials: data.initials,
            small: 'Olá,',
            big: data.shortName,
            onAccount: data.openAccount,
            onBell: data.bellAction,
            unread: data.unread > 0,
            onBrand: true,
          ),
        ),
        // O cartão cobre os últimos 54 px da faixa (`.cd{margin-top:-54px}`).
        Stack(children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 54,
            child: Container(
              decoration: BoxDecoration(
                color: t.ac,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
            ),
          ),
          card,
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            VibeReveal(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: vibeHomeAlerts(context, data)),
            ),
            const SizedBox(height: 10),
            const VibeSectionTitle('Seus atalhos'),
            VibeServiceRail(items: data.rail(context)),
            VibeReveal(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (reminder != null) ...[
                      const SizedBox(height: 18),
                      reminder,
                    ],
                    if (promos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      VibePromoCarousel(
                          promos: promos,
                          title: promos.first.highlight
                              ? 'Dicas do app'
                              : 'Para você'),
                    ],
                    if (late != null) ...[const SizedBox(height: 12), late],
                  ]),
            ),
          ]),
        ),
      ],
    );
    return ColoredBox(
      color: t.bg,
      child: onRefresh == null
          ? list
          : RefreshIndicator(
              onRefresh: onRefresh!,
              color: t.ac,
              backgroundColor: t.card,
              child: list),
    );
  }
}

/// Linha do valor com o botão (só para medir o espaço no erro sem dados).
Widget _amountRow(BuildContext context, VibeInvoiceView main) {
  final t = VibeTokens.of(context);
  return Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.end,
    spacing: 10,
    runSpacing: 10,
    children: [
      VibeAmount(main.invoice.valor, size: 32, color: t.ink),
      vibePayButton(context, main,
          kind: VibeButtonKind.primary,
          size: VibeButtonSize.small,
          pixLabel: 'Copiar Pix'),
    ],
  );
}

/// Borda tracejada do rodapé do cartão (`border-top:1px dashed`).
class _DashedLine extends CustomPainter {
  _DashedLine({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, .5), Offset(x + 3, .5), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLine old) => old.color != color;
}
