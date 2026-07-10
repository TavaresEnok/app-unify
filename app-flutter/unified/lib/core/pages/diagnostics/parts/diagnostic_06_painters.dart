part of '../diagnostic_06_page.dart';

// ============ GAUGE PAINTER ============
class _GaugePainter extends CustomPainter {
  final double fill;
  final Color color;
  _GaugePainter({required this.fill, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final center = Offset(size.width / 2, size.height / 2);
      final radius = math.min(size.width, size.height) / 2 - 10;
      const strokeWidth = 12.0;
      const startAngle = 135 * math.pi / 180;
      const sweepAngle = 270 * math.pi / 180;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = const Color(0xFFE4E4E7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );

      final fillPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [color.withValues(alpha: 0.5), color],
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * fill,
        false,
        fillPaint,
      );

      if (fill > 0.05) {
        final endAngle = startAngle + sweepAngle * fill;
        final tipX = center.dx + radius * math.cos(endAngle);
        final tipY = center.dy + radius * math.sin(endAngle);
        canvas.drawCircle(Offset(tipX, tipY), 10,
            Paint()..color = color.withValues(alpha: 0.4));
        canvas.drawCircle(Offset(tipX, tipY), 5, Paint()..color = Colors.white);
      }
    } catch (_) {
      // Falha silenciosa no painter
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.color != color;
}
