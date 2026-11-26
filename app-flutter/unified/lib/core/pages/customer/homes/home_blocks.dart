import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../vibe/vibe_home_parts.dart';
import '../../../vibe/vibe_icon.dart';
import '../../../vibe/vibe_invoice.dart';
import '../../../vibe/vibe_skeleton.dart';
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
    final slot = VibeInvoiceSlot(data.billing, onBrand: true);
    final empty = vibeEmptyInvoice(context, data, onBrand: true);
    final main = slot.view;
    final incomplete = vibeIncompleteNote(context, data, onBrand: true);
    final stale = vibeStaleNote(context, data, onBrand: true);

    Widget invoice(VibeInvoiceView main) =>
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
                child: slot.title('Fatura de ', main.month,
                    vibeText(t, 15, 700, color: t.on))),
            VibeStatusChip(
                tone: slot.failed ? VibeTone.warning : main.tone,
                label: slot.chipLabel(main),
                onBrand: true,
                redacted: slot.redacted),
          ]),
          const SizedBox(height: 16),
          slot.amount(
            context,
            VibeAmount(main.invoice.valor, size: 40, color: t.on),
            frame: (amount) => Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(fit: BoxFit.scaleDown, child: amount),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 10,
            spacing: 10,
            children: [
              slot.due(
                VibeDueLine(
                    text: main.dueShort,
                    tone: main.tone,
                    paid: main.paid,
                    onBrand: true,
                    center: true,
                    redacted: slot.redacted),
              ),
              slot.actions(
                vibePayButton(context, main,
                    kind: VibeButtonKind.black,
                    paidKind: VibeButtonKind.black,
                    size: VibeButtonSize.small,
                    pixLabel: 'Copiar Pix',
                    onBrand: true),
                keepSize: false,
                retryButton: VibeButton(
                    label: 'Tentar de novo',
                    kind: VibeButtonKind.black,
                    size: VibeButtonSize.small,
                    onBrand: true,
                    onPressed: slot.retry),
              ),
            ],
          ),
          if (main.note != null) ...[
            const SizedBox(height: 10),
            VibeNoteLine(
                text: main.note!, tone: main.tone, icon: 'bolt', onBrand: true),
          ],
          if (incomplete != null) incomplete,
          VibeReveal(child: stale ?? const SizedBox(width: double.infinity)),
        ]);

    Widget card() => slot.semantics(ClipRRect(
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
              VibeRefreshEdge(
                active: data.billing.refreshing,
                onBrand: true,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: empty ??
                      (main == null ? const SizedBox.shrink() : invoice(main)),
                ),
              ),
            ]),
          ),
        ));

    // Seis blocos (`PK(s,SC(['fat','bol','wifi','spd','diag','sup']))`):
    // o boleto fica no segundo lugar quando a fatura tem documento.
    final tiles = <VibeShortcut>[];
    final relevance = data.shortcuts(6);
    final real = data.billing.main;
    // O boleto tem lugar fixo (2º bloco) enquanto a consulta não termina:
    // quase toda fatura tem boleto, e assim os blocos não trocam de lugar
    // quando ela chega. Sem toque até lá.
    final reserveBoleto =
        data.can('invoices') && (slot.redacted || slot.failed);
    final boleto = real != null && real.hasBoleto && data.can('invoices')
        ? VibeShortcut(
            real.paid ? 'Baixar PDF' : 'Boleto',
            real.paid ? 'down' : 'bar',
            () => VibeInvoiceActions.openBoleto(context, real.invoice))
        : reserveBoleto
            ? const VibeShortcut('Boleto', 'bar', null)
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
        VibeReveal(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: vibeHomeAlerts(context, data)),
        ),
        const SizedBox(height: 14),
        _BlockGrid(items: tiles),
        VibeReveal(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (late != null) ...[
              const SizedBox(height: 12),
              late
            ] else if (promotion.isNotEmpty) ...[
              const SizedBox(height: 18),
              VibePromoCarousel(
                  promos: promotion,
                  title:
                      promotion.first.highlight ? 'Dicas do app' : 'Para você'),
            ],
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

/// Grade de três colunas com blocos de 88 px (`.d7 .gr`).
class _BlockGrid extends StatelessWidget {
  const _BlockGrid({required this.items});

  final List<VibeShortcut> items;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(builder: (context, constraints) {
      // Três colunas como no protótipo; com tela estreita e fonte ampliada,
      // duas, para "Velocidade" não quebrar no meio da palavra.
      final three = (constraints.maxWidth - 16) / 3 - 12 >= 68 * scale;
      final width = three
          ? (constraints.maxWidth - 16) / 3
          : (constraints.maxWidth - 8) / 2;
      return Wrap(spacing: 8, runSpacing: 8, children: [
        for (final item in items)
          SizedBox(
            width: width,
            child: Semantics(
              button: true,
              label: item.label,
              excludeSemantics: true,
              child: VibeDimmed(
                dimmed: item.onTap == null,
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
          ),
      ]);
    });
  }
}
