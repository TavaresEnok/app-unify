/// Widgets de Animação Reutilizáveis
/// Componentes com animações otimizadas para performance
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animação FadeSlideIn - Entrada suave com fade + slide
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final Duration duration;
  final Offset slideOffset;
  final Curve curve;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.duration = const Duration(milliseconds: 500),
    this.slideOffset = const Offset(0, 0.15),
    this.curve = Curves.easeOut,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _offset = Tween<Offset>(begin: widget.slideOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delayMs > 0) {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

/// Animação ScalePress - Efeito de escala ao pressionar
class ScalePressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleDown;
  final Duration duration;
  final bool enableHaptic;

  const ScalePressButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.enableHaptic = true,
  });

  @override
  State<ScalePressButton> createState() => _ScalePressButtonState();
}

class _ScalePressButtonState extends State<ScalePressButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (widget.enableHaptic) HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleDown : 1.0,
        duration: widget.duration,
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}

/// Animação Shimmer - Loading placeholder
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                0.0,
                0.5 + _animation.value * 0.25,
                1.0,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Animação Pulse - Pulsação suave (para indicadores de status)
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

/// RepaintBoundary wrapper para otimização
class OptimizedWidget extends StatelessWidget {
  final Widget child;

  const OptimizedWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: child);
  }
}

/// Staggered animation para listas
class StaggeredListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final int baseDelayMs;

  const StaggeredListItem({
    super.key,
    required this.child,
    required this.index,
    this.baseDelayMs = 50,
  });

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delayMs: index * baseDelayMs,
      child: child,
    );
  }
}
