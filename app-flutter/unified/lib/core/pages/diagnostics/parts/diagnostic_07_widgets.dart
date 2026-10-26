part of '../diagnostic_07_page.dart';

// ============ UTILS ============

// Staggered Animation Helper
class _StaggeredItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggeredItem({required this.index, required this.child, super.key});
  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // Staggered Start
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _GlassContainer({required this.child, this.padding});
  @override
  Widget build(BuildContext context) {
    // BackdropFilter removido: causa crash silencioso em release mode em certos
    // dispositivos Android (GPU sem suporte a composição de camadas).
    // Efeito visual equivalente via opacidade + borda + sombra.
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: AppTheme.borderRadius,
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppTheme.borderRadius,
        child: child,
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  final Widget child;
  const _GlassBadge({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: child,
    );
  }
}

// ============ PAINTERS ============

class _CombinedBackgroundPainter extends CustomPainter {
  final double meshTime;
  _CombinedBackgroundPainter({required this.meshTime});

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final rect = Offset.zero & size;
      // 1. Bg
      canvas.drawRect(rect, Paint()..color = AppTheme.bgLight);

      // 2. Mesh Orbs — gradiente radial (sem MaskFilter.blur, que crasha em GPUs antigas)
      final cx1 = size.width * 0.3 + math.sin(meshTime) * 30;
      final cy1 = size.height * 0.2;
      final r1 = size.width * 0.5;
      final p1 = Paint()
        ..shader = RadialGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.14),
            AppTheme.primary.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx1, cy1), radius: r1));
      canvas.drawCircle(Offset(cx1, cy1), r1, p1);

      final cx2 = size.width * 0.8 - math.cos(meshTime) * 30;
      final cy2 = size.height * 0.6;
      final r2 = size.width * 0.6;
      final p2 = Paint()
        ..shader = RadialGradient(
          colors: [
            AppTheme.accent.withValues(alpha: 0.12),
            AppTheme.accent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx2, cy2), radius: r2));
      canvas.drawCircle(Offset(cx2, cy2), r2, p2);

      // 3. Particles (sem blur)
      final rnd = math.Random(42);
      final pp = Paint()..color = AppTheme.primary.withValues(alpha: 0.18);
      for (int i = 0; i < 20; i++) {
        final x =
            (rnd.nextDouble() * size.width + math.sin(meshTime + i) * 20) %
                size.width;
        final y =
            (rnd.nextDouble() * size.height + math.cos(meshTime + i) * 20) %
                size.height;
        canvas.drawCircle(Offset(x, y), rnd.nextDouble() * 2.5 + 0.5, pp);
      }
    } catch (_) {
      // Falha silenciosa: nunca deixa o painter crashar a UI
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = AppTheme.bgLight,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CombinedBackgroundPainter old) =>
      old.meshTime != meshTime;
}

class _SmoothChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _SmoothChartPainter({required this.data, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    try {
      if (data.length < 2) return;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path();
      final widthStep = size.width / (data.length - 1);
      path.moveTo(0,
          size.height - (data[0] / 1000 * size.height).clamp(0.0, size.height));
      for (int i = 0; i < data.length - 1; i++) {
        final x1 = i * widthStep;
        final y1 = size.height -
            (data[i] / 1000 * size.height).clamp(0.0, size.height);
        final x2 = (i + 1) * widthStep;
        final y2 = size.height -
            (data[i + 1] / 1000 * size.height).clamp(0.0, size.height);
        path.cubicTo(x1 + widthStep / 2, y1, x1 + widthStep / 2, y2, x2, y2);
      }
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
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.0)
                ]).createShader(Offset.zero & size));
      canvas.drawPath(path, paint);
    } catch (_) {
      // Falha silenciosa no painter
    }
  }

  @override
  bool shouldRepaint(_SmoothChartPainter old) => true;
}
