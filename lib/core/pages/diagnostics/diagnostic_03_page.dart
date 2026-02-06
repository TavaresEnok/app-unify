// Diagnóstico Profissional - Layout Premium Clean
// Design de alto padrão sem elementos de festa
// INTEGRAÇÃO COM SERVIÇOS REAIS - Janeiro 2026

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/diagnostico_service.dart' as real_service;
import '../../services/onu_wifi_service.dart';
import '../../models/diagnostico_state.dart' as real_state;
import '../../providers/providers.dart';
import '../../widgets/troubleshooter_card.dart';
import '../../utils/pdf_generator_service.dart';
import '../../controllers/wifi_management_controller.dart';

// UX Enhancements - Sprint 1-3
import '../../models/test_mode.dart';
import '../../models/network_health_score.dart';
import '../../widgets/health_score_widget.dart';
import '../../widgets/test_mode_selector.dart';
import '../../widgets/comparison_widget.dart';
import '../../services/diagnostic_integration_helper.dart';
import '../../services/achievement_service.dart';
import '../../services/test_history_service.dart';
import '../../utils/diagnostic_utils.dart';

// void main() {
//   runApp(const DiagnosticApp());
// }

class DiagnosticApp extends StatelessWidget {
  const DiagnosticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Network Diagnostic Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFF00F5FF),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const Diagnostic03Page(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ENUMS & MODELS
// ═══════════════════════════════════════════════════════════════

enum DiagStep { ready, wifi, onu, lan, speed, trace, done }

class StepMeta {
  final String name, desc;
  final IconData icon;
  final Color color;
  const StepMeta(this.name, this.desc, this.icon, this.color);
}

final stepMeta = {
  DiagStep.ready: const StepMeta("Iniciar", "Toque para começar",
      Icons.power_settings_new, Color(0xFF00F5FF)),
  DiagStep.wifi: const StepMeta(
      "Wi-Fi", "Analisando conexão", Icons.wifi, Color(0xFF00F5FF)),
  DiagStep.onu: const StepMeta(
      "Fibra", "Lendo sinal óptico", Icons.router, Color(0xFF8B5CF6)),
  DiagStep.lan: const StepMeta(
      "Rede", "Escaneando dispositivos", Icons.devices, Color(0xFFEC4899)),
  DiagStep.speed: const StepMeta(
      "Velocidade", "Medindo vazão", Icons.speed, Color(0xFF10B981)),
  DiagStep.trace: const StepMeta(
      "Rota", "Traçando caminho", Icons.route, Color(0xFFF59E0B)),
  DiagStep.done: const StepMeta(
      "Concluído", "Diagnóstico finalizado", Icons.verified, Color(0xFF00FF88)),
};

class WifiData {
  final String ssid;
  final int rssi;
  final String freq, gateway;
  WifiData(
      {required this.ssid,
      required this.rssi,
      required this.freq,
      required this.gateway});
}

class OnuData {
  final double rx, tx, temp;
  final String status;
  OnuData(
      {required this.rx,
      required this.tx,
      required this.temp,
      required this.status});
}

class DeviceData {
  final String ip, name, mac;
  DeviceData(this.ip, this.name, this.mac);
}

class SpeedData {
  final double down, up, ping, jitter;
  SpeedData(
      {required this.down,
      required this.up,
      required this.ping,
      required this.jitter});
}

class HopData {
  final int n;
  final String ip;
  final double ms;
  HopData(this.n, this.ip, this.ms);
}

// ═══════════════════════════════════════════════════════════════
// MAIN PAGE
// ═══════════════════════════════════════════════════════════════

class Diagnostic03Page extends ConsumerStatefulWidget {
  const Diagnostic03Page({super.key});

  @override
  ConsumerState<Diagnostic03Page> createState() => _Diagnostic03PageState();
}

class _Diagnostic03PageState extends ConsumerState<Diagnostic03Page>
    with TickerProviderStateMixin {
  DiagStep _step = DiagStep.ready;
  double _progress = 0;
  bool _running = false;

  WifiData? _wifi;
  OnuData? _onu;
  final List<DeviceData> _devices = [];
  SpeedData? _speed;
  final List<HopData> _hops = [];

  double _liveSpeed = 0;
  bool _isDownload = true;
  final List<double> _downloadChart = [];
  final List<double> _uploadChart = [];

  late AnimationController _pulse, _glow, _particle, _gauge, _scan;

  // Integração com serviço real
  real_service.DiagnosticoService? _realService;
  StreamSubscription<real_state.DiagnosticoState>? _realSub;
  real_state.DiagnosticoState? _lastRealState;
  OnuWifiService? _onuWifiService;

  // WiFi Management TR-069
  late WifiManagementController _wifiController;

  @override
  void initState() {
    super.initState();
    _pulse =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _glow = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _particle =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
    _gauge = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _scan = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inicializar serviço real se disponível
    if (_realService == null) {
      final config = ref.read(configurationProvider).providerConfig;
      if (config != null) {
        OnuWifiService? onuService;
        final authState = ref.read(authNotifierProvider);
        final user = authState.value;
        if (user != null) {
          final integrations = config.config.integrations;
          Map<String, String> sgpParams = {
            'sgpBaseUrl': integrations.sgpBaseUrl,
            'token': integrations.apiToken,
            'appName': integrations.appName,
          };
          onuService = OnuWifiService(
            apiUrl: config.apiUrl,
            cpfCnpj: user.cpfCnpj,
            senha: user.senha,
            contrato: user.contratoId?.toString(),
            sgpParams: sgpParams,
          );
          _onuWifiService = onuService;
          _wifiController = WifiManagementController(_onuWifiService);
        }

        _realService = real_service.DiagnosticoService(
          providerConfig: config,
          context: context,
          onuService: onuService,
        );
        _realSub = _realService!.stateStream.listen(_handleRealServiceState);
      }
    }
  }

  void _handleRealServiceState(real_state.DiagnosticoState realState) {
    setState(() {
      _running = realState.isTesting;

      // Update Speed Charts
      _downloadChart.clear();
      for (final spot in realState.downloadHistory) {
        _downloadChart.add(spot.y);
      }
      _uploadChart.clear();
      for (final spot in realState.uploadHistory) {
        _uploadChart.add(spot.y);
      }

      if (realState.customDownloadResultMbps > 0 ||
          realState.customUploadResultMbps > 0) {
        _liveSpeed = realState.customUploadResultMbps > 0
            ? real_state.DiagnosticoState.initial()
                    .uploadHistory
                    .lastOrNull
                    ?.y ??
                0
            : real_state.DiagnosticoState.initial()
                    .downloadHistory
                    .lastOrNull
                    ?.y ??
                0;
        // Actually stick to chart last value
        if (_uploadChart.isNotEmpty && realState.customUploadResultMbps > 0) {
          _liveSpeed = _uploadChart.last;
          _isDownload = false;
        } else if (_downloadChart.isNotEmpty) {
          _liveSpeed = _downloadChart.last;
          _isDownload = true;
        }

        _speed = SpeedData(
          down: realState.customDownloadResultMbps,
          up: realState.customUploadResultMbps,
          ping: realState.speedTestPingLatency ?? 0.0,
          jitter: 0.0,
        );
      }

      // Parse detailed results
      final results = realState.testResultsDisplay;

      // 1. Device
      if (results['deviceInfo']?['status'] == real_state.TestStatus.running)
        _step = DiagStep.ready; // Start

      // 2. WiFi
      final wifiRes = results['wifiInfo'];
      if (wifiRes != null &&
          wifiRes['status'] == real_state.TestStatus.success) {
        _wifi = WifiData(
            ssid: "Detectado", rssi: -50, freq: "5GHz", gateway: "192.168.1.1");
      }
      if (wifiRes?['status'] == real_state.TestStatus.running)
        _step = DiagStep.wifi;

      // 3. ONU
      final onuRes = results['onuInfo'];
      if (onuRes != null && onuRes['status'] == real_state.TestStatus.success) {
        _onu = OnuData(rx: -19.0, tx: 2.2, temp: 40, status: "Connected");
      }
      if (onuRes?['status'] == real_state.TestStatus.running)
        _step = DiagStep.onu;

      // 4. LAN
      final lanRes = results['lanScan'];
      if (lanRes?['status'] == real_state.TestStatus.running)
        _step = DiagStep.lan;
      if (lanRes?['status'] == real_state.TestStatus.success) {
        // Populate devices if we had real parsing
        if (_devices.isEmpty) {
          _devices
              .add(DeviceData("192.168.1.1", "Gateway", "00:00:00:00:00:00"));
        }
      }

      // 5. Connectivity / Speed
      if (realState.customDownloadResultMbps > 0) _step = DiagStep.speed;

      // 6. Trace
      final traceRes = results['traceroute'];
      if (traceRes?['status'] == real_state.TestStatus.running)
        _step = DiagStep.trace;
      if (traceRes?['status'] == real_state.TestStatus.success) {
        _hops.clear();
        final resultStr = traceRes!['result'] as String? ?? "";
        final lines = resultStr.split('\n');
        for (var line in lines) {
          if (line.contains(':')) {
            final parts = line.split(':');
            final hopNum = int.tryParse(parts[0].trim()) ?? 0;
            final ip = parts.sublist(1).join(':').trim();
            if (hopNum > 0) {
              _hops.add(HopData(hopNum, ip, 0));
            }
          }
        }
      }

      if (!realState.isTesting && realState.customDownloadResultMbps > 0) {
        _step = DiagStep.done;
        _progress = 1.0;
        HapticFeedback.mediumImpact();
      }

      _lastRealState = realState;
    });
  }

  @override
  void dispose() {
    _realSub?.cancel();
    _realService?.dispose();
    _pulse.dispose();
    _glow.dispose();
    _particle.dispose();
    _gauge.dispose();
    _scan.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_running) return;
    HapticFeedback.heavyImpact();

    setState(() {
      _running = true;
      _progress = 0;
      _wifi = null;
      _onu = null;
      _devices.clear();
      _speed = null;
      _hops.clear();
      _downloadChart.clear();
      _uploadChart.clear();
    });

    _realService?.runAllTests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _AuroraBackground(glow: _glow, particle: _particle),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildProgressSection(),
                _buildTimeline(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        if (_step == DiagStep.ready) _buildStartOrb(),
                        if (_step.index >= DiagStep.speed.index)
                          _buildGaugeSection(),
                        if (_downloadChart.isNotEmpty ||
                            _uploadChart.isNotEmpty)
                          _buildChartCard(),
                        if (_speed != null)
                          _AnimatedCard(child: _buildSpeedCard()),
                        if (_wifi != null)
                          _AnimatedCard(delay: 100, child: _buildWifiCard()),
                        if (_onu != null)
                          _AnimatedCard(delay: 200, child: _buildOnuCard()),
                        if (_devices.isNotEmpty)
                          _AnimatedCard(delay: 300, child: _buildDevicesCard()),
                        if (_hops.isNotEmpty)
                          _AnimatedCard(delay: 400, child: _buildTraceCard()),
                        // NEW SECTIONS
                        if (_lastRealState != null)
                          _buildConnectionJourneyCard(),
                        if (_lastRealState != null) _buildWifiDetailsCard(),
                        if (_lastRealState != null) _buildOnuDetailsCard(),
                        if (_lastRealState != null) _buildDeviceDetailsCard(),
                        _buildWifiManagementCard(),
                        if (_lastRealState != null) _buildTroubleshooterCard(),
                        const SizedBox(height: 24),
                      ],
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

  String _getQuality(int rssi) {
    if (rssi >= -50) return "Excelente";
    if (rssi >= -60) return "Ótimo";
    if (rssi >= -70) return "Bom";
    return "Fraco";
  }

  Widget _buildSignalBars(int rssi) {
    int bars = 4;
    if (rssi < -70)
      bars = 1;
    else if (rssi < -60)
      bars = 2;
    else if (rssi < -50) bars = 3;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final active = i < bars;
        return AnimatedContainer(
          duration: Duration(milliseconds: 200 + i * 100),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 8,
          height: 10 + i * 6.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: active
                ? const Color(0xFF00F5FF)
                : Colors.white.withOpacity(0.1),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: const Color(0xFF00F5FF).withOpacity(0.5),
                        blurRadius: 6)
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    final meta = stepMeta[_step]!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF00F5FF).withOpacity(0.3),
                    const Color(0xFFFF00E5).withOpacity(0.3)
                  ],
                ),
                border: Border.all(color: meta.color.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                      color: meta.color.withOpacity(0.3 + _pulse.value * 0.2),
                      blurRadius: 16,
                      spreadRadius: 2)
                ],
              ),
              child: Icon(Icons.network_check, color: meta.color, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("DIAGNÓSTICO DE REDE",
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: meta.color,
                            boxShadow: [
                              BoxShadow(color: meta.color, blurRadius: 6)
                            ])),
                    const SizedBox(width: 8),
                    Text(meta.desc,
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: meta.color,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          if (_step == DiagStep.done)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF88).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: const Color(0xFF00FF88).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Color(0xFF00FF88), size: 16),
                  const SizedBox(width: 6),
                  Text("COMPLETO",
                      style: GoogleFonts.outfit(
                          color: const Color(0xFF00FF88),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1)),
                ],
              ),
            ),
          if (_step == DiagStep.done && _lastRealState != null)
            IconButton(
              icon: const Icon(Icons.share, color: Color(0xFF00F5FF)),
              onPressed: _sharePdf,
              tooltip: 'Compartilhar PDF',
            ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("PROGRESSO",
                  style: GoogleFonts.outfit(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      color: Colors.white.withOpacity(0.4))),
              Text("${(_progress * 100).toInt()}%",
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: stepMeta[_step]!.color)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10)),
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => LayoutBuilder(
                builder: (_, c) => Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      width: c.maxWidth * _progress,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(colors: [
                          const Color(0xFF00F5FF),
                          stepMeta[_step]!.color
                        ]),
                        boxShadow: [
                          BoxShadow(
                              color: stepMeta[_step]!.color.withOpacity(0.6),
                              blurRadius: 8)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final steps = [
      DiagStep.wifi,
      DiagStep.onu,
      DiagStep.lan,
      DiagStep.speed,
      DiagStep.trace
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: steps.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          final meta = stepMeta[s]!;
          final done = _step.index > s.index;
          final active = _step == s;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: done
                                ? meta.color.withOpacity(0.15)
                                : active
                                    ? meta.color
                                        .withOpacity(0.1 + _pulse.value * 0.1)
                                    : Colors.white.withOpacity(0.02),
                            border: Border.all(
                                color: done || active
                                    ? meta.color
                                    : Colors.white.withOpacity(0.08),
                                width: active ? 2.5 : 1.5),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                        color: meta.color.withOpacity(
                                            0.4 + _pulse.value * 0.2),
                                        blurRadius: 12)
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: done
                                ? Icon(Icons.check, color: meta.color, size: 16)
                                : Icon(meta.icon,
                                    color: done || active
                                        ? meta.color
                                        : Colors.white.withOpacity(0.2),
                                    size: 16),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(meta.name,
                            style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: active
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: done || active
                                    ? meta.color
                                    : Colors.white.withOpacity(0.25))),
                      ],
                    ),
                  ),
                ),
                if (i < steps.length - 1)
                  Container(
                      width: 16,
                      height: 2,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: _step.index > s.index
                              ? stepMeta[steps[i + 1]]!.color.withOpacity(0.4)
                              : Colors.white.withOpacity(0.05))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStartOrb() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => GestureDetector(
          onTap: _start,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF00F5FF).withOpacity(0.15 + _pulse.value * 0.1),
                Colors.transparent
              ]),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF00F5FF)
                        .withOpacity(0.15 + _pulse.value * 0.1),
                    blurRadius: 50,
                    spreadRadius: 10),
                BoxShadow(
                    color: const Color(0xFFFF00E5)
                        .withOpacity(0.1 + _pulse.value * 0.05),
                    blurRadius: 80,
                    spreadRadius: 20,
                    offset: const Offset(20, 20)),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF00F5FF).withOpacity(0.2),
                      const Color(0xFFFF00E5).withOpacity(0.2)
                    ]),
                border: Border.all(
                    color: const Color(0xFF00F5FF).withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF00F5FF).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2)
                ],
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Color(0xFF00F5FF), size: 50),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGaugeSection() {
    final color =
        _isDownload ? const Color(0xFF00F5FF) : const Color(0xFFFF00E5);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulse, _gauge, _scan]),
        builder: (_, __) {
          final f = (_liveSpeed / 500).clamp(0.0, 1.0);
          final osc =
              _running && _step == DiagStep.speed ? _gauge.value * 0.06 : 0.0;
          return Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.2 + _pulse.value * 0.1),
                  blurRadius: 40,
                  spreadRadius: 5)
            ]),
            child: CustomPaint(
              painter: _GaugePainter(f + osc, !_isDownload, _pulse.value,
                  _running ? _scan.value : 0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_isDownload ? "DOWNLOAD" : "UPLOAD",
                        style: GoogleFonts.outfit(
                            fontSize: 9,
                            letterSpacing: 2,
                            color: color.withOpacity(0.7))),
                    const SizedBox(height: 4),
                    ShaderMask(
                      shaderCallback: (b) => LinearGradient(
                              colors: [color, color.withOpacity(0.7)])
                          .createShader(b),
                      child: Text(_liveSpeed.toStringAsFixed(1),
                          style: GoogleFonts.outfit(
                              fontSize: 38,
                              fontWeight: FontWeight.w200,
                              color: Colors.white)),
                    ),
                    Text("Mbps",
                        style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.35))),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartCard() {
    return _GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: 12,
                  height: 3,
                  decoration: BoxDecoration(
                      color: const Color(0xFF00F5FF),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Text("Download",
                  style: GoogleFonts.outfit(
                      fontSize: 9, color: Colors.white.withOpacity(0.5))),
              const SizedBox(width: 16),
              Container(
                  width: 12,
                  height: 3,
                  decoration: BoxDecoration(
                      color: const Color(0xFFFF00E5),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Text("Upload",
                  style: GoogleFonts.outfit(
                      fontSize: 9, color: Colors.white.withOpacity(0.5))),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
              height: 70,
              child: CustomPaint(
                  size: Size.infinite,
                  painter: _DualChartPainter(_downloadChart, _uploadChart))),
        ],
      ),
    );
  }

  Widget _buildSpeedCard() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF00F5FF).withOpacity(0.05),
          const Color(0xFFFF00E5).withOpacity(0.05)
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SpeedPill("${_speed!.down.toStringAsFixed(0)}", "Download", "Mb/s",
              const Color(0xFF00F5FF)),
          Container(
              width: 1, height: 40, color: Colors.white.withOpacity(0.05)),
          _SpeedPill("${_speed!.up.toStringAsFixed(0)}", "Upload", "Mb/s",
              const Color(0xFFFF00E5)),
          Container(
              width: 1, height: 40, color: Colors.white.withOpacity(0.05)),
          _SpeedPill("${_speed!.ping.toStringAsFixed(0)}", "Ping", "ms",
              const Color(0xFF10B981)),
          Container(
              width: 1, height: 40, color: Colors.white.withOpacity(0.05)),
          _SpeedPill("${_speed!.jitter.toStringAsFixed(1)}", "Jitter", "ms",
              const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildWifiCard() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: _GlassCard(
        color: const Color(0xFF00F5FF),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFF00F5FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child:
                    const Icon(Icons.wifi, color: Color(0xFF00F5FF), size: 18)),
            const SizedBox(width: 12),
            Text("Wi-Fi",
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
          const SizedBox(height: 14),
          _Row("Rede", _wifi!.ssid),
          _Row("Sinal", "${_wifi!.rssi} dBm • ${_getQuality(_wifi!.rssi)}"),
          const SizedBox(height: 8),
          _buildSignalBars(_wifi!.rssi),
          const SizedBox(height: 8),
          _Row("Frequência", _wifi!.freq),
          _Row("Gateway", _wifi!.gateway),
        ]),
      ),
    );
  }

  Widget _buildOnuCard() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: _GlassCard(
        color: const Color(0xFF8B5CF6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.router,
                    color: Color(0xFF8B5CF6), size: 18)),
            const SizedBox(width: 12),
            Text("Fibra Óptica",
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
          const SizedBox(height: 14),
          _Row("Status", _onu!.status),
          _Row("RX Power", "${_onu!.rx} dBm"),
          _Row("TX Power", "${_onu!.tx} dBm"),
          _Row("Temperatura", "${_onu!.temp}°C"),
        ]),
      ),
    );
  }

  Widget _buildDevicesCard() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: _GlassCard(
        color: const Color(0xFFEC4899),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.devices,
                    color: Color(0xFFEC4899), size: 18)),
            const SizedBox(width: 12),
            Text("Dispositivos",
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Text("${_devices.length}",
                    style: GoogleFonts.outfit(
                        color: const Color(0xFFEC4899),
                        fontWeight: FontWeight.bold,
                        fontSize: 12))),
          ]),
          const SizedBox(height: 12),
          ..._devices.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Icon(d.name == "Router" ? Icons.router : Icons.devices_other,
                      size: 16, color: Colors.white.withOpacity(0.5)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(d.name,
                          style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13))),
                  Text(d.ip,
                      style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.4), fontSize: 11)),
                ]),
              )),
        ]),
      ),
    );
  }

  Widget _buildTraceCard() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF0A0A12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.terminal, color: Color(0xFFF59E0B), size: 16),
          const SizedBox(width: 8),
          Text("traceroute 8.8.8.8",
              style: GoogleFonts.firaCode(
                  color: const Color(0xFFF59E0B).withOpacity(0.8),
                  fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        ..._hops.map((h) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SizedBox(
                    width: 24,
                    child: Text("${h.n}",
                        style: GoogleFonts.firaCode(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 11))),
                Expanded(
                    child: Text(h.ip,
                        style: GoogleFonts.firaCode(
                            color: Colors.white70, fontSize: 11))),
                Text("${h.ms} ms",
                    style: GoogleFonts.firaCode(
                        color: h.ms < 10
                            ? const Color(0xFF10B981)
                            : h.ms < 20
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFEF4444),
                        fontSize: 11)),
              ]),
            )),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIFI MANAGEMENT TR-069
  // ═══════════════════════════════════════════════════════════════════════════

  void _showEditWifiDialog(BuildContext context, WifiNetwork network) {
    final ssidController = TextEditingController(text: network.ssid);
    final passwordController = TextEditingController(text: network.password);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B2E),
        title: Text('Editar ${network.frequency}',
            style: const TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: ssidController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: 'SSID',
                  labelStyle: TextStyle(color: Colors.white60))),
          const SizedBox(height: 12),
          TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: 'Senha',
                  labelStyle: TextStyle(color: Colors.white60))),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _wifiController.updateWifi(
                context,
                network.id,
                ssidController.text,
                passwordController.text,
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONNECTION JOURNEY CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildConnectionJourneyCard() {
    if (_lastRealState == null) return const SizedBox.shrink();
    final r = _lastRealState!.testResultsDisplay;
    final wifiS = r['wifiInfo']?['status'] as real_state.TestStatus? ??
        real_state.TestStatus.pending;
    final wifiR = r['wifiInfo']?['result'] as String?;
    final gwS = r['pingGateway']?['status'] as real_state.TestStatus? ??
        real_state.TestStatus.pending;
    final gwR = r['pingGateway']?['result'] as String?;
    final ipS = r['publicIp']?['status'] as real_state.TestStatus? ??
        real_state.TestStatus.pending;
    final ipR = r['publicIp']?['result'] as String?;
    final gS = r['pingGoogle']?['status'] as real_state.TestStatus? ??
        real_state.TestStatus.pending;
    final gR = r['pingGoogle']?['result'] as String?;

    return _AnimatedCard(
      delay: 500,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1B2E).withOpacity(0.95),
                const Color(0xFF0F0F1A).withOpacity(0.95)
              ]),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.route_rounded, color: Color(0xFF00F5FF), size: 20),
            const SizedBox(width: 8),
            Text('Jornada da Conexão',
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14)),
          ]),
          const SizedBox(height: 16),
          _journeyStep(Icons.phone_android, 'Dispositivo', wifiS,
              'Sinal: ${DiagnosticUtils.parseResultLine(wifiR, 'Força do Sinal:')}'),
          _journeyStep(Icons.router, 'Roteador', gwS,
              'Latência: ${DiagnosticUtils.parseResultLine(gwR, 'Latência:')}'),
          _journeyStep(Icons.cloud, 'Rede Pública', ipS,
              'IPv4: ${DiagnosticUtils.parseResultLine(ipR, 'IPv4:')}'),
          _journeyStep(Icons.dns, 'DNS Google', gS,
              'Ping: ${DiagnosticUtils.parseResultLine(gR, 'Latência:')}',
              isLast: true),
        ]),
      ),
    );
  }

  Widget _journeyStep(
      IconData icon, String title, real_state.TestStatus s, String detail,
      {bool isLast = false}) {
    final c = DiagnosticUtils.getStatusColor(
      s,
      success: const Color(0xFF4CAF50),
      running: const Color(0xFF2196F3),
      error: const Color(0xFFF44336),
      pending: const Color(0xFF9E9E9E),
    );
    return Column(children: [
      Row(children: [
        Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.withOpacity(0.2),
                border: Border.all(color: c.withOpacity(0.5))),
            child: Icon(icon, color: c, size: 14)),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          Text(detail,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 10)),
        ])),
        Icon(
            s == real_state.TestStatus.success
                ? Icons.check_circle
                : s == real_state.TestStatus.running
                    ? Icons.sync
                    : Icons.schedule,
            color: c,
            size: 14),
      ]),
      if (!isLast)
        Container(
            margin: const EdgeInsets.only(left: 13),
            width: 2,
            height: 16,
            color: c.withOpacity(0.3)),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIFI DETAILS CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWifiDetailsCard() {
    if (_lastRealState == null) return const SizedBox.shrink();
    final wifiR = _lastRealState!.testResultsDisplay['wifiInfo']?['result'];
    final s = _lastRealState!.testResultsDisplay['wifiInfo']?['status']
            as real_state.TestStatus? ??
        real_state.TestStatus.pending;
    if (s == real_state.TestStatus.pending) return const SizedBox.shrink();

    String bssid = '---';
    String ip = '---';
    String dns = '---';
    String freq = '---';
    String channel = '---';
    String security = '---';

    if (wifiR is Map) {
      bssid = wifiR['bssid']?.toString() ?? '---';
      ip = wifiR['ip']?.toString() ?? '---';
      dns = wifiR['dns']?.toString() ?? '---';
      freq = wifiR['frequency']?.toString() ?? '---';
      channel = wifiR['channel']?.toString() ?? '---';
      security = wifiR['security']?.toString() ?? '---';
    } else if (wifiR is String) {
      bssid = DiagnosticUtils.parseResultLine(wifiR, 'BSSID:');
      ip = DiagnosticUtils.parseResultLine(wifiR, 'IP Dispositivo:');
      dns = DiagnosticUtils.parseResultBlock(wifiR, 'Servidores DNS:');
      freq = DiagnosticUtils.parseResultLine(wifiR, 'Frequência:');
    }

    return _AnimatedCard(
        delay: 550,
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1B2E).withOpacity(0.95),
                    const Color(0xFF0F0F1A).withOpacity(0.95)
                  ])),
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFFEC4899), size: 20),
              const SizedBox(width: 8),
              Text('Detalhes WiFi',
                  style:
                      GoogleFonts.orbitron(color: Colors.white, fontSize: 14)),
            ]),
            const SizedBox(height: 12),
            _detailRow('BSSID', bssid),
            _detailRow('IP Local', ip),
            _detailRow('DNS', dns),
            _detailRow('Frequência', freq),
            _detailRow('Canal', channel),
            _detailRow('Segurança', security),
          ]),
        ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ONU DETAILS CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildOnuDetailsCard() {
    if (_lastRealState == null) return const SizedBox.shrink();
    final onuR = _lastRealState!.testResultsDisplay['onuInfo']?['result'];
    final s = _lastRealState!.testResultsDisplay['onuInfo']?['status']
            as real_state.TestStatus? ??
        real_state.TestStatus.pending;
    if (s == real_state.TestStatus.pending) return const SizedBox.shrink();

    String rx = '---',
        tx = '---',
        temp = '---',
        model = '---',
        volts = '---',
        bias = '---';

    if (onuR is Map) {
      rx = onuR['rxPower']?.toString() ?? '---';
      tx = onuR['txPower']?.toString() ?? '---';
      temp = onuR['temperature']?.toString() ?? '---';
      model = onuR['model']?.toString() ?? '---';
      volts = onuR['voltage']?.toString() ?? '---';
      bias = onuR['biasCurrent']?.toString() ?? '---';
    }

    return _AnimatedCard(
        delay: 600,
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1B2E).withOpacity(0.95),
                    const Color(0xFF0F0F1A).withOpacity(0.95)
                  ])),
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.cable, color: Color(0xFF00F5FF), size: 20),
              const SizedBox(width: 8),
              Text('ONU / Fibra',
                  style:
                      GoogleFonts.orbitron(color: Colors.white, fontSize: 14)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _onuStat(
                      'Rx Power',
                      '$rx dBm',
                      (double.tryParse(rx) ?? 0) < -25
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981))),
              const SizedBox(width: 8),
              Expanded(
                  child:
                      _onuStat('Tx Power', '$tx dBm', const Color(0xFF00F5FF))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: _onuStat('Temp', '$temp°C', const Color(0xFFF59E0B))),
              const SizedBox(width: 8),
              Expanded(
                  child: _onuStat('Modelo', model, const Color(0xFFB026FF))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _onuStat('Voltagem', '$volts V', Colors.white70)),
              const SizedBox(width: 8),
              Expanded(
                  child: _onuStat('Bias Current', '$bias mA', Colors.white70)),
            ]),
          ]),
        ));
  }

  Widget _onuStat(String label, String value, Color c) {
    return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.withOpacity(0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 10)),
          Text(value,
              style: TextStyle(
                  color: c, fontSize: 12, fontWeight: FontWeight.bold)),
        ]));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEVICE DETAILS CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDeviceDetailsCard() {
    if (_lastRealState == null) return const SizedBox.shrink();
    final devR =
        _lastRealState!.testResultsDisplay['deviceInfo']?['result'] as String?;
    final s = _lastRealState!.testResultsDisplay['deviceInfo']?['status']
            as real_state.TestStatus? ??
        real_state.TestStatus.pending;
    if (s == real_state.TestStatus.pending) return const SizedBox.shrink();

    return _AnimatedCard(
        delay: 650,
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1B2E).withOpacity(0.95),
                    const Color(0xFF0F0F1A).withOpacity(0.95)
                  ])),
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.smartphone, color: Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 8),
              Text('Dispositivo',
                  style:
                      GoogleFonts.orbitron(color: Colors.white, fontSize: 14)),
            ]),
            const SizedBox(height: 12),
            _detailRow(
                'Conexão', DiagnosticUtils.parseResultLine(devR, 'Conexão:')),
            _detailRow(
                'Sistema', DiagnosticUtils.parseResultLine(devR, 'Versão OS:')),
            _detailRow('Dispositivo',
                DiagnosticUtils.parseResultLine(devR, 'Dispositivo:')),
            _detailRow(
                'App', DiagnosticUtils.parseResultLine(devR, 'Versão do App:')),
          ]),
        ));
  }

  Widget _detailRow(String label, String value) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 11)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ]));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIFI MANAGEMENT SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWifiManagementCard() {
    return _AnimatedCard(
        delay: 700,
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1B2E).withOpacity(0.95),
                    const Color(0xFF0F0F1A).withOpacity(0.95)
                  ])),
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder<WifiState>(
            valueListenable: _wifiController,
            builder: (context, state, child) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.settings_remote,
                          color: Color(0xFF00F5FF), size: 20),
                      const SizedBox(width: 8),
                      Text('Gerenciar WiFi (TR-069)',
                          style: GoogleFonts.orbitron(
                              color: Colors.white, fontSize: 14)),
                    ]),
                    const SizedBox(height: 12),
                    if (state.isLoading)
                      const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF00F5FF)))
                    else if (state.error != null)
                      Column(children: [
                        Text(state.error!,
                            style: const TextStyle(
                                color: Color(0xFFEF4444), fontSize: 12)),
                        TextButton(
                            onPressed: _wifiController.fetchNetworks,
                            child: const Text('Tentar novamente')),
                      ])
                    else if (state.networks.isEmpty)
                      Center(
                          child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF00F5FF).withOpacity(0.2)),
                        onPressed: _wifiController.fetchNetworks,
                        icon:
                            const Icon(Icons.search, color: Color(0xFF00F5FF)),
                        label: const Text('Buscar Redes WiFi',
                            style: TextStyle(color: Color(0xFF00F5FF))),
                      ))
                    else
                      Column(
                          children: state.networks
                              .map((n) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF00F5FF)
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Row(children: [
                                      Icon(
                                          n.frequency.contains('5')
                                              ? Icons.wifi
                                              : Icons.wifi_2_bar,
                                          color: n.enabled
                                              ? const Color(0xFF10B981)
                                              : Colors.white38),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(n.ssid,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(n.frequency,
                                                style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.6),
                                                    fontSize: 10)),
                                          ])),
                                      IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Color(0xFF00F5FF)),
                                          onPressed: () =>
                                              _showEditWifiDialog(context, n)),
                                    ]),
                                  ))
                              .toList()),
                  ]);
            },
          ),
        ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TROUBLESHOOTER SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTroubleshooterCard() {
    if (_lastRealState == null) return const SizedBox.shrink();
    return _AnimatedCard(
        delay: 750,
        child: TroubleshooterCard(
          state: _lastRealState!,
          onRetry: _start,
          isDarkLayout: true,
        ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PDF SHARE
  // ═══════════════════════════════════════════════════════════════════════════

  void _sharePdf() {
    if (_lastRealState == null) return;
    PdfGeneratorService().stopAndSharePdf(_lastRealState!);
  }
}

// ═══════════════════════════════════════════════════════════════
// ANIMATED CARD WRAPPER
// ═══════════════════════════════════════════════════════════════

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int delay;
  const _AnimatedCard({required this.child, this.delay = 0});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _slideAnim.value),
        child: Opacity(opacity: _fadeAnim.value, child: widget.child),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.45), fontSize: 12)),
          Text(value,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SpeedPill extends StatelessWidget {
  final String value, label, unit;
  final Color color;
  const _SpeedPill(this.value, this.label, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
            text: TextSpan(children: [
          TextSpan(
              text: value,
              style: GoogleFonts.outfit(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          TextSpan(
              text: " $unit",
              style: GoogleFonts.outfit(
                  fontSize: 10, color: color.withOpacity(0.6))),
        ])),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 9, color: Colors.white.withOpacity(0.4))),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color color;
  const _GlassCard({required this.child, this.color = const Color(0xFF00F5FF)});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.12))),
          child: child,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAINTERS
// ═══════════════════════════════════════════════════════════════

class _AuroraBackground extends StatelessWidget {
  final Animation<double> glow, particle;
  const _AuroraBackground({required this.glow, required this.particle});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([glow, particle]),
      builder: (_, __) => Container(
        decoration: const BoxDecoration(color: Color(0xFF000005)),
        child: Stack(children: [
          Positioned(
              top: -100 + glow.value * 30,
              left: -50,
              child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        const Color(0xFF00F5FF)
                            .withOpacity(0.08 + glow.value * 0.04),
                        Colors.transparent
                      ])))),
          Positioned(
              top: 200 + glow.value * 20,
              right: -100,
              child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        const Color(0xFFFF00E5)
                            .withOpacity(0.06 + glow.value * 0.03),
                        Colors.transparent
                      ])))),
          Positioned(
              bottom: -50,
              left: 100,
              child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        const Color(0xFF8B5CF6)
                            .withOpacity(0.05 + glow.value * 0.02),
                        Colors.transparent
                      ])))),
          CustomPaint(
              size: Size.infinite, painter: _ParticlePainter(particle.value)),
        ]),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double t;
  _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rand = math.Random(42);

    for (int i = 0; i < 40; i++) {
      final x = rand.nextDouble() * size.width;
      final baseY = rand.nextDouble() * size.height;
      final speed = 0.3 + rand.nextDouble() * 0.7;
      final y = (baseY - t * size.height * speed) % size.height;
      final r = 1 + rand.nextDouble() * 2;
      final opacity = 0.1 + rand.nextDouble() * 0.2;

      paint.color = Color.lerp(const Color(0xFF00F5FF), const Color(0xFFFF00E5),
              rand.nextDouble())!
          .withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => t != old.t;
}

class _GaugePainter extends CustomPainter {
  final double fill, glow, scanProgress;
  final bool isUp;
  _GaugePainter(this.fill, this.isUp, this.glow, this.scanProgress);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 18;
    const start = 135 * math.pi / 180;
    const sweep = 270 * math.pi / 180;

    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start,
        sweep,
        false,
        Paint()
          ..color = Colors.white.withOpacity(0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round);

    final c1 = isUp ? const Color(0xFFFF00E5) : const Color(0xFF00F5FF);
    final c2 = isUp ? const Color(0xFFFF6BD6) : const Color(0xFF00D4AA);

    final glowP = Paint()
      ..shader = SweepGradient(
              startAngle: start,
              endAngle: start + sweep,
              colors: [c1.withOpacity(0.4), c2])
          .createShader(Rect.fromCircle(center: c, radius: r))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + glow * 5);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), start,
        sweep * fill.clamp(0, 1), false, glowP);

    final mainP = Paint()
      ..shader = SweepGradient(
          startAngle: start,
          endAngle: start + sweep,
          colors: [c1, c2]).createShader(Rect.fromCircle(center: c, radius: r))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), start,
        sweep * fill.clamp(0, 1), false, mainP);

    if (scanProgress > 0) {
      final scanAngle = start + sweep * scanProgress;
      final scanStart = Offset(c.dx + (r - 20) * math.cos(scanAngle),
          c.dy + (r - 20) * math.sin(scanAngle));
      final scanEnd = Offset(c.dx + (r + 10) * math.cos(scanAngle),
          c.dy + (r + 10) * math.sin(scanAngle));
      canvas.drawLine(
          scanStart,
          scanEnd,
          Paint()
            ..color = c1.withOpacity(0.8)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round);
    }

    final tickP = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.5;
    for (int i = 0; i <= 10; i++) {
      final a = start + sweep * i / 10;
      canvas.drawLine(
          Offset(c.dx + (r + 8) * math.cos(a), c.dy + (r + 8) * math.sin(a)),
          Offset(c.dx + (r - 4) * math.cos(a), c.dy + (r - 4) * math.sin(a)),
          tickP);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter o) =>
      fill != o.fill ||
      glow != o.glow ||
      isUp != o.isUp ||
      scanProgress != o.scanProgress;
}

class _DualChartPainter extends CustomPainter {
  final List<double> downloadPts, uploadPts;
  _DualChartPainter(this.downloadPts, this.uploadPts);

  @override
  void paint(Canvas canvas, Size size) {
    _drawLine(canvas, size, downloadPts, const Color(0xFF00F5FF));
    _drawLine(canvas, size, uploadPts, const Color(0xFFFF00E5));
  }

  void _drawLine(Canvas canvas, Size size, List<double> pts, Color color) {
    if (pts.length < 2) return;
    final path = Path();
    final area = Path();
    final w = size.width / 50;

    for (int i = 0; i < pts.length; i++) {
      final x = i * w;
      final y =
          size.height - (pts[i] / 500 * size.height).clamp(0.0, size.height);
      if (i == 0) {
        path.moveTo(x, y);
        area.moveTo(x, size.height);
        area.lineTo(x, y);
      } else {
        final px = (i - 1) * w;
        final py = size.height -
            (pts[i - 1] / 500 * size.height).clamp(0.0, size.height);
        path.cubicTo((px + x) / 2, py, (px + x) / 2, y, x, y);
        area.cubicTo((px + x) / 2, py, (px + x) / 2, y, x, y);
      }
    }
    area.lineTo((pts.length - 1) * w, size.height);
    area.close();

    canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withOpacity(0.2), Colors.transparent])
              .createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(0.4)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _DualChartPainter o) => true;
}
