// LAYOUT 04 - AURORA - SPEED TEST PAGE
// Design: Futuristic speed test with animated gauge

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'aurora_theme.dart';

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage>
    with TickerProviderStateMixin {
  late AnimationController _gaugeController;
  late AnimationController _pulseController;
  bool _isRunning = false;
  double _downloadSpeed = 0;
  double _uploadSpeed = 0;
  int _ping = 0;
  String _status = 'Pronto para testar';

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startTest() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _downloadSpeed = 0;
      _uploadSpeed = 0;
      _ping = 0;
      _status = 'Testando ping...';
    });

    _gaugeController.repeat();

    // Simulate ping test
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _ping = 12 + math.Random().nextInt(10);
      _status = 'Testando download...';
    });

    // Simulate download test
    for (int i = 0; i <= 20; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() {
        _downloadSpeed = 50 + (i * 2.5) + math.Random().nextDouble() * 5;
      });
    }

    setState(() => _status = 'Testando upload...');

    // Simulate upload test
    for (int i = 0; i <= 20; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() {
        _uploadSpeed = 50 + (i * 2.5) + math.Random().nextDouble() * 5;
      });
    }

    _gaugeController.stop();
    setState(() {
      _isRunning = false;
      _status = 'Teste concluído';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: ShaderMask(
            shaderCallback: (bounds) =>
                AuroraColors.primaryGradient.createShader(bounds),
            child: const Text('Speed Test',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Main Gauge Card
            GlassCard(
              glowColor: _isRunning ? AuroraColors.neonCyan : null,
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Animated Gauge
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background ring
                        AnimatedBuilder(
                          animation: _gaugeController,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(200, 200),
                              painter: _SpeedGaugePainter(
                                progress:
                                    _isRunning ? _gaugeController.value : 0.5,
                                isRunning: _isRunning,
                              ),
                            );
                          },
                        ),
                        // Center display
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => AuroraColors
                                  .primaryGradient
                                  .createShader(bounds),
                              child: Text(
                                _downloadSpeed.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Text(
                              'Mbps',
                              style:
                                  TextStyle(color: AuroraColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Status
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Opacity(
                        opacity:
                            _isRunning ? 0.5 + 0.5 * _pulseController.value : 1,
                        child: Text(
                          _status,
                          style: TextStyle(
                            fontSize: 16,
                            color: _isRunning
                                ? AuroraColors.neonCyan
                                : AuroraColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Start Button
                  NeonButton(
                    text: _isRunning ? 'Testando...' : 'Iniciar Teste',
                    icon: _isRunning ? Icons.hourglass_top : Icons.play_arrow,
                    isLoading: _isRunning,
                    onPressed: _isRunning ? null : _startTest,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Results
            Row(
              children: [
                Expanded(
                  child: _buildResultCard(
                    'Download',
                    _downloadSpeed > 0
                        ? '${_downloadSpeed.toStringAsFixed(1)} Mbps'
                        : '---',
                    Icons.arrow_downward,
                    AuroraColors.neonCyan,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildResultCard(
                    'Upload',
                    _uploadSpeed > 0
                        ? '${_uploadSpeed.toStringAsFixed(1)} Mbps'
                        : '---',
                    Icons.arrow_upward,
                    AuroraColors.neonPurple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildResultCard(
              'Latência (Ping)',
              _ping > 0 ? '$_ping ms' : '---',
              Icons.timer,
              AuroraColors.success,
            ),

            const SizedBox(height: 24),

            // Server Info
            GlassCard(
              child: Row(
                children: [
                  Icon(Icons.cloud, color: AuroraColors.neonCyan),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Servidor',
                            style: TextStyle(
                                color: AuroraColors.textMuted, fontSize: 12)),
                        Text('São Paulo, BR',
                            style: TextStyle(
                                color: AuroraColors.textPrimary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Icon(Icons.signal_cellular_alt, color: AuroraColors.success),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(
      String label, String value, IconData icon, Color color) {
    return GlassCard(
      glowColor: color.withOpacity(0.5),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 15),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          Text(label,
              style:
                  TextStyle(color: AuroraColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SpeedGaugePainter extends CustomPainter {
  final double progress;
  final bool isRunning;

  _SpeedGaugePainter({required this.progress, required this.isRunning});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background arc
    final bgPaint = Paint()
      ..color = AuroraColors.glassBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      bgPaint,
    );

    // Gradient arc
    if (isRunning) {
      final gradient = SweepGradient(
        startAngle: math.pi * 0.75,
        endAngle: math.pi * 0.75 + math.pi * 1.5,
        colors: const [
          AuroraColors.neonCyan,
          AuroraColors.neonPurple,
          AuroraColors.neonPink,
        ],
      );

      final progressPaint = Paint()
        ..shader = gradient
            .createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi * 0.75,
        math.pi * 1.5 * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isRunning != isRunning;
  }
}
