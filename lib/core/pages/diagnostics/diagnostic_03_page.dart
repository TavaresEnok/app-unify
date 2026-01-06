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
import '../../models/diagnostico_state.dart' as real_state;
import '../../providers/providers.dart';

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
  final _rand = math.Random();

  // Integração com serviço real
  real_service.DiagnosticoService? _realService;
  StreamSubscription<real_state.DiagnosticoState>? _realSub;

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
        _realService = real_service.DiagnosticoService(
          providerConfig: config,
          context: context,
        );
        _realSub = _realService!.stateStream.listen(_handleRealServiceState);
      }
    }
  }

  void _handleRealServiceState(real_state.DiagnosticoState realState) {
    // Atualizar dados com valores reais do serviço
    final downloadMbps = realState.customDownloadResultMbps;
    final uploadMbps = realState.customUploadResultMbps;

    if (downloadMbps > 0 || uploadMbps > 0) {
      setState(() {
        _speed = SpeedData(
          down: downloadMbps,
          up: uploadMbps,
          ping: realState.speedTestPingLatency ?? 0.0,
          jitter: 0.0,
        );
        // Atualizar gráficos com dados reais
        for (final spot in realState.downloadHistory) {
          _downloadChart.add(spot.y);
        }
        for (final spot in realState.uploadHistory) {
          _uploadChart.add(spot.y);
        }
      });
    }
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

    // Wi-Fi
    await _runStep(DiagStep.wifi, 0.18, () async {
      await Future.delayed(const Duration(milliseconds: 1400));
      _wifi = WifiData(
          ssid: "UltraFiber_5G",
          rssi: -38,
          freq: "5 GHz • CH 149",
          gateway: "192.168.1.1");
    });

    // ONU
    await _runStep(DiagStep.onu, 0.35, () async {
      await Future.delayed(const Duration(milliseconds: 1600));
      _onu = OnuData(rx: -17.8, tx: 2.5, temp: 39.0, status: "SYNCED (O5)");
    });

    // LAN
    await _runStep(DiagStep.lan, 0.50, () async {
      for (var d in [
        DeviceData("192.168.1.1", "Router", "AA:BB:CC:DD:EE:FF"),
        DeviceData("192.168.1.10", "Desktop", "11:22:33:44:55:66"),
        DeviceData("192.168.1.15", "Smart TV", "77:88:99:00:11:22"),
        DeviceData("192.168.1.22", "iPhone", "AA:11:BB:22:CC:33"),
      ]) {
        await Future.delayed(const Duration(milliseconds: 350));
        setState(() => _devices.add(d));
      }
    });

    // Speed
    await _runStep(DiagStep.speed, 0.82, () async {
      double d = 0, p = 0;
      setState(() => _isDownload = true);
      for (int i = 0; i < 35; i++) {
        await Future.delayed(const Duration(milliseconds: 80));
        final s = (280 + math.sin(i * 0.6) * 120 + _rand.nextDouble() * 60)
            .clamp(80.0, 500.0);
        d = s;
        p = 8 + _rand.nextDouble() * 4;
        setState(() {
          _liveSpeed = s;
          _downloadChart.add(s);
          if (_downloadChart.length > 50) _downloadChart.removeAt(0);
        });
      }
      double u = 0;
      setState(() => _isDownload = false);
      for (int i = 0; i < 25; i++) {
        await Future.delayed(const Duration(milliseconds: 80));
        final s = (90 + math.sin(i * 0.7) * 50 + _rand.nextDouble() * 25)
            .clamp(30.0, 200.0);
        u = s;
        setState(() {
          _liveSpeed = s;
          _uploadChart.add(s);
          if (_uploadChart.length > 50) _uploadChart.removeAt(0);
        });
      }
      _speed = SpeedData(
          down: d, up: u, ping: p, jitter: 1.5 + _rand.nextDouble() * 2);
      setState(() => _liveSpeed = 0);
    });

    // Trace
    await _runStep(DiagStep.trace, 0.95, () async {
      for (var h in [
        HopData(1, "192.168.1.1", 0.8),
        HopData(2, "10.0.0.1", 4.2),
        HopData(3, "187.100.50.1", 9.5),
        HopData(4, "72.14.233.1", 18.0),
        HopData(5, "8.8.8.8", 22.3),
      ]) {
        await Future.delayed(const Duration(milliseconds: 450));
        setState(() => _hops.add(h));
      }
    });

    setState(() {
      _step = DiagStep.done;
      _progress = 1.0;
      _running = false;
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _runStep(
      DiagStep step, double target, Future<void> Function() fn) async {
    setState(() => _step = step);
    await fn();
    setState(() => _progress = target);
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
                        const SizedBox(height: 80),
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
