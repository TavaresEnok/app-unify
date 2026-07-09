import 'dart:math';
import 'package:flutter/material.dart';
import 'diagnostic_theme.dart';

class HoloBackground extends StatefulWidget {
  final Widget child;
  const HoloBackground({super.key, required this.child});
  @override
  State<HoloBackground> createState() => _HoloBackgroundState();
}

class _HoloBackgroundState extends State<HoloBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _HexagonGridPainter(
            _ctrl.value, DiagnosticTheme.cyan.withAlpha(15)),
        child: widget.child,
      ),
    );
  }
}

class _HexagonGridPainter extends CustomPainter {
  final double scroll;
  final Color color;
  _HexagonGridPainter(this.scroll, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const double r = 30; // Hexagon radius
    // Calculate hex dimensions
    final double w = sqrt(3) * r;
    const double h = 2 * r;

    // Offset grid by scroll
    final double yOffset = (scroll * h * 2) % (h * 3); // Loop smoothly

    for (double y = -h; y < size.height + h; y += h * 0.75) {
      for (double x = -w; x < size.width + w; x += w) {
        final double xPos = x + ((y / (h * 0.75)).floor() % 2 == 0 ? w / 2 : 0);
        final double yPos = y + yOffset;
        _drawHex(canvas, Offset(xPos, yPos), r, paint);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HexagonGridPainter old) => old.scroll != scroll;
}
