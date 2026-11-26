import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'vibe_icon.dart';
import 'vibe_skeleton.dart';
import 'vibe_text.dart';
import 'vibe_tokens.dart';

/// Controles e retornos das páginas internas do layout aprovado: campo de
/// texto (`.g-fl`, `.g-in`), opções (`.g-chips`), carregamento (`.g-load`),
/// barra (`.g-bar`), ponto de situação (`.g-dot`) e os estados de página e
/// diálogos que o protótipo não desenha, feitos com as mesmas peças.

/// Campo com rótulo, ícone e borda de 1,5 que vira a cor da marca no foco.
class VibeField extends StatefulWidget {
  const VibeField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.hint,
    this.enabled = true,
    this.obscure = false,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final String? icon;
  final String? hint;
  final bool enabled;

  /// Campo de senha, com o botão de mostrar e ocultar (`.g-eye`).
  final bool obscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  @override
  State<VibeField> createState() => _VibeFieldState();
}

class _VibeFieldState extends State<VibeField> {
  FocusNode? _own;
  bool _visible = false;

  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.label, style: vibeText(t, 13, 650)),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _focus,
            builder: (context, _) => Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.only(left: 14, right: 6),
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _focus.hasFocus ? t.ac : t.line,
                    width: _focus.hasFocus ? 2 : 1.5),
              ),
              child: Row(children: [
                if (widget.icon != null) ...[
                  VibeIcon(widget.icon!, size: 16, color: t.mut),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    enabled: widget.enabled,
                    obscureText: widget.obscure && !_visible,
                    autocorrect: false,
                    enableSuggestions: !widget.obscure,
                    keyboardType: widget.keyboardType,
                    inputFormatters: widget.inputFormatters,
                    textInputAction: widget.textInputAction,
                    maxLength: widget.maxLength,
                    autofillHints: widget.autofillHints,
                    style: vibeText(t, 15, 500,
                        color: widget.enabled ? t.ink : t.mut),
                    cursorColor: t.ac,
                    decoration: InputDecoration(
                      filled: false,
                      isCollapsed: true,
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      hintText: widget.hint,
                      hintStyle: vibeText(t, 15, 500, color: t.mut),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                  ),
                ),
                if (widget.obscure)
                  Semantics(
                    button: true,
                    label: _visible ? 'Ocultar senha' : 'Mostrar senha',
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => setState(() => _visible = !_visible),
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                            child: VibeIcon('eye', size: 16, color: t.mut)),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ]);
  }
}

/// Opções em pílula, uma selecionada (`.g-chips`).
class VibeChoiceChips<T> extends StatelessWidget {
  const VibeChoiceChips(
      {super.key,
      required this.options,
      required this.selected,
      required this.onSelected,
      this.enabled = true});

  final List<(T, String)> options;
  final T? selected;
  final ValueChanged<T> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Wrap(spacing: 6, runSpacing: 6, children: [
      for (final (value, label) in options)
        Semantics(
          button: true,
          selected: value == selected,
          label: label,
          excludeSemantics: true,
          child: Material(
            color: value == selected ? t.ac : t.ink.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? () => onSelected(value) : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Center(
                    widthFactor: 1,
                    child: Text(label,
                        style: vibeText(t, 13, 650,
                            color: value == selected ? t.on : t.ink)),
                  ),
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}

/// Ponto de situação (`.g-dot`): verde, âmbar, vermelho ou cinza.
class VibeDot extends StatelessWidget {
  const VibeDot(this.tone, {super.key});

  /// `null` é o cinza de "sem medição".
  final VibeTone? tone;

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: switch (tone) {
            VibeTone.ok => const Color(0xFF16A34A),
            VibeTone.warning => const Color(0xFFF59E0B),
            VibeTone.bad => const Color(0xFFDC2626),
            _ => const Color(0xFF9AA1AD),
          },
        ),
      );
}

/// Seta das linhas que abrem e fecham (`chevd`, girada quando aberta).
class VibeChevron extends StatelessWidget {
  const VibeChevron({super.key, required this.open});
  final bool open;

  @override
  Widget build(BuildContext context) => AnimatedRotation(
        turns: open ? .5 : 0,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        child: VibeIcon('chevd', size: 16, color: VibeTokens.of(context).ink),
      );
}

/// Barra de progresso (`.g-bar`); sem [value], desliza enquanto espera.
class VibeProgressBar extends StatelessWidget {
  const VibeProgressBar({super.key, this.value});
  final double? value;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: LinearProgressIndicator(
          value: value?.clamp(0, 1),
          minHeight: 8,
          color: t.ac,
          backgroundColor: t.ink.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Carregamento em blocos (`.g-load`): faixas com o brilho único do app.
/// Prefira o desenho real com [VibeRedact]; isto fica para listas cujo
/// tamanho não se conhece antes.
class VibeLoading extends StatelessWidget {
  const VibeLoading({super.key, this.blocks = 3, this.label = 'Carregando'});
  final int blocks;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      liveRegion: true,
      child: Column(children: [
        for (var i = 0; i < blocks; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          const VibeShimmerBar(height: 64, radius: 14),
        ],
      ]),
    );
  }
}

/// Barra de carregamento com dimensões fixas, no mesmo brilho sincronizado
/// e nos mesmos tons de [VibeRedact].
class VibeShimmerBar extends StatelessWidget {
  const VibeShimmerBar({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
    this.color,
    this.onBrand = false,
  });

  final double? width;
  final double height;
  final double radius;
  final Color? color;
  final bool onBrand;

  @override
  Widget build(BuildContext context) => VibeRedact(
        redacted: true,
        block: true,
        radius: radius,
        onBrand: onBrand,
        color: color,
        child: SizedBox(width: width ?? double.infinity, height: height),
      );
}

/// Estado de página inteira (sem dados, erro, recurso indisponível): ícone
/// em círculo, título, texto e uma ação. O protótipo só desenha o estado
/// dentro de cartão (`.g-empty`); este usa as mesmas medidas, centralizado.
class VibeStatePanel extends StatelessWidget {
  const VibeStatePanel({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.tone = VibeTone.neutral,
  });

  final String icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VibeTone tone;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final (Color bg, Color fg) = switch (tone) {
      VibeTone.bad => (t.badb, t.bad),
      VibeTone.warning => (t.wab, t.wa),
      VibeTone.ok => (t.okb, t.ok),
      VibeTone.neutral => (t.ac.withValues(alpha: t.dark ? .22 : .12), t.at),
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: VibeIcon(icon, size: 28, color: fg),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(title,
                  textAlign: TextAlign.center,
                  style: vibeText(t, 19, 800, letterSpacingEm: -.01)),
            ),
            if (message?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: vibeText(t, 13.5, 500, color: t.mut, height: 1.5)),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              _PlainButton(label: actionLabel!, onPressed: onAction!),
            ],
          ]),
        ),
      ),
    );
  }
}

class _PlainButton extends StatelessWidget {
  const _PlainButton(
      {required this.label,
      required this.onPressed,
      this.ghost = false,
      this.danger = false});
  final String label;
  final VoidCallback onPressed;
  final bool ghost;
  final bool danger;

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
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
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
            constraints: const BoxConstraints(minHeight: 48, minWidth: 120),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Center(
                widthFactor: 1,
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: vibeText(t, 14.5, 750, color: fg, height: 1.2)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Confirmação em diálogo com o desenho dos cartões de confirmação do
/// protótipo ("Sair da conta?", "Limpar o histórico?"): título, texto e os
/// dois botões lado a lado. Devolve `true` quando confirmado.
Future<bool> showVibeConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancelar',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0x99101320),
    builder: (dialog) {
      final t = VibeTokens.of(dialog);
      return Dialog(
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(math.max(14, t.rad))),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(title,
                      style: vibeText(t, 17, 800, letterSpacingEm: -.01)),
                ),
                const SizedBox(height: 8),
                Text(message,
                    style: vibeText(t, 13.5, 500, color: t.mut, height: 1.5)),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(
                    child: _PlainButton(
                        label: cancelLabel,
                        ghost: true,
                        onPressed: () => Navigator.pop(dialog, false)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PlainButton(
                        label: confirmLabel,
                        danger: danger,
                        onPressed: () => Navigator.pop(dialog, true)),
                  ),
                ]),
              ]),
        ),
      );
    },
  );
  return result == true;
}
