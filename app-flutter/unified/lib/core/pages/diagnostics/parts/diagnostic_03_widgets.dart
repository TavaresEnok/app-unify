part of '../diagnostic_03_page.dart';

// ═══════════════════════════════════════════════════════════════
// ANIMATED CARD WRAPPER
// ═══════════════════════════════════════════════════════════════

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int delay;
  const _AnimatedCard({required this.child, this.delay = 0});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _slideAnim.value),
        child: Opacity(opacity: _fadeAnim.value, child: widget.child),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
          Text(value,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SpeedPill extends StatelessWidget {
  final String value, label, unit;
  final Color color;
  const _SpeedPill(this.value, this.label, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
            text: TextSpan(children: [
          TextSpan(
              text: value,
              style: GoogleFonts.outfit(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          TextSpan(
              text: " $unit",
              style: GoogleFonts.outfit(
                  fontSize: 10, color: color.withValues(alpha: 0.6))),
        ])),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 9, color: Colors.white.withValues(alpha: 0.4))),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color color;
  const _GlassCard({required this.child, this.color = const Color(0xFF00F5FF)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAINTERS
// ═══════════════════════════════════════════════════════════════

class _AuroraBackground extends StatelessWidget {
  final Animation<double> glow, particle;
  const _AuroraBackground({required this.glow, required this.particle});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([glow, particle]),
      builder: (_, __) => Container(
        decoration: const BoxDecoration(color: Color(0xFF000005)),
        child: Stack(children: [
          Positioned(
              top: -100 + glow.value * 30,
              left: -50,
              child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        const Color(0xFF00F5FF)
                            .withValues(alpha: 0.08 + glow.value * 0.04),
                        Colors.transparent
                      ])))),
          Positioned(
              top: 200 + glow.value * 20,
              right: -100,
              child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        const Color(0xFFFF00E5)
                            .withValues(alpha: 0.06 + glow.value * 0.03),
                        Colors.transparent
                      ])))),
          Positioned(
              bottom: -50,
              left: 100,
              child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        const Color(0xFF8B5CF6)
                            .withValues(alpha: 0.05 + glow.value * 0.02),
                        Colors.transparent
                      ])))),
          CustomPaint(
              size: Size.infinite, painter: _ParticlePainter(particle.value)),
        ]),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double t;
  _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final paint = Paint()..style = PaintingStyle.fill;
      final rand = math.Random(42);

      for (int i = 0; i < 40; i++) {
        final x = rand.nextDouble() * size.width;
        final baseY = rand.nextDouble() * size.height;
        final speed = 0.3 + rand.nextDouble() * 0.7;
        final y = (baseY - t * size.height * speed) % size.height;
        final r = 1 + rand.nextDouble() * 2;
        final opacity = 0.1 + rand.nextDouble() * 0.2;

        paint.color = Color.lerp(const Color(0xFF00F5FF),
                const Color(0xFFFF00E5), rand.nextDouble())!
            .withValues(alpha: opacity);
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    } catch (_) {
      // Falha silenciosa no painter
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => t != old.t;
}

class _GaugePainter extends CustomPainter {
  final double fill, glow, scanProgress;
  final bool isUp;
  _GaugePainter(this.fill, this.isUp, this.glow, this.scanProgress);

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final c = Offset(size.width / 2, size.height / 2);
      final r = size.width / 2 - 18;
      const start = 135 * math.pi / 180;
      const sweep = 270 * math.pi / 180;

      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          start,
          sweep,
          false,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.04)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14
            ..strokeCap = StrokeCap.round);

      final c1 = isUp ? const Color(0xFFFF00E5) : const Color(0xFF00F5FF);
      final c2 = isUp ? const Color(0xFFFF6BD6) : const Color(0xFF00D4AA);

      // Glow sem MaskFilter.blur (causa crash em GPUs antigas)
      final glowP = Paint()
        ..shader = SweepGradient(
            startAngle: start,
            endAngle: start + sweep,
            colors: [
              c1.withValues(alpha: 0.35),
              c2.withValues(alpha: 0.35)
            ]).createShader(Rect.fromCircle(center: c, radius: r))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), start,
          sweep * fill.clamp(0, 1), false, glowP);

      final mainP = Paint()
        ..shader = SweepGradient(
                startAngle: start, endAngle: start + sweep, colors: [c1, c2])
            .createShader(Rect.fromCircle(center: c, radius: r))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), start,
          sweep * fill.clamp(0, 1), false, mainP);

      if (scanProgress > 0) {
        final scanAngle = start + sweep * scanProgress;
        final scanStart = Offset(c.dx + (r - 20) * math.cos(scanAngle),
            c.dy + (r - 20) * math.sin(scanAngle));
        final scanEnd = Offset(c.dx + (r + 10) * math.cos(scanAngle),
            c.dy + (r + 10) * math.sin(scanAngle));
        canvas.drawLine(
            scanStart,
            scanEnd,
            Paint()
              ..color = c1.withValues(alpha: 0.8)
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round);
      }

      final tickP = Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..strokeWidth = 1.5;
      for (int i = 0; i <= 10; i++) {
        final a = start + sweep * i / 10;
        canvas.drawLine(
            Offset(c.dx + (r + 8) * math.cos(a), c.dy + (r + 8) * math.sin(a)),
            Offset(c.dx + (r - 4) * math.cos(a), c.dy + (r - 4) * math.sin(a)),
            tickP);
      }
    } catch (_) {
      // Falha silenciosa no painter
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter o) =>
      fill != o.fill ||
      glow != o.glow ||
      isUp != o.isUp ||
      scanProgress != o.scanProgress;
}

class _DualChartPainter extends CustomPainter {
  final List<double> downloadPts, uploadPts;
  _DualChartPainter(this.downloadPts, this.uploadPts);

  @override
  void paint(Canvas canvas, Size size) {
    try {
      _drawLine(canvas, size, downloadPts, const Color(0xFF00F5FF));
      _drawLine(canvas, size, uploadPts, const Color(0xFFFF00E5));
    } catch (_) {
      // Falha silenciosa no painter
    }
  }

  void _drawLine(Canvas canvas, Size size, List<double> pts, Color color) {
    if (pts.length < 2) return;
    final path = Path();
    final area = Path();
    final w = size.width / 50;

    for (int i = 0; i < pts.length; i++) {
      final x = i * w;
      final y =
          size.height - (pts[i] / 500 * size.height).clamp(0.0, size.height);
      if (i == 0) {
        path.moveTo(x, y);
        area.moveTo(x, size.height);
        area.lineTo(x, y);
      } else {
        final px = (i - 1) * w;
        final py = size.height -
            (pts[i - 1] / 500 * size.height).clamp(0.0, size.height);
        path.cubicTo((px + x) / 2, py, (px + x) / 2, y, x, y);
        area.cubicTo((px + x) / 2, py, (px + x) / 2, y, x, y);
      }
    }
    area.lineTo((pts.length - 1) * w, size.height);
    area.close();

    canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withValues(alpha: 0.2), Colors.transparent])
              .createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    // Linha de glow sem MaskFilter.blur (causa crash em GPUs antigas)
    canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke);
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _DualChartPainter o) => true;
}
