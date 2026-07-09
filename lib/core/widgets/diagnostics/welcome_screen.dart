import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'diagnostic_theme.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onStart;
  const WelcomeScreen({super.key, required this.onStart});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _gridCtrl, _rotateCtrl, _pulseCtrl, _scanCtrl;

  @override
  void initState() {
    super.initState();
    _gridCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _gridCtrl.dispose();
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF02060D)),
      child: Stack(
        children: [
          // 1. Dynamic Hexagon Grid (Background)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _gridCtrl,
              builder: (_, __) => CustomPaint(
                painter: _HexagonGridPainter(
                  _gridCtrl.value,
                  DiagnosticTheme.cyan.withAlpha(20),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // V5 Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: DiagnosticTheme.cyan.withAlpha(20),
                          border: Border.all(
                              color: DiagnosticTheme.cyan.withAlpha(100)),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: DiagnosticTheme.cyan.withAlpha(30),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Text(
                          "QUANTUM NET v5.0",
                          style: TextStyle(
                            color: DiagnosticTheme.cyan,
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Network Status
                      Row(
                        children: [
                          Icon(
                            Icons.hub,
                            color: DiagnosticTheme.purple.withAlpha(200),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "MESH ACTIVE",
                            style: TextStyle(
                              color: DiagnosticTheme.purple.withAlpha(200),
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 2. Center: Scanner Interface (Hybrid V3/V4)
                Center(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      widget.onStart();
                    },
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer Dashed Ring (Slow Rotate)
                          AnimatedBuilder(
                            animation: _rotateCtrl,
                            builder: (_, __) => Transform.rotate(
                              angle: _rotateCtrl.value * 2 * pi,
                              child: CustomPaint(
                                size: const Size(280, 280),
                                painter: _DashedRingPainter(
                                  color: DiagnosticTheme.cyan.withAlpha(80),
                                  dash: 40,
                                  gap: 20,
                                ),
                              ),
                            ),
                          ),

                          // Inner Dashed Ring (Fast Counter-Rotate)
                          AnimatedBuilder(
                            animation: _rotateCtrl,
                            builder: (_, __) => Transform.rotate(
                              angle: -_rotateCtrl.value * 2 * pi * 1.5,
                              child: CustomPaint(
                                size: const Size(240, 240),
                                painter: _DashedRingPainter(
                                  color: DiagnosticTheme.purple.withAlpha(100),
                                  dash: 10,
                                  gap: 10,
                                ),
                              ),
                            ),
                          ),

                          // Scanner Beam (Active Scan) in Portal
                          ClipOval(
                            child: Stack(
                              children: [
                                // Glass Core Background
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(100),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                // The Beam
                                AnimatedBuilder(
                                  animation: _scanCtrl,
                                  builder: (_, __) => CustomPaint(
                                    size: const Size(200, 200),
                                    painter: _ScannerBeamPainter(
                                      _scanCtrl.value,
                                      DiagnosticTheme.cyan,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Central START Button (Pulsing)
                          AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (_, __) => Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: DiagnosticTheme.cyan.withAlpha(
                                  (20 + _pulseCtrl.value * 30).toInt(),
                                ),
                                border: Border.all(
                                  color: DiagnosticTheme.cyan.withAlpha(
                                    (100 + _pulseCtrl.value * 155).toInt(),
                                  ),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: DiagnosticTheme.cyan.withAlpha(
                                      (50 + _pulseCtrl.value * 50).toInt(),
                                    ),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  "START",
                                  style: TextStyle(
                                    color: DiagnosticTheme.cyan,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Footer
                Text(
                  "INITIATE DIAGNOSTIC",
                  style: TextStyle(
                    color: Colors.white.withAlpha(100),
                    fontSize: 12,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════ Helper Widgets & Painters ════════════════

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

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double dash;
  final double gap;
  _DashedRingPainter({required this.color, this.dash = 20, this.gap = 10});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    double radius = size.width / 2;
    double circumference = 2 * pi * radius;
    int count = (circumference / (dash + gap)).floor();
    double angle = (dash / circumference) * 2 * pi;
    double space = (gap / circumference) * 2 * pi;

    for (int i = 0; i < count; i++) {
      canvas.drawArc(
        Rect.fromLTWH(0, 0, size.width, size.height),
        i * (angle + space),
        angle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter old) => false;
}

class _ScannerBeamPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ScannerBeamPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Triangle wave 0->1->0
    final cycle = (progress * 2);
    final norm = cycle > 1 ? 2 - cycle : cycle;
    final y = size.height * norm;

    // Scan line
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = color
        ..strokeWidth = 2,
    );
    // Gradient trail (upwards from line)
    final rect = Rect.fromLTWH(0, y - 50, size.width, 50);
    // Draw trail
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [color.withAlpha(100), Colors.transparent],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerBeamPainter old) =>
      old.progress != progress;
}
