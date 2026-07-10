part of '../diagnostic_05_page.dart';

// ============ WIDGETS ============

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int delay;
  final Color? accentColor;

  const _AnimatedCard({required this.child, this.delay = 0, this.accentColor});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
            begin: const Offset(0, 0.1), end: Offset.zero)
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF64748B).withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8))
            ],
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.6), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Row(
              children: [
                if (widget.accentColor != null)
                  Container(width: 4, color: widget.accentColor),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: widget.child)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Text(title,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  final bool isBold;
  const _InfoRow(
      {this.icon,
      required this.label,
      required this.value,
      this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
          ],
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _MetricCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.unit,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: value,
                  style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w800, color: color)),
              TextSpan(
                  text: " $unit",
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ============ PAINTERS ============

class _MeshGradientPainter extends CustomPainter {
  final double animationValue;
  _MeshGradientPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final paint = Paint();
      paint.color = const Color(0xFFF8FAFC);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

      final t = animationValue * 2 * math.pi;

      _drawOrb(
          canvas,
          Offset(size.width * 0.15 + math.cos(t) * 40,
              size.height * 0.2 + math.sin(t) * 40),
          220,
          AppColors.primary.withValues(alpha: 0.12));
      _drawOrb(
          canvas,
          Offset(size.width * 0.85 + math.sin(t) * 35,
              size.height * 0.75 + math.cos(t) * 35),
          280,
          AppColors.secondary.withValues(alpha: 0.10));
      _drawOrb(
          canvas,
          Offset(size.width * 0.9 + math.cos(t * 0.7) * 25,
              size.height * 0.4 + math.sin(t * 0.7) * 25),
          160,
          AppColors.accent.withValues(alpha: 0.08));
      _drawOrb(
          canvas,
          Offset(size.width * 0.7 + math.sin(t * 0.5) * 30,
              size.height * 0.1 + math.cos(t * 0.5) * 30),
          120,
          AppColors.pink.withValues(alpha: 0.07));
    } catch (_) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFFF8FAFC),
      );
    }
  }

  void _drawOrb(Canvas canvas, Offset center, double radius, Color color) {
    // BlendMode.screen removido: requer compositing de camadas que crasha em GPUs antigas
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) => true;
}

class _LightGaugePainter extends CustomPainter {
  final double fill;
  final Color color;
  _LightGaugePainter({required this.fill, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final center = Offset(size.width / 2, size.height / 2);
      final radius = math.min(size.width, size.height) / 2;
      const strokeWidth = 14.0;
      const startAngle = 135 * math.pi / 180;
      const sweepAngle = 270 * math.pi / 180;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = const Color(0xFFE2E8F0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );

      final gradientRect = Rect.fromCircle(center: center, radius: radius);
      final fillPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [color.withValues(alpha: 0.4), color],
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
        ).createShader(gradientRect);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle * fill,
        false,
        fillPaint,
      );

      if (fill > 0.05) {
        final endAngle = startAngle + sweepAngle * fill;
        final tipX =
            center.dx + (radius - strokeWidth / 2) * math.cos(endAngle);
        final tipY =
            center.dy + (radius - strokeWidth / 2) * math.sin(endAngle);
        canvas.drawCircle(Offset(tipX, tipY), 10,
            Paint()..color = color.withValues(alpha: 0.4));
        canvas.drawCircle(Offset(tipX, tipY), 5, Paint()..color = Colors.white);
      }
    } catch (_) {
      // Falha silenciosa no painter
    }
  }

  @override
  bool shouldRepaint(covariant _LightGaugePainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.color != color;
}

class _ChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _ChartPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    try {
      if (data.length < 2) return;

      final path = Path();
      final stepX = size.width / (data.length - 1);
      const maxVal = 600.0;

      for (int i = 0; i < data.length; i++) {
        final x = i * stepX;
        final y = size.height -
            (data[i] / maxVal * size.height).clamp(0.0, size.height);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          final prevX = (i - 1) * stepX;
          final prevY = size.height -
              (data[i - 1] / maxVal * size.height).clamp(0.0, size.height);
          path.cubicTo(prevX + stepX / 2, prevY, x - stepX / 2, y, x, y);
        }
      }

      canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);

      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();

      canvas.drawPath(
          fillPath,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.25),
                color.withValues(alpha: 0)
              ],
            ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
            ..style = PaintingStyle.fill);
    } catch (_) {
      // Falha silenciosa no painter
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}
