import 'dart:ui';

import 'package:flutter/material.dart';

class FrostedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final BorderRadiusGeometry borderRadius;
  final double blur;

  const FrostedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.blur = 18,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surface = Theme.of(context).cardColor;

    final card = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface.withValues(alpha: 0.72),
            borderRadius: borderRadius,
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap == null) return card;

    return GestureDetector(
      onTap: onTap,
      child: card,
    );
  }
}
