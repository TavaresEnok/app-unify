import 'dart:ui';
import 'package:flutter/material.dart';

/// Bento Card Widget for Layout 09 - Glassmorphism with pastel accents
class BentoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? height;
  final double? width;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool useGlass;
  final int flex;

  const BentoCard({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.width,
    this.onTap,
    this.backgroundColor,
    this.useGlass = false,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).cardColor;

    Widget cardContent = Container(
      height: height,
      width: width,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? surfaceColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    if (useGlass) {
      cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: height,
            width: width,
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: cardContent,
    );
  }
}

/// Gradient Orb for background decoration
class GradientOrb extends StatelessWidget {
  final double size;
  final Color color;
  final Offset position;

  const GradientOrb({
    super.key,
    required this.size,
    required this.color,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.4),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
