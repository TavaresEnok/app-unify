import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'vibe_tokens.dart';

/// Carregamento sem salto de layout.
///
/// A regra é uma só: a tela já nasce com o desenho final. Rótulos, ícones,
/// molduras e botões aparecem sempre; só os valores (mês, valor, data, IP…)
/// ficam cobertos por uma barra do tamanho exato do texto que vai entrar.
/// O [VibeRedact] mede o próprio filho (com a fonte e a escala de texto do
/// aparelho) e pinta a barra no lugar dele, então a geometria é idêntica em
/// qualquer largura, escala de fonte ou tema.

/// Relógio único do brilho: todas as barras de uma tela andam juntas, com a
/// faixa clara varrendo a tela em coordenadas globais.
class VibeSkeletonScope extends StatefulWidget {
  const VibeSkeletonScope({super.key, required this.child});

  final Widget child;

  /// Brilho para quando não há escopo acima (barra estática).
  static VibeSkeletonClock? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_SkeletonScopeMarker>()?.clock;

  @override
  State<VibeSkeletonScope> createState() => _VibeSkeletonScopeState();
}

class _SkeletonScopeMarker extends InheritedWidget {
  const _SkeletonScopeMarker({required this.clock, required super.child});
  final VibeSkeletonClock clock;

  @override
  bool updateShouldNotify(_SkeletonScopeMarker old) => old.clock != clock;
}

/// Fase do brilho (0–1) e se ele ainda anda. Após [calmAfter] carregando,
/// ou com animações desligadas no aparelho, as barras ficam estáticas.
class VibeSkeletonClock extends ChangeNotifier {
  VibeSkeletonClock(TickerProvider vsync)
      : _controller = AnimationController(vsync: vsync, duration: period) {
    _controller.addListener(notifyListeners);
  }

  static const period = Duration(milliseconds: 1600);
  static const calmAfter = Duration(seconds: 8);

  final AnimationController _controller;
  int _users = 0;
  bool _reduceMotion = false;
  bool _calmed = false;
  Timer? _calm;

  double get phase => Curves.easeInOut.transform(_controller.value);
  bool get moving => _controller.isAnimating;

  set reduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    _sync();
  }

  void acquire() {
    _users++;
    _sync();
  }

  void release() {
    _users = (_users - 1).clamp(0, 1 << 30);
    _sync();
  }

  void _sync() {
    if (_users == 0) {
      // Próximo carregamento começa com brilho de novo.
      _calmed = false;
      _calm?.cancel();
      _calm = null;
    } else if (_calm == null && !_calmed) {
      // Timer (e não relógio de parede) para seguir o tempo dos testes.
      _calm = Timer(calmAfter, () {
        _calmed = true;
        _sync();
      });
    }
    final run = _users > 0 && !_reduceMotion && !_calmed;
    if (run && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!run && _controller.isAnimating) {
      _controller.stop();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _calm?.cancel();
    _controller.dispose();
    super.dispose();
  }
}

class _VibeSkeletonScopeState extends State<VibeSkeletonScope>
    with SingleTickerProviderStateMixin {
  late final VibeSkeletonClock _clock = VibeSkeletonClock(this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _clock.reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _SkeletonScopeMarker(clock: _clock, child: widget.child);
}

/// Tons da barra conforme a superfície: tinta sobre cartão claro, branco
/// sobre cartão escuro e a cor do texto sobre a cor da marca.
({Color low, Color high}) vibeSkeletonTint(BuildContext context,
    {bool onBrand = false, Color? color}) {
  final t = VibeTokens.of(context);
  if (color != null) {
    return (
      low: color.withValues(alpha: .12),
      high: color.withValues(alpha: .18)
    );
  }
  if (onBrand) {
    return (
      low: t.on.withValues(alpha: .14),
      high: t.on.withValues(alpha: .22)
    );
  }
  return t.dark
      ? (
          low: Colors.white.withValues(alpha: .07),
          high: Colors.white.withValues(alpha: .11)
        )
      : (low: t.ink.withValues(alpha: .06), high: t.ink.withValues(alpha: .10));
}

/// Cobre um valor enquanto ele não chegou.
///
/// O filho é medido normalmente (use um texto de exemplo com o tamanho
/// típico do valor, como "R$ 199,90"), mas fica invisível; no lugar dele
/// aparece uma barra arredondada do mesmo tamanho. Quando o valor chega, a
/// barra some em 180 ms e o texto entra no mesmo lugar.
///
/// Para não piscar em respostas rápidas, a barra só aparece depois de
/// 150 ms e, uma vez visível, fica pelo menos 400 ms. Com as animações do
/// aparelho desligadas, troca na hora.
class VibeRedact extends StatefulWidget {
  const VibeRedact({
    super.key,
    required this.redacted,
    required this.child,
    this.onBrand = false,
    this.color,
    this.block = false,
    this.radius,
  });

  /// Raio próprio da barra (padrão: proporcional à altura do texto).
  final double? radius;

  final bool redacted;
  final Widget child;
  final bool onBrand;

  /// Cor base da barra para superfícies próprias (ex.: o cartão da Dock).
  final Color? color;

  /// Ocupa a área inteira do filho (gráfico, linha de botões), em vez de
  /// ficar na altura das letras.
  final bool block;

  static const delay = Duration(milliseconds: 150);
  static const minimum = Duration(milliseconds: 400);
  static const fade = Duration(milliseconds: 180);

  @override
  State<VibeRedact> createState() => _VibeRedactState();
}

class _VibeRedactState extends State<VibeRedact>
    with SingleTickerProviderStateMixin {
  // 0: barra; 1: valor.
  late final AnimationController _reveal = AnimationController(
      vsync: this, duration: VibeRedact.fade, value: widget.redacted ? 0 : 1);
  Timer? _timer;
  DateTime? _barSince;
  bool _barVisible = false;
  VibeSkeletonClock? _clock;
  bool _acquired = false;

  bool get _instant => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void initState() {
    super.initState();
    _reveal.addListener(_onReveal);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final clock = VibeSkeletonScope.maybeOf(context);
    if (clock != _clock) {
      if (_acquired) _clock?.release();
      _acquired = false;
      _clock = clock;
    }
    if (widget.redacted && _timer == null && !_barVisible) _startBar();
    _syncClock();
  }

  @override
  void didUpdateWidget(VibeRedact old) {
    super.didUpdateWidget(old);
    if (widget.redacted == old.redacted) return;
    if (widget.redacted) {
      _reveal.value = 0;
      _startBar();
    } else {
      _finish();
    }
  }

  void _startBar() {
    _timer?.cancel();
    if (_instant) {
      _timer = null;
      _showBar();
      return;
    }
    // Enquanto espera, só a moldura aparece (nem barra nem valor).
    _barVisible = false;
    _timer = Timer(VibeRedact.delay, () {
      _timer = null;
      if (mounted && widget.redacted) setState(_showBar);
    });
  }

  void _showBar() {
    _barVisible = true;
    _barSince = DateTime.now();
    _syncClock();
  }

  void _finish() {
    _timer?.cancel();
    _timer = null;
    if (_instant || !_barVisible) {
      // Sem barra na tela (resposta rápida): o valor entra com um fade curto.
      _barVisible = false;
      _barSince = null;
      _syncClock();
      if (_instant) {
        _reveal.value = 1;
      } else {
        _reveal.forward(from: 0);
      }
      return;
    }
    final shown = DateTime.now().difference(_barSince!);
    final wait = VibeRedact.minimum - shown;
    void go() {
      if (!mounted || widget.redacted) return;
      _reveal.forward(from: 0);
    }

    if (wait > Duration.zero) {
      _timer = Timer(wait, () {
        _timer = null;
        go();
      });
    } else {
      go();
    }
  }

  void _onReveal() {
    if (_reveal.isCompleted && _barVisible && !widget.redacted) {
      _barVisible = false;
      _barSince = null;
      _syncClock();
    }
    setState(() {});
  }

  void _syncClock() {
    final want = _barVisible;
    if (want && !_acquired) {
      _clock?.acquire();
      _acquired = _clock != null;
    } else if (!want && _acquired) {
      _clock?.release();
      _acquired = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_acquired) _clock?.release();
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint =
        vibeSkeletonTint(context, onBrand: widget.onBrand, color: widget.color);
    final hidden = widget.redacted || _reveal.value < 1;
    final waiting = widget.redacted && !_barVisible;
    final double childOpacity = widget.redacted ? 0 : _reveal.value;
    final double barOpacity = !_barVisible
        ? 0
        : widget.redacted
            ? 1
            : 1 - _reveal.value;
    return ExcludeSemantics(
      excluding: widget.redacted,
      child: IgnorePointer(
        ignoring: hidden,
        child: _RedactBox(
          childOpacity: waiting ? 0 : childOpacity,
          barOpacity: barOpacity,
          low: tint.low,
          high: tint.high,
          block: widget.block,
          radius: widget.radius,
          clock: _clock,
          child: widget.child,
        ),
      ),
    );
  }
}

class _RedactBox extends SingleChildRenderObjectWidget {
  const _RedactBox({
    required this.childOpacity,
    required this.barOpacity,
    required this.low,
    required this.high,
    required this.block,
    required this.radius,
    required this.clock,
    required super.child,
  });

  final double? radius;

  final double childOpacity;
  final double barOpacity;
  final Color low;
  final Color high;
  final bool block;
  final VibeSkeletonClock? clock;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderRedact(
        childOpacity: childOpacity,
        barOpacity: barOpacity,
        low: low,
        high: high,
        block: block,
        radius: radius,
        clock: clock,
      );

  @override
  void updateRenderObject(BuildContext context, _RenderRedact render) {
    render
      ..childOpacity = childOpacity
      ..barOpacity = barOpacity
      ..low = low
      ..high = high
      ..block = block
      ..radius = radius
      ..clock = clock;
  }
}

class _RenderRedact extends RenderProxyBox {
  _RenderRedact({
    required double childOpacity,
    required double barOpacity,
    required Color low,
    required Color high,
    required bool block,
    required double? radius,
    required VibeSkeletonClock? clock,
  })  : _radius = radius,
        _childOpacity = childOpacity,
        _barOpacity = barOpacity,
        _low = low,
        _high = high,
        _block = block,
        _clock = clock;

  double? _radius;
  double _childOpacity;
  double _barOpacity;

  set radius(double? v) {
    if (v == _radius) return;
    _radius = v;
    markNeedsPaint();
  }

  Color _low;
  Color _high;
  bool _block;
  VibeSkeletonClock? _clock;
  Size? _barSize;

  set childOpacity(double v) {
    if (v == _childOpacity) return;
    _childOpacity = v;
    markNeedsPaint();
  }

  set barOpacity(double v) {
    if (v == _barOpacity) return;
    final was = _barOpacity > 0;
    _barOpacity = v;
    if (was != (v > 0)) _listen();
    markNeedsPaint();
  }

  set low(Color v) {
    if (v == _low) return;
    _low = v;
    markNeedsPaint();
  }

  set high(Color v) {
    if (v == _high) return;
    _high = v;
    markNeedsPaint();
  }

  set block(bool v) {
    if (v == _block) return;
    _block = v;
    markNeedsPaint();
  }

  set clock(VibeSkeletonClock? v) {
    if (v == _clock) return;
    _unlisten();
    _clock = v;
    _listen();
  }

  bool _listening = false;
  void _listen() {
    _unlisten();
    if (attached && _clock != null && _barOpacity > 0) {
      _clock!.addListener(markNeedsPaint);
      _listening = true;
    }
  }

  void _unlisten() {
    if (_listening) _clock?.removeListener(markNeedsPaint);
    _listening = false;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _listen();
  }

  @override
  void detach() {
    _unlisten();
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => child != null && _childOpacity < 1;

  @override
  void performLayout() {
    super.performLayout();
    // Enquanto o valor real não está pintado por inteiro, a barra guarda o
    // tamanho do exemplo para o fade de saída não mudar de forma.
    if (_childOpacity == 0 || _barSize == null || _barOpacity == 0) {
      _barSize = size;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && _childOpacity > 0) {
      if (_childOpacity >= 1) {
        context.paintChild(child!, offset);
      } else {
        context.pushOpacity(offset, (_childOpacity * 255).round(),
            (c, o) => c.paintChild(child!, o));
      }
    }
    if (_barOpacity <= 0) return;
    final s = _barSize ?? size;
    if (s.isEmpty) return;
    final inset = _block ? 0.0 : (s.height * .2).clamp(0.0, s.height / 2 - 4);
    final rect = Rect.fromLTWH(
        offset.dx, offset.dy + inset, s.width, s.height - inset * 2);
    final radius = _radius != null
        ? _radius!.clamp(0.0, rect.shortestSide / 2)
        : _block
            ? 12.0
            : (s.height * .3).clamp(4.0, 10.0).clamp(0.0, rect.height / 2);
    final paint = Paint()..isAntiAlias = true;
    final clock = _clock;
    final a = _barOpacity;
    Color fade(Color c) => c.withValues(alpha: c.a * a);
    if (clock != null && clock.moving) {
      // Faixa clara de 60% da largura da tela, em coordenadas globais, para
      // todas as barras andarem como uma só.
      final viewWidth = _viewWidth ?? 400.0;
      final band = viewWidth * .3;
      final globalX = localToGlobal(Offset.zero).dx;
      final center = -band + (viewWidth + band * 2) * clock.phase;
      final dx = offset.dx - globalX;
      paint.shader = ui.Gradient.linear(
        Offset(center - band + dx, 0),
        Offset(center + band + dx, 0),
        [fade(_low), fade(_high), fade(_low)],
        const [0, .5, 1],
      );
    } else {
      paint.color = fade(Color.lerp(_low, _high, .35)!);
    }
    context.canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);
  }

  double? get _viewWidth {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return null;
    final view = views.first;
    return view.physicalSize.width / view.devicePixelRatio;
  }
}

/// Botões que ainda não podem ser usados: aparecem no desenho real, com 45%
/// de opacidade e sem toque, até os dados chegarem.
class VibeDimmed extends StatelessWidget {
  const VibeDimmed({super.key, required this.dimmed, required this.child});

  final bool dimmed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final instant = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return IgnorePointer(
      ignoring: dimmed,
      child: ExcludeSemantics(
        excluding: dimmed,
        child: AnimatedOpacity(
          opacity: dimmed ? .45 : 1,
          duration: instant ? Duration.zero : VibeRedact.fade,
          child: child,
        ),
      ),
    );
  }
}

/// Região que pode crescer quando os dados chegam (avisos, próxima fatura):
/// em vez de empurrar a tela de uma vez, abre em 220 ms.
class VibeReveal extends StatelessWidget {
  const VibeReveal({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final instant = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    // Sem animações, só o conteúdo (AnimatedSize com duração zero se
    // remarca durante o próprio layout).
    if (instant) return child;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}

/// Barra fina indeterminada no topo de um cartão enquanto os dados já
/// mostrados são atualizados. Só aparece se a atualização passar de 600 ms.
class VibeRefreshEdge extends StatefulWidget {
  const VibeRefreshEdge({
    super.key,
    required this.active,
    required this.child,
    this.onBrand = false,
    this.color,
    this.top = 0,
    this.inset = 0,
  });

  final bool active;
  final Widget child;
  final bool onBrand;
  final Color? color;

  /// Posição da barra em relação ao topo do filho (negativa fica acima).
  final double top;
  final double inset;

  @override
  State<VibeRefreshEdge> createState() => _VibeRefreshEdgeState();
}

class _VibeRefreshEdgeState extends State<VibeRefreshEdge> {
  Timer? _timer;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) _arm();
  }

  @override
  void didUpdateWidget(VibeRefreshEdge old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _arm();
    if (!widget.active && old.active) {
      _timer?.cancel();
      _timer = null;
      _shown = false;
    }
  }

  void _arm() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 600), () {
      _timer = null;
      if (mounted && widget.active) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final color =
        widget.color ?? (widget.onBrand ? t.on.withValues(alpha: .55) : t.ac);
    final instant = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Stack(clipBehavior: Clip.none, children: [
      widget.child,
      Positioned(
        top: widget.top,
        left: widget.inset,
        right: widget.inset,
        height: 2,
        child: IgnorePointer(
          child: Semantics(
            label: _shown ? 'Atualizando' : null,
            liveRegion: _shown,
            child: AnimatedOpacity(
              opacity: _shown ? 1 : 0,
              duration: instant ? Duration.zero : VibeRedact.fade,
              child: _shown && !instant
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(1),
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        color: color,
                        backgroundColor: color.withValues(alpha: .18),
                      ),
                    )
                  : _shown
                      ? ColoredBox(color: color.withValues(alpha: .6))
                      : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    ]);
  }
}

/// Troca um texto por outro depois de [after] em espera (ex.: "Ainda
/// consultando…" quando a resposta demora). Fica no mesmo lugar e com a
/// mesma altura de linha.
class VibeSlowSwap extends StatefulWidget {
  const VibeSlowSwap({
    super.key,
    required this.waiting,
    required this.child,
    required this.slow,
    this.after = const Duration(seconds: 8),
  });

  final bool waiting;
  final Widget child;
  final Widget slow;
  final Duration after;

  @override
  State<VibeSlowSwap> createState() => _VibeSlowSwapState();
}

class _VibeSlowSwapState extends State<VibeSlowSwap> {
  Timer? _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    if (widget.waiting) _arm();
  }

  @override
  void didUpdateWidget(VibeSlowSwap old) {
    super.didUpdateWidget(old);
    if (widget.waiting && !old.waiting) _arm();
    if (!widget.waiting) {
      _timer?.cancel();
      _timer = null;
      _slow = false;
    }
  }

  void _arm() {
    _timer?.cancel();
    _timer = Timer(widget.after, () {
      _timer = null;
      if (mounted && widget.waiting) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _slow && widget.waiting ? widget.slow : widget.child;
}
