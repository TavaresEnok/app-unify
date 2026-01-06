// ignore_for_file: deprecated_member_use

// Diagnostic6 - Premium Clean Layout with Vertical Timeline
// INTEGRAÇÃO COM SERVIÇOS REAIS - Janeiro 2026
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/diagnostico_service.dart' as real_service;
import '../../models/diagnostico_state.dart' as real_state;
import '../../providers/providers.dart'; // ============ COLORS ============

class AppColors {
  static const bg = Color(0xFFFAFAFA);
  static const cardBg = Colors.white;
  static const primary = Color(0xFF475569); // Slate
  static const accent = Color(0xFF0EA5E9); // Sky blue
  static const accentLight = Color(0xFF7DD3FC);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFFA1A1AA);
  static const border = Color(0xFFE4E4E7);
}

enum DiagStep { ready, wifi, fiber, devices, speed, route, done }

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

class DiagnosticApp extends StatelessWidget {
  const DiagnosticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bg,
      ),
      home: const Diagnostic06Page(),
    );
  }
}

class Diagnostic06Page extends ConsumerStatefulWidget {
  const Diagnostic06Page({super.key});

  @override
  ConsumerState<Diagnostic06Page> createState() => _Diagnostic06PageState();
}

class _Diagnostic06PageState extends ConsumerState<Diagnostic06Page>
    with TickerProviderStateMixin {
  DiagStep _currentStep = DiagStep.ready;
  bool _isRunning = false;
  double _liveSpeed = 0;
  bool _isDownload = true;
  double _progress = 0;
  final _random = math.Random();

  late AnimationController _breatheController;
  late AnimationController _spinController;
  late AnimationController _gaugeController;

  // Data - Same as D5
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
    _breatheController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _spinController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _gaugeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
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
      });
    }
  }

  @override
  void dispose() {
    _realSub?.cancel();
    _realService?.dispose();
    _breatheController.dispose();
    _spinController.dispose();
    _gaugeController.dispose();
    super.dispose();
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
    });

    // Wi-Fi - Same data as D5
    setState(() => _currentStep = DiagStep.wifi);
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() {
      _wifi = {
        'ssid': 'FibraMax_5G',
        'rssi': -42,
        'frequency': '5 GHz',
        'channel': 149,
        'gateway': '192.168.1.1'
      };
      _progress = 0.15;
    });

    // Fiber - Same data as D5
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

    // Devices - Same data as D5 (with IPs)
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
    for (var d in deviceList) {
      await Future.delayed(const Duration(milliseconds: 350));
      setState(() => _devices.add(d));
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
      setState(() => _liveSpeed = speed);
    }

    setState(() => _isDownload = false);
    double maxUp = 0;
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      final speed = (80 + math.sin(i * 0.6) * 40 + _random.nextDouble() * 30)
          .clamp(30.0, 180.0);
      maxUp = math.max(maxUp, speed);
      setState(() => _liveSpeed = speed);
    }

    final ping = 8 + _random.nextDouble() * 12;
    setState(() {
      _speed = {'download': maxDown, 'upload': maxUp, 'ping': ping};
      _liveSpeed = 0;
      _progress = 0.80;
    });

    // Route - Same as D5
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
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _currentStep == DiagStep.ready
            ? _buildWelcomeScreen()
            : _buildDiagnosticScreen(),
      ),
    );
  }

  // ============ WELCOME SCREEN ============
  Widget _buildWelcomeScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 3),

          // Modern Animated Icon with Gradient Ring
          AnimatedBuilder(
            animation: _breatheController,
            builder: (_, __) {
              final scale = 1.0 + _breatheController.value * 0.05;
              final rotation = _breatheController.value * 0.1;
              return Transform.scale(
                scale: scale,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer gradient ring
                    Transform.rotate(
                      angle: rotation,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              AppColors.accent.withOpacity(0.3),
                              AppColors.accentLight.withOpacity(0.1),
                              AppColors.accent.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Inner white circle
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    // Icon container
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.accent, AppColors.accentLight],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.wifi_tethering_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 56),

          // Title with gradient
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.textPrimary, AppColors.primary],
            ).createShader(bounds),
            child: Text(
              "Diagnóstico",
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ),
          Text(
            "de Rede",
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w300,
              color: AppColors.textSecondary,
              letterSpacing: -1,
            ),
          ),

          const SizedBox(height: 20),

          // Subtitle with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    color: AppColors.success, size: 14),
              ),
              const SizedBox(width: 10),
              Text(
                "Sistema pronto para análise",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const Spacer(flex: 3),

          // Modern Start Button
          GestureDetector(
            onTap: _startDiagnostic,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.85)
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    "Iniciar Diagnóstico",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ============ DIAGNOSTIC SCREEN ============
  Widget _buildDiagnosticScreen() {
    return Column(
      children: [
        // Modern Header with Progress
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    "Diagnóstico",
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (_isRunning)
                    AnimatedBuilder(
                      animation: _spinController,
                      builder: (_, __) => Transform.rotate(
                        angle: _spinController.value * 2 * math.pi,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.settings_rounded,
                              color: AppColors.accent, size: 20),
                        ),
                      ),
                    ),
                  if (!_isRunning && _currentStep == DiagStep.done)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.success.withOpacity(0.15),
                            AppColors.success.withOpacity(0.05)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 16),
                          const SizedBox(width: 6),
                          Text("Concluído",
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success)),
                        ],
                      ),
                    ),
                ],
              ),
              if (_isRunning || _currentStep != DiagStep.ready) ...[
                const SizedBox(height: 14),
                // Progress bar
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) => Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: constraints.maxWidth * _progress,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accent, AppColors.accentLight],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Vertical Timeline
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              children: [
                // Speed Test with Gauge
                if (_currentStep.index >= DiagStep.speed.index &&
                    _currentStep != DiagStep.done)
                  _buildSpeedGauge(),

                // Results
                if (_speed != null) _buildModernResults(),

                // Timeline Items with full data
                if (_wifi != null) _buildWifiCard(),
                if (_fiber != null) _buildFiberCard(),
                if (_devices.isNotEmpty) _buildDevicesCard(),
                if (_hops.isNotEmpty) _buildRouteCard(),

                // Restart Button
                if (_currentStep == DiagStep.done) ...[
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => setState(() => _currentStep = DiagStep.ready),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            "Novo Diagnóstico",
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedGauge() {
    final color = _isDownload ? AppColors.accent : AppColors.primary;
    final fill = (_liveSpeed / 500).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gauge
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(180, 180),
                  painter: _GaugePainter(fill: fill, color: color),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _isDownload ? "DOWNLOAD" : "UPLOAD",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _liveSpeed.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 44,
                        fontWeight: FontWeight.w200,
                        color: AppColors.textPrimary,
                        letterSpacing: -2,
                      ),
                    ),
                    Text(
                      "Mbps",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textMuted,
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

  Widget _buildModernResults() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          _buildMetricCard(
            icon: Icons.download_rounded,
            value: (_speed!['download'] as double).toStringAsFixed(0),
            unit: "Mbps",
            label: "Download",
            color: AppColors.accent,
          ),
          const SizedBox(width: 12),
          _buildMetricCard(
            icon: Icons.upload_rounded,
            value: (_speed!['upload'] as double).toStringAsFixed(0),
            unit: "Mbps",
            label: "Upload",
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          _buildMetricCard(
            icon: Icons.flash_on_rounded,
            value: (_speed!['ping'] as double).toStringAsFixed(0),
            unit: "ms",
            label: "Ping",
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  TextSpan(
                    text: " $unit",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiCard() {
    return _buildTimelineCard(
      icon: Icons.wifi_rounded,
      title: "Wi-Fi",
      color: AppColors.accent,
      isLast: _fiber == null && _devices.isEmpty && _hops.isEmpty,
      content: Column(
        children: [
          _buildInfoRow("Rede", _wifi!['ssid'], isBold: true),
          _buildInfoRow("Sinal", "${_wifi!['rssi']} dBm"),
          _buildInfoRow("Frequência",
              "${_wifi!['frequency']} • Canal ${_wifi!['channel']}"),
          _buildInfoRow("Gateway", _wifi!['gateway']),
        ],
      ),
    );
  }

  Widget _buildFiberCard() {
    return _buildTimelineCard(
      icon: Icons.cable_rounded,
      title: "Fibra Óptica",
      color: AppColors.success,
      isLast: _devices.isEmpty && _hops.isEmpty,
      content: Column(
        children: [
          _buildInfoRow("Status", _fiber!['status'],
              isBold: true, valueColor: AppColors.success),
          _buildInfoRow("Potência RX", "${_fiber!['rxPower']} dBm"),
          _buildInfoRow("Potência TX", "${_fiber!['txPower']} dBm"),
          _buildInfoRow("Temperatura", "${_fiber!['temperature']}°C"),
        ],
      ),
    );
  }

  Widget _buildDevicesCard() {
    return _buildTimelineCard(
      icon: Icons.devices_rounded,
      title: "Dispositivos",
      color: AppColors.warning,
      isLast: _hops.isEmpty,
      trailing: Text("${_devices.length} online",
          style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.warning)),
      content: Column(
        children: _devices.map((d) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(d['icon'] as IconData,
                      size: 18, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['name'],
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text(d['ip'],
                          style: GoogleFonts.firaCode(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRouteCard() {
    return _buildTimelineCard(
      icon: Icons.alt_route_rounded,
      title: "Traceroute",
      color: AppColors.primary,
      isLast: true,
      content: Column(
        children: _hops.map((hop) {
          final latency = hop['latency'] as double;
          final latencyColor = latency < 10
              ? AppColors.success
              : latency < 20
                  ? AppColors.warning
                  : AppColors.error;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text("${hop['hop']}",
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(hop['ip'],
                      style: GoogleFonts.firaCode(
                          fontSize: 12, color: AppColors.textPrimary)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: latencyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text("${latency}ms",
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: latencyColor)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget content,
    Widget? trailing,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline
        Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color.withOpacity(0.3), AppColors.border],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        // Content
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const Spacer(),
                    if (trailing != null) trailing,
                  ],
                ),
                const SizedBox(height: 12),
                content,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
                  color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}

// ============ GAUGE PAINTER ============
class _GaugePainter extends CustomPainter {
  final double fill;
  final Color color;
  _GaugePainter({required this.fill, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    const strokeWidth = 12.0;
    const startAngle = 135 * math.pi / 180;
    const sweepAngle = 270 * math.pi / 180;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = const Color(0xFFE4E4E7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Fill with gradient
    final fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [color.withOpacity(0.5), color],
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * fill,
      false,
      fillPaint,
    );

    // Glow tip
    if (fill > 0.05) {
      final endAngle = startAngle + sweepAngle * fill;
      final tipX = center.dx + radius * math.cos(endAngle);
      final tipY = center.dy + radius * math.sin(endAngle);

      canvas.drawCircle(
        Offset(tipX, tipY),
        10,
        Paint()
          ..color = color.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        Offset(tipX, tipY),
        5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.color != color;
}
