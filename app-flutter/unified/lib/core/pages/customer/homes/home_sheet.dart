import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../vibe/vibe_home_parts.dart';
import '../../../vibe/vibe_icon.dart';
import '../../../vibe/vibe_text.dart';
import '../../../vibe/vibe_tokens.dart';
import 'vibe_home_blocks.dart';
import 'vibe_home_data.dart';

/// 1º lugar — Histórico na folha (layout_02, `D[2]` no protótipo).
///
/// A fatura ocupa o topo na cor da marca, com Pix e boleto lado a lado. Os
/// atalhos ficam na folha arredondada que sobe 22 px sobre o topo.
class VibeSheetHome extends ConsumerWidget {
  const VibeSheetHome({super.key, required this.onNavigate, this.onRefresh});

  final ValueChanged<String> onNavigate;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VibeTokens.of(context);
    final data = VibeHomeData.watch(ref, onNavigate);
    final inset = MediaQuery.paddingOf(context).top;
    final main = data.billing.main;
    final slotState = vibeInvoiceSlotState(context, data,
        onBrand: true, variant: VibeInvoiceSlotVariant.sheet);
    final incomplete = vibeIncompleteNote(context, data, onBrand: true);

    final top = Container(
      color: t.ac,
      padding: EdgeInsets.fromLTRB(20, inset + 8, 20, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: VibeLogo(
                  name: data.providerName,
                  logoUrl: data.logoUrl,
                  height: 36,
                  onBrand: true),
            ),
          ),
          if (data.bellAction != null)
            VibeBell(
                onTap: data.bellAction!,
                unread: data.unread > 0,
                onBrand: true),
        ]),
        const SizedBox(height: 24),
        if (!data.can('invoices'))
          Text('Olá, ${data.firstName}!',
              style: vibeText(t, 22, 800, color: t.on))
        else if (slotState != null)
          slotState
        else ...[
          Row(children: [
            Expanded(
              child: Text('Fatura de ${main!.month}',
                  style: vibeText(t, 13, 600, color: t.on)),
            ),
            VibeStatusChip(tone: main.tone, label: main.chip, onBrand: true),
          ]),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: VibeAmount(main.invoice.valor, size: 44, color: t.on),
            ),
          ),
          const SizedBox(height: 10),
          VibeDueLine(
              text: main.dueFull,
              tone: main.tone,
              paid: main.paid,
              onBrand: true),
          if (main.note != null) ...[
            const SizedBox(height: 6),
            VibeNoteLine(
                text: main.note!, tone: main.tone, icon: 'bolt', onBrand: true),
          ],
          if (incomplete != null) incomplete,
          const SizedBox(height: 18),
          _PayRow(children: [
            vibePayButton(context, main,
                kind: VibeButtonKind.white,
                paidKind: VibeButtonKind.white,
                pixLabel: 'Copiar Pix',
                onBrand: true),
            if (vibeBoletoButton(context, main,
                    kind: VibeButtonKind.ghostOnBrand, onBrand: true)
                case final boleto?)
              boleto,
          ]),
          if (data.nextDue() case final next?) ...[
            const SizedBox(height: 12),
            Row(children: [
              VibeIcon('cal', size: 16, color: t.on.withValues(alpha: .78)),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Próxima fatura vence em '),
                    TextSpan(
                        text: DateFormat('dd/MM').format(next),
                        style: vibeText(t, 13, 800,
                            color: t.on.withValues(alpha: .78))),
                  ]),
                  style:
                      vibeText(t, 13, 600, color: t.on.withValues(alpha: .78)),
                ),
              ),
            ]),
          ],
        ],
      ]),
    );

    final shortcuts = data.shortcuts(4);
    final promos = data.promos(context);
    final late = vibeLateHelp(data);
    final sheet = Container(
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ...vibeHomeAlerts(context, data),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(18),
          ),
          child: VibeShortcutGrid(items: shortcuts),
        ),
        // O título das ofertas encosta nos atalhos: `.sheet .sec:first-child`
        // zera a margem e a altura das setas (44 px) faz o espaço.
        if (promos.isNotEmpty)
          VibePromoCarousel(
              promos: promos,
              title: promos.first.highlight ? 'Dicas do app' : 'Para você'),
        if (late != null) ...[const SizedBox(height: 12), late],
      ]),
    );

    final list = ListView(
      padding: const EdgeInsets.only(bottom: 28),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        top,
        // A folha sobe 22 px sobre o topo: a cor da marca continua atrás dos
        // cantos arredondados, como `.sheet{margin-top:-22px}`.
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
      color: t.bg,
      child: onRefresh == null
          ? list
          : RefreshIndicator(onRefresh: onRefresh!, child: list),
    );
  }
}

/// Botões lado a lado com a mesma largura (`.hl .b{flex:1}`).
class _PayRow extends StatelessWidget {
  const _PayRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.length == 1 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.4) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          children[i],
        ],
      ]);
    }
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: children[i]),
        ],
      ]),
    );
  }
}
