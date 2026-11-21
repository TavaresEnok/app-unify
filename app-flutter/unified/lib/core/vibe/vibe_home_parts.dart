import 'package:flutter/material.dart';

import 'vibe_icon.dart';
import 'vibe_text.dart';
import 'vibe_tokens.dart';

/// Peças da tela inicial do layout aprovado. Cada classe cita a classe CSS
/// correspondente do protótipo (layout-app/vibe-5-definitivas.html).

/// Valor `R$ 99,90` (`.amt`): centavos menores e alinhados pela base.
class VibeAmount extends StatelessWidget {
  const VibeAmount(this.value,
      {super.key, required this.size, required this.color});

  final double value;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final cents = (value * 100).round();
    final whole = cents ~/ 100;
    final rest = (cents % 100).toString().padLeft(2, '0');
    final grouped = whole
        .toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    final small = size * .42;
    return Text.rich(
      TextSpan(children: [
        TextSpan(
            text: 'R\$',
            style: vibeText(t, small, 650, color: color, height: 1)),
        WidgetSpan(
            alignment: PlaceholderAlignment.bottom,
            child: SizedBox(width: small * .28, height: 0)),
        TextSpan(
            text: grouped,
            style: vibeText(t, size, 780,
                color: color, height: 1, letterSpacingEm: -.035)),
        TextSpan(
            text: ',$rest',
            style: vibeText(t, size * .6, 780,
                color: color, height: 1, letterSpacingEm: -.01)),
      ]),
      semanticsLabel: 'R\$ $grouped,$rest',
      maxLines: 1,
      softWrap: false,
    );
  }
}

/// Selo de situação (`.ch`).
class VibeStatusChip extends StatelessWidget {
  const VibeStatusChip(
      {super.key,
      required this.tone,
      required this.label,
      this.onBrand = false});

  final VibeTone tone;
  final String label;
  final bool onBrand;

  static String iconFor(VibeTone tone) => switch (tone) {
        VibeTone.bad => 'alert',
        VibeTone.ok => 'check',
        _ => 'clock',
      };

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final fg = onBrand ? t.on : t.toneText(tone);
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: onBrand ? t.overlayOnBrand() : t.toneBackground(tone),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        VibeIcon(iconFor(tone), size: 14, strokeWidth: 2.2, color: fg),
        const SizedBox(width: 5),
        Text(label, style: vibeText(t, 12, 650, color: fg, height: 1)),
      ]),
    );
  }
}

/// Linha de vencimento (`.du`).
class VibeDueLine extends StatelessWidget {
  const VibeDueLine(
      {super.key,
      required this.text,
      required this.tone,
      this.paid = false,
      this.onBrand = false,
      this.center = false});

  final String text;
  final VibeTone tone;
  final bool paid;
  final bool onBrand;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final color = onBrand
        ? t.on
        : tone == VibeTone.bad
            ? t.bad
            : t.mut;
    return Row(
        mainAxisSize: center ? MainAxisSize.min : MainAxisSize.max,
        children: [
          VibeIcon(paid ? 'check' : 'cal', size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
              child: Text(text,
                  style: vibeText(t, 13, 600, color: color), maxLines: 2)),
        ]);
  }
}

/// Observação curta da fatura (`.nt`).
class VibeNoteLine extends StatelessWidget {
  const VibeNoteLine(
      {super.key,
      required this.text,
      required this.tone,
      this.icon = 'info',
      this.onBrand = false});

  final String text;
  final VibeTone tone;
  final String icon;
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final color = onBrand
        ? t.on.withValues(alpha: .9)
        : switch (tone) {
            VibeTone.warning => t.wa,
            VibeTone.bad => t.bad,
            _ => t.mut,
          };
    return Row(children: [
      VibeIcon(icon,
          size: 16,
          color: onBrand && t.on == Colors.white
              ? const Color(0xFFFFD27A)
              : color),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: vibeText(t, 12.5, 650, color: color))),
    ]);
  }
}

enum VibeButtonKind { primary, white, black, ghostOnBrand, outline, tinted }

enum VibeButtonSize { regular, small, tiny }

/// Botão do Início (`.b` com `.p`, `.w`, `.k`, `.g`, `.o`, `.t`).
class VibeButton extends StatelessWidget {
  const VibeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = VibeButtonKind.primary,
    this.size = VibeButtonSize.regular,
    this.onBrand = false,
    this.semanticLabel,
    this.dense = false,
  });

  final String label;
  final String? icon;
  final VoidCallback? onPressed;
  final VibeButtonKind kind;
  final VibeButtonSize size;
  final bool onBrand;
  final String? semanticLabel;

  /// Texto de 13 px e respiro de 12 (`.old .b`, cartão da próxima fatura).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    var (height, padding, radius, fontSize, gap) = switch (size) {
      VibeButtonSize.regular => (48.0, 18.0, 14.0, 15.0, 8.0),
      VibeButtonSize.small => (40.0, 14.0, 12.0, 14.0, 6.0),
      VibeButtonSize.tiny => (34.0, 12.0, 10.0, 13.0, 6.0),
    };
    if (dense) {
      padding = 12;
      fontSize = 13;
      gap = 6;
    }
    final (Color bg, Color fg, Color? border) = switch (kind) {
      VibeButtonKind.primary => (t.ac, t.on, null),
      VibeButtonKind.white => (Colors.white, t.whiteButtonText, null),
      VibeButtonKind.black => (const Color(0xFF0F1115), Colors.white, null),
      VibeButtonKind.ghostOnBrand => (t.overlayOnBrand(.16), t.on, null),
      VibeButtonKind.outline => onBrand
          ? (
              Colors.transparent,
              t.on,
              t.on.withValues(alpha: .45),
            )
          : (
              Colors.transparent,
              t.dark ? Colors.white : t.ink,
              t.dark ? const Color(0xFF383C46) : t.line,
            ),
      VibeButtonKind.tinted => onBrand
          ? (t.overlayOnBrand(.16), t.on, null)
          : t.dark
              ? (
                  vibeMix(const Color(0xFF121418), t.ac, .24),
                  Colors.white,
                  null
                )
              : (vibeMix(Colors.white, t.ac, .11), t.at, null),
    };
    final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: border == null
            ? BorderSide.none
            : BorderSide(color: border, width: 1.5));
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: bg,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      VibeIcon(icon!, size: 20, color: fg),
                      SizedBox(width: gap),
                    ],
                    Flexible(
                        child: Text(label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: vibeText(t, fontSize, 700,
                                color: fg, height: 1.1))),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

enum VibeNetwork { wifi, mobile, offline, unknown }

/// Situação da rede do celular com atalho para Verificar (`.cx`).
class VibeConnectionPill extends StatelessWidget {
  const VibeConnectionPill(
      {super.key, required this.network, required this.onTap});

  final VibeNetwork network;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final (icon, label, tone) = switch (network) {
      VibeNetwork.wifi => ('wifi', 'Celular no Wi-Fi', VibeTone.ok),
      VibeNetwork.mobile => (
          'cell',
          'Celular nos dados móveis',
          VibeTone.neutral
        ),
      VibeNetwork.offline => (
          'alert',
          'Celular sem internet',
          VibeTone.warning
        ),
      VibeNetwork.unknown => ('wifi', 'Sua conexão', VibeTone.neutral),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: '$label. Verificar conexão',
        excludeSemantics: true,
        child: Material(
          color: t.card,
          shape: StadiumBorder(side: BorderSide(color: t.line)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 36),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                        color: t.toneBackground(tone), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: VibeIcon(icon, size: 16, color: t.toneText(tone)),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: Text(label, style: vibeText(t, 13, 700))),
                  const SizedBox(width: 12),
                  Container(width: 1, height: 18, color: t.line),
                  const SizedBox(width: 9),
                  Text('Verificar', style: vibeText(t, 12.5, 700, color: t.at)),
                  VibeIcon('chev', size: 16, color: t.at),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão de avisos com marcador de não lidos (`.hb`).
class VibeBell extends StatelessWidget {
  const VibeBell(
      {super.key,
      required this.onTap,
      this.unread = false,
      this.onBrand = false});

  final VoidCallback onTap;
  final bool unread;
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final bg = onBrand
        ? t.overlayOnBrand(.16)
        : t.dark
            ? const Color(0xFF1A1C21)
            : t.card;
    return Semantics(
      button: true,
      label: unread ? 'Avisos, há avisos não lidos' : 'Avisos',
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: CircleBorder(
            side: onBrand || t.dark
                ? BorderSide.none
                : BorderSide(color: t.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(children: [
              Center(
                  child: VibeIcon('bell',
                      size: 20, color: onBrand ? t.on : t.ink)),
              if (unread)
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: onBrand
                          ? null
                          : Border.all(
                              color: t.dark ? const Color(0xFF1A1C21) : t.card,
                              width: 2,
                              strokeAlign: BorderSide.strokeAlignOutside),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Iniciais do assinante (`.av`).
class VibeAvatar extends StatelessWidget {
  const VibeAvatar(
      {super.key, required this.initials, this.onBrand = false, this.onTap});

  final String initials;
  final bool onBrand;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final bg = onBrand
        ? t.overlayOnBrand(.22)
        : t.dark
            ? vibeMix(const Color(0xFF15171B), t.ac, .30)
            : vibeMix(Colors.white, t.ac, .16);
    final fg = onBrand
        ? t.on
        : t.dark
            ? Colors.white
            : t.at;
    return Semantics(
      button: onTap != null,
      label: 'Minha conta',
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
                child: Text(initials,
                    style: vibeText(t, 13, 750, color: fg, height: 1))),
          ),
        ),
      ),
    );
  }
}

/// Avatar, linha pequena e nome, com o sino à direita (`.pf`).
class VibeProfileHeader extends StatelessWidget {
  const VibeProfileHeader({
    super.key,
    required this.initials,
    required this.small,
    required this.big,
    required this.onAccount,
    this.onBell,
    this.unread = false,
    this.onBrand = false,
  });

  final String initials;
  final String small;
  final String big;
  final VoidCallback onAccount;
  final VoidCallback? onBell;
  final bool unread;
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Row(children: [
      VibeAvatar(initials: initials, onBrand: onBrand, onTap: onAccount),
      const SizedBox(width: 12),
      Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
            Text(small,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: vibeText(t, 13, 500, color: onBrand ? t.on : t.mut)),
            Text(big,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: vibeText(t, 17, 750,
                    color: onBrand ? t.on : t.ink, letterSpacingEm: -.01)),
          ])),
      if (onBell != null) ...[
        const SizedBox(width: 12),
        VibeBell(onTap: onBell!, unread: unread, onBrand: onBrand),
      ],
    ]);
  }
}

/// Marca do provedor: logotipo enviado ou a inicial e o nome (`.lg`).
class VibeLogo extends StatelessWidget {
  const VibeLogo(
      {super.key, required this.name, this.logoUrl, this.onBrand = false});

  final String name;
  final String? logoUrl;
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final mark = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
          color: onBrand ? Colors.white : t.ac,
          borderRadius: BorderRadius.circular(9)),
      alignment: Alignment.center,
      child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: vibeText(t, 16, 800,
              color: onBrand ? t.whiteButtonText : t.on, height: 1)),
    );
    final word = Flexible(
        child: Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: vibeText(t, 20, 800,
                color: onBrand ? t.on : t.ink,
                height: 1,
                letterSpacingEm: -.04)));
    final url = logoUrl?.trim() ?? '';
    return Semantics(
      label: name,
      excludeSemantics: true,
      child: url.isEmpty
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              mark,
              const SizedBox(width: 8),
              word,
            ])
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160, maxHeight: 34),
              child: Image.network(url,
                  height: 30,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                  errorBuilder: (_, __, ___) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [mark, const SizedBox(width: 8), word])),
            ),
    );
  }
}

/// Título de seção (`.sec > b`).
class VibeSectionTitle extends StatelessWidget {
  const VibeSectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Row(children: [
      Expanded(
          child: Semantics(
              header: true,
              child: Text(title,
                  style: vibeText(t, 16, 750, letterSpacingEm: -.01)))),
      if (trailing != null) trailing!,
    ]);
  }
}

/// Um atalho do Início.
class VibeShortcut {
  const VibeShortcut(this.label, this.icon, this.onTap);
  final String label;
  final String icon;
  final VoidCallback onTap;
}

/// Grade de atalhos em quatro colunas (`.tg` e `.tq`).
class VibeShortcutGrid extends StatelessWidget {
  const VibeShortcutGrid({super.key, required this.items});

  final List<VibeShortcut> items;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final box = t.dark ? t.neub : vibeMix(Colors.white, t.ac, .10);
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 6.0;
      final minLabelWidth = MediaQuery.textScalerOf(context).scale(12) * 4.5;
      final columns =
          (constraints.maxWidth - gap * 3) / 4 >= minLabelWidth ? 4 : 2;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(spacing: gap, runSpacing: 14, children: [
        for (final item in items)
          SizedBox(
            width: width,
            child: Semantics(
              button: true,
              label: item.label,
              excludeSemantics: true,
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Column(children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: box, borderRadius: BorderRadius.circular(16)),
                    alignment: Alignment.center,
                    child: VibeIcon(item.icon, size: 22, color: t.at),
                  ),
                  const SizedBox(height: 8),
                  Text(item.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: vibeText(t, 12, 600, height: 1.2)),
                ]),
              ),
            ),
          ),
      ]);
    });
  }
}

/// Atalhos que deslizam na horizontal (`.service-rail`).
class VibeServiceRail extends StatelessWidget {
  const VibeServiceRail({super.key, required this.items, this.onBrand = false});

  final List<VibeShortcut> items;
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final fg = onBrand ? t.on : t.ink;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(builder: (context, constraints) {
      final minLabelWidth =
          MediaQuery.textScalerOf(context).scale(12) * 4.5 + 12;
      final visible =
          (constraints.maxWidth - 24) / 3.5 >= minLabelWidth ? 3.5 : 2.5;
      final width = (constraints.maxWidth - 8 * visible.floor()) / visible;
      return SizedBox(
        height: 88 + 30 * (scale - 1).clamp(0, 2),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 4),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return SizedBox(
              width: width,
              child: Semantics(
                button: true,
                label: item.label,
                excludeSemantics: true,
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: fg.withValues(alpha: .11),
                            shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: VibeIcon(item.icon, size: 20, color: fg),
                      ),
                      const SizedBox(height: 5),
                      Text(item.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: vibeText(t, 12, 600, color: fg, height: 1.2)),
                    ]),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

/// Uma oferta do provedor no carrossel do Início.
class VibePromo {
  const VibePromo({
    required this.title,
    this.kicker = '',
    this.text = '',
    this.cta = 'Saiba mais',
    this.imageUrl = '',
    required this.onTap,
  });

  final String kicker;
  final String title;
  final String text;
  final String cta;
  final String imageUrl;
  final VoidCallback onTap;
}

/// Carrossel de ofertas com contador, setas e pontos (`.prw`).
class VibePromoCarousel extends StatefulWidget {
  const VibePromoCarousel(
      {super.key,
      required this.promos,
      this.title = 'Para você',
      this.sidePadding = 20});

  final List<VibePromo> promos;
  final String title;
  final double sidePadding;

  @override
  State<VibePromoCarousel> createState() => _VibePromoCarouselState();
}

class _VibePromoCarouselState extends State<VibePromoCarousel> {
  final _controller = ScrollController();
  int _index = 0;
  double _step = 1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final next = (_controller.offset / _step)
          .round()
          .clamp(0, widget.promos.length - 1);
      if (next != _index) setState(() => _index = next);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int index) {
    final target = (index.clamp(0, widget.promos.length - 1)) * _step;
    _controller.animateTo(target.clamp(0, _controller.position.maxScrollExtent),
        duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final promos = widget.promos;
    if (promos.isEmpty) return const SizedBox.shrink();
    final scale = MediaQuery.textScalerOf(context).scale(1);
    Widget arrow(int delta) {
      final enabled = delta < 0 ? _index > 0 : _index < promos.length - 1;
      return Semantics(
        button: true,
        enabled: enabled,
        label: delta < 0 ? 'Promoção anterior' : 'Próxima promoção',
        excludeSemantics: true,
        child: Opacity(
          opacity: enabled ? 1 : .4,
          child: Material(
            color: t.card,
            shape: CircleBorder(side: BorderSide(color: t.line)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? () => _go(_index + delta) : null,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Transform.rotate(
                    angle: delta < 0 ? 3.14159265 : 0,
                    child: VibeIcon('chev', size: 16, color: t.ink),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      VibeSectionTitle(widget.title,
          trailing: promos.length < 2
              ? null
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('${_index + 1} de ${promos.length}',
                      style: vibeText(t, 12.5, 650, color: t.mut)),
                  const SizedBox(width: 8),
                  arrow(-1),
                  const SizedBox(width: 6),
                  arrow(1),
                ])),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth - 30;
        _step = width + 10;
        return SizedBox(
          height: 169 + 160 * (scale - 1).clamp(0, 2),
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: _SnapPhysics(_step),
            itemCount: promos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => SizedBox(
                width: width,
                child: _PromoCard(promo: promos[index], style: index % 3)),
          ),
        );
      }),
      if (promos.length > 1)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < promos.length; i++)
            Semantics(
              button: true,
              selected: i == _index,
              label: 'Promoção ${i + 1} de ${promos.length}',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _go(i),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: i == _index ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: i == _index ? t.at : t.mut,
                          borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                ),
              ),
            ),
        ]),
    ]);
  }
}

class _SnapPhysics extends ScrollPhysics {
  const _SnapPhysics(this.step, {super.parent});
  final double step;

  @override
  _SnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapPhysics(step, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    var page = position.pixels / step;
    if (velocity < -tolerance.velocity) {
      page -= .5;
    } else if (velocity > tolerance.velocity) {
      page += .5;
    }
    final target = (page.roundToDouble() * step)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(spring, position.pixels, target, velocity,
        tolerance: tolerance);
  }

  @override
  bool get allowImplicitScrolling => false;
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promo, required this.style});

  final VibePromo promo;
  final int style;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final (Decoration decoration, Color fg, Color art) = switch (style) {
      // Marca escura: degradê da marca clareada à escurecida (`.prc.p1`).
      // Marca clara, com texto escuro: do tom claro à própria marca, como o
      // rosa da galeria (`linear-gradient(125deg,#ff97d1,#fc46aa 78%)`).
      0 => (
          BoxDecoration(
              gradient: t.on == Colors.white
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                          vibeMix(Colors.white, t.ac, .92),
                          vibeMix(Colors.black, t.ac, .68),
                        ])
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0, .78],
                      colors: [vibeMix(Colors.white, t.ac, .6), t.ac])),
          t.on,
          t.on,
        ),
      1 => (
          const BoxDecoration(color: Color(0xFF15171C)),
          Colors.white,
          vibeMix(Colors.white, t.ac, .62),
        ),
      _ => (
          BoxDecoration(
              color: t.dark
                  ? vibeMix(const Color(0xFF17191E), t.ac, .20)
                  : vibeMix(Colors.white, t.ac, .12)),
          t.ink,
          t.at,
        ),
    };
    final hasImage = promo.imageUrl.trim().isNotEmpty;
    return Semantics(
      button: true,
      label: [promo.kicker, promo.title, promo.text]
          .where((s) => s.isNotEmpty)
          .join('. '),
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: decoration,
            child: InkWell(
              onTap: promo.onTap,
              child: Stack(children: [
                if (hasImage)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: 128,
                    child: Image.network(promo.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  )
                else
                  Positioned(
                    right: -10,
                    bottom: -12,
                    child: VibeArt(const ['turbo', 'wifi', 'gift'][style],
                        color: art),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FractionallySizedBox(
                    widthFactor: .64,
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (promo.kicker.isNotEmpty)
                          Text(promo.kicker,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: vibeText(t, 12, 650,
                                  color: fg.withValues(alpha: .8))),
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(promo.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: vibeText(t, 19, 800,
                                  color: fg,
                                  height: 1.12,
                                  letterSpacingEm: -.02)),
                        ),
                        if (promo.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(promo.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: vibeText(t, 12.5, 500,
                                    color: fg.withValues(alpha: .86),
                                    height: 1.3)),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: fg.withValues(alpha: .16),
                              borderRadius: BorderRadius.circular(99)),
                          child: Text(promo.cta,
                              style: vibeText(t, 12.5, 750,
                                  color: fg, height: 1.1)),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso de internet suspensa (`.al`).
class VibeAlertBox extends StatelessWidget {
  const VibeAlertBox(
      {super.key, required this.title, required this.text, this.onTap});

  final String title;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final body = t.dark ? const Color(0xFFFFD5D5) : const Color(0xFF7A1520);
    return Semantics(
      container: true,
      child: Material(
        color: t.badb,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: VibeIcon('lock', size: 20, color: t.bad)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title, style: vibeText(t, 14, 700, color: t.bad)),
                    const SizedBox(height: 2),
                    Text(text,
                        style:
                            vibeText(t, 12.5, 500, color: body, height: 1.4)),
                  ])),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Cartão com ícone em caixa, título, texto e seta (`.tr`).
class VibeActionCard extends StatelessWidget {
  const VibeActionCard(
      {super.key,
      required this.icon,
      required this.title,
      required this.text,
      required this.onTap});

  final String icon;
  final String title;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Semantics(
      button: true,
      label: '$title. $text',
      excludeSemantics: true,
      child: Material(
        color: t.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: t.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: t.tinted(.12),
                    borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: VibeIcon(icon, size: 20, color: t.at),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title, style: vibeText(t, 14, 700)),
                    Text(text, style: vibeText(t, 12.5, 500, color: t.mut)),
                  ])),
              const SizedBox(width: 12),
              VibeIcon('chev', size: 16, color: t.mut),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Ajuda quando a fatura venceu (`.lt`).
class VibeLateHelp extends StatelessWidget {
  const VibeLateHelp(
      {super.key, required this.suspended, required this.onAction});

  final bool suspended;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.line)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: t.neub, borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child:
              VibeIcon(suspended ? 'router' : 'check', size: 20, color: t.ink),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              suspended
                  ? 'Pagou e a internet não voltou?'
                  : 'Já pagou esta fatura?',
              style: vibeText(t, 14, 700)),
          const SizedBox(height: 3),
          Text(
              suspended
                  ? 'Depois que o pagamento é confirmado, o acesso volta sozinho em alguns minutos.'
                  : 'Pelo Pix, a confirmação sai em minutos. Pelo boleto, em até 3 dias úteis.',
              style: vibeText(t, 12.5, 500, color: t.mut, height: 1.4)),
          if (onAction != null)
            InkWell(
              onTap: onAction,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1,
                  child: Text(
                      suspended ? 'Falar com o suporte' : 'Enviar comprovante',
                      style: vibeText(t, 13, 650, color: t.at)),
                ),
              ),
            ),
        ])),
      ]),
    );
  }
}
