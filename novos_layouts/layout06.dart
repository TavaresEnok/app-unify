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

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _testController;

  double _currentSpeed = 0;
  final double _maxSpeed = 520;

  final double _dataUsed = 342.5;
  final double _dataTotal = 500;

  final List<double> _usageHistory = [120, 180, 250, 200, 280, 320, 342.5];
  final List<String> _days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _testController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _testController.addListener(() {
      setState(() {
        _currentSpeed =
            _maxSpeed *
            _testController.value *
            (0.85 + math.Random().nextDouble() * 0.15);
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _testController.dispose();
    super.dispose();
  }

  void _startSpeedTest() {
    if (_isTesting) return;
    setState(() => _isTesting = true);
    HapticFeedback.mediumImpact();
    _testController.forward(from: 0).then((_) {
      setState(() {
        _isTesting = false;
        _currentSpeed = 458.5;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildConnectionCard(),
                  const SizedBox(height: 20),
                  _buildSpeedTest(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildUsageChart(),
                  const SizedBox(height: 24),
                  _buildPlanCard(),
                  const SizedBox(height: 24),
                  _buildServiceStatus(),
                  const SizedBox(height: 24),
                  _buildDevices(),
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

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A0E21), Color(0xFF0D1B2A)],
                ),
              ),
            ),
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00BCD4).withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 200,
              left: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7C4DFF).withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00BCD4).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.wifi_rounded,
              color: Colors.white,
              size: 26,
            ),
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
                          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'FIBRA',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Cliente Premium desde 2022',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildHeaderBtn(Icons.headset_mic_rounded),
          const SizedBox(width: 10),
          _buildHeaderBtn(Icons.notifications_outlined, badge: 3),
        ],
      ),
    );
  }

  Widget _buildHeaderBtn(IconData icon, {int? badge}) {
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.8), size: 22),
            if (badge != null)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BCD4).withOpacity(0.5),
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
    );
  }

  Widget _buildConnectionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  (_isConnected
                          ? const Color(0xFF00BCD4)
                          : const Color(0xFFE53935))
                      .withOpacity(0.12),
                  (_isConnected
                          ? const Color(0xFF00BCD4)
                          : const Color(0xFFE53935))
                      .withOpacity(0.04),
                ],
              ),
              border: Border.all(
                color:
                    (_isConnected
                            ? const Color(0xFF00BCD4)
                            : const Color(0xFFE53935))
                        .withOpacity(0.15 + _pulseController.value * 0.1),
              ),
            ),
            child: Row(
              children: [
                // Animated WiFi signal
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isConnected)
                        ...List.generate(3, (i) {
                          final delay = i * 0.25;
                          final progress =
                              ((_pulseController.value + delay) % 1.0);
                          return Opacity(
                            opacity: (1 - progress) * 0.4,
                            child: Container(
                              width: 40 + (progress * 30),
                              height: 40 + (progress * 30),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF00BCD4),
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isConnected
                                ? [
                                    const Color(0xFF00BCD4),
                                    const Color(0xFF00838F),
                                  ]
                                : [
                                    const Color(0xFFE53935),
                                    const Color(0xFFC62828),
                                  ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_isConnected
                                          ? const Color(0xFF00BCD4)
                                          : const Color(0xFFE53935))
                                      .withOpacity(0.4),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isConnected
                              ? Icons.wifi_rounded
                              : Icons.wifi_off_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
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
                              color: _isConnected
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFFE53935),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (_isConnected
                                              ? const Color(0xFF00E676)
                                              : const Color(0xFFE53935))
                                          .withOpacity(0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isConnected ? 'Conectado' : 'Desconectado',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isConnected
                            ? 'Fibra Óptica • 500 Mbps • Latência: 3ms'
                            : 'Verifique seu roteador ou entre em contato',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
              ],
            ),
          );
        },
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1F3C), Color(0xFF0F1225)],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00BCD4).withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Teste de Velocidade',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_isTesting && _currentSpeed > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF00E676),
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Concluído',
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
            const SizedBox(height: 30),
            // Speed gauge
            GestureDetector(
              onTap: _startSpeedTest,
              child: AnimatedBuilder(
                animation: Listenable.merge([_waveController, _testController]),
                builder: (context, _) {
                  return SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circles
                        CustomPaint(
                          size: const Size(220, 220),
                          painter: SpeedGaugePainter(
                            _currentSpeed / _maxSpeed,
                            _isTesting ? _waveController.value : 0,
                          ),
                        ),
                        // Center content
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isTesting)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF00BCD4),
                                ),
                              )
                            else if (_currentSpeed == 0)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(
                                    0xFF00BCD4,
                                  ).withOpacity(0.15),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Color(0xFF00BCD4),
                                  size: 40,
                                ),
                              )
                            else
                              Column(
                                children: [
                                  Text(
                                    _currentSpeed.toStringAsFixed(1),
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
                                      color: Color(0xFF00BCD4),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            if (_isTesting)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  'Testando...',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            if (!_isTesting && _currentSpeed == 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  'Toque para iniciar',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 13,
                                  ),
                                ),
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
            Row(
              children: [
                Expanded(
                  child: _buildSpeedMetric(
                    'Download',
                    '${_currentSpeed > 0 ? _currentSpeed.toStringAsFixed(1) : "—"} Mbps',
                    Icons.arrow_downward_rounded,
                    const Color(0xFF00BCD4),
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.white.withOpacity(0.08),
                ),
                Expanded(
                  child: _buildSpeedMetric(
                    'Upload',
                    '${_currentSpeed > 0 ? (_currentSpeed * 0.27).toStringAsFixed(1) : "—"} Mbps',
                    Icons.arrow_upward_rounded,
                    const Color(0xFF00E676),
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.white.withOpacity(0.08),
                ),
                Expanded(
                  child: _buildSpeedMetric(
                    'Ping',
                    '${_currentSpeed > 0 ? "3" : "—"} ms',
                    Icons.network_ping_rounded,
                    const Color(0xFFFFB74D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
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
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildAction(
            'Roteador',
            Icons.router_rounded,
            const Color(0xFF7C4DFF),
          ),
          _buildAction(
            '2ª Via',
            Icons.receipt_long_rounded,
            const Color(0xFF00BCD4),
          ),
          _buildAction(
            'Upgrade',
            Icons.rocket_launch_rounded,
            const Color(0xFFFF7043),
          ),
          _buildAction(
            'Wi-Fi',
            Icons.wifi_password_rounded,
            const Color(0xFF00E676),
          ),
          _buildAction(
            'Suporte',
            Icons.support_agent_rounded,
            const Color(0xFFFFB74D),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => HapticFeedback.lightImpact(),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Consumo Semanal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00BCD4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_dataUsed.toStringAsFixed(0)} GB',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(_usageHistory.length, (i) {
                      final height = (_usageHistory[i] / _dataTotal) * 100;
                      final isToday = i == _usageHistory.length - 1;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, _) {
                                  return Container(
                                    height: height,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: isToday
                                            ? [
                                                const Color(0xFF00BCD4),
                                                const Color(0xFF00838F),
                                              ]
                                            : [
                                                Colors.white.withOpacity(0.15),
                                                Colors.white.withOpacity(0.08),
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: isToday
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF00BCD4)
                                                    .withOpacity(
                                                      0.3 +
                                                          _pulseController
                                                                  .value *
                                                              0.1,
                                                    ),
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _days[i],
                                style: TextStyle(
                                  color: isToday
                                      ? const Color(0xFF00BCD4)
                                      : Colors.white.withOpacity(0.4),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${((_dataTotal - _dataUsed)).toStringAsFixed(0)} GB restantes',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Renova em 10 dias',
                      style: TextStyle(
                        color: const Color(0xFF00BCD4).withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withOpacity(0.35),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seu Plano',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Text(
                          'TURBO ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '500',
                          style: TextStyle(
                            color: Color(0xFFFFD740),
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Ativo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPlanBadge('500 Mbps', Icons.speed_rounded),
                _buildPlanBadge('500 GB', Icons.data_usage_rounded),
                _buildPlanBadge('Wi-Fi 6', Icons.wifi_rounded),
                _buildPlanBadge('IP Fixo', Icons.language_rounded),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Próxima Fatura',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'R\$ 149,90',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Vencimento: 05/01/2024',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => HapticFeedback.mediumImpact(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Pagar',
                        style: TextStyle(
                          color: Color(0xFF7C4DFF),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanBadge(String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.85), size: 22),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status dos Serviços',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  'Internet',
                  'Operacional',
                  Icons.public_rounded,
                  const Color(0xFF00E676),
                  true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusCard(
                  'TV',
                  'Operacional',
                  Icons.tv_rounded,
                  const Color(0xFF00E676),
                  true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusCard(
                  'Telefone',
                  'Manutenção',
                  Icons.phone_rounded,
                  const Color(0xFFFFB74D),
                  false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    String title,
    String status,
    IconData icon,
    Color color,
    bool isActive,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
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
                  color: const Color(0xFF00E676).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '8 ativos',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 95,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              _buildDevice('iPhone', Icons.phone_iphone_rounded, '12 MB/s'),
              _buildDevice('MacBook', Icons.laptop_mac_rounded, '45 MB/s'),
              _buildDevice('Smart TV', Icons.tv_rounded, '8 MB/s'),
              _buildDevice('PS5', Icons.gamepad_rounded, '25 MB/s'),
              _buildDevice('Alexa', Icons.speaker_rounded, '1 MB/s'),
              _buildDevice('iPad', Icons.tablet_mac_rounded, '5 MB/s'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDevice(String name, IconData icon, String speed) {
    return Container(
      width: 85,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF00BCD4), size: 26),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            speed,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
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
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E21).withOpacity(0.92),
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
                  _buildNavItem(Icons.speed_rounded, 'Velocidade', 1),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00BCD4).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF00BCD4)
                  : Colors.white.withOpacity(0.35),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF00BCD4)
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
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF00BCD4,
                  ).withOpacity(0.35 + _pulseController.value * 0.1),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              _isTesting ? Icons.stop_rounded : Icons.speed_rounded,
              color: Colors.white,
              size: 28,
            ),
          );
        },
      ),
    );
  }
}

class SpeedGaugePainter extends CustomPainter {
  final double progress;
  final double animation;

  SpeedGaugePainter(this.progress, this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 15;

    // Background arcs
    for (int i = 0; i < 3; i++) {
      final r = radius - (i * 15);
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.03 + i * 0.01)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(center, r, paint);
    }

    // Progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: const [Color(0xFF00BCD4), Color(0xFF00E676), Color(0xFF00BCD4)],
        transform: GradientRotation(animation * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00BCD4).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      glowPaint,
    );

    // Tick marks
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 2;
    for (int i = 0; i < 12; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / 12);
      final start = Offset(
        center.dx + (radius - 25) * math.cos(angle),
        center.dy + (radius - 25) * math.sin(angle),
      );
      final end = Offset(
        center.dx + (radius - 32) * math.cos(angle),
        center.dy + (radius - 32) * math.sin(angle),
      );
      canvas.drawLine(start, end, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SpeedGaugePainter oldDelegate) =>
      progress != oldDelegate.progress || animation != oldDelegate.animation;
}
