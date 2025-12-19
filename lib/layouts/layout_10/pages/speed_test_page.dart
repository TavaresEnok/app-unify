import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../core/providers/providers.dart';
import '../../../core/services/diagnostico_service.dart';
import '../../../core/models/diagnostico_state.dart';
import '../theme.dart';
import '../login_page.dart'; // Reuse MeshGradientPainter

class Layout10SpeedTestPage extends ConsumerStatefulWidget {
  const Layout10SpeedTestPage({super.key});

  @override
  ConsumerState<Layout10SpeedTestPage> createState() =>
      _Layout10SpeedTestPageState();
}

class _Layout10SpeedTestPageState extends ConsumerState<Layout10SpeedTestPage>
    with TickerProviderStateMixin {
  late final DiagnosticoService _service;
  bool _serviceInitialized = false;
  DiagnosticoState _state = DiagnosticoState.initial();
  StreamSubscription? _subscription;

  late AnimationController _meshController;
  late AnimationController _particleController;
  final List<Particle> _particles = List.generate(30, (index) => Particle());

  @override
  void initState() {
    super.initState();
    _meshController =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
    _particleController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
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
        });
      });
      _serviceInitialized = true;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    _meshController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _startTest() {
    HapticFeedback.heavyImpact();
    _service.runSpeedTestsOnly();
  }

  void _stopTest() {
    _service.stopAllTests();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Layout10Theme.primary(ref.watch(themeProvider).config);
    final secondaryColor = Layout10Theme.secondary(null);
    final isRunning = _state.isTesting ||
        _state.testResultsDisplay['speedTestCustom']?['status'] ==
            TestStatus.running;

    final download = _state.customDownloadResultMbps;
    final upload = _state.customUploadResultMbps;
    final displaySpeed = upload > 1 ? upload : download;

    return Scaffold(
      backgroundColor: Layout10Theme.backgroundColor(null),
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('MEDIDOR PREMIUM')),
      body: Stack(
        children: [
          // Background Mesh
          AnimatedBuilder(
            animation: _meshController,
            builder: (context, child) {
              return CustomPaint(
                painter: MeshGradientPainter(
                  animation: _meshController.value,
                  primary: primaryColor,
                  secondary: secondaryColor,
                ),
                size: Size.infinite,
              );
            },
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Speedometer Glass
                  Layout10Theme.glassCard(
                    opacity: 0.1,
                    blur: 30,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 250,
                          width: 250,
                          child: Stack(
                            children: [
                              // Particles Layer
                              AnimatedBuilder(
                                animation: _particleController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: ParticlePainter(
                                      particles: _particles,
                                      speed: displaySpeed,
                                      animation: _particleController.value,
                                      color: primaryColor,
                                    ),
                                    size: Size.infinite,
                                  );
                                },
                              ),
                              // Speed Content
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      displaySpeed.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 64,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Mbps',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color:
                                            Colors.white.withValues(alpha: 0.5),
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniResult('DOWNLOAD', download,
                                Icons.arrow_downward_rounded, primaryColor),
                            Container(
                                width: 1, height: 40, color: Colors.white12),
                            _buildMiniResult('UPLOAD', upload,
                                Icons.arrow_upward_rounded, secondaryColor),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Action Button
                  GestureDetector(
                    onTap: isRunning ? _stopTest : _startTest,
                    child: Layout10Theme.glassCard(
                      opacity: isRunning ? 0.05 : 0.8,
                      color: isRunning ? Colors.red : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      borderRadius: BorderRadius.circular(20),
                      child: Center(
                        child: Text(
                          isRunning ? 'CANCELAR' : 'INICIAR TESTE AGORA',
                          style: TextStyle(
                            color: isRunning ? Colors.redAccent : primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Teste certificado pelo seu provedor',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniResult(
      String label, double value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.7), size: 16),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class Particle {
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble();
  double size = math.Random().nextDouble() * 3 + 1;
  double speed = math.Random().nextDouble() * 0.02 + 0.01;
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double speed;
  final double animation;
  final Color color;

  ParticlePainter(
      {required this.particles,
      required this.speed,
      required this.animation,
      required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.4);
    final speedFactor = (speed / 100).clamp(1.0, 10.0);

    for (var particle in particles) {
      // Mover partículas circularmente ao redor do centro
      final angle = (animation * 2 * math.pi * particle.speed * speedFactor) +
          (particle.x * 2 * math.pi);
      final radius = (size.width / 2 - 20) * (0.8 + 0.2 * particle.y);

      final dx = size.width / 2 + radius * math.cos(angle);
      final dy = size.height / 2 + radius * math.sin(angle);

      canvas.drawCircle(Offset(dx, dy), particle.size, paint);

      // Desenhar rastro sutil
      final trailPaint = Paint()..color = color.withValues(alpha: 0.1);
      final prevAngle = angle - 0.1;
      final pdx = size.width / 2 + radius * math.cos(prevAngle);
      final pdy = size.height / 2 + radius * math.sin(prevAngle);
      canvas.drawLine(Offset(dx, dy), Offset(pdx, pdy), trailPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
