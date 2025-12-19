import 'package:flutter/material.dart';

/// ShaderMask that applies a Gold Gradient to its child (Text/Icon)
class GoldGradientText extends StatelessWidget {
  final Widget child;

  const GoldGradientText({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFFBF953F), // Gold Dark
          Color(0xFFFCF6BA), // Gold Light
          Color(0xFFB38728), // Gold Dark
          Color(0xFFFBF5B7), // Gold Light
          Color(0xFFAA771C), // Gold Dark
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: child,
    );
  }
}

/// A Dark Matte Card with a subtle Gold border and shadow
class VelvetCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const VelvetCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // Matte Black
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFB38728).withOpacity(0.3), // Gold Border
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
            // Subtle Gold Glow
            BoxShadow(
              color: const Color(0xFFB38728).withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
