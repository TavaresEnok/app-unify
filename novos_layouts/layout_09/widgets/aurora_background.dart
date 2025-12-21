import 'dart:ui';

import 'package:flutter/material.dart';

class AuroraBackground extends StatelessWidget {
  final List<Color>? colors;

  const AuroraBackground({super.key, this.colors});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    final palette = colors ??
        [
          scheme.primary.withValues(alpha: 0.35),
          scheme.secondary.withValues(alpha: 0.28),
          const Color(0xFF7C3AED).withValues(alpha: 0.20),
          const Color(0xFF06B6D4).withValues(alpha: 0.18),
        ];

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              gradient: RadialGradient(
                center: const Alignment(-0.7, -0.8),
                radius: 1.2,
                colors: [
                  palette[0],
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.9, -0.2),
                radius: 1.4,
                colors: [
                  palette[1],
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, 1.0),
                radius: 1.3,
                colors: [
                  palette[2],
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}
