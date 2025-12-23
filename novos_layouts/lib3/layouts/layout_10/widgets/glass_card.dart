import 'package:flutter/material.dart';
import '../theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final bool border;
  final List<BoxShadow>? boxShadow;
  final Color? backgroundColor;
  final double? opacity;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.border = true,
    this.boxShadow,
    this.backgroundColor,
    this.opacity,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(Layout10Theme.spacingS),
      padding: padding ?? const EdgeInsets.all(Layout10Theme.spacingL),
      decoration: BoxDecoration(
        color: backgroundColor ?? 
            (Layout10Theme.surfaceColor).withValues(alpha: opacity ?? 0.9),
        borderRadius: BorderRadius.circular(borderRadius ?? Layout10Theme.borderRadiusL),
        border: border
            ? Border.all(
                color: Layout10Theme.accentColor.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
        boxShadow: boxShadow ?? Layout10Theme.cardShadow,
        gradient: gradient,
      ),
      child: child,
    );
  }
}

class NeonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final Color? neonColor;
  final bool animated;

  const NeonCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.neonColor,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = neonColor ?? Layout10Theme.accentColor;
    
    return AnimatedContainer(
      duration: animated ? const Duration(milliseconds: 300) : Duration.zero,
      margin: margin ?? const EdgeInsets.all(Layout10Theme.spacingS),
      padding: padding ?? const EdgeInsets.all(Layout10Theme.spacingL),
      decoration: BoxDecoration(
        color: Layout10Theme.surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius ?? Layout10Theme.borderRadiusL),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: animated ? 20 : 15,
            spreadRadius: animated ? 2 : 1,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: animated ? 40 : 30,
            spreadRadius: animated ? 4 : 2,
          ),
        ],
      ),
      child: child,
    );
  }
}

class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;

  const GradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.gradient,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(Layout10Theme.spacingS),
      padding: padding ?? const EdgeInsets.all(Layout10Theme.spacingL),
      decoration: BoxDecoration(
        gradient: gradient ?? Layout10Theme.primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius ?? Layout10Theme.borderRadiusL),
        boxShadow: boxShadow ?? Layout10Theme.cardShadow,
      ),
      child: child,
    );
  }
}
