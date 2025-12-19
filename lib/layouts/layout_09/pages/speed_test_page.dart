import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/diagnostico_service.dart';
import '../../../core/models/diagnostico_state.dart';
import '../theme.dart';

class Layout09SpeedTestPage extends ConsumerStatefulWidget {
  const Layout09SpeedTestPage({super.key});

  @override
  ConsumerState<Layout09SpeedTestPage> createState() =>
      _Layout09SpeedTestPageState();
}

class _Layout09SpeedTestPageState extends ConsumerState<Layout09SpeedTestPage>
    with SingleTickerProviderStateMixin {
  late final DiagnosticoService _service;
  bool _serviceInitialized = false;
  DiagnosticoState _state = DiagnosticoState.initial();
  StreamSubscription? _subscription;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serviceInitialized) {
      final configProvider = ref.read(configurationProvider);
      final providerConfig = configProvider.providerConfig!;
      _service =
          DiagnosticoService(providerConfig: providerConfig, context: context);
      _subscription = _service.stateStream.listen((newState) {
        setState(() {
          _state = newState;
          if (_state.isTesting) {
            if (!_pulseController.isAnimating) {
              _pulseController.repeat(reverse: true);
            }
          } else {
            _pulseController.stop();
          }
        });
      });
      _serviceInitialized = true;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTest() {
    HapticFeedback.mediumImpact();
    _service.runSpeedTestsOnly();
  }

  void _stopTest() {
    _service.stopAllTests();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Layout09Theme.primary(ref.watch(themeProvider).config);
    final secondaryColor = Layout09Theme.secondary(null);
    final isRunning = _state.isTesting ||
        _state.testResultsDisplay['speedTestCustom']?['status'] ==
            TestStatus.running;

    final download = _state.customDownloadResultMbps;
    final upload = _state.customUploadResultMbps;
    final displaySpeed = upload > 1 ? upload : download;

    return Scaffold(
      backgroundColor: Layout09Theme.backgroundColor(null),
      appBar: AppBar(title: const Text('MEDIDOR DE VELOCIDADE')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Blob Pulsante Central
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.1);
                  final speedFactor = (displaySpeed / 500).clamp(0.0, 1.0);

                  return Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: isRunning
                          ? Color.lerp(
                                  primaryColor, secondaryColor, speedFactor)!
                              .withValues(alpha: 0.1)
                          : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.05),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Transform.scale(
                      scale: scale,
                      child: CustomPaint(
                        painter: SpeedBlobPainter(
                          progress: speedFactor,
                          color: isRunning
                              ? Color.lerp(
                                  primaryColor, secondaryColor, speedFactor)!
                              : Colors.blueGrey.withValues(alpha: 0.2),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                displaySpeed.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Layout09Theme.primary(null),
                                ),
                              ),
                              const Text(
                                'Mbps',
                                style: TextStyle(
                                    color: Colors.blueGrey,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 60),

            // Resultados
            Row(
              children: [
                Expanded(
                  child: _buildResultCard('Download', download,
                      Icons.download_rounded, primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildResultCard(
                      'Upload', upload, Icons.upload_rounded, secondaryColor),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // Botão Orgânico
            GestureDetector(
              onTap: isRunning ? _stopTest : _startTest,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: isRunning
                      ? Colors.red.withValues(alpha: 0.1)
                      : primaryColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: isRunning
                      ? null
                      : [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Center(
                  child: Text(
                    isRunning ? 'PARAR TESTE' : 'INICIAR TESTE',
                    style: TextStyle(
                      color: isRunning ? Colors.red : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(
      String label, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          const SizedBox(height: 4),
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class SpeedBlobPainter extends CustomPainter {
  final double progress;
  final Color color;

  SpeedBlobPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    for (int i = 0; i < 360; i += 10) {
      final angle = i * math.pi / 180;
      // Adicionar variação orgânica baseada no progresso
      final variation = math.sin(angle * 3) * (5 + 15 * progress);
      final currentRadius = radius + variation;

      final x = center.dx + currentRadius * math.cos(angle);
      final y = center.dy + currentRadius * math.sin(angle);

      if (i == 0) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      } else {
        // Apenas desenha pontos para um efeito "floaty"
        canvas.drawCircle(Offset(x, y), 2 + (progress * 2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
