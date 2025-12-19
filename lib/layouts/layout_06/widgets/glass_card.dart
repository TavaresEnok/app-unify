import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? height;
  final VoidCallback? onTap;
  final bool useGradientBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.onTap,
    this.useGradientBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    // Layout 06 is designed as a Dark theme.
    // Even if the global theme is Light, these cards must remain dark (Black).
    final surfaceColor = Theme.of(context).cardColor;

    final dynamicGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryColor, secondaryColor],
    );

    final glassmorphism = BoxDecoration(
      color: surfaceColor, // Removed .withValues(alpha: 0.6) to allow vibrant colors
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: padding ?? const EdgeInsets.all(20),
        decoration: useGradientBorder
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: dynamicGradient,
              )
            : glassmorphism,
        child: useGradientBorder
            ? Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: padding ?? const EdgeInsets.all(20),
                child: child,
              )
            : child,
      ),
    );
  }
}
