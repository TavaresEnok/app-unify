import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../vibe/vibe_home_parts.dart';
import '../../../vibe/vibe_icon.dart';
import '../../../vibe/vibe_invoice.dart';
import '../../../vibe/vibe_text.dart';
import '../../../vibe/vibe_tokens.dart';
import 'vibe_home_blocks.dart';
import 'vibe_home_data.dart';

/// 3º lugar — Blocos escuros (layout_04, `D[7]` no protótipo).
///
/// Cartão da fatura na cor da marca com o botão preto do Pix, a rede do
/// celular, seis serviços em blocos e uma oferta em linha.
class VibeBlocksHome extends ConsumerWidget {
  const VibeBlocksHome({super.key, required this.onNavigate, this.onRefresh});

  final ValueChanged<String> onNavigate;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VibeTokens.of(context);
    final data = VibeHomeData.watch(ref, onNavigate);
    final inset = MediaQuery.paddingOf(context).top;
    final main = data.billing.main;
    final slotState = vibeInvoiceSlotState(context, data, onBrand: true);
    final incomplete = vibeIncompleteNote(context, data, onBrand: true);

    Widget card() => ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: t.ac,
            child: Stack(children: [
              // Círculo claro no canto (`.cd::after`).
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .08),
                      shape: BoxShape.circle),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: slotState ??
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text('Fatura de ${main!.month}',
                                    style: vibeText(t, 15, 700, color: t.on))),
                            VibeStatusChip(
                                tone: main.tone,
                                label: main.chip,
                                onBrand: true),
                          ]),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: VibeAmount(main.invoice.valor,
                                    size: 40, color: t.on)),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 10,
                            spacing: 10,
                            children: [
                              VibeDueLine(
                                  text: main.dueShort,
                                  tone: main.tone,
                                  paid: main.paid,
                                  onBrand: true,
                                  center: true),
                              vibePayButton(context, main,
                                  kind: VibeButtonKind.black,
                                  paidKind: VibeButtonKind.black,
                                  size: VibeButtonSize.small,
                                  pixLabel: 'Copiar Pix',
                                  onBrand: true),
                            ],
                          ),
                          if (main.note != null) ...[
                            const SizedBox(height: 10),
                            VibeNoteLine(
                                text: main.note!,
                                tone: main.tone,
                                icon: 'bolt',
                                onBrand: true),
                          ],
                          if (incomplete != null) incomplete,
                        ]),
              ),
            ]),
          ),
        );

    // Seis blocos (`PK(s,SC(['fat','bol','wifi','spd','diag','sup']))`):
    // o boleto fica no segundo lugar quando a fatura tem documento.
    final tiles = <VibeShortcut>[];
    final relevance = data.shortcuts(6);
    final boleto = main != null && main.hasBoleto && data.can('invoices')
        ? VibeShortcut(
            main.paid ? 'Baixar PDF' : 'Boleto',
            main.paid ? 'down' : 'bar',
            () => VibeInvoiceActions.openBoleto(context, main.invoice))
        : null;
    tiles.addAll(relevance);
    if (boleto != null) {
      tiles.insert(1, boleto);
      // Mantém seis blocos: sai o último atalho antes de "Ver todos".
      if (tiles.length > 6) tiles.removeAt(tiles.length - 2);
    }

    final promotion = data.promos(context);
    final late = vibeLateHelp(data);
    final list = ListView(
      padding: EdgeInsets.fromLTRB(20, inset + 6, 20, 28),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Row(children: [
          Expanded(
            child: Text('Olá, ${data.firstName}!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: vibeText(t, 22, 800, letterSpacingEm: -.02)),
          ),
          if (data.bellAction != null)
            VibeBell(onTap: data.bellAction!, unread: data.unread > 0),
        ]),
        if (data.can('invoices')) ...[
          const SizedBox(height: 14),
          card(),
        ],
        const SizedBox(height: 12),
        ...vibeHomeAlerts(context, data),
        const SizedBox(height: 14),
        _BlockGrid(items: tiles),
        if (late != null) ...[
          const SizedBox(height: 12),
          late
        ] else if (promotion.isNotEmpty) ...[
          const SizedBox(height: 14),
          _PromoLine(promo: promotion.first),
        ],
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

/// Grade de três colunas com blocos de 88 px (`.d7 .gr`).
class _BlockGrid extends StatelessWidget {
  const _BlockGrid({required this.items});

  final List<VibeShortcut> items;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(builder: (context, constraints) {
      final width = (constraints.maxWidth - 16) / 3;
      return Wrap(spacing: 8, runSpacing: 8, children: [
        for (final item in items)
          SizedBox(
            width: width,
            child: Semantics(
              button: true,
              label: item.label,
              excludeSemantics: true,
              child: Material(
                color: t.card,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: item.onTap,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: 88 * scale.clamp(1, 1.6)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 10),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            VibeIcon(item.icon, size: 24, color: t.at),
                            const SizedBox(height: 10),
                            Text(item.label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: vibeText(t, 12.5, 650, height: 1.2)),
                          ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ]);
    });
  }
}

/// Oferta em linha (`.d7 .promo`).
class _PromoLine extends StatelessWidget {
  const _PromoLine({required this.promo});

  final VibePromo promo;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Semantics(
      button: true,
      label: '${promo.kicker}. ${promo.title}',
      excludeSemantics: true,
      child: Material(
        color: t.card,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: promo.onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              if (promo.imageUrl.trim().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(promo.imageUrl,
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          VibeIcon('gift', size: 22, color: t.at)),
                )
              else
                VibeIcon('gift', size: 22, color: t.at),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (promo.kicker.isNotEmpty)
                        Text(promo.kicker,
                            style: vibeText(t, 12, 500, color: t.mut)),
                      Text(promo.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: vibeText(t, 14, 700, height: 1.25)),
                    ]),
              ),
              const SizedBox(width: 12),
              VibeIcon('chev', size: 22, color: t.at),
            ]),
          ),
        ),
      ),
    );
  }
}
