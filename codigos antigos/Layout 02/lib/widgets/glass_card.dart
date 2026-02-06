import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final bool useBlur; // Nova flag para controle de performance

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.borderColor,
    this.shadows,
    this.useBlur = true, // Padrão é true, mas pode ser desligado globalmente
  });

  @override
  Widget build(BuildContext context) {
    final Color fallbackBorder = borderColor ?? Colors.white.withOpacity(0.08);
    
    // Design base (usado com ou sem blur)
    final decoration = BoxDecoration(
      color: useBlur 
          ? const Color(0xAA0F172A) // Mais transparente se tiver blur
          : const Color(0xFF111827).withOpacity(0.95), // Quase sólido se não tiver blur
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: fallbackBorder),
      boxShadow: shadows ?? [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 24,
          offset: const Offset(0, 18),
        ),
      ],
    );

    // Se a performance for crítica, retornamos apenas o Container sem BackdropFilter
    if (!useBlur) {
      return Container(
        decoration: decoration,
        child: Padding(padding: padding, child: child),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container( // Usando Container ao invés de DecoratedBox para consistência
          decoration: decoration,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
