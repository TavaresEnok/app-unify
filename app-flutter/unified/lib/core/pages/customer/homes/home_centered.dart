import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../vibe/vibe_home_parts.dart';
import '../../../vibe/vibe_skeleton.dart';
import '../../../vibe/vibe_text.dart';
import '../../../vibe/vibe_tokens.dart';
import 'vibe_home_blocks.dart';
import 'vibe_home_data.dart';

/// 5º lugar — Topo centralizado (layout_06, `D[17]` no protótipo).
///
/// Todo o topo fica na cor da marca, com o valor no centro, o botão branco
/// do Pix e os atalhos. Avisos e ofertas ficam na folha branca abaixo.
class VibeCenteredHome extends ConsumerWidget {
  const VibeCenteredHome({super.key, required this.onNavigate, this.onRefresh});

  final ValueChanged<String> onNavigate;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VibeTokens.of(context);
    final data = VibeHomeData.watch(ref, onNavigate);
    final inset = MediaQuery.paddingOf(context).top;
    final slot = VibeInvoiceSlot(data.billing, onBrand: true);
    final empty = vibeEmptyInvoice(context, data, onBrand: true, center: true);
    final main = slot.view;
    final incomplete = vibeIncompleteNote(context, data, onBrand: true);
    final stale = vibeStaleNote(context, data, onBrand: true, center: true);

    final top = VibeBrandSurface(
      padding: EdgeInsets.fromLTRB(20, inset + 8, 20, 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        VibeProfileHeader(
          initials: data.initials,
          small: data.contractLabel ?? data.plan,
          big: 'Olá, ${data.firstName}!',
          onAccount: data.openAccount,
          onBell: data.bellAction,
          unread: data.unread > 0,
          onBrand: true,
        ),
        if (data.can('invoices')) ...[
          const SizedBox(height: 20),
          if (empty != null)
            empty
          else if (main != null)
            slot.semantics(VibeRefreshEdge(
              active: data.billing.refreshing,
              onBrand: true,
              top: -11,
              inset: 40,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    slot.title('Fatura de ', main.month,
                        vibeText(t, 13, 600, color: t.on),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    slot.amount(
                      context,
                      VibeAmount(main.invoice.valor,
                          size: 48, color: t.on, currencyScale: .36),
                      frame: (amount) => Center(
                          child:
                              FittedBox(fit: BoxFit.scaleDown, child: amount)),
                      alignment: Alignment.center,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Center(
                        child: VibeStatusChip(
                            tone: slot.failed ? VibeTone.warning : main.tone,
                            label: slot.chipLabel(main),
                            onBrand: true,
                            redacted: slot.redacted)),
                    const SizedBox(height: 8),
                    Center(
                      child: slot.due(
                        VibeDueLine(
                            text: main.dueFull,
                            tone: main.tone,
                            paid: main.paid,
                            onBrand: true,
                            center: true,
                            redacted: slot.redacted),
                        slow: const VibeDueLine(
                            text: VibeInvoiceSlot.slowMessage,
                            tone: VibeTone.neutral,
                            icon: 'clock',
                            maxLines: 1,
                            center: true,
                            onBrand: true),
                      ),
                    ),
                    if (main.note != null) ...[
                      const SizedBox(height: 6),
                      Center(
                        child: Text(main.note!,
                            textAlign: TextAlign.center,
                            style: vibeText(t, 12.5, 650,
                                color: t.on.withValues(alpha: .9))),
                      ),
                    ],
                    if (incomplete != null) incomplete,
                    VibeReveal(
                        child: stale ?? const SizedBox(width: double.infinity)),
                    const SizedBox(height: 16),
                    slot.actions(
                      vibePayButton(context, main,
                          kind: VibeButtonKind.white,
                          paidKind: VibeButtonKind.white,
                          onBrand: true),
                      retryButton: VibeButton(
                          label: 'Tentar novamente',
                          icon: 'g-refresh',
                          kind: VibeButtonKind.white,
                          onBrand: true,
                          onPressed: slot.retry),
                    ),
                  ]),
            )),
        ],
        const SizedBox(height: 12),
        VibeServiceRail(items: data.rail(context), onBrand: true),
      ]),
    );

    final promos = data.promos(context);
    final late = vibeLateHelp(data);
    final sheet = Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        VibeReveal(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ...vibeHomeAlerts(context, data),
            if (promos.isNotEmpty)
              VibePromoCarousel(
                  promos: promos,
                  title: promos.first.highlight ? 'Dicas do app' : 'Para você'),
            if (late != null) ...[const SizedBox(height: 12), late],
          ]),
        ),
      ]),
    );

    final list = ListView(
      padding: const EdgeInsets.only(bottom: 28),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        top,
        // A folha sobe 22 px sobre o topo (`.sh{margin-top:-22px}`).
        Stack(children: [
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 22,
              child: ColoredBox(color: t.ac)),
          sheet,
        ]),
      ],
    );
    return ColoredBox(
      color: t.card,
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
