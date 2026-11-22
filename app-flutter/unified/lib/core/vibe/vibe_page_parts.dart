import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'vibe_home_parts.dart' show VibeNetwork;
export 'vibe_controls.dart';
import 'vibe_icon.dart';
import 'vibe_logo.dart';
import 'vibe_text.dart';
import 'vibe_tokens.dart';

/// Peças das páginas internas do layout aprovado (classes `g-*` do
/// protótipo). Medidas e cores seguem o CSS `.m .gapp …`.

/// Cabeçalho da página (`.g-hd`): faixa na cor do destaque do layout ou,
/// na tela Dock, um cartão abaixo da marca (`.gapp.kb .g-hd`).
class VibePageHeader extends StatelessWidget {
  const VibePageHeader(
      {super.key,
      required this.title,
      this.subtitle,
      this.onBack,
      this.actions = const []});

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  /// Ações à direita do título (ícone na cor do texto do cabeçalho).
  final List<VibeHeaderAction> actions;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final dock = t.dock != null;
    final content = Row(children: [
      if (onBack != null) ...[
        Semantics(
          button: true,
          label: 'Voltar',
          excludeSemantics: true,
          child: Material(
            color: t.hx.withValues(alpha: .15),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onBack,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Transform.rotate(
                      angle: math.pi,
                      child: VibeIcon('chev', size: 20, color: t.hx)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(title,
                    style: vibeText(t, 21, 800,
                        color: t.hx, height: 1.15, letterSpacingEm: -.02)),
              ),
              if (subtitle?.trim().isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!,
                      style: vibeText(t, 12.5, 500,
                          color: t.hx.withValues(alpha: .82))),
                ),
            ]),
      ),
      for (final action in actions)
        IconButton(
          tooltip: action.tooltip,
          onPressed: action.onPressed,
          icon: VibeIcon(action.icon, size: 20, color: t.hx),
        ),
    ]);
    if (dock) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
              color: t.hero, borderRadius: BorderRadius.circular(t.rad)),
          child: content,
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      decoration: BoxDecoration(
        color: t.hero,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(t.rad)),
      ),
      child: content,
    );
  }
}

/// Ação do cabeçalho da página.
class VibeHeaderAction {
  const VibeHeaderAction(
      {required this.icon, required this.tooltip, required this.onPressed});
  final String icon;
  final String tooltip;
  final VoidCallback? onPressed;
}

/// Página com corpo próprio (rolagem, estados) sob o cabeçalho do layout,
/// para telas que antes usavam a barra do Material. O voltar aparece
/// quando há página anterior.
class VibeHeaderPage extends StatelessWidget {
  const VibeHeaderPage({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<VibeHeaderAction> actions;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final navigator = Navigator.of(context);
    return Material(
      color: t.bg,
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          VibePageHeader(
            title: title,
            subtitle: subtitle,
            actions: actions,
            onBack: navigator.canPop() ? () => navigator.maybePop() : null,
          ),
          Expanded(child: body),
        ]),
      ),
    );
  }
}

/// Página interna completa: faixa de status na cor do fundo, cabeçalho que
/// rola com o conteúdo e corpo com espaçamento de 12 entre os blocos
/// (`.g-bd`). Na tela Dock a marca fica fixa acima (`.app-brand`).
class VibePageScaffold extends StatelessWidget {
  const VibePageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.children,
    this.body,
    this.onRefresh,
    this.masthead,
  }) : assert((children == null) != (body == null));

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  /// Blocos do corpo, empilhados com 12 de espaço.
  final List<Widget>? children;

  /// Corpo com rolagem própria, abaixo de um cabeçalho fixo.
  final Widget? body;
  final Future<void> Function()? onRefresh;

  /// Marca fixa da tela Dock (só no layout_03).
  final Widget? masthead;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final header =
        VibePageHeader(title: title, subtitle: subtitle, onBack: onBack);
    Widget content;
    if (children != null) {
      final list = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          header,
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: VibeGap(children: children!),
          ),
        ],
      );
      content = onRefresh == null
          ? list
          : RefreshIndicator(onRefresh: onRefresh!, child: list);
    } else {
      content = Column(children: [header, Expanded(child: body!)]);
    }
    // Material próprio: linhas e botões com toque funcionam mesmo fora de
    // um Scaffold.
    return Material(
      color: t.bg,
      child: SafeArea(
        bottom: false,
        child: masthead == null
            ? content
            : Column(children: [masthead!, Expanded(child: content)]),
      ),
    );
  }
}

/// Coluna com 12 de espaço entre os filhos (`gap:12px`).
class VibeGap extends StatelessWidget {
  const VibeGap({super.key, required this.children, this.gap = 12});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final visible = children
        .where((c) => c is! SizedBox || c.child != null || c.height != 0)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          visible[i],
        ],
      ],
    );
  }
}

/// Cartão (`.g-cd`); `main` usa o espaçamento de 16 (`.g-main`).
class VibeCard extends StatelessWidget {
  const VibeCard(
      {super.key,
      required this.child,
      this.main = false,
      this.center = false,
      this.padding});

  final Widget child;
  final bool main;
  final bool center;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Container(
      padding: padding ??
          (main
              ? const EdgeInsets.all(16)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 6)),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(math.max(10, t.rad - 2)),
        border: Border.all(color: t.line),
      ),
      child: center
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [child])
          : child,
    );
  }
}

/// Linhas de um cartão separadas por um fio (`.g-row + .g-row`).
class VibeRows extends StatelessWidget {
  const VibeRows({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) Divider(height: 1, thickness: 1, color: t.line),
        children[i],
      ],
    ]);
  }
}

/// Linha tocável com ícone em caixa, título, texto e seta (`.g-row`).
class VibeRow extends StatelessWidget {
  const VibeRow({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.plainIcon = false,
    this.showChevron = true,
  });

  final String? icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Ícone solto na cor da marca, sem caixa (`.g-row > .ic:first-child`).
  final bool plainIcon;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final iconColor =
        t.dark && !plainIcon ? vibeMix(t.ac, Colors.white, .40) : t.at;
    return Semantics(
      button: onTap != null,
      label: [title, if (subtitle != null) subtitle!].join('. '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              if (icon != null) ...[
                if (plainIcon)
                  VibeIcon(icon!, size: 20, color: iconColor)
                else
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: t.ac.withValues(alpha: t.dark ? .22 : .15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: VibeIcon(icon!, size: 20, color: iconColor),
                  ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: vibeText(t, 14, 700, height: 1.3)),
                      if (subtitle?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(subtitle!,
                              style: vibeText(t, 12.5, 500,
                                  color: t.mut, height: 1.35)),
                        ),
                    ]),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ] else if (showChevron && onTap != null) ...[
                const SizedBox(width: 12),
                VibeIcon('chev', size: 16, color: t.mut),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// Rótulo e valor (`.g-kv`).
class VibeKv extends StatelessWidget {
  const VibeKv(this.label, this.value,
      {super.key, this.leading, this.muted = false});

  final String label;
  final String value;
  final Widget? leading;

  /// Valor ainda sem medição (`.g-kv em`): cinza e sem peso.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // O rótulo ocupa até 45% da linha; o valor fica com o restante,
        // alinhado à direita.
        ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .4),
            child: Text(label, style: vibeText(t, 13.5, 500, color: t.mut))),
        const SizedBox(width: 12),
        Expanded(
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            Flexible(
                child: Text(value,
                    textAlign: TextAlign.right,
                    style: muted
                        ? vibeText(t, 13.5, 500, color: t.mut)
                        : vibeText(t, 13.5, 650))),
          ]),
        ),
      ]),
    );
  }
}

/// Lista de rótulos e valores com fio entre eles (`.g-kv + .g-kv`).
class VibeKvList extends StatelessWidget {
  const VibeKvList(this.items, {super.key});

  final List<VibeKv> items;

  @override
  Widget build(BuildContext context) => VibeRows(children: items);
}

/// Botão das páginas (`.g-btn`, `.ghost`, `.danger`, `.sm`).
class VibePageButton extends StatelessWidget {
  const VibePageButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.ghost = false,
    this.danger = false,
    this.small = false,
    this.expand = true,
  });

  final String label;
  final String? icon;
  final VoidCallback? onPressed;
  final bool ghost;
  final bool danger;
  final bool small;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final bg = danger
        ? const Color(0xFFD92D20)
        : ghost
            ? Colors.transparent
            : t.ac;
    final fg = danger
        ? Colors.white
        : ghost
            ? t.ink
            : t.on;
    final disabled = onPressed == null;
    final button = Opacity(
      opacity: disabled ? .6 : 1,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(math.max(10, t.rad - 4)),
          side: ghost ? BorderSide(color: t.line, width: 1.5) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: small ? 40 : 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    VibeIcon(icon!, size: 16, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style: vibeText(t, small ? 13.5 : 14.5, 750,
                            color: fg, height: 1.2)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
        button: true,
        enabled: !disabled,
        label: label,
        excludeSemantics: true,
        child: button);
  }
}

/// Dois botões lado a lado (`.g-two`).
class VibeTwo extends StatelessWidget {
  const VibeTwo(this.first, this.second, {super.key});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(1) > 1.4) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        first,
        const SizedBox(height: 8),
        second,
      ]);
    }
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: first),
        const SizedBox(width: 8),
        Expanded(child: second),
      ]),
    );
  }
}

/// Seletor de duas ou mais opções (`.g-seg`).
class VibeSegmented<T> extends StatelessWidget {
  const VibeSegmented(
      {super.key,
      required this.options,
      required this.selected,
      required this.onChanged});

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.ink.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        for (final (value, label) in options)
          Expanded(
            child: Semantics(
              button: true,
              selected: value == selected,
              label: label,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  constraints: const BoxConstraints(minHeight: 38),
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: value == selected ? t.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: value == selected
                        ? const [
                            BoxShadow(
                                color: Color(0x1F000000),
                                blurRadius: 3,
                                offset: Offset(0, 1))
                          ]
                        : null,
                  ),
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: vibeText(t, 13.5, 700,
                          color: value == selected ? t.ink : t.mut)),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Selo das páginas (`.g-chip`).
class VibePageChip extends StatelessWidget {
  const VibePageChip({super.key, required this.tone, required this.label});

  final VibeTone tone;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final (Color bg, Color fg) = switch (tone) {
      VibeTone.bad => t.dark
          ? (t.badb, t.bad)
          : (const Color(0xFFFDE2E2), const Color(0xFFB42318)),
      VibeTone.ok => t.dark
          ? (const Color(0xFF1A3B2C), const Color(0xFFA8EDC4))
          : (const Color(0xFFDCFCE7), const Color(0xFF166534)),
      VibeTone.warning => t.dark
          ? (t.wab, t.wa)
          : (const Color(0xFFFEF0C7), const Color(0xFF93370D)),
      VibeTone.neutral => (t.ink.withValues(alpha: .09), t.ink),
    };
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      // `widthFactor: 1`: o selo fica do tamanho do texto, sem esticar.
      child: Center(
          widthFactor: 1,
          child:
              Text(label, style: vibeText(t, 12, 700, color: fg, height: 1.1))),
    );
  }
}

/// Botões secundários em pílula clara (`.g-links`).
class VibeLinkButtons extends StatelessWidget {
  const VibeLinkButtons({super.key, required this.items});

  final List<(String icon, String label, VoidCallback? onTap)> items;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Row(children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          child: Semantics(
            button: true,
            label: items[i].$2,
            excludeSemantics: true,
            child: Material(
              color: t.ink.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: items[i].$3,
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: t.dock != null ? 44 : 40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          VibeIcon(items[i].$1, size: 16, color: t.ink),
                          const SizedBox(width: 6),
                          Flexible(
                              child: Text(items[i].$2,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  style: vibeText(t, 13, 650, height: 1.2))),
                        ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ]);
  }
}

/// Rótulo pequeno (`.g-lbl`).
class VibeLabel extends StatelessWidget {
  const VibeLabel(this.text, {super.key, this.icon});

  final String text;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[
        VibeIcon(icon!, size: 16, color: t.mut),
        const SizedBox(width: 5),
      ],
      Flexible(child: Text(text, style: vibeText(t, 12.5, 600, color: t.mut))),
    ]);
  }
}

/// Valor grande das páginas (`.g-amt`).
class VibePageAmount extends StatelessWidget {
  const VibePageAmount(this.value, {super.key, this.size = 36});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final cents = (value * 100).round();
    final whole = (cents ~/ 100)
        .toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    final rest = (cents % 100).toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(
              text: 'R\$',
              style: vibeText(t, size * .42, 700,
                  height: 1, letterSpacingEm: -.03 / .42)),
          // O espaço fica no tamanho do valor, como no protótipo
          // (`<small>R$</small> 99`): é ele que separa o cifrão.
          TextSpan(
              text: ' ',
              style: vibeText(t, size * .55, 800,
                  height: 1, letterSpacingEm: -.03)),
          TextSpan(
              text: whole,
              style: vibeText(t, size, 800, height: 1, letterSpacingEm: -.03)),
          TextSpan(
              text: ',$rest',
              style: vibeText(t, size * .62, 800,
                  height: 1, letterSpacingEm: -.03 / .62)),
        ]),
        semanticsLabel: 'R\$ $whole,$rest',
      ),
    );
  }
}

/// Linha de apoio com ícone (`.g-sub`).
class VibeSubLine extends StatelessWidget {
  const VibeSubLine(
      {super.key, required this.icon, required this.text, this.tone});

  final String icon;
  final String text;
  final VibeTone? tone;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final color = switch (tone) {
      VibeTone.bad =>
        t.dark ? const Color(0xFFFF8F8F) : const Color(0xFFD92D20),
      VibeTone.ok => t.dark ? const Color(0xFF6EE29B) : const Color(0xFF15803D),
      VibeTone.warning =>
        t.dark ? const Color(0xFFFBBF4C) : const Color(0xFFB54708),
      _ => t.mut,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        VibeIcon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: vibeText(t, 13, 600, color: color))),
      ]),
    );
  }
}

/// Texto de apoio (`.g-note`) e parágrafo (`.g-p`).
class VibeNote extends StatelessWidget {
  const VibeNote(this.text,
      {super.key, this.paragraph = false, this.center = false});

  final String text;
  final bool paragraph;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Text(text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: vibeText(t, paragraph ? 13.5 : 12.5, 500,
            color: t.mut, height: paragraph ? 1.5 : 1.45));
  }
}

/// Título de grupo (`.g-sec`).
class VibeGroupTitle extends StatelessWidget {
  const VibeGroupTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
      child: Semantics(
          header: true, child: Text(text, style: vibeText(t, 15, 800))),
    );
  }
}

/// Título de destaque de um cartão (`.g-big`).
class VibeBigText extends StatelessWidget {
  const VibeBigText(this.text, {super.key, this.center = false});

  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Text(text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: vibeText(t, 19, 800, letterSpacingEm: -.01));
  }
}

/// Círculo de situação (`.g-st`, `.g-res`).
class VibeStatusCircle extends StatelessWidget {
  const VibeStatusCircle({super.key, required this.icon, required this.tone});

  final String icon;
  final VibeTone tone;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final (Color bg, Color fg) = switch (tone) {
      VibeTone.warning => t.dark
          ? (t.wab, t.wa)
          : (const Color(0xFFFEF0C7), const Color(0xFFB54708)),
      VibeTone.bad => t.dark
          ? (t.badb, t.bad)
          : (const Color(0xFFFDE2E2), const Color(0xFFB42318)),
      _ => t.dark
          ? (t.okb, t.ok)
          : (const Color(0xFFDCFCE7), const Color(0xFF15803D)),
    };
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: VibeIcon(icon, size: 26, color: fg),
    );
  }
}

/// Estado vazio de um cartão (`.g-empty`).
class VibeEmpty extends StatelessWidget {
  const VibeEmpty(
      {super.key,
      required this.icon,
      required this.title,
      this.text,
      this.action});

  final String icon;
  final String title;
  final String? text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 6),
      child: Column(children: [
        VibeIcon(icon, size: 30, color: t.mut),
        const SizedBox(height: 6),
        Text(title, textAlign: TextAlign.center, style: vibeText(t, 15, 700)),
        if (text?.isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text(text!,
              textAlign: TextAlign.center,
              style: vibeText(t, 13, 500, color: t.mut, height: 1.45)),
        ],
        if (action != null) ...[const SizedBox(height: 14), action!],
      ]),
    );
  }
}

/// Confirmação (`.g-ok`) e faixa de resultado (`.g-ok.sm`).
class VibeOkBox extends StatelessWidget {
  const VibeOkBox(
      {super.key,
      required this.title,
      this.text,
      this.strip = false,
      this.warning = false});

  final String title;
  final String? text;
  final bool strip;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    if (strip) {
      final (Color bg, Color fg) = t.dark
          ? (warning ? (t.wab, t.wa) : (t.okb, t.ok))
          : warning
              ? (const Color(0xFFFFFAEB), const Color(0xFF93370D))
              : (const Color(0xFFECFDF3), const Color(0xFF166534));
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          VibeIcon(warning ? 'alert' : 'check', size: 16, color: fg),
          const SizedBox(width: 6),
          Expanded(child: Text(title, style: vibeText(t, 13, 650, color: fg))),
        ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: t.dark ? t.okb : const Color(0xFFDCFCE7),
              shape: BoxShape.circle),
          alignment: Alignment.center,
          child: VibeIcon('check',
              size: 24, color: t.dark ? t.ok : const Color(0xFF15803D)),
        ),
        const SizedBox(height: 6),
        Text(title, textAlign: TextAlign.center, style: vibeText(t, 16, 700)),
        if (text?.isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text(text!,
              textAlign: TextAlign.center,
              style: vibeText(t, 13, 500, color: t.mut, height: 1.45)),
        ],
      ]),
    );
  }
}

/// Mensagem de erro curta (`.g-err`).
class VibeErrorLine extends StatelessWidget {
  const VibeErrorLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final color = t.dark ? const Color(0xFFFF8F8F) : const Color(0xFFD92D20);
    return Semantics(
      liveRegion: true,
      child: Row(children: [
        VibeIcon('alert', size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: vibeText(t, 13, 650, color: color))),
      ]),
    );
  }
}

/// Marca fixa da tela Dock (`.app-brand`): nome com ponto na cor da marca,
/// assinante e plano, rede do celular, avisos e conta.
class VibeDockMasthead extends StatelessWidget {
  const VibeDockMasthead({
    super.key,
    required this.providerName,
    required this.subtitle,
    required this.initials,
    required this.network,
    required this.onNetwork,
    required this.onAccount,
    this.onBell,
    this.logoUrl,
  });

  final String providerName;
  final String subtitle;
  final String initials;
  final String? logoUrl;
  final VibeNetwork network;
  final VoidCallback onNetwork;
  final VoidCallback? onBell;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final p = t.dock!;
    final (icon, label) = switch (network) {
      VibeNetwork.wifi => ('i-wifi', t.wifi),
      VibeNetwork.mobile => ('i-speed', 'Dados'),
      VibeNetwork.offline => ('i-close', 'Sem rede'),
      VibeNetwork.unknown => ('i-wifi', 'Rede'),
    };
    final word = providerName.trim().isEmpty ? '' : providerName.trim();
    return Container(
      color: p.base,
      padding: const EdgeInsets.fromLTRB(16, 2, 14, 2),
      constraints: const BoxConstraints(minHeight: 51),
      child: Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                VibeLogo(
                  name: word,
                  logoUrl: logoUrl,
                  height: 26,
                  maxWidth: 150,
                  background: p.base,
                  fallback: _word(t, p, word),
                ),
                Text(subtitle,
                    style: vibeText(t, 12, 550, color: p.ink, height: 1.12)),
              ]),
        ),
        Semantics(
          button: true,
          label: 'Rede do celular: $label. Verificar conexão',
          excludeSemantics: true,
          child: InkWell(
            onTap: onNetwork,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                      color: p.soft, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    VibeIcon(icon, size: 16, strokeWidth: 1.7, color: p.onwash),
                    const SizedBox(width: 4),
                    Text(label,
                        maxLines: 1,
                        softWrap: false,
                        style: vibeText(t, 12, 650,
                            color: p.onwash,
                            height: 1.14,
                            letterSpacingEm: -.0175)),
                  ]),
                ),
              ),
            ),
          ),
        ),
        if (onBell != null)
          Semantics(
            button: true,
            label: 'Avisos',
            excludeSemantics: true,
            child: InkWell(
              onTap: onBell,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                    child: VibeIcon('i-bell',
                        size: 21, strokeWidth: 1.7, color: p.ink)),
              ),
            ),
          ),
        Semantics(
          button: true,
          label: 'Minha conta',
          excludeSemantics: true,
          child: InkWell(
            onTap: onAccount,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration:
                      BoxDecoration(color: p.soft, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(initials,
                      style: vibeText(t, 13, 650,
                          color: p.onwash,
                          height: 1.35,
                          letterSpacingEm: -.016)),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _word(VibeTokens t, VibeDockPalette p, String word) => Text.rich(
        TextSpan(children: [
          TextSpan(
              text: word,
              style: vibeText(t, 23, 700,
                  color: p.ink, height: 1.04, letterSpacingEm: -.1)),
          TextSpan(
              text: '.',
              style: vibeText(t, 23, 700,
                  color: p.mark, height: 1.04, letterSpacingEm: -.1)),
        ]),
      );
}
