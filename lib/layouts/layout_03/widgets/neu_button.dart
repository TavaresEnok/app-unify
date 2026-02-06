import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

/// Neumorphic Button with press animation effect
class NeuButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double size;

  const NeuButton({
    super.key,
    required this.child,
    required this.onTap,
    this.size = 48,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Layout03Theme.neuBase,
          borderRadius: BorderRadius.circular(14),
          boxShadow:
              _pressed ? Layout03Theme.neuPressed() : Layout03Theme.neuFlat(),
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}
