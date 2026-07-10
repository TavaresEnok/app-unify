import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/diagnostic_enums.dart';
import 'diagnostic_theme.dart';
import 'holo_card.dart';

class LiveSpeedGraph extends StatelessWidget {
  final List<double> downloadData;
  final List<double> uploadData;
  final double currentSpeed;
  final SpeedPhase phase;
  final double downloadSpeed;
  final double uploadSpeed;

  const LiveSpeedGraph({
    super.key,
    required this.downloadData,
    required this.uploadData,
    required this.currentSpeed,
    required this.phase,
    required this.downloadSpeed,
    required this.uploadSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return HoloCard(
      isScanning: phase != SpeedPhase.idle,
      accent: phase == SpeedPhase.download
          ? DiagnosticTheme.cyan
          : phase == SpeedPhase.upload
              ? DiagnosticTheme.purple
              : null,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            // Need Container for padding of inner content or just Padding widget
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withAlpha(5), Colors.transparent],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with current speed
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VELOCIDADE EM TEMPO REAL',
                              style: TextStyle(
                                color: Colors.white.withAlpha(120),
                                fontSize: 11,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currentSpeed.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    height: 1,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    'Mbps',
                                    style: TextStyle(
                                      color: DiagnosticTheme.textSecondary,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (phase != SpeedPhase.idle)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: phase == SpeedPhase.download
                                  ? [DiagnosticTheme.cyan, DiagnosticTheme.blue]
                                  : [
                                      DiagnosticTheme.purple,
                                      DiagnosticTheme.pink
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (phase == SpeedPhase.download
                                        ? DiagnosticTheme.cyan
                                        : DiagnosticTheme.purple)
                                    .withAlpha(100),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                phase == SpeedPhase.download
                                    ? Icons.download_rounded
                                    : Icons.upload_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                phase == SpeedPhase.download
                                    ? 'DOWNLOAD'
                                    : 'UPLOAD',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Graph with RepaintBoundary for performance
                  SizedBox(
                    height: 140,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: const Size(double.infinity, 140),
                        painter: _SpeedGraphPainter(downloadData, uploadData),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Legend and results
                  Row(
                    children: [
                      _LegendItem(
                        color: DiagnosticTheme.cyan,
                        label: 'Download',
                        value: downloadSpeed > 0
                            ? '${downloadSpeed.toStringAsFixed(1)} Mbps'
                            : '--',
                      ),
                      const SizedBox(width: 24),
                      _LegendItem(
                        color: DiagnosticTheme.purple,
                        label: 'Upload',
                        value: uploadSpeed > 0
                            ? '${uploadSpeed.toStringAsFixed(1)} Mbps'
                            : '--',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label, value;
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style:
                  const TextStyle(color: DiagnosticTheme.textDim, fontSize: 11),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SpeedGraphPainter extends CustomPainter {
  final List<double> downloadData;
  final List<double> uploadData;

  _SpeedGraphPainter(this.downloadData, this.uploadData);

  @override
  void paint(Canvas canvas, Size size) {
    const maxPoints = 60;

    // Grid lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()..color = Colors.white.withAlpha(10),
      );
    }

    // Draw download line
    if (downloadData.isNotEmpty) {
      _drawLine(canvas, size, downloadData, DiagnosticTheme.cyan, maxPoints);
    }

    // Draw upload line
    if (uploadData.isNotEmpty) {
      _drawLine(canvas, size, uploadData, DiagnosticTheme.purple, maxPoints);
    }
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    List<double> data,
    Color color,
    int maxPoints,
  ) {
    if (data.isEmpty) return;

    const maxVal = 500.0;
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i / max(1, maxPoints - 1) * size.width;
      final y = size.height - (data[i] / maxVal * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Fill under line
    final lastX = (data.length - 1) / max(1, maxPoints - 1) * size.width;
    fillPath.lineTo(lastX, size.height);
    fillPath.close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withAlpha(60), color.withAlpha(0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line with glow
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // End dot
    if (data.isNotEmpty) {
      final lastY = size.height - (data.last / maxVal * size.height);
      canvas.drawCircle(Offset(lastX, lastY), 5, Paint()..color = Colors.white);
      canvas.drawCircle(
        Offset(lastX, lastY),
        10,
        Paint()
          ..color = color.withAlpha(100)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedGraphPainter old) => true;
}
