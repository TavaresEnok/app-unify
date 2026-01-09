import 'package:flutter/material.dart';
import 'diagnostic_theme.dart';

class HoloCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? accent;
  final bool isScanning;

  const HoloCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.accent,
    this.isScanning = false,
  });

  @override
  State<HoloCard> createState() => _HoloCardState();
}

class _HoloCardState extends State<HoloCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanCtrl;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isScanning) _scanCtrl.repeat();
  }

  @override
  void didUpdateWidget(covariant HoloCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _scanCtrl.repeat();
      } else {
        _scanCtrl.stop();
        _scanCtrl.reset();
      }
    }
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accent ?? DiagnosticTheme.cyan;
    return CustomPaint(
      painter: _CornerPainter(color: color),
      foregroundPainter:
          widget.isScanning ? _CardScannerPainter(_scanCtrl, color) : null,
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: color.withAlpha(10),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: widget.child,
      ),
    );
  }
}

class _CardScannerPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  _CardScannerPainter(this.animation, this.color) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final y = animation.value * size.height;

    // Scan line
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = color.withOpacity(0.8)
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Trail
    final trailRect = Rect.fromLTWH(0, y - 40, size.width, 40);
    canvas.drawRect(
      trailRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [color.withOpacity(0.3), Colors.transparent],
        ).createShader(trailRect),
    );
  }

  @override
  bool shouldRepaint(covariant _CardScannerPainter old) => true;
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;

    final double len = 10;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, 0)
        ..lineTo(len, 0),
      paint,
    );
    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, len),
      paint,
    );
    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - len)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width - len, size.height),
      paint,
    );
    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(len, size.height)
        ..lineTo(0, size.height)
        ..lineTo(0, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => false;
}
