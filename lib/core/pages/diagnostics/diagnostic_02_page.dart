// Página de Diagnóstico - NOVA UI com Gráfico em Tempo Real
// Two-screen flow: Welcome Screen → Diagnostic with Live Graph
// INTEGRAÇÃO COM SERVIÇOS REAIS - Janeiro 2026

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/diagnostico_service.dart' as real_service;
import '../../services/onu_wifi_service.dart';
import '../../models/diagnostico_state.dart' as real_state;
import '../../providers/providers.dart';
import '../../widgets/troubleshooter_card.dart';
import '../../utils/pdf_generator_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class OnuData {
  final double signalRx, signalTx, temperature;
  final String status;
  final bool isRegistered;
  OnuData({
    this.signalRx = -18.5,
    this.signalTx = 2.3,
    this.temperature = 42.0,
    this.status = 'Online',
    this.isRegistered = true,
  });
}

class WifiData {
  final String ssid, bssid, frequency, quality, localIp, gateway;
  final int rssi, dnsLatency;
  final List<String> dns;
  WifiData({
    this.ssid = 'MinhaRede_5G',
    this.bssid = 'A4:B1:C2:D3:E4:F5',
    this.rssi = -52,
    this.frequency = '5 GHz',
    this.quality = 'Excelente',
    this.localIp = '192.168.1.105',
    this.gateway = '192.168.1.1',
    this.dns = const ['8.8.8.8', '8.8.4.4'],
    this.dnsLatency = 12,
  });
}

class LanDevice {
  final String ip, mac, vendor, name;
  LanDevice({
    required this.ip,
    required this.mac,
    this.vendor = 'Unknown',
    this.name = 'Unknown',
  });
}

class TracertHop {
  final int hop, latency;
  final String ip;
  final bool isSuccess;
  TracertHop({
    required this.hop,
    required this.ip,
    required this.latency,
    this.isSuccess = true,
  });
}

class DeviceInfo {
  final int batteryLevel;
  final bool isCharging;
  final String model, osVersion, appVersion;
  DeviceInfo({
    this.batteryLevel = 85,
    this.isCharging = false,
    this.model = 'Samsung Galaxy S23',
    this.osVersion = 'Android 14',
    this.appVersion = '2.1.0',
  });
}

class ConnectivityData {
  final int pingRouter, pingGoogle, pingCloudflare;
  final double jitter, packetLoss;
  final String ipv4, ipv6, provider;
  ConnectivityData({
    this.pingRouter = 2,
    this.pingGoogle = 18,
    this.pingCloudflare = 15,
    this.jitter = 3.2,
    this.packetLoss = 0.0,
    this.ipv4 = '187.123.45.67',
    this.ipv6 = '2804:14d:1234::1',
    this.provider = 'Vivo Fibra',
  });
}

enum DiagStep { device, wifi, onu, lan, connectivity, speed, tracert }

enum SpeedPhase { idle, download, upload }

class DiagState {
  final DiagStep currentStep;
  final Set<DiagStep> completedSteps;
  final SpeedPhase speedPhase;
  final double currentSpeed, downloadSpeed, uploadSpeed, jitter;
  final int ping, progress;
  final OnuData? onu;
  final WifiData? wifi;
  final List<LanDevice> lan;
  final List<TracertHop> tracert;
  final DeviceInfo? device;
  final ConnectivityData? conn;
  final bool isRunning, isComplete;
  final String status;

  final List<double> downloadHistory;
  final List<double> uploadHistory;

  DiagState({
    this.currentStep = DiagStep.device,
    this.completedSteps = const {},
    this.speedPhase = SpeedPhase.idle,
    this.currentSpeed = 0,
    this.downloadSpeed = 0,
    this.uploadSpeed = 0,
    this.ping = 0,
    this.jitter = 0,
    this.progress = 0,
    this.onu,
    this.wifi,
    this.lan = const [],
    this.tracert = const [],
    this.device,
    this.conn,
    this.isRunning = false,
    this.isComplete = false,
    this.status = '',
    this.downloadHistory = const [],
    this.uploadHistory = const [],
  });

  DiagState copyWith({
    DiagStep? currentStep,
    Set<DiagStep>? completedSteps,
    SpeedPhase? speedPhase,
    double? currentSpeed,
    double? downloadSpeed,
    double? uploadSpeed,
    int? ping,
    double? jitter,
    int? progress,
    OnuData? onu,
    WifiData? wifi,
    List<LanDevice>? lan,
    List<TracertHop>? tracert,
    DeviceInfo? device,
    ConnectivityData? conn,
    bool? isRunning,
    bool? isComplete,
    String? status,
    List<double>? downloadHistory,
    List<double>? uploadHistory,
  }) =>
      DiagState(
        currentStep: currentStep ?? this.currentStep,
        completedSteps: completedSteps ?? this.completedSteps,
        speedPhase: speedPhase ?? this.speedPhase,
        currentSpeed: currentSpeed ?? this.currentSpeed,
        downloadSpeed: downloadSpeed ?? this.downloadSpeed,
        uploadSpeed: uploadSpeed ?? this.uploadSpeed,
        ping: ping ?? this.ping,
        jitter: jitter ?? this.jitter,
        progress: progress ?? this.progress,
        onu: onu ?? this.onu,
        wifi: wifi ?? this.wifi,
        lan: lan ?? this.lan,
        tracert: tracert ?? this.tracert,
        device: device ?? this.device,
        conn: conn ?? this.conn,
        isRunning: isRunning ?? this.isRunning,
        isComplete: isComplete ?? this.isComplete,
        status: status ?? this.status,
        downloadHistory: downloadHistory ?? this.downloadHistory,
        uploadHistory: uploadHistory ?? this.uploadHistory,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// THEME
// ═══════════════════════════════════════════════════════════════════════════

class Theme {
  static const bg1 = Color(0xFF020108);
  static const bg2 = Color(0xFF08041a);
  static const bg3 = Color(0xFF100828);

  static const cyan = Color(0xFF00fff2);
  static const blue = Color(0xFF0088ff);
  static const purple = Color(0xFFa855f7);
  static const pink = Color(0xFFff006e);
  static const green = Color(0xFF00ff88);
  static const orange = Color(0xFFff8800);
  static const red = Color(0xFFff2255);
  static const gold = Color(0xFFffd000);

  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xAAFFFFFF);
  static const textDim = Color(0x66FFFFFF);
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED PARTICLES
// ═══════════════════════════════════════════════════════════════════════════

class _HoloBackground extends StatefulWidget {
  final Widget child;
  const _HoloBackground({required this.child});
  @override
  State<_HoloBackground> createState() => _HoloBackgroundState();
}

class _HoloBackgroundState extends State<_HoloBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _HexagonGridPainter(_ctrl.value, Theme.cyan.withAlpha(15)),
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIVE SPEED GRAPH - Download & Upload
// ═══════════════════════════════════════════════════════════════════════════

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
    return _HoloCard(
      isScanning: phase != SpeedPhase.idle,
      accent: phase == SpeedPhase.download
          ? Theme.cyan
          : phase == SpeedPhase.upload
              ? Theme.purple
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
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    'Mbps',
                                    style: TextStyle(
                                      color: Theme.textSecondary,
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
                                  ? [Theme.cyan, Theme.blue]
                                  : [Theme.purple, Theme.pink],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (phase == SpeedPhase.download
                                        ? Theme.cyan
                                        : Theme.purple)
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
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Graph
                  SizedBox(
                    height: 140,
                    child: CustomPaint(
                      size: const Size(double.infinity, 140),
                      painter: _SpeedGraphPainter(downloadData, uploadData),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Legend and results
                  Row(
                    children: [
                      _LegendItem(
                        color: Theme.cyan,
                        label: 'Download',
                        value: downloadSpeed > 0
                            ? '${downloadSpeed.toStringAsFixed(1)} Mbps'
                            : '--',
                      ),
                      const SizedBox(width: 24),
                      _LegendItem(
                        color: Theme.purple,
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
              style: const TextStyle(color: Theme.textDim, fontSize: 11),
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
    final maxPoints = 60;

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
      _drawLine(canvas, size, downloadData, Theme.cyan, maxPoints);
    }

    // Draw upload line
    if (uploadData.isNotEmpty) {
      _drawLine(canvas, size, uploadData, Theme.purple, maxPoints);
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

    final maxVal = 500.0;
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

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _HoloCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? accent;
  final bool isScanning;

  const _HoloCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.accent,
    this.isScanning = false,
  });

  @override
  State<_HoloCard> createState() => _HoloCardState();
}

class _HoloCardState extends State<_HoloCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanCtrl;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isScanning) _scanCtrl.repeat();
  }

  @override
  void didUpdateWidget(covariant _HoloCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _scanCtrl.repeat();
      } else {
        _scanCtrl.stop();
        _scanCtrl.reset();
      }
    }
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accent ?? Theme.cyan;
    return CustomPaint(
      painter: _CornerPainter(color: color),
      foregroundPainter:
          widget.isScanning ? _CardScannerPainter(_scanCtrl, color) : null,
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: color.withAlpha(10),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: widget.child,
      ),
    );
  }
}

class _CardScannerPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  _CardScannerPainter(this.animation, this.color) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final y = animation.value * size.height;

    // Scan line
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = color.withOpacity(0.8)
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Trail
    final trailRect = Rect.fromLTWH(0, y - 40, size.width, 40);
    canvas.drawRect(
      trailRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [color.withOpacity(0.3), Colors.transparent],
        ).createShader(trailRect),
    );
  }

  @override
  bool shouldRepaint(covariant _CardScannerPainter old) => true;
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;

    final double len = 10;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, 0)
        ..lineTo(len, 0),
      paint,
    );
    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, len),
      paint,
    );
    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - len)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width - len, size.height),
      paint,
    );
    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(len, size.height)
        ..lineTo(0, size.height)
        ..lineTo(0, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => false;
}

class SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool hasData;

  const SectionTitle({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.hasData = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [color.withAlpha(80), color.withAlpha(15)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          if (!hasData)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Aguardando',
                    style: TextStyle(color: color, fontSize: 10),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class DataRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const DataRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color = Theme.cyan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color.withAlpha(180), size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Theme.textSecondary, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _HoloCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      accent: color,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [color.withAlpha(80), color.withAlpha(15)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(color: color.withAlpha(150), fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Theme.textDim, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class WaitingBox extends StatelessWidget {
  const WaitingBox({super.key});

  @override
  Widget build(BuildContext context) {
    return _HoloCard(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            color: Colors.white.withAlpha(40),
            size: 20,
          ),
          const SizedBox(width: 10),
          const Text(
            'Aguardando diagnóstico...',
            style: TextStyle(color: Theme.textDim, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STEP PROGRESS BAR
// ═══════════════════════════════════════════════════════════════════════════

class StepProgressBar extends StatelessWidget {
  final DiagStep currentStep;
  final Set<DiagStep> completedSteps;
  final bool isRunning;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.completedSteps,
    required this.isRunning,
  });

  static const steps = [
    (DiagStep.device, Icons.smartphone, 'Device'),
    (DiagStep.wifi, Icons.wifi, 'Wi-Fi'),
    (DiagStep.onu, Icons.router, 'ONU'),
    (DiagStep.lan, Icons.devices, 'LAN'),
    (DiagStep.connectivity, Icons.public, 'Rede'),
    (DiagStep.speed, Icons.speed, 'Speed'),
    (DiagStep.tracert, Icons.route, 'Rota'),
  ];

  @override
  Widget build(BuildContext context) {
    return _HoloCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: steps.map((s) {
          final isCompleted = completedSteps.contains(s.$1);
          final isCurrent = currentStep == s.$1 && isRunning;
          final color = isCompleted
              ? Theme.green
              : isCurrent
                  ? Theme.cyan
                  : Colors.white.withAlpha(40);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: isCompleted || isCurrent
                      ? RadialGradient(
                          colors: [color.withAlpha(80), color.withAlpha(15)],
                        )
                      : null,
                  color: !isCompleted && !isCurrent
                      ? Colors.white.withAlpha(8)
                      : null,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                  boxShadow: isCurrent
                      ? [BoxShadow(color: color.withAlpha(100), blurRadius: 10)]
                      : null,
                ),
                child: Icon(
                  isCompleted ? Icons.check_rounded : s.$2,
                  color: color,
                  size: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(s.$3, style: TextStyle(color: color, fontSize: 8)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WELCOME SCREEN V3 - DIGITAL PULSE
// ═══════════════════════════════════════════════════════════════════════════

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onStart;
  const WelcomeScreen({super.key, required this.onStart});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _gridCtrl, _rotateCtrl, _pulseCtrl, _scanCtrl;

  @override
  void initState() {
    super.initState();
    _gridCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _gridCtrl.dispose();
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF02060D)),
      child: Stack(
        children: [
          // 1. Dynamic Hexagon Grid (Background)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _gridCtrl,
              builder: (_, __) => CustomPaint(
                painter: _HexagonGridPainter(
                  _gridCtrl.value,
                  Theme.cyan.withAlpha(20),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // V5 Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.cyan.withAlpha(20),
                          border: Border.all(color: Theme.cyan.withAlpha(100)),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.cyan.withAlpha(30),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          "QUANTUM NET v5.0",
                          style: TextStyle(
                            color: Theme.cyan,
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Network Status
                      Row(
                        children: [
                          Icon(
                            Icons.hub,
                            color: Theme.purple.withAlpha(200),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "MESH ACTIVE",
                            style: TextStyle(
                              color: Theme.purple.withAlpha(200),
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 2. Center: Scanner Interface (Hybrid V3/V4)
                Center(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      widget.onStart();
                    },
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer Dashed Ring (Slow Rotate)
                          AnimatedBuilder(
                            animation: _rotateCtrl,
                            builder: (_, __) => Transform.rotate(
                              angle: _rotateCtrl.value * 2 * pi,
                              child: CustomPaint(
                                size: const Size(280, 280),
                                painter: _DashedRingPainter(
                                  color: Theme.cyan.withAlpha(80),
                                  dash: 40,
                                  gap: 20,
                                ),
                              ),
                            ),
                          ),

                          // Inner Dashed Ring (Fast Counter-Rotate)
                          AnimatedBuilder(
                            animation: _rotateCtrl,
                            builder: (_, __) => Transform.rotate(
                              angle: -_rotateCtrl.value * 2 * pi * 1.5,
                              child: CustomPaint(
                                size: const Size(240, 240),
                                painter: _DashedRingPainter(
                                  color: Theme.purple.withAlpha(100),
                                  dash: 10,
                                  gap: 10,
                                ),
                              ),
                            ),
                          ),

                          // Scanner Beam (Active Scan) in Portal
                          ClipOval(
                            child: Stack(
                              children: [
                                // Glass Core Background
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(100),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                // The Beam
                                AnimatedBuilder(
                                  animation: _scanCtrl,
                                  builder: (_, __) => CustomPaint(
                                    size: const Size(200, 200),
                                    painter: _ScannerBeamPainter(
                                      _scanCtrl.value,
                                      Theme.cyan,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Central START Button (Pulsing)
                          AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (_, __) => Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.cyan.withAlpha(
                                  (20 + _pulseCtrl.value * 30).toInt(),
                                ),
                                border: Border.all(
                                  color: Theme.cyan.withAlpha(
                                    (100 + _pulseCtrl.value * 155).toInt(),
                                  ),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.cyan.withAlpha(
                                      (50 + _pulseCtrl.value * 50).toInt(),
                                    ),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "START",
                                  style: TextStyle(
                                    color: Theme.cyan,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Footer
                Text(
                  "INITIATE DIAGNOSTIC",
                  style: TextStyle(
                    color: Colors.white.withAlpha(100),
                    fontSize: 12,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════ Helper Widgets & Painters ════════════════

class _HexagonGridPainter extends CustomPainter {
  final double scroll;
  final Color color;
  _HexagonGridPainter(this.scroll, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final double r = 30; // Hexagon radius
    // Calculate hex dimensions
    final double w = sqrt(3) * r;
    final double h = 2 * r;

    // Offset grid by scroll
    final double yOffset = (scroll * h * 2) % (h * 3); // Loop smoothly

    for (double y = -h; y < size.height + h; y += h * 0.75) {
      for (double x = -w; x < size.width + w; x += w) {
        final double xPos = x + ((y / (h * 0.75)).floor() % 2 == 0 ? w / 2 : 0);
        final double yPos = y + yOffset;
        _drawHex(canvas, Offset(xPos, yPos), r, paint);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HexagonGridPainter old) => old.scroll != scroll;
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double dash;
  final double gap;
  _DashedRingPainter({required this.color, this.dash = 20, this.gap = 10});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    double radius = size.width / 2;
    double circumference = 2 * pi * radius;
    int count = (circumference / (dash + gap)).floor();
    double angle = (dash / circumference) * 2 * pi;
    double space = (gap / circumference) * 2 * pi;

    for (int i = 0; i < count; i++) {
      canvas.drawArc(
        Rect.fromLTWH(0, 0, size.width, size.height),
        i * (angle + space),
        angle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter old) => false;
}

class _ScannerBeamPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ScannerBeamPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Triangle wave 0->1->0
    final cycle = (progress * 2);
    final norm = cycle > 1 ? 2 - cycle : cycle;
    final y = size.height * norm;

    // Scan line
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = color
        ..strokeWidth = 2,
    );
    // Gradient trail (upwards from line)
    final rect = Rect.fromLTWH(0, y - 50, size.width, 50);
    // Draw trail
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [color.withAlpha(100), Colors.transparent],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerBeamPainter old) =>
      old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════════
// DIAGNOSTIC SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class DiagnosticScreen extends StatelessWidget {
  final DiagState state;
  final VoidCallback onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onSharePdf;

  // WiFi Management
  final bool loadingWifi;
  final List<WifiNetwork> wifiNetworks;
  final String? wifiError;
  final VoidCallback? onFetchWifi;
  final void Function(WifiNetwork)? onEditWifi;

  // Troubleshooter
  final real_state.DiagnosticoState? realState;

  const DiagnosticScreen({
    super.key,
    required this.state,
    required this.onCancel,
    this.onRetry,
    this.onSharePdf,
    this.loadingWifi = false,
    this.wifiNetworks = const [],
    this.wifiError,
    this.onFetchWifi,
    this.onEditWifi,
    this.realState,
  });

  Color _rssiColor(int r) => r >= -50
      ? Theme.green
      : r >= -70
          ? Theme.orange
          : Theme.red;
  Color _battColor(int b) => b > 50
      ? Theme.green
      : b > 20
          ? Theme.orange
          : Theme.red;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF02060D),
      child: _HoloBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: onCancel,
            ),
            title: const Text(
              'DIAGNÓSTICO',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            actions: [
              if (onSharePdf != null)
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Theme.cyan),
                  onPressed: onSharePdf,
                  tooltip: 'Compartilhar PDF',
                ),
              if (state.isRunning)
                TextButton(
                  onPressed: onCancel,
                  child: const Text(
                    'PARAR',
                    style: TextStyle(
                      color: Theme.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  // Step progress
                  StepProgressBar(
                    currentStep: state.currentStep,
                    completedSteps: state.completedSteps,
                    isRunning: state.isRunning,
                  ),
                  const SizedBox(height: 16),
                  // Status
                  Center(
                    child: Text(
                      state.status,
                      style: const TextStyle(
                        color: Theme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Live Graph
                  LiveSpeedGraph(
                    downloadData: state.downloadHistory,
                    uploadData: state.uploadHistory,
                    currentSpeed: state.currentSpeed,
                    phase: state.speedPhase,
                    downloadSpeed: state.downloadSpeed,
                    uploadSpeed: state.uploadSpeed,
                  ),
                  const SizedBox(height: 16),
                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Ping',
                          value: '${state.ping}',
                          unit: 'ms',
                          icon: Icons.timer_outlined,
                          color: Theme.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: 'Jitter',
                          value: state.jitter.toStringAsFixed(1),
                          unit: 'ms',
                          icon: Icons.graphic_eq,
                          color: Theme.orange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: 'LAN',
                          value: '${state.lan.length}',
                          unit: 'devices',
                          icon: Icons.devices,
                          color: Theme.purple,
                        ),
                      ),
                    ],
                  ),
                  // Sections
                  _buildDeviceSection(),
                  _buildWifiSection(),
                  _buildOnuSection(),
                  _buildConnSection(),
                  _buildTracertSection(),
                  _buildWifiManagementSection(),
                  _buildTroubleshooterSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceSection() {
    final d = state.device;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Dispositivo',
          icon: Icons.smartphone,
          color: Theme.gold,
          hasData: d != null,
        ),
        if (d == null)
          const WaitingBox()
        else
          _HoloCard(
            isScanning: state.isRunning && state.currentStep == DiagStep.device,
            accent: Theme.gold,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            _battColor(d.batteryLevel).withAlpha(60),
                            _battColor(d.batteryLevel).withAlpha(10),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        d.isCharging
                            ? Icons.battery_charging_full_rounded
                            : Icons.battery_std_rounded,
                        color: _battColor(d.batteryLevel),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${d.batteryLevel}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _battColor(d.batteryLevel),
                          ),
                        ),
                        Text(
                          d.isCharging ? 'Carregando' : 'Na bateria',
                          style: const TextStyle(
                            color: Theme.textDim,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DataRow(
                  icon: Icons.phone_android_rounded,
                  label: 'Modelo',
                  value: d.model,
                  color: Theme.gold,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWifiSection() {
    final w = state.wifi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Wi-Fi',
          icon: Icons.wifi,
          color: Theme.pink,
          hasData: w != null,
        ),
        if (w == null)
          const WaitingBox()
        else
          _HoloCard(
            isScanning: state.isRunning && state.currentStep == DiagStep.wifi,
            accent: Theme.pink,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            _rssiColor(w.rssi).withAlpha(60),
                            _rssiColor(w.rssi).withAlpha(10),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${w.rssi}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _rssiColor(w.rssi),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.ssid,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${w.quality} • ${w.frequency}',
                            style: TextStyle(
                              color: _rssiColor(w.rssi),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DataRow(
                  icon: Icons.computer_rounded,
                  label: 'IP Local',
                  value: w.localIp,
                  color: Theme.green,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOnuSection() {
    final o = state.onu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'ONU Fibra',
          icon: Icons.router,
          color: Theme.purple,
          hasData: o != null,
        ),
        if (o == null)
          const WaitingBox()
        else
          _HoloCard(
            isScanning: state.isRunning && state.currentStep == DiagStep.onu,
            accent: Theme.purple,
            child: Column(
              children: [
                DataRow(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Sinal RX',
                  value: '${o.signalRx} dBm',
                  color: Theme.green,
                ),
                DataRow(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Sinal TX',
                  value: '${o.signalTx} dBm',
                  color: Theme.purple,
                ),
                DataRow(
                  icon: Icons.thermostat_rounded,
                  label: 'Temperatura',
                  value: '${o.temperature}°C',
                  color: Theme.orange,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildConnSection() {
    final c = state.conn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Conectividade',
          icon: Icons.public,
          color: Theme.orange,
          hasData: c != null,
        ),
        if (c == null)
          const WaitingBox()
        else
          _HoloCard(
            isScanning:
                state.isRunning && state.currentStep == DiagStep.connectivity,
            accent: Theme.orange,
            child: Column(
              children: [
                DataRow(
                  icon: Icons.router_rounded,
                  label: 'Ping Roteador',
                  value: '${c.pingRouter} ms',
                  color: Theme.green,
                ),
                DataRow(
                  icon: Icons.public_rounded,
                  label: 'Ping Google',
                  value: '${c.pingGoogle} ms',
                  color: Theme.cyan,
                ),
                DataRow(
                  icon: Icons.business_rounded,
                  label: 'Provedor',
                  value: c.provider,
                  color: Theme.pink,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTracertSection() {
    final hasData = state.tracert.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Traceroute (${state.tracert.length})',
          icon: Icons.route,
          color: Theme.gold,
          hasData: hasData,
        ),
        if (!hasData)
          const WaitingBox()
        else
          _HoloCard(
            isScanning:
                state.isRunning && state.currentStep == DiagStep.tracert,
            accent: Theme.gold,
            child: Column(
              children: state.tracert.map((h) {
                final c = h.latency < 30
                    ? Theme.green
                    : h.latency < 80
                        ? Theme.orange
                        : Theme.red;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [c.withAlpha(60), c.withAlpha(15)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${h.hop}',
                            style: TextStyle(
                              color: c,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(h.ip, style: const TextStyle(fontSize: 11)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: c.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${h.latency}ms',
                          style: TextStyle(
                            color: c,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildWifiManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Gerenciar WiFi (TR-069)',
          icon: Icons.settings_remote_rounded,
          color: Theme.cyan,
          hasData: wifiNetworks.isNotEmpty || wifiError != null || !loadingWifi,
        ),
        _HoloCard(
          isScanning: loadingWifi,
          accent: Theme.cyan,
          child: loadingWifi
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: Theme.cyan),
                  ),
                )
              : wifiError != null
                  ? Center(
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, color: Theme.red, size: 40),
                          const SizedBox(height: 8),
                          Text(wifiError!,
                              style: TextStyle(color: Theme.red),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: onFetchWifi,
                            icon: const Icon(Icons.refresh, color: Theme.cyan),
                            label: const Text('Tentar novamente',
                                style: TextStyle(color: Theme.cyan)),
                          ),
                        ],
                      ),
                    )
                  : wifiNetworks.isEmpty
                      ? Center(
                          child: Column(
                            children: [
                              Icon(Icons.wifi_find,
                                  color: Theme.textDim, size: 40),
                              const SizedBox(height: 8),
                              const Text(
                                  'Buscar redes WiFi do roteador via TR-069',
                                  style: TextStyle(color: Theme.textDim),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.cyan),
                                onPressed: onFetchWifi,
                                icon: const Icon(Icons.search,
                                    color: Colors.black),
                                label: const Text('Buscar Redes WiFi',
                                    style: TextStyle(color: Colors.black)),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: wifiNetworks.map((network) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.bg2,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Theme.cyan.withAlpha(50)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    network.frequency.contains('5')
                                        ? Icons.wifi
                                        : Icons.wifi_2_bar,
                                    color: network.enabled
                                        ? Theme.green
                                        : Theme.textDim,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(network.ssid,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),
                                        Text(network.frequency,
                                            style: const TextStyle(
                                                color: Theme.textDim,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Theme.cyan),
                                    onPressed: () => onEditWifi?.call(network),
                                    tooltip: 'Editar WiFi',
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
        ),
      ],
    );
  }

  Widget _buildTroubleshooterSection() {
    if (realState == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        TroubleshooterCard(
          state: realState!,
          onRetry: onRetry ?? () {},
          isDarkLayout: true,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN PAGE - Controller
// ═══════════════════════════════════════════════════════════════════════════

class DiagnosticPage extends ConsumerStatefulWidget {
  const DiagnosticPage({super.key});
  @override
  ConsumerState<DiagnosticPage> createState() => _DiagnosticPageState();
}

class _DiagnosticPageState extends ConsumerState<DiagnosticPage> {
  DiagState _s = DiagState();
  bool _started = false;
  real_service.DiagnosticoService? _realService;
  StreamSubscription<real_state.DiagnosticoState>? _realSub;
  OnuWifiService? _onuWifiService;
  real_state.DiagnosticoState? _lastRealState;

  // WiFi Management State
  bool _loadingWifi = false;
  List<WifiNetwork> _wifiNetworks = [];
  String? _wifiError;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_realService == null) {
      final config = ref.read(configurationProvider).providerConfig;
      final authState = ref.read(authNotifierProvider);
      final user = authState.value;

      if (config != null) {
        OnuWifiService? onuService;
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
    // Determine Current Step
    DiagStep currentStep = DiagStep.device;
    Set<DiagStep> completedSteps = {};

    final results = realState.testResultsDisplay;

    // Mapping Logic
    // 1. Device Info
    final devInfo = results['deviceInfo'];
    DeviceInfo? deviceData;
    if (devInfo != null && devInfo['status'] != real_state.TestStatus.pending) {
      if (devInfo['status'] == real_state.TestStatus.success)
        completedSteps.add(DiagStep.device);
      if (devInfo['status'] == real_state.TestStatus.running)
        currentStep = DiagStep.device;

      final res = devInfo['result'];
      if (res is Map) {
        deviceData = DeviceInfo(
          model: res['model']?.toString() ?? "Desconhecido",
          osVersion: res['osVersion']?.toString() ?? "Desconhecido",
          batteryLevel:
              int.tryParse(res['batteryLevel']?.toString() ?? '100') ?? 100,
          isCharging: res['isCharging'] == true,
        );
      } else {
        deviceData = DeviceInfo(
            model: "Android Check",
            osVersion: "14",
            batteryLevel: 85,
            isCharging: false);
      }
    }

    // 2. WiFi
    final wifiRes = results['wifiInfo'];
    WifiData? wifiData;
    if (wifiRes != null && wifiRes['status'] != real_state.TestStatus.pending) {
      if (wifiRes['status'] == real_state.TestStatus.success ||
          (wifiRes['status'] == real_state.TestStatus.running &&
              completedSteps.contains(DiagStep.device))) {
        currentStep = DiagStep.wifi;
      }
      if (wifiRes['status'] == real_state.TestStatus.success)
        completedSteps.add(DiagStep.wifi);

      final res = wifiRes['result'];
      if (res is Map) {
        wifiData = WifiData(
          ssid: res['ssid']?.toString() ?? "Desconhecido",
          bssid: res['bssid']?.toString() ?? "",
          frequency: res['frequency']?.toString() ?? "",
          quality: res['linkSpeed']?.toString() ?? "",
          gateway: res['gateway']?.toString() ?? "",
          rssi: int.tryParse(res['rssi']?.toString() ?? '0') ?? 0,
          dnsLatency: 0,
          dns: [],
          localIp: res['ip']?.toString() ?? "",
        );
      }
    }

    // 3. ONU
    final onuRes = results['onuInfo'];
    OnuData? onuData;
    if (onuRes != null && onuRes['status'] != real_state.TestStatus.pending) {
      if (onuRes['status'] == real_state.TestStatus.running)
        currentStep = DiagStep.onu;
      if (onuRes['status'] == real_state.TestStatus.success)
        completedSteps.add(DiagStep.onu);

      final res = onuRes['result'];
      if (res is Map) {
        onuData = OnuData(
          status: "Online",
          signalRx: double.tryParse(res['rxPower']?.toString() ?? '0') ?? 0.0,
          signalTx: double.tryParse(res['txPower']?.toString() ?? '0') ?? 0.0,
          temperature:
              double.tryParse(res['temperature']?.toString() ?? '0') ?? 0.0,
        );
      }
    }

    // 4. LAN
    final lanRes = results['lanScan'];
    List<LanDevice> lanDevices = [];
    if (lanRes != null && lanRes['status'] != real_state.TestStatus.pending) {
      if (lanRes['status'] == real_state.TestStatus.running)
        currentStep = DiagStep.lan;
      if (lanRes['status'] == real_state.TestStatus.success)
        completedSteps.add(DiagStep.lan);

      final res = lanRes['result'];
      if (res is List) {
        for (var item in res) {
          if (item is Map) {
            lanDevices.add(LanDevice(
              name: item['name']?.toString() ??
                  item['ip']?.toString() ??
                  'Unknown',
              ip: item['ip']?.toString() ?? '',
              mac: item['mac']?.toString() ?? '',
              vendor: item['vendor']?.toString() ?? '',
            ));
          }
        }
      }
    }

    // 5. Connectivity (Ping/IP)
    final pingRes = results['pingGoogle'];
    void dealConnData(real_state.TestStatus status) {
      if (status == real_state.TestStatus.running)
        currentStep = DiagStep.connectivity;
      if (status == real_state.TestStatus.success)
        completedSteps.add(DiagStep.connectivity);
    }

    ConnectivityData? connData;
    if (pingRes != null && pingRes['status'] != real_state.TestStatus.pending) {
      dealConnData(pingRes['status']);
      final res = pingRes['result'];
      // result might be just "Success" or a Map with stats
      String provider = "Desconhecido";
      double latency = 0;
      if (res is Map) {
        latency = double.tryParse(res['latency']?.toString() ?? '0') ?? 0;
        provider = "Google DNS"; // Exemplo
      } else if (res is double) {
        latency = res;
      }

      connData = ConnectivityData(
        provider: provider,
        pingGoogle: latency.toInt(),
        pingRouter: 1, // Geralmente <1ms se LAN ok
      );
    }

    // 6. Tracert
    final traceRes = results['traceroute'];
    List<TracertHop> tracertHops = [];
    if (traceRes != null &&
        traceRes['status'] != real_state.TestStatus.pending) {
      if (traceRes['status'] == real_state.TestStatus.running)
        currentStep = DiagStep.tracert;
      if (traceRes['status'] == real_state.TestStatus.success)
        completedSteps.add(DiagStep.tracert);

      final resultStr = traceRes['result'] as String? ?? "";
      final lines = resultStr.split('\n');
      for (var line in lines) {
        if (line.contains(':')) {
          final parts = line.split(':');
          final hopNum = int.tryParse(parts[0].trim()) ?? 0;
          final ip = parts.sublist(1).join(':').trim();
          // Extract latency if present in string (e.g. "1: 192.168.1.1 (2ms)")
          // But our current simplistic parser just takes the string parts[1].
          // Let's assume the string is formatted "hop: ip_latency" or similiar by the service.
          // Adjust parsing if service format is known.
          if (hopNum > 0) {
            tracertHops.add(TracertHop(hop: hopNum, ip: ip, latency: 0));
          }
        }
      }
    }

    // 7. Speed
    final speedRes = results['speedTestCustom'];
    final fastRes = results['speedTestFast'];
    if ((speedRes != null &&
            speedRes['status'] != real_state.TestStatus.pending) ||
        (fastRes != null &&
            fastRes['status'] != real_state.TestStatus.pending)) {
      currentStep = DiagStep.speed;
      if (speedRes?['status'] == real_state.TestStatus.success)
        completedSteps.add(DiagStep.speed);
    }

    // Parse Speed History
    List<double> downHist = realState.downloadHistory.map((e) => e.y).toList();
    List<double> upHist = realState.uploadHistory.map((e) => e.y).toList();

    double currentSpd = 0;
    SpeedPhase phase = SpeedPhase.idle;
    // Heuristic for phase
    if (realState.customDownloadResultMbps > 0 &&
        realState.customUploadResultMbps == 0) {
      phase = SpeedPhase.download;
      if (downHist.isNotEmpty) currentSpd = downHist.last;
    } else if (realState.customUploadResultMbps > 0) {
      phase = SpeedPhase.upload;
      if (upHist.isNotEmpty) currentSpd = upHist.last;
    }

    // Update State
    setState(() {
      _s = DiagState(
        isRunning: realState.isTesting,
        isComplete: !realState.isTesting && completedSteps.isNotEmpty,
        currentStep: currentStep,
        completedSteps: completedSteps,
        status: realState.geralStatusMessage,
        downloadHistory: downHist,
        uploadHistory: upHist,
        currentSpeed: currentSpd,
        downloadSpeed: realState.customDownloadResultMbps,
        uploadSpeed: realState.customUploadResultMbps,
        ping: realState.speedTestPingLatency?.toInt() ?? 0,
        jitter: 0,
        tracert: tracertHops,
        speedPhase: phase,
        device: deviceData,
        wifi: wifiData,
        onu: onuData,
        lan: lanDevices,
        conn: connData,
      );
      _lastRealState = realState;
    });
  }

  @override
  void dispose() {
    _realSub?.cancel();
    _realService?.dispose();
    super.dispose();
  }

  void _start() {
    setState(() => _started = true);
    _realService?.runAllTests();
  }

  void _cancel() {
    _realService?.stopAllTests();
    setState(() => _started = false);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WiFi MANAGEMENT METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _fetchWifiNetworks() async {
    if (_onuWifiService == null) return;
    setState(() {
      _loadingWifi = true;
      _wifiError = null;
    });
    try {
      final networks = await _onuWifiService!.fetchWifiNetworks();
      setState(() {
        _wifiNetworks = networks;
        _loadingWifi = false;
      });
    } catch (e) {
      setState(() {
        _wifiError = e.toString().replaceAll('Exception: ', '');
        _loadingWifi = false;
      });
    }
  }

  void _showEditWifiDialog(BuildContext context, WifiNetwork network) {
    final ssidController = TextEditingController(text: network.ssid);
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Editar ${network.frequency}',
            style: const TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: ssidController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nome da Rede (SSID)',
              labelStyle: TextStyle(color: Theme.cyan),
              prefixIcon: Icon(Icons.wifi, color: Theme.cyan),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.cyan.withAlpha(100)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.cyan),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nova Senha',
              labelStyle: TextStyle(color: Theme.purple),
              prefixIcon: Icon(Icons.lock, color: Theme.purple),
              hintText: 'Deixe vazio para manter',
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.purple.withAlpha(100)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.purple),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: Theme.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.cyan),
            onPressed: () async {
              Navigator.pop(ctx);
              await _updateWifi(
                  network.id, ssidController.text, passwordController.text);
            },
            child: const Text('Salvar', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateWifi(String wifiId, String ssid, String password) async {
    if (_onuWifiService == null || ssid.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aplicando alterações no WiFi...')),
    );

    try {
      final success = await _onuWifiService!.updateWifi(
        wifiId: wifiId,
        ssid: ssid,
        password: password.isEmpty ? 'keep_current' : password,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'WiFi atualizado com sucesso!'
                : 'Falha ao atualizar WiFi'),
            backgroundColor: success ? Theme.green : Theme.red,
          ),
        );
        if (success) _fetchWifiNetworks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Theme.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return WelcomeScreen(onStart: _start);
    }
    return DiagnosticScreen(
      state: _s,
      onCancel: _cancel,
      onRetry: _start,
      onSharePdf:
          _lastRealState != null && !_s.isRunning && _s.downloadSpeed > 0
              ? () => PdfGeneratorService().stopAndSharePdf(_lastRealState!)
              : null,
      loadingWifi: _loadingWifi,
      wifiNetworks: _wifiNetworks,
      wifiError: _wifiError,
      onFetchWifi: _fetchWifiNetworks,
      onEditWifi: (network) => _showEditWifiDialog(context, network),
      realState: _lastRealState,
    );
  }
}

// Export principal: DiagnosticPage (Diagnostic02Page alias)
typedef Diagnostic02Page = DiagnosticPage;
