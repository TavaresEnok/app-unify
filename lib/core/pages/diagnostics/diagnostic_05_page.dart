// ignore_for_file: deprecated_member_use

// Diagnostic Clean Light - Single File
// INTEGRAÇÃO COM SERVIÇOS REAIS - Janeiro 2026
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/diagnostico_service.dart' as real_service;
import '../../models/diagnostico_state.dart' as real_state;
import '../../providers/providers.dart';

// main() function removed for integration - use Diagnostic05Page directly
/*
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const DiagnosticApp());
}
*/

class AppColors {
  static const bg = Color(0xFFF8FAFC);
  static const subtleBg = Color(0xFFF1F5F9);
  static const primary = Color(0xFF3B82F6);
  static const secondary = Color(0xFF8B5CF6);
  static const accent = Color(0xFF06B6D4);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const borderLight = Color(0xFFF1F5F9);
  static const pink = Color(0xFFEC4899);
}

enum DiagStep { ready, wifi, fiber, devices, speed, route, done }

class DiagnosticApp extends StatelessWidget {
  const DiagnosticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diagnostic Light',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bg,
        primaryColor: AppColors.primary,
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const Diagnostic05Page(),
    );
  }
}

class Diagnostic05Page extends ConsumerStatefulWidget {
  const Diagnostic05Page({super.key});

  @override
  ConsumerState<Diagnostic05Page> createState() => _Diagnostic05PageState();
}

class _Diagnostic05PageState extends ConsumerState<Diagnostic05Page>
    with TickerProviderStateMixin {
  DiagStep _currentStep = DiagStep.ready;
  double _progress = 0;
  bool _isRunning = false;
  double _liveSpeed = 0;
  bool _isDownload = true;
  List<double> _speedHistory = [];
  bool _buttonPressed = false;

  late AnimationController _pulseController;
  late AnimationController _bgController;
  late AnimationController _celebrationController;
  final _random = math.Random();

  // Simulated data
  Map<String, dynamic>? _wifi;
  Map<String, dynamic>? _fiber;
  List<Map<String, dynamic>> _devices = [];
  Map<String, dynamic>? _speed;
  List<Map<String, dynamic>> _hops = [];

  // Integração com serviço real
  real_service.DiagnosticoService? _realService;
  StreamSubscription<real_state.DiagnosticoState>? _realSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);

    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat();

    _celebrationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));

    _progress = 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_realService == null) {
      final config = ref.read(configurationProvider).providerConfig;
      if (config != null) {
        _realService = real_service.DiagnosticoService(
          providerConfig: config,
          context: context,
        );
        _realSub = _realService!.stateStream.listen(_handleRealServiceState);
      }
    }
  }

  void _handleRealServiceState(real_state.DiagnosticoState realState) {
    final downloadMbps = realState.customDownloadResultMbps;
    final uploadMbps = realState.customUploadResultMbps;

    if (downloadMbps > 0 || uploadMbps > 0) {
      setState(() {
        _speed = {
          'download': downloadMbps,
          'upload': uploadMbps,
          'ping': realState.speedTestPingLatency ?? 0.0,
          'jitter': 0.0,
        };
        for (final spot in realState.downloadHistory) {
          _speedHistory.add(spot.y);
        }
      });
    }
  }

  @override
  void dispose() {
    _realSub?.cancel();
    _realService?.dispose();
    _pulseController.dispose();
    _bgController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  String get _currentStepLabel {
    switch (_currentStep) {
      case DiagStep.wifi:
        return "Wi-Fi";
      case DiagStep.fiber:
        return "Fibra Óptica";
      case DiagStep.devices:
        return "Dispositivos";
      case DiagStep.speed:
        return _isDownload ? "Download" : "Upload";
      case DiagStep.route:
        return "Rota de Rede";
      default:
        return "Rede";
    }
  }

  Future<void> _startDiagnostic() async {
    if (_isRunning) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _isRunning = true;
      _progress = 0;
      _wifi = null;
      _fiber = null;
      _devices = [];
      _speed = null;
      _hops = [];
      _speedHistory = [];
    });

    // Wi-Fi
    setState(() => _currentStep = DiagStep.wifi);
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() {
      _wifi = {
        'ssid': 'FibraMax_5G',
        'rssi': -42,
        'frequency': '5 GHz • Canal 149',
        'gateway': '192.168.1.1'
      };
      _progress = 0.15;
    });

    // Fiber
    setState(() => _currentStep = DiagStep.fiber);
    await Future.delayed(const Duration(milliseconds: 1400));
    setState(() {
      _fiber = {
        'rxPower': -18.2,
        'txPower': 2.4,
        'temperature': 38.5,
        'status': 'Sincronizado (O5)'
      };
      _progress = 0.30;
    });

    // Devices
    setState(() => _currentStep = DiagStep.devices);
    final deviceList = [
      {'name': 'Roteador', 'ip': '192.168.1.1', 'icon': Icons.router_rounded},
      {'name': 'Desktop', 'ip': '192.168.1.10', 'icon': Icons.computer_rounded},
      {'name': 'Smart TV', 'ip': '192.168.1.15', 'icon': Icons.tv_rounded},
      {
        'name': 'iPhone',
        'ip': '192.168.1.22',
        'icon': Icons.phone_iphone_rounded
      },
    ];
    for (int i = 0; i < deviceList.length; i++) {
      await Future.delayed(const Duration(milliseconds: 350));
      setState(() => _devices.add(deviceList[i]));
    }
    setState(() => _progress = 0.45);

    // Speed Test
    setState(() => _currentStep = DiagStep.speed);
    setState(() => _isDownload = true);
    double maxDown = 0;
    for (int i = 0; i < 25; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      final speed = (320 + math.sin(i * 0.5) * 100 + _random.nextDouble() * 50)
          .clamp(100.0, 500.0);
      maxDown = math.max(maxDown, speed);
      setState(() {
        _liveSpeed = speed;
        _speedHistory.add(speed);
        if (_speedHistory.length > 30) _speedHistory.removeAt(0);
      });
    }

    setState(() => _isDownload = false);
    double maxUp = 0;
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      final speed = (80 + math.sin(i * 0.6) * 40 + _random.nextDouble() * 30)
          .clamp(30.0, 180.0);
      maxUp = math.max(maxUp, speed);
      setState(() {
        _liveSpeed = speed;
        _speedHistory.add(speed);
        if (_speedHistory.length > 30) _speedHistory.removeAt(0);
      });
    }

    final ping = 8 + _random.nextDouble() * 12;
    setState(() {
      _speed = {'download': maxDown, 'upload': maxUp, 'ping': ping};
      _liveSpeed = 0;
      _progress = 0.80;
    });

    // Route
    setState(() => _currentStep = DiagStep.route);
    final routes = [
      {'hop': 1, 'ip': '192.168.1.1', 'latency': 0.8},
      {'hop': 2, 'ip': '10.0.0.1', 'latency': 3.5},
      {'hop': 3, 'ip': '187.100.50.1', 'latency': 8.2},
      {'hop': 4, 'ip': '8.8.8.8', 'latency': 18.7},
    ];
    for (var hop in routes) {
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() => _hops.add(hop));
    }

    setState(() {
      _currentStep = DiagStep.done;
      _progress = 1.0;
      _isRunning = false;
    });

    _celebrationController.forward(from: 0);
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: _currentStep != DiagStep.ready
            ? Text('Diagnóstico Inteligente',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16))
            : null,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Animated Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _MeshGradientPainter(
                    animationValue: _bgController.value,
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                if (_isRunning || _currentStep != DiagStep.ready)
                  _buildProgressBar(),
                if (_isRunning || _currentStep != DiagStep.ready)
                  _buildStepIndicators(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          if (_currentStep == DiagStep.ready) ...[
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.08),
                            _buildHeroSection(),
                            const SizedBox(height: 50),
                            _buildPremiumStartButton(),
                            const SizedBox(height: 30),
                            Text(
                              "Toque para iniciar a análise\ncompleta da sua rede",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                height: 1.6,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                          if (_currentStep == DiagStep.done)
                            _buildCompletionHeader(),
                          if (_currentStep.index >= DiagStep.speed.index &&
                              _currentStep != DiagStep.done)
                            _buildGauge(),
                          if (_speedHistory.isNotEmpty &&
                              _currentStep != DiagStep.done)
                            _AnimatedCard(
                                delay: 0, child: _buildChartContent()),
                          if (_speed != null) _buildSpeedResults(),
                          if (_wifi != null)
                            _AnimatedCard(
                                delay: 100,
                                child: _buildWifiContent(),
                                accentColor: AppColors.primary),
                          if (_fiber != null)
                            _AnimatedCard(
                                delay: 200,
                                child: _buildFiberContent(),
                                accentColor: AppColors.secondary),
                          if (_devices.isNotEmpty)
                            _AnimatedCard(
                                delay: 300,
                                child: _buildDevicesContent(),
                                accentColor: AppColors.accent),
                          if (_hops.isNotEmpty)
                            _AnimatedCard(
                                delay: 400,
                                child: _buildRouteContent(),
                                accentColor: AppColors.warning),
                          if (_currentStep == DiagStep.done)
                            _buildActionButtons(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        // Pulsating Badge
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: AppColors.success
                      .withOpacity(0.3 + _pulseController.value * 0.2),
                  width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success
                      .withOpacity(0.1 + _pulseController.value * 0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text("DIAGNÓSTICO DE REDE",
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                        letterSpacing: 1.2)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumStartButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _buttonPressed = true),
      onTapUp: (_) {
        setState(() => _buttonPressed = false);
        _startDiagnostic();
      },
      onTapCancel: () => setState(() => _buttonPressed = false),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (_, __) => AnimatedScale(
          scale: _buttonPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle outer ring
              Container(
                width: 200 + (_pulseController.value * 15),
                height: 200 + (_pulseController.value * 15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.08),
                    width: 1,
                  ),
                ),
              ),
              // Main Button - Clean Neumorphic
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 10,
                      offset: Offset(-5, -5),
                    ),
                  ],
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFF1F5F9)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: AppColors.primary, size: 38),
                    ),
                    const SizedBox(height: 10),
                    Text("INICIAR",
                        style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Verificando $_currentStepLabel...",
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary)),
              Text("${(_progress * 100).toInt()}%",
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10)),
            child: LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: constraints.maxWidth * _progress,
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF60A5FA)]),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicators() {
    final steps = [
      DiagStep.wifi,
      DiagStep.fiber,
      DiagStep.devices,
      DiagStep.speed,
      DiagStep.route
    ];
    final icons = [
      Icons.wifi_rounded,
      Icons.router_rounded,
      Icons.devices_rounded,
      Icons.speed_rounded,
      Icons.alt_route_rounded
    ];
    final labels = ["Wi-Fi", "Fibra", "Rede", "Speed", "Rota"];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            final isComplete = _currentStep.index > steps[stepIndex].index ||
                _currentStep == DiagStep.done;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isComplete
                      ? AppColors.success.withOpacity(0.5)
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }

          final i = index ~/ 2;
          final step = steps[i];
          final isComplete =
              _currentStep.index > step.index || _currentStep == DiagStep.done;
          final isActive = _currentStep == step && _isRunning;

          return AnimatedScale(
            scale: isActive ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isComplete
                        ? AppColors.success
                        : isActive
                            ? AppColors.primary
                            : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (isActive || isComplete)
                        BoxShadow(
                          color: (isComplete
                                  ? AppColors.success
                                  : AppColors.primary)
                              .withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      if (!isActive && !isComplete)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                    ],
                    border: Border.all(
                        color: isComplete
                            ? AppColors.success
                            : isActive
                                ? AppColors.primary
                                : AppColors.border,
                        width: 2),
                  ),
                  child: Icon(isComplete ? Icons.check_rounded : icons[i],
                      color: isComplete || isActive
                          ? Colors.white
                          : AppColors.textMuted,
                      size: isActive ? 22 : 18),
                ),
                const SizedBox(height: 6),
                Text(labels[i],
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: isComplete || isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isComplete
                            ? AppColors.success
                            : isActive
                                ? AppColors.primary
                                : AppColors.textMuted)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCompletionHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.check_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Text("Diagnóstico Concluído",
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success)),
        ],
      ),
    );
  }

  Widget _buildGauge() {
    final color = _isDownload ? AppColors.primary : AppColors.secondary;
    final fill = (_liveSpeed / 500).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(200, 200),
              painter: _LightGaugePainter(fill: fill, color: color),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_isDownload ? "DOWNLOAD" : "UPLOAD",
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          color: color,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 6),
                Text(_liveSpeed.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                        fontSize: 46,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textPrimary,
                        letterSpacing: -2)),
                Text("Mbps",
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContent() {
    final color = _isDownload ? AppColors.primary : AppColors.secondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 8),
          Text("Fluxo em Tempo Real",
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
            height: 80,
            child: CustomPaint(
                size: const Size(double.infinity, 80),
                painter: _ChartPainter(_speedHistory, color))),
      ],
    );
  }

  Widget _buildSpeedResults() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
              child: _MetricCard(
                  icon: Icons.download_rounded,
                  label: "Download",
                  value: (_speed!['download'] as double).toStringAsFixed(0),
                  unit: "Mbps",
                  color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(
              child: _MetricCard(
                  icon: Icons.upload_rounded,
                  label: "Upload",
                  value: (_speed!['upload'] as double).toStringAsFixed(0),
                  unit: "Mbps",
                  color: AppColors.secondary)),
          const SizedBox(width: 12),
          Expanded(
              child: _MetricCard(
                  icon: Icons.flash_on_rounded,
                  label: "Ping",
                  value: (_speed!['ping'] as double).toStringAsFixed(0),
                  unit: "ms",
                  color: AppColors.success)),
        ],
      ),
    );
  }

  Widget _buildWifiContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
            icon: Icons.wifi_rounded,
            title: "Conexão Wi-Fi",
            color: AppColors.primary),
        const SizedBox(height: 16),
        _InfoRow(
            icon: Icons.wifi_rounded,
            label: "Rede",
            value: _wifi!['ssid'],
            isBold: true),
        _InfoRow(
            icon: Icons.signal_cellular_alt_rounded,
            label: "Sinal",
            value: "${_wifi!['rssi']} dBm"),
        _InfoRow(
            icon: Icons.router_rounded,
            label: "Frequência",
            value: _wifi!['frequency']),
      ],
    );
  }

  Widget _buildFiberContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
            icon: Icons.cable_rounded,
            title: "Fibra Óptica",
            color: AppColors.secondary),
        const SizedBox(height: 16),
        _InfoRow(
            icon: Icons.check_circle_rounded,
            label: "Status",
            value: _fiber!['status'],
            valueColor: AppColors.success,
            isBold: true),
        _InfoRow(
            icon: Icons.arrow_downward_rounded,
            label: "Potência RX",
            value: "${_fiber!['rxPower']} dBm"),
        _InfoRow(
            icon: Icons.arrow_upward_rounded,
            label: "Potência TX",
            value: "${_fiber!['txPower']} dBm"),
      ],
    );
  }

  Widget _buildDevicesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionHeader(
                icon: Icons.devices_rounded,
                title: "Dispositivos",
                color: AppColors.accent),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text("${_devices.length} Online",
                  style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(_devices.length, (i) {
          final device = _devices[i];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + i * 100),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(20 * (1 - value), 0),
                child: child,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                  border: i < _devices.length - 1
                      ? const Border(
                          bottom: BorderSide(color: AppColors.borderLight))
                      : null),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: AppColors.subtleBg,
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(device['icon'] as IconData,
                        color: AppColors.textSecondary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(device['name'],
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontSize: 14)),
                        Text(device['ip'],
                            style: GoogleFonts.inter(
                                color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: AppColors.success, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text("Online",
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRouteContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
            icon: Icons.alt_route_rounded,
            title: "Traceroute",
            color: AppColors.warning),
        const SizedBox(height: 16),
        ...List.generate(_hops.length, (i) {
          final hop = _hops[i];
          final latency = hop['latency'] as double;
          final latencyColor = latency < 10
              ? AppColors.success
              : latency < 20
                  ? AppColors.warning
                  : AppColors.error;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vertical line + dot
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Center(
                        child: Text("${hop['hop']}",
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning))),
                  ),
                  if (i < _hops.length - 1)
                    Container(
                      width: 2,
                      height: 24,
                      color: AppColors.border,
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(hop['ip'],
                              style: GoogleFonts.firaCode(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: latencyColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12)),
                        child: Text("${latency}ms",
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: latencyColor)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startDiagnostic,
              icon: const Icon(Icons.refresh_rounded, size: 22),
              label: Text("NOVO DIAGNÓSTICO",
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                // Share functionality placeholder
              },
              icon: const Icon(Icons.share_rounded, size: 20),
              label: Text("Compartilhar Resultado",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                side: const BorderSide(color: AppColors.border, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF64748B).withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8))
            ],
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
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
              color: color.withOpacity(0.12),
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
  final Color? valueColor;
  final bool isBold;
  const _InfoRow(
      {this.icon,
      required this.label,
      required this.value,
      this.valueColor,
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
                  color: valueColor ?? AppColors.textPrimary)),
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
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
        border: Border.all(color: color.withOpacity(0.15)),
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
    final paint = Paint();

    // Base Color
    paint.color = const Color(0xFFF8FAFC);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final t = animationValue * 2 * math.pi;

    // Orb 1 - Top Left (Blue)
    _drawOrb(
        canvas,
        Offset(size.width * 0.15 + math.cos(t) * 40,
            size.height * 0.2 + math.sin(t) * 40),
        220,
        AppColors.primary.withOpacity(0.12));

    // Orb 2 - Bottom Right (Purple)
    _drawOrb(
        canvas,
        Offset(size.width * 0.85 + math.sin(t) * 35,
            size.height * 0.75 + math.cos(t) * 35),
        280,
        AppColors.secondary.withOpacity(0.10));

    // Orb 3 - Center Right (Cyan)
    _drawOrb(
        canvas,
        Offset(size.width * 0.9 + math.cos(t * 0.7) * 25,
            size.height * 0.4 + math.sin(t * 0.7) * 25),
        160,
        AppColors.accent.withOpacity(0.08));

    // Orb 4 - Top Right (Pink) - NEW
    _drawOrb(
        canvas,
        Offset(size.width * 0.7 + math.sin(t * 0.5) * 30,
            size.height * 0.1 + math.cos(t * 0.5) * 30),
        120,
        AppColors.pink.withOpacity(0.07));
  }

  void _drawOrb(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withOpacity(0)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..blendMode = BlendMode.screen;
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
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 14.0;
    const startAngle = 135 * math.pi / 180;
    const sweepAngle = 270 * math.pi / 180;

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Fill
    final fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final gradientRect = Rect.fromCircle(center: center, radius: radius);
    fillPaint.shader = SweepGradient(
      colors: [color.withOpacity(0.4), color],
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      transform: const GradientRotation(0),
    ).createShader(gradientRect);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle * fill,
      false,
      fillPaint,
    );

    // Glow at tip
    if (fill > 0.05) {
      final endAngle = startAngle + sweepAngle * fill;
      final tipX = center.dx + (radius - strokeWidth / 2) * math.cos(endAngle);
      final tipY = center.dy + (radius - strokeWidth / 2) * math.sin(endAngle);

      final glowPaint = Paint()
        ..color = color.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawCircle(Offset(tipX, tipY), 12, glowPaint);
      canvas.drawCircle(Offset(tipX, tipY), 5, Paint()..color = Colors.white);
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
    if (data.isEmpty) return;

    final path = Path();
    final stepX = size.width / (data.length - 1);
    final maxVal = 600.0;

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

        final cp1x = prevX + stepX / 2;
        final cp1y = prevY;
        final cp2x = x - stepX / 2;
        final cp2y = y;

        path.cubicTo(cp1x, cp1y, cp2x, cp2y, x, y);
      }
    }

    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    // Fill
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
            colors: [color.withOpacity(0.25), color.withOpacity(0)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}
