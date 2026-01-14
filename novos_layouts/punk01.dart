import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const ISPScreen(),
    );
  }
}

class ISPScreen extends StatefulWidget {
  const ISPScreen({super.key});

  @override
  State<ISPScreen> createState() => _ISPScreenState();
}

class _ISPScreenState extends State<ISPScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isConnected = true;
  bool _isTesting = false;
  int _testPhase = 0; // 0: idle, 1: ping, 2: download, 3: upload, 4: done

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _dataFlowController;
  late AnimationController _testController;

  double _currentSpeed = 0;
  double _ping = 0;
  double _download = 0;
  double _upload = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _dataFlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _testController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _testController.addListener(_updateTestPhase);
  }

  void _updateTestPhase() {
    final progress = _testController.value;
    setState(() {
      if (progress < 0.15) {
        _testPhase = 1;
        _ping = 3 + (progress / 0.15) * 2;
      } else if (progress < 0.55) {
        _testPhase = 2;
        final p = (progress - 0.15) / 0.4;
        _currentSpeed = 520 * p * (0.9 + math.Random().nextDouble() * 0.1);
        _download = _currentSpeed;
      } else if (progress < 0.95) {
        _testPhase = 3;
        final p = (progress - 0.55) / 0.4;
        _currentSpeed = 140 * p * (0.9 + math.Random().nextDouble() * 0.1);
        _upload = _currentSpeed;
      } else {
        _testPhase = 4;
        _currentSpeed = _download;
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _dataFlowController.dispose();
    _testController.dispose();
    super.dispose();
  }

  void _startSpeedTest() {
    if (_isTesting) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _isTesting = true;
      _testPhase = 0;
      _ping = 0;
      _download = 0;
      _upload = 0;
      _currentSpeed = 0;
    });
    _testController.forward(from: 0).then((_) {
      setState(() {
        _isTesting = false;
        _ping = 3;
        _download = 487.5;
        _upload = 128.3;
        _currentSpeed = _download;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050810),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildHeroCard(),
                  const SizedBox(height: 20),
                  _buildLiveStats(),
                  const SizedBox(height: 20),
                  _buildSpeedTest(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildNetworkMap(),
                  const SizedBox(height: 24),
                  _buildPromoBanner(),
                  const SizedBox(height: 24),
                  _buildDevicesGrid(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        return Stack(
          children: [
            Container(color: const Color(0xFF050810)),
            // Animated gradient orbs
            Positioned(
              top: -150 + math.sin(_waveController.value * math.pi * 2) * 20,
              right: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00E5FF).withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 300 + math.cos(_waveController.value * math.pi * 2) * 15,
              left: -100,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7C4DFF).withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Grid pattern
            Positioned.fill(
              child: CustomPaint(
                painter: GridPatternPainter(_waveController.value),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          // Animated logo
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF00E5FF,
                      ).withOpacity(0.3 + _pulseController.value * 0.15),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'TurboNet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Text(
                        'ULTRA',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Fibra Óptica • 500 Mbps',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildGlassBtn(Icons.support_agent_rounded),
          const SizedBox(width: 10),
          _buildGlassBtn(Icons.notifications_rounded, badge: 5),
        ],
      ),
    );
  }

  Widget _buildGlassBtn(IconData icon, {int? badge}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: () => HapticFeedback.lightImpact(),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: Colors.white.withOpacity(0.9), size: 22),
                if (badge != null)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5252).withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _dataFlowController]),
        builder: (context, _) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF00E5FF).withOpacity(0.15),
                  const Color(0xFF00B8D4).withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: const Color(
                  0xFF00E5FF,
                ).withOpacity(0.2 + _pulseController.value * 0.1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Animated connection indicator
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Data flow rings
                        ...List.generate(3, (i) {
                          final delay = i * 0.3;
                          final progress =
                              ((_dataFlowController.value + delay) % 1.0);
                          return Container(
                            width: 55 + (progress * 25),
                            height: 55 + (progress * 25),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(
                                  0xFF00E5FF,
                                ).withOpacity((1 - progress) * 0.3),
                                width: 1.5,
                              ),
                            ),
                          );
                        }),
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withOpacity(0.4),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.wifi_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF00E676),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00E676,
                                      ).withOpacity(0.6),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Online',
                                style: TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Há 45 dias',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Conexão estável e ultrarrápida',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Última verificação: agora',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Live data flow visualization
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: AnimatedBuilder(
                      animation: _dataFlowController,
                      builder: (context, _) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.3 + _dataFlowController.value * 0.7,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF00E5FF).withOpacity(0),
                                  const Color(0xFF00E5FF),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF00E5FF,
                                  ).withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Download',
              '487.5 Mbps',
              Icons.arrow_downward_rounded,
              const Color(0xFF00E5FF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Upload',
              '128.3 Mbps',
              Icons.arrow_upward_rounded,
              const Color(0xFF00E676),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Ping',
              '3 ms',
              Icons.network_ping_rounded,
              const Color(0xFFFFB74D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedTest() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF0D1117), Color(0xFF161B22)],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Speed Test',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_testPhase == 4)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00E676).withOpacity(0.2),
                          const Color(0xFF00E676).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00E676).withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF00E676),
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Excelente',
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            // Speed Test Gauge
            GestureDetector(
              onTap: _startSpeedTest,
              child: AnimatedBuilder(
                animation: Listenable.merge([_waveController, _testController]),
                builder: (context, _) {
                  return SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(240, 240),
                          painter: SpeedTestPainter(
                            _isTesting
                                ? _testController.value
                                : (_testPhase == 4 ? 1.0 : 0.0),
                            _currentSpeed / 520,
                            _waveController.value,
                            _testPhase,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_isTesting && _testPhase == 0)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00E5FF),
                                      Color(0xFF00B8D4),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00E5FF,
                                      ).withOpacity(0.4),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              )
                            else if (_isTesting)
                              Column(
                                children: [
                                  Text(
                                    _currentSpeed.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _testPhase == 1
                                        ? 'Ping...'
                                        : _testPhase == 2
                                        ? 'Download'
                                        : 'Upload',
                                    style: TextStyle(
                                      color: const Color(
                                        0xFF00E5FF,
                                      ).withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  Text(
                                    _download.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 52,
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    ),
                                  ),
                                  const Text(
                                    'Mbps',
                                    style: TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Test results
            Row(
              children: [
                Expanded(
                  child: _buildTestResult(
                    'Ping',
                    _testPhase >= 1 ? '${_ping.toStringAsFixed(0)} ms' : '—',
                    const Color(0xFFFFB74D),
                  ),
                ),
                Container(
                  width: 1,
                  height: 45,
                  color: Colors.white.withOpacity(0.08),
                ),
                Expanded(
                  child: _buildTestResult(
                    'Download',
                    _testPhase >= 2
                        ? '${_download.toStringAsFixed(1)} Mbps'
                        : '—',
                    const Color(0xFF00E5FF),
                  ),
                ),
                Container(
                  width: 1,
                  height: 45,
                  color: Colors.white.withOpacity(0.08),
                ),
                Expanded(
                  child: _buildTestResult(
                    'Upload',
                    _testPhase >= 3
                        ? '${_upload.toStringAsFixed(1)} Mbps'
                        : '—',
                    const Color(0xFF00E676),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResult(String label, String value, Color color) {
    final isActive =
        (_testPhase == 1 && label == 'Ping') ||
        (_testPhase == 2 && label == 'Download') ||
        (_testPhase == 3 && label == 'Upload');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: isActive ? color : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return SizedBox(
      height: 105,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildActionCard(
            'Meu\nRoteador',
            Icons.router_rounded,
            const Color(0xFF7C4DFF),
            '2 devices',
          ),
          _buildActionCard(
            'Upgrade\nPlano',
            Icons.rocket_launch_rounded,
            const Color(0xFFFF7043),
            'Até 1Gbps',
          ),
          _buildActionCard(
            '2ª Via\nBoleto',
            Icons.receipt_long_rounded,
            const Color(0xFF00E5FF),
            'R\$ 149,90',
          ),
          _buildActionCard(
            'Senha\nWi-Fi',
            Icons.wifi_password_rounded,
            const Color(0xFF00E676),
            'Copiar',
          ),
          _buildActionCard(
            'Suporte\n24h',
            Icons.headset_mic_rounded,
            const Color(0xFFFFB74D),
            'Online',
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String label,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => HapticFeedback.lightImpact(),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: color.withOpacity(0.8), fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkMap() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mapa da Rede',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFF00E676),
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Tudo OK',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: AnimatedBuilder(
              animation: _dataFlowController,
              builder: (context, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNetworkNode(
                      'Internet',
                      Icons.public_rounded,
                      const Color(0xFF00E5FF),
                      true,
                    ),
                    _buildNetworkLine(),
                    _buildNetworkNode(
                      'Roteador',
                      Icons.router_rounded,
                      const Color(0xFF7C4DFF),
                      true,
                    ),
                    _buildNetworkLine(),
                    _buildNetworkNode(
                      'Você',
                      Icons.phone_iphone_rounded,
                      const Color(0xFF00E676),
                      true,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkNode(
    String label,
    IconData icon,
    Color color,
    bool isActive,
  ) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
                border: Border.all(
                  color: color.withOpacity(0.3 + _pulseController.value * 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.2), blurRadius: 15),
                ],
              ),
              child: Icon(icon, color: color, size: 26),
            );
          },
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF00E676) : Colors.grey,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF00E676).withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkLine() {
    return AnimatedBuilder(
      animation: _dataFlowController,
      builder: (context, _) {
        return SizedBox(
          width: 40,
          height: 4,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Positioned(
                left: _dataFlowController.value * 30,
                child: Container(
                  width: 10,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Colors.transparent],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7043), Color(0xFFFF5722)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7043).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🚀 UPGRADE DISPONÍVEL!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Turbo 1 Gbps',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dobro da velocidade pelo mesmo preço!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => HapticFeedback.mediumImpact(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Ver',
                  style: TextStyle(
                    color: Color(0xFFFF5722),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dispositivos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '8 conectados',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: [
              _buildDeviceGridItem(
                'iPhone',
                Icons.phone_iphone_rounded,
                '45 MB/s',
                true,
              ),
              _buildDeviceGridItem(
                'MacBook',
                Icons.laptop_mac_rounded,
                '120 MB/s',
                true,
              ),
              _buildDeviceGridItem(
                'Smart TV',
                Icons.tv_rounded,
                '25 MB/s',
                true,
              ),
              _buildDeviceGridItem(
                'PS5',
                Icons.gamepad_rounded,
                '80 MB/s',
                true,
              ),
              _buildDeviceGridItem(
                'Alexa',
                Icons.speaker_rounded,
                '2 MB/s',
                true,
              ),
              _buildDeviceGridItem(
                'iPad',
                Icons.tablet_mac_rounded,
                '30 MB/s',
                true,
              ),
              _buildDeviceGridItem(
                'Câmera',
                Icons.videocam_rounded,
                '5 MB/s',
                true,
              ),
              _buildDeviceGridItem('+ Add', Icons.add_rounded, '', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceGridItem(
    String name,
    IconData icon,
    String speed,
    bool isActive,
  ) {
    final isAdd = name == '+ Add';
    return Container(
      decoration: BoxDecoration(
        color: isAdd ? Colors.transparent : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAdd
              ? Colors.white.withOpacity(0.15)
              : Colors.white.withOpacity(0.06),
          style: isAdd ? BorderStyle.solid : BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isAdd
                ? Colors.white.withOpacity(0.4)
                : const Color(0xFF00E5FF),
            size: 26,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              color: Colors.white.withOpacity(isAdd ? 0.4 : 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (!isAdd && speed.isNotEmpty)
            Text(
              speed,
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 9,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF050810).withOpacity(0.8),
                  const Color(0xFF050810).withOpacity(0.95),
                ],
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.06)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_rounded, 'Início', 0),
                  _buildNavItem(Icons.analytics_rounded, 'Consumo', 1),
                  _buildCenterNav(),
                  _buildNavItem(Icons.receipt_long_rounded, 'Faturas', 2),
                  _buildNavItem(Icons.person_rounded, 'Conta', 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E5FF).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF00E5FF)
                  : Colors.white.withOpacity(0.35),
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF00E5FF)
                    : Colors.white.withOpacity(0.35),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNav() {
    return GestureDetector(
      onTap: _startSpeedTest,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF00E5FF,
                  ).withOpacity(0.4 + _pulseController.value * 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _isTesting ? Icons.stop_rounded : Icons.speed_rounded,
              color: Colors.white,
              size: 30,
            ),
          );
        },
      ),
    );
  }
}

class GridPatternPainter extends CustomPainter {
  final double animation;
  GridPatternPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPatternPainter oldDelegate) => false;
}

class SpeedTestPainter extends CustomPainter {
  final double progress;
  final double speedRatio;
  final double animation;
  final int phase;

  SpeedTestPainter(this.progress, this.speedRatio, this.animation, this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Background circles
    for (int i = 0; i < 3; i++) {
      final r = radius - (i * 12);
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.03 + i * 0.01)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, r, paint);
    }

    // Progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        colors: const [Color(0xFF00E5FF), Color(0xFF00E676), Color(0xFF00E5FF)],
        transform: GradientRotation(animation * math.pi * 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * speedRatio,
      false,
      progressPaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * speedRatio,
      false,
      glowPaint,
    );

    // Speed markers
    final markerPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 2;
    for (int i = 0; i < 12; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / 12);
      final start = Offset(
        center.dx + (radius - 20) * math.cos(angle),
        center.dy + (radius - 20) * math.sin(angle),
      );
      final end = Offset(
        center.dx + (radius - 28) * math.cos(angle),
        center.dy + (radius - 28) * math.sin(angle),
      );
      canvas.drawLine(start, end, markerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SpeedTestPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      speedRatio != oldDelegate.speedRatio ||
      animation != oldDelegate.animation;
}
