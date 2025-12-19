import 'package:flutter/material.dart';

class CyberCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final Color backgroundColor;
  final double cutSize;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const CyberCard({
    super.key,
    required this.child,
    this.borderColor = const Color(0xFF00FFFF), // Cyan
    this.backgroundColor = const Color(0xFF121212),
    this.cutSize = 20.0,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _CyberPainter(
          borderColor: borderColor,
          backgroundColor: backgroundColor,
          cutSize: cutSize,
        ),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}

class _CyberPainter extends CustomPainter {
  final Color borderColor;
  final Color backgroundColor;
  final double cutSize;

  _CyberPainter({
    required this.borderColor,
    required this.backgroundColor,
    required this.cutSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();

    // Top Left Cut
    path.moveTo(0, cutSize);
    path.lineTo(cutSize, 0);

    // Top Right
    path.lineTo(size.width, 0);

    // Bottom Right Cut
    path.lineTo(size.width, size.height - cutSize);
    path.lineTo(size.width - cutSize, size.height);

    // Bottom Left
    path.lineTo(0, size.height);

    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // Decorative "Cyber" lines
    final decoPaint = Paint()
      ..color = borderColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
        Offset(cutSize + 5, 5), Offset(size.width - 5, 5), decoPaint);

    canvas.drawLine(Offset(5, size.height - 5),
        Offset(size.width - cutSize - 5, size.height - 5), decoPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
