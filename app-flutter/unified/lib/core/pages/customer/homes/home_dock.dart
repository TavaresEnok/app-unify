import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/fatura.dart';
import '../../../utils/app_formatters.dart';
import '../../../vibe/vibe_controls.dart';
import '../../../vibe/vibe_home_parts.dart';
import '../../../vibe/vibe_icon.dart';
import '../../../vibe/vibe_invoice.dart';
import '../../../vibe/vibe_page_parts.dart' show VibeGap;
import '../../../vibe/vibe_text.dart';
import '../../../vibe/vibe_tokens.dart';
import '../../invoice_detail_page.dart';
import 'vibe_home_data.dart';

/// 2º lugar — Dock de serviços (layout_03, conceito 22 da página das nove
/// telas): marca fixa no topo, cartão escuro da fatura, serviços em uma
/// faixa, ofertas e avisos.
class VibeDockHome extends ConsumerStatefulWidget {
  const VibeDockHome({super.key, required this.onNavigate, this.onRefresh});

  final ValueChanged<String> onNavigate;
  final Future<void> Function()? onRefresh;

  @override
  ConsumerState<VibeDockHome> createState() => _VibeDockHomeState();
}

class _VibeDockHomeState extends ConsumerState<VibeDockHome> {
  String? _selected;
  int _offer = 0;

  static String _key(Fatura i) => jsonEncode([
        i.numero,
        i.vencimento.toIso8601String(),
        i.valor,
        i.pixCopiaECola,
        i.urlBoleto,
        i.linhaDigitavel,
      ]);

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final p = t.dock!;
    final data = VibeHomeData.watch(ref, widget.onNavigate);
    final billing = data.billing;
    final open = billing.open;

    // Com duas ou mais faturas em aberto o assinante escolhe qual pagar
    // (`choice(s)`). Se a escolhida mudar na consulta, a escolha é refeita
    // por ele: o app não troca de fatura sozinho.
    if (_selected == null && open.length > 1 && billing.ready) {
      _selected = _key(open.first);
    }
    Fatura? chosen;
    if (open.length > 1) {
      for (final i in open) {
        if (_key(i) == _selected) chosen = i;
      }
    }
    final stale = open.length > 1 && chosen == null && _selected != null;
    final view = open.length > 1
        ? (chosen == null ? null : VibeInvoiceView(chosen))
        : billing.main;

    final children = <Widget>[];
    if (data.can('invoices')) {
      if (open.length > 1) {
        children.add(_choice(context, open, chosen, billing));
      }
      if (stale) {
        children.add(_message(
            context, 'A fatura selecionada mudou. Selecione novamente.'));
      } else {
        children.add(_invoiceCard(context, data, view));
      }
      final alert = _trust(context, data);
      if (alert != null) children.add(alert);
    }
    children.add(_services(context, data));
    final promos = data.promos(context);
    if (promos.isNotEmpty) {
      children.add(_offers(context, promos));
    } else if (billing.overdue || data.suspended) {
      children.add(_installation(context, data));
    }
    if (data.can('notifications')) {
      children.add(_listRow(context, 'i-bell', 'Avisos do provedor',
          () => data.onNavigate('notifications')));
    }

    final list = ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [VibeGap(gap: 10, children: children)],
    );
    // A marca fixa (`.app-brand`) fica na moldura do app, acima das abas.
    return ColoredBox(
      color: p.base,
      child: widget.onRefresh == null
          ? list
          : RefreshIndicator(onRefresh: widget.onRefresh!, child: list),
    );
  }

  Widget _message(BuildContext context, String text) {
    final t = VibeTokens.of(context);
    final p = t.dock!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: p.hair)),
      child: Text(text, style: vibeText(t, 14, 600, color: p.ink)),
    );
  }

  /// Escolha da mensalidade quando há duas ou mais em aberto (`.fl-choice`).
  Widget _choice(BuildContext context, List<Fatura> open, Fatura? chosen,
      VibeBilling billing) {
    final t = VibeTokens.of(context);
    final p = t.dock!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.hair)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
              child: Text('${open.length} faturas em aberto',
                  style: vibeText(t, 12, 700, color: p.ink))),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: 'Total ',
                    style: vibeText(t, 12, 500, color: p.muted)),
                TextSpan(
                    text: AppFormatters.currency(billing.openTotal),
                    style: vibeText(t, 12, 700, color: p.muted)),
              ]),
              textAlign: TextAlign.right,
            ),
          ),
        ]),
        const SizedBox(height: 7),
        LayoutBuilder(builder: (context, constraints) {
          final half = (constraints.maxWidth - 5) / 2;
          return Wrap(spacing: 5, runSpacing: 5, children: [
            for (final invoice in open)
              SizedBox(
                width: half,
                child:
                    _choiceButton(context, invoice, identical(invoice, chosen)),
              ),
          ]);
        }),
      ]),
    );
  }

  Widget _choiceButton(BuildContext context, Fatura invoice, bool on) {
    final t = VibeTokens.of(context);
    final p = t.dock!;
    final label = VibeInvoiceView(invoice).monthTitle;
    return Semantics(
      button: true,
      selected: on,
      label: 'Fatura de $label, ${AppFormatters.currency(invoice.valor)}',
      excludeSemantics: true,
      child: Material(
        color: on ? p.ink : Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
            side: BorderSide(color: on ? p.ink : p.hair)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _selected = _key(invoice)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(
                  child: Text(label,
                      style: vibeText(t, 13, 600, color: on ? p.base : p.ink)),
                ),
                if (on) ...[
                  const SizedBox(width: 5),
                  VibeIcon('i-check',
                      size: 14, strokeWidth: 1.7, color: p.base),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }

  /// Cartão escuro da fatura (`.fl-invoice.layout-dock`).
  Widget _invoiceCard(
      BuildContext context, VibeHomeData data, VibeInvoiceView? view) {
    final t = VibeTokens.of(context);
    final p = t.dock!;
    final billing = data.billing;
    Widget body;
    if (view == null || billing.failed) {
      if (billing.loading) {
        body = _invoiceLoading(context);
      } else if (billing.failed) {
        body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Faturas indisponíveis',
              style:
                  vibeText(t, 18, 700, color: p.hink, letterSpacingEm: -.03)),
          const SizedBox(height: 4),
          Text('Não foi possível consultar as mensalidades.',
              style: vibeText(t, 14, 500, color: p.hmuted)),
          const SizedBox(height: 10),
          _dockButton(context, 'i-history', 'Tentar novamente', true,
              billing.finance.fetchHistory),
        ]);
      } else {
        body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sem fatura emitida',
              style:
                  vibeText(t, 18, 700, color: p.hink, letterSpacingEm: -.03)),
          const SizedBox(height: 4),
          Text(
              billing.finance.incompleteInvoices > 0
                  ? 'Algumas faturas estão com dados incompletos. Consulte o provedor.'
                  : 'A próxima mensalidade aparecerá aqui.',
              style: vibeText(t, 14, 500, color: p.hmuted)),
        ]);
      }
    } else {
      final chipIcon = view.paid
          ? 'i-check'
          : view.overdue
              ? 'i-clock'
              : 'i-calendar';
      final invoice = view.invoice;
      final buttons = <Widget>[
        if (view.paid)
          _dockButton(context, 'i-history', 'Ver no histórico', true,
              () => data.onNavigate('invoices'))
        else ...[
          if (view.hasPix)
            _dockButton(context, 'i-pix', 'Copiar Pix', true,
                () => VibeInvoiceActions.copyPix(context, invoice)),
          if (view.hasBoleto)
            _dockButton(context, 'i-boleto', 'Ver boleto', !view.hasPix,
                () => VibeInvoiceActions.openBoleto(context, invoice)),
          if (view.hasLine && (!view.hasPix || !view.hasBoleto))
            _dockButton(
                context,
                'i-copy',
                'Copiar código de barras',
                !view.hasPix && !view.hasBoleto,
                () => VibeInvoiceActions.copyLine(context, invoice)),
          if (!view.hasPaymentData)
            _dockButton(context, 'i-support', 'Consultar suporte', false,
                () => data.onNavigate('support')),
        ],
      ];
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text('Fatura de ${view.month}',
                  style: vibeText(t, 14, 650,
                      color: p.hink, height: 1.3, letterSpacingEm: -.017)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
                color: p.htint,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: p.hthin)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              VibeIcon(chipIcon, size: 14, strokeWidth: 1.7, color: p.hink),
              const SizedBox(width: 4),
              Text(view.chip,
                  style: vibeText(t, 12, 650,
                      color: p.hink, height: 1.2, letterSpacingEm: -.0175)),
            ]),
          ),
        ]),
        const SizedBox(height: 11),
        Container(
          decoration:
              BoxDecoration(border: Border(top: BorderSide(color: p.hthin))),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: 'R\$ ',
                      style: vibeText(t, 19.78, 550,
                          color: p.hink, height: 1.05, letterSpacingEm: -.03)),
                  TextSpan(
                      text: AppFormatters.currency(invoice.valor)
                          .replaceFirst('R\$', '')
                          .trim(),
                      style: vibeText(t, 46, 620,
                          color: p.hink,
                          height: 1.02,
                          letterSpacingEm: -.0565)),
                ]),
                semanticsLabel: AppFormatters.currency(invoice.valor),
              ),
            ),
            const SizedBox(height: 5),
            Text(view.dueLong,
                style: vibeText(t, 14, 500,
                    color: p.hmuted, height: 1.35, letterSpacingEm: -.009)),
          ]),
        ),
        const SizedBox(height: 10),
        if (buttons.length == 1)
          buttons.first
        else
          IntrinsicHeight(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: buttons[0]),
              const SizedBox(width: 8),
              Expanded(child: buttons[1]),
            ]),
          ),
        if (buttons.length > 2) ...[const SizedBox(height: 8), buttons[2]],
      ]);
    }
    return Semantics(
      container: true,
      child: GestureDetector(
        onTap: view == null
            ? null
            : () => openSubscriberInvoice(context, view.invoice),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 19),
          decoration: BoxDecoration(
            color: p.hero,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(17),
                topRight: Radius.circular(17),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4)),
            border: Border.all(color: p.hthin),
          ),
          child: body,
        ),
      ),
    );
  }

  Widget _invoiceLoading(BuildContext context) {
    final t = VibeTokens.of(context);
    final p = t.dock!;
    return Semantics(
      label: 'Consultando suas faturas',
      liveRegion: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text('Consultando suas faturas…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: vibeText(t, 14, 650,
                      color: p.hink, height: 1.3, letterSpacingEm: -.017)),
            ),
          ),
          const SizedBox(width: 8),
          VibeShimmerBar(width: 78, height: 26, radius: 99, color: p.hink),
        ]),
        const SizedBox(height: 11),
        Container(
          decoration:
              BoxDecoration(border: Border(top: BorderSide(color: p.hthin))),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            VibeShimmerBar(width: 170, height: 47, radius: 10, color: p.hink),
            const SizedBox(height: 5),
            VibeShimmerBar(width: 155, height: 19, radius: 6, color: p.hink),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: VibeShimmerBar(height: 44, radius: 10, color: p.hink)),
          const SizedBox(width: 8),
          Expanded(
              child: VibeShimmerBar(height: 44, radius: 10, color: p.hink)),
        ]),
      ]),
    );
  }

  Widget _dockButton(BuildContext context, String icon, String label, bool main,
      VoidCallback onTap) {
    final t = VibeTokens.of(context);
    final p = t.dock!;
    final fg = main ? p.onmain : p.hink;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: main ? p.main : p.htint,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: main ? Colors.transparent : p.hthin)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                VibeIcon(icon, size: 18, strokeWidth: 1.7, color: fg),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: vibeText(t, 14, 650,
                          color: fg, height: 1.15, letterSpacingEm: -.015)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  /// Fatura vencida ou internet suspensa (`.fl-alert`).
  Widget? _trust(BuildContext context, VibeHomeData data) {
    if (!data.billing.overdue) return null;
    final t = VibeTokens.of(context);
    final fg = t.dark ? const Color(0xFFFFC599) : const Color(0xFF633319);
    final bg = t.dark ? const Color(0xFF2D1E14) : const Color(0xFFFFF0D9);
    final accentBorder =
        t.dark ? const Color(0xFFD97943) : const Color(0xFFB35B30);
    final edgeBorder =
        t.dark ? const Color(0xFF6E3D22) : const Color(0xFFD0A287);
    final suspended = data.suspended;
    final action = data.can('invoices')
        ? ('Liberação por confiança', () => data.onNavigate('trust_unlock'))
        : data.can('support')
            ? ('Consultar suporte', () => data.onNavigate('support'))
            : null;
    // Borda de cores diferentes não aceita raio no Flutter: o recorte
    // arredondado fica por fora.
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            left: BorderSide(color: accentBorder, width: 4),
            top: BorderSide(color: edgeBorder),
            right: BorderSide(color: edgeBorder),
            bottom: BorderSide(color: edgeBorder),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(11, 9, 11, 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: VibeIcon(suspended ? 'i-wifi' : 'i-clock',
                size: 20, strokeWidth: 1.7, color: fg),
          ),
          const SizedBox(width: 9),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(suspended ? 'Internet suspensa' : 'Fatura vencida',
                  style: vibeText(t, 15, 700, color: fg)),
              if (action != null)
                InkWell(
                  onTap: action.$2,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Flexible(
                          child: Text(action.$1,
                              style: vibeText(t, 13, 650, color: fg))),
                      const SizedBox(width: 2),
                      VibeIcon('i-right',
                          size: 14, strokeWidth: 1.7, color: fg),
                    ]),
                  ),
                )
              else
                const SizedBox(height: 7),
            ]),
          ),
        ]),
      ),
    );
  }

  /// Serviços em uma faixa (`.fl-services.fl-mini`).
  Widget _services(BuildContext context, VibeHomeData data) {
    final t = VibeTokens.of(context);
    final p = t.dock!;
    final items = data.shortcuts(4);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(
        header: true,
        child: Text('Meus serviços',
            style: vibeText(t, 16, 650,
                color: p.ink, height: 1.25, letterSpacingEm: -.028)),
      ),
      const SizedBox(height: 5),
      VibeDockShortcuts(items: items),
    ]);
  }

  /// Ofertas do provedor (`.pr-module.pr-panorama`): uma por vez, com
  /// contador e setas.
  Widget _offers(BuildContext context, List<VibePromo> promos) {
    final t = VibeTokens.of(context);
    final p = t.dock!;
    final index = _offer.clamp(0, promos.length - 1);
    final promo = promos[index];
    final multiple = promos.length > 1;
    Widget step(int delta, String icon, String label) => Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          // Área de toque de 44 px em volta do círculo de 27 px do desenho.
          child: InkResponse(
            radius: 22,
            onTap: () => setState(
                () => _offer = (index + delta + promos.length) % promos.length),
            child: SizedBox(
              width: 38,
              height: 44,
              child: Center(
                child: Container(
                  width: 27,
                  height: 27,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: p.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.hair)),
                  child:
                      VibeIcon(icon, size: 14, strokeWidth: 1.7, color: p.ink),
                ),
              ),
            ),
          ),
        );
    final hasImage = promo.imageUrl.trim().isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: 44,
        child: Row(children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                  promo.highlight
                      ? 'Dicas do app'
                      : multiple
                          ? 'Ofertas do provedor'
                          : 'Oferta do provedor',
                  style: vibeText(t, 16, 650,
                      color: p.ink, height: 1.2, letterSpacingEm: -.028)),
            ),
          ),
          if (multiple) ...[
            Text('${index + 1} de ${promos.length}',
                style: vibeText(t, 12, 500,
                    color: p.muted, letterSpacingEm: -.0175)),
            const SizedBox(width: 4),
            step(-1, 'i-left', 'Anterior'),
            step(1, 'i-right', 'Próximo'),
          ],
        ]),
      ),
      const SizedBox(height: 2),
      Semantics(
        button: true,
        label: '${promo.highlight ? promo.cta : 'Ver oferta'}, ${promo.title}',
        excludeSemantics: true,
        child: Material(
          color: p.hero,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: promo.onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 107),
              child: Stack(children: [
                Positioned(
                  top: 5,
                  bottom: 5,
                  right: 5,
                  width: 150,
                  child: hasImage
                      ? ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            colors: [Colors.transparent, Colors.black],
                            stops: [0, .28],
                          ).createShader(rect),
                          blendMode: BlendMode.dstIn,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.network(promo.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink()),
                          ),
                        )
                      : Align(
                          alignment: Alignment.centerRight,
                          child: Opacity(
                            opacity: .9,
                            child: promo.icon.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(right: 14),
                                    child: VibeIcon(promo.icon,
                                        size: 72,
                                        strokeWidth: 1.1,
                                        color: p.main),
                                  )
                                : VibeArt(
                                    promo.art.isNotEmpty
                                        ? promo.art
                                        : const [
                                            'turbo',
                                            'wifi',
                                            'gift'
                                          ][index % 3],
                                    size: 104,
                                    color: p.main),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(21, 9, 0, 9),
                  child: FractionallySizedBox(
                    widthFactor: .56,
                    alignment: Alignment.centerLeft,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(promo.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: vibeText(t, 23, 670,
                                  color: Colors.white,
                                  height: 1.08,
                                  letterSpacingEm: -.035)),
                          if (promo.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(promo.text,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: vibeText(t, 13, 500,
                                      color: const Color(0xFFF2F1E8),
                                      height: 1.25,
                                      letterSpacingEm: -.016)),
                            ),
                          const SizedBox(height: 11),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Flexible(
                                child: Text(
                                    promo.highlight ? promo.cta : 'Ver oferta',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: vibeText(t, 13, 650,
                                        color: Colors.white,
                                        height: 1.15,
                                        letterSpacingEm: -.016))),
                            const SizedBox(width: 3),
                            const VibeIcon('i-right',
                                size: 15,
                                strokeWidth: 1.7,
                                color: Colors.white),
                          ]),
                        ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  /// Painel no lugar das ofertas quando há atraso (`utilityPanel`).
  Widget _installation(BuildContext context, VibeHomeData data) {
    final t = VibeTokens.of(context);
    final p = t.dock!;
    final rows = <(String, String)>[
      if (data.user?.nome.trim().isNotEmpty == true)
        ('Titular', data.shortName),
      if (data.user?.contratoId != null)
        ('Contrato', '${data.user!.contratoId}'),
      if (data.providerName.isNotEmpty) ('Provedor', data.providerName),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(
        header: true,
        child: Text('Dados da instalação',
            style: vibeText(t, 16, 650,
                color: p.ink, height: 1.25, letterSpacingEm: -.028)),
      ),
      const SizedBox(height: 5),
      Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: p.hair)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: p.soft, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: VibeIcon('i-pin',
                  size: 21, strokeWidth: 1.7, color: p.onwash),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.plan.isEmpty ? 'Seu plano' : data.plan,
                        style: vibeText(t, 14, 700, color: p.ink)),
                    Text('Internet residencial',
                        style: vibeText(t, 12, 500, color: p.muted)),
                  ]),
            ),
          ]),
          const SizedBox(height: 6),
          for (final (key, value) in rows)
            Container(
              decoration:
                  BoxDecoration(border: Border(top: BorderSide(color: p.hair))),
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(children: [
                Text(key, style: vibeText(t, 13, 500, color: p.muted)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(value,
                        textAlign: TextAlign.right,
                        style: vibeText(t, 13, 650, color: p.ink))),
              ]),
            ),
          if (data.can('contract'))
            _listRow(context, 'i-contract', 'Consultar contrato',
                () => data.onNavigate('contract'),
                boxed: false),
        ]),
      ),
    ]);
  }

  /// Linha de serviço em cartão (`.fl-service.list`).
  Widget _listRow(
      BuildContext context, String icon, String label, VoidCallback onTap,
      {bool boxed = true}) {
    final t = VibeTokens.of(context);
    final p = t.dock!;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: p.soft, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: VibeIcon(icon, size: 21, strokeWidth: 1.7, color: p.onwash),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: vibeText(t, 14, 620,
                    color: p.ink, height: 1.2, letterSpacingEm: -.015))),
        VibeIcon('i-right', size: 16, strokeWidth: 1.7, color: p.muted),
      ]),
    );
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: boxed ? p.card : Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
            side: boxed ? BorderSide(color: p.hair) : BorderSide.none),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: row),
      ),
    );
  }
}

/// Keeps the four-column dock when labels fit and expands to two columns
/// when the system font scale would split a service name.
class VibeDockShortcuts extends StatelessWidget {
  const VibeDockShortcuts({super.key, required this.items});
  final List<VibeShortcut> items;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final p = t.dock!;
    final style = vibeText(t, 12, 620,
        color: p.ink, height: 1.2, letterSpacingEm: -.0175);
    return LayoutBuilder(builder: (context, constraints) {
      final fourWidth = (constraints.maxWidth - 10) / 4;
      final fits =
          items.every((item) => item.label.split(RegExp(r'\s+')).every((word) {
                final painter = TextPainter(
                    text: TextSpan(text: word, style: style),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                    maxLines: 1)
                  ..layout();
                final width = painter.width;
                painter.dispose();
                return width + 4 <= fourWidth;
              }));
      final columns = fits ? 4 : 2;
      final width = (constraints.maxWidth - 10) / columns;
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: p.hair)),
        child: Wrap(children: [
          for (final item in items)
            SizedBox(
                width: width,
                child: Semantics(
                  button: true,
                  label: item.label,
                  excludeSemantics: true,
                  child: InkWell(
                      onTap: item.onTap,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 5),
                        child: Column(children: [
                          SizedBox(
                              width: 34,
                              height: 34,
                              child: Center(
                                  child: VibeIcon(item.icon,
                                      size: 21,
                                      strokeWidth: 1.7,
                                      color: p.mark))),
                          const SizedBox(height: 5),
                          Text(item.label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: style),
                        ]),
                      )),
                )),
        ]),
      );
    });
  }
}
