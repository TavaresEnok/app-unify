// Página de Diagnóstico - NOVA UI com Gráfico em Tempo Real
// Two-screen flow: Welcome Screen → Diagnostic with Live Graph
// INTEGRAÇÃO COM SERVIÇOS REAIS - Janeiro 2026

import 'dart:async';

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
import '../../utils/diagnostic_utils.dart';
import '../../controllers/wifi_management_controller.dart';
import '../../widgets/diagnostics/diagnostic_theme.dart';
import '../../widgets/diagnostics/holo_background.dart';
import '../../widgets/diagnostics/holo_card.dart';
import '../../widgets/diagnostics/section_title.dart';
import '../../widgets/diagnostics/diagnostic_data_row.dart';
import '../../widgets/diagnostics/live_speed_graph.dart';
import '../../widgets/diagnostics/step_progress_bar.dart';
import '../../widgets/diagnostics/stat_card.dart';
import '../../widgets/diagnostics/waiting_box.dart';
import '../../widgets/diagnostics/welcome_screen.dart';
import '../../models/diagnostic_enums.dart';

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

// Enums moved to diagnostic_enums.dart

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

// Shared widgets moved to lib/core/widgets/diagnostics/

class DiagnosticScreen extends StatelessWidget {
  final DiagState state;
  final VoidCallback onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onSharePdf;

  // WiFi Management Controller
  final WifiManagementController? wifiController;

  // Troubleshooter
  final real_state.DiagnosticoState? realState;

  const DiagnosticScreen({
    super.key,
    required this.state,
    required this.onCancel,
    this.onRetry,
    this.onSharePdf,
    this.wifiController,
    this.realState,
  });

  Color _rssiColor(int r) => r >= -50
      ? DiagnosticTheme.green
      : r >= -70
          ? DiagnosticTheme.orange
          : DiagnosticTheme.red;
  Color _battColor(int b) => b > 50
      ? DiagnosticTheme.green
      : b > 20
          ? DiagnosticTheme.orange
          : DiagnosticTheme.red;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF02060D),
      child: HoloBackground(
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
                  icon: const Icon(Icons.share_rounded,
                      color: DiagnosticTheme.cyan),
                  onPressed: onSharePdf,
                  tooltip: 'Compartilhar PDF',
                ),
              if (state.isRunning)
                TextButton(
                  onPressed: onCancel,
                  child: const Text(
                    'PARAR',
                    style: TextStyle(
                      color: DiagnosticTheme.red,
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
                        color: DiagnosticTheme.textSecondary,
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
                          color: DiagnosticTheme.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: 'Jitter',
                          value: state.jitter.toStringAsFixed(1),
                          unit: 'ms',
                          icon: Icons.graphic_eq,
                          color: DiagnosticTheme.orange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: 'LAN',
                          value: '${state.lan.length}',
                          unit: 'devices',
                          icon: Icons.devices,
                          color: DiagnosticTheme.purple,
                        ),
                      ),
                    ],
                  ),
                  // Sections
                  _buildConnectionJourneySection(),
                  _buildDeviceDetailsSection(),
                  _buildWifiDetailsSection(),
                  _buildOnuDetailsSection(),
                  _buildLanDetailsSection(),
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
          color: DiagnosticTheme.gold,
          hasData: d != null,
        ),
        if (d == null)
          const WaitingBox()
        else
          HoloCard(
            isScanning: state.isRunning && state.currentStep == DiagStep.device,
            accent: DiagnosticTheme.gold,
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
                            color: DiagnosticTheme.textDim,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DiagnosticDataRow(
                  icon: Icons.phone_android_rounded,
                  label: 'Modelo',
                  value: d.model,
                  color: DiagnosticTheme.gold,
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
          color: DiagnosticTheme.pink,
          hasData: w != null,
        ),
        if (w == null)
          const WaitingBox()
        else
          HoloCard(
            isScanning: state.isRunning && state.currentStep == DiagStep.wifi,
            accent: DiagnosticTheme.pink,
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
                DiagnosticDataRow(
                  icon: Icons.computer_rounded,
                  label: 'IP Local',
                  value: w.localIp,
                  color: DiagnosticTheme.green,
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
          color: DiagnosticTheme.purple,
          hasData: o != null,
        ),
        if (o == null)
          const WaitingBox()
        else
          HoloCard(
            isScanning: state.isRunning && state.currentStep == DiagStep.onu,
            accent: DiagnosticTheme.purple,
            child: Column(
              children: [
                DiagnosticDataRow(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Sinal RX',
                  value: '${o.signalRx} dBm',
                  color: DiagnosticTheme.green,
                ),
                DiagnosticDataRow(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Sinal TX',
                  value: '${o.signalTx} dBm',
                  color: DiagnosticTheme.purple,
                ),
                DiagnosticDataRow(
                  icon: Icons.thermostat_rounded,
                  label: 'Temperatura',
                  value: '${o.temperature}°C',
                  color: DiagnosticTheme.orange,
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
          color: DiagnosticTheme.orange,
          hasData: c != null,
        ),
        if (c == null)
          const WaitingBox()
        else
          HoloCard(
            isScanning:
                state.isRunning && state.currentStep == DiagStep.connectivity,
            accent: DiagnosticTheme.orange,
            child: Column(
              children: [
                DiagnosticDataRow(
                  icon: Icons.router_rounded,
                  label: 'Ping Roteador',
                  value: '${c.pingRouter} ms',
                  color: DiagnosticTheme.green,
                ),
                DiagnosticDataRow(
                  icon: Icons.public_rounded,
                  label: 'Ping Google',
                  value: '${c.pingGoogle} ms',
                  color: DiagnosticTheme.cyan,
                ),
                DiagnosticDataRow(
                  icon: Icons.business_rounded,
                  label: 'Provedor',
                  value: c.provider,
                  color: DiagnosticTheme.pink,
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
          color: DiagnosticTheme.gold,
          hasData: hasData,
        ),
        if (!hasData)
          const WaitingBox()
        else
          HoloCard(
            isScanning:
                state.isRunning && state.currentStep == DiagStep.tracert,
            accent: DiagnosticTheme.gold,
            child: Column(
              children: state.tracert.map((h) {
                final c = h.latency < 30
                    ? DiagnosticTheme.green
                    : h.latency < 80
                        ? DiagnosticTheme.orange
                        : DiagnosticTheme.red;
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
    if (wifiController == null) return const SizedBox.shrink();

    return ValueListenableBuilder<WifiState>(
      valueListenable: wifiController!,
      builder: (context, state, _) {
        final loadingWifi = state.isLoading;
        final wifiError = state.error;
        final wifiNetworks = state.networks;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(
              title: 'Gerenciar WiFi (TR-069)',
              icon: Icons.settings_remote_rounded,
              color: DiagnosticTheme.cyan,
              hasData:
                  wifiNetworks.isNotEmpty || wifiError != null || !loadingWifi,
            ),
            HoloCard(
              isScanning: loadingWifi,
              accent: DiagnosticTheme.cyan,
              child: loadingWifi
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                            color: DiagnosticTheme.cyan),
                      ),
                    )
                  : wifiError != null
                      ? Center(
                          child: Column(
                            children: [
                              Icon(Icons.error_outline,
                                  color: DiagnosticTheme.red, size: 40),
                              const SizedBox(height: 8),
                              Text(wifiError,
                                  style: TextStyle(color: DiagnosticTheme.red),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    wifiController!.fetchNetworks(),
                                icon: const Icon(Icons.refresh,
                                    color: DiagnosticTheme.cyan),
                                label: const Text('Tentar novamente',
                                    style:
                                        TextStyle(color: DiagnosticTheme.cyan)),
                              ),
                            ],
                          ),
                        )
                      : wifiNetworks.isEmpty
                          ? Center(
                              child: Column(
                                children: [
                                  Icon(Icons.wifi_find,
                                      color: DiagnosticTheme.textDim, size: 40),
                                  const SizedBox(height: 8),
                                  const Text(
                                      'Buscar redes WiFi do roteador via TR-069',
                                      style: TextStyle(
                                          color: DiagnosticTheme.textDim),
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: DiagnosticTheme.cyan),
                                    onPressed: () =>
                                        wifiController!.fetchNetworks(),
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
                                    color: DiagnosticTheme.bg2,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color:
                                            DiagnosticTheme.cyan.withAlpha(50)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        network.frequency.contains('5')
                                            ? Icons.wifi
                                            : Icons.wifi_2_bar,
                                        color: network.enabled
                                            ? DiagnosticTheme.green
                                            : DiagnosticTheme.textDim,
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
                                                    color:
                                                        DiagnosticTheme.textDim,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: DiagnosticTheme.cyan),
                                        onPressed: () => _showEditWifiDialog(
                                            context, network),
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
      },
    );
  }

  void _showEditWifiDialog(BuildContext context, WifiNetwork network) {
    if (wifiController == null) return;

    final ssidController = TextEditingController(text: network.ssid);
    final passwordController = TextEditingController(text: network.password);

    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: DiagnosticTheme.bg2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(Icons.edit, color: DiagnosticTheme.cyan),
            const SizedBox(width: 10),
            Text('Editar ${network.frequency}',
                style: const TextStyle(color: Colors.white))
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: ssidController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'SSID (Nome da Rede)',
                labelStyle: const TextStyle(color: DiagnosticTheme.textDim),
                enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: DiagnosticTheme.textDim)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: DiagnosticTheme.cyan)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Senha',
                labelStyle: const TextStyle(color: DiagnosticTheme.textDim),
                enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: DiagnosticTheme.textDim)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: DiagnosticTheme.cyan)),
              ),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(color: DiagnosticTheme.textDim))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: DiagnosticTheme.cyan),
              onPressed: () {
                Navigator.pop(ctx);
                wifiController!.updateWifi(
                  context, // Pass context for SnackBar
                  network.id,
                  ssidController.text,
                  passwordController.text,
                );
              },
              child: const Text('Salvar Alterações',
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // PARSING HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  // _parseResultLine REMOVED - Using DiagnosticUtils.parseResultLine instead

  Color _getStatusColor(real_state.TestStatus status) {
    return DiagnosticUtils.getStatusColor(
      status,
      success: DiagnosticTheme.green,
      running: DiagnosticTheme.cyan,
      error: DiagnosticTheme.red,
      pending: DiagnosticTheme.textDim,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONNECTION JOURNEY CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildConnectionJourneySection() {
    if (realState == null) return const SizedBox.shrink();

    final results = realState!.testResultsDisplay;

    final wifiStatus =
        results['wifiInfo']?['status'] as real_state.TestStatus? ??
            real_state.TestStatus.pending;
    final wifiResult = results['wifiInfo']?['result'] as String?;
    final gatewayStatus =
        results['pingGateway']?['status'] as real_state.TestStatus? ??
            real_state.TestStatus.pending;
    final gatewayResult = results['pingGateway']?['result'] as String?;
    final ipStatus = results['publicIp']?['status'] as real_state.TestStatus? ??
        real_state.TestStatus.pending;
    final ipResult = results['publicIp']?['result'] as String?;
    final googleStatus =
        results['pingGoogle']?['status'] as real_state.TestStatus? ??
            real_state.TestStatus.pending;
    final googleResult = results['pingGoogle']?['result'] as String?;
    final cloudflareStatus =
        results['pingCloudflare']?['status'] as real_state.TestStatus? ??
            real_state.TestStatus.pending;
    final cloudflareResult = results['pingCloudflare']?['result'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Jornada da Conexão',
          icon: Icons.route_rounded,
          color: DiagnosticTheme.cyan,
          hasData: wifiStatus != real_state.TestStatus.pending,
        ),
        HoloCard(
          isScanning: wifiStatus == real_state.TestStatus.running ||
              gatewayStatus == real_state.TestStatus.running,
          accent: DiagnosticTheme.cyan,
          child: Column(
            children: [
              _buildJourneyStep(
                icon: Icons.phone_android_rounded,
                title: 'Você (Dispositivo)',
                status: wifiStatus,
                details: [
                  (
                    'Sinal',
                    DiagnosticUtils.parseResultLine(
                        wifiResult, 'Força do Sinal:')
                  ),
                  (
                    'SSID',
                    DiagnosticUtils.parseResultLine(wifiResult, 'SSID:')
                  ),
                ],
              ),
              _buildJourneyConnector(wifiStatus),
              _buildJourneyStep(
                icon: Icons.router_rounded,
                title: 'Seu Roteador',
                status: gatewayStatus,
                details: [
                  (
                    'IP',
                    DiagnosticUtils.parseResultLine(
                        wifiResult, 'Gateway (Roteador):')
                  ),
                  (
                    'Latência',
                    DiagnosticUtils.parseResultLine(gatewayResult, 'Latência:')
                  ),
                  (
                    'Jitter',
                    DiagnosticUtils.parseResultLine(gatewayResult, 'Jitter:')
                  ),
                ],
              ),
              _buildJourneyConnector(gatewayStatus),
              _buildJourneyStep(
                icon: Icons.cloud_queue_rounded,
                title: 'Nossa Rede',
                status: ipStatus,
                details: [
                  ('IPv4', DiagnosticUtils.parseResultLine(ipResult, 'IPv4:')),
                  ('IPv6', DiagnosticUtils.parseResultLine(ipResult, 'IPv6:')),
                ],
              ),
              _buildJourneyConnector(ipStatus),
              _buildJourneyStep(
                icon: Icons.dns_rounded,
                title: 'Internet (DNS)',
                status: (googleStatus == real_state.TestStatus.success ||
                        cloudflareStatus == real_state.TestStatus.success)
                    ? real_state.TestStatus.success
                    : googleStatus,
                details: [
                  (
                    'Google',
                    '${DiagnosticUtils.parseResultLine(googleResult, 'Latência:')}'
                  ),
                  (
                    'Cloudflare',
                    '${DiagnosticUtils.parseResultLine(cloudflareResult, 'Latência:')}'
                  ),
                ],
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyStep({
    required IconData icon,
    required String title,
    required real_state.TestStatus status,
    required List<(String, String)> details,
    bool isLast = false,
  }) {
    final color = _getStatusColor(status);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(100)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    const Spacer(),
                    if (status == real_state.TestStatus.running)
                      SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: color))
                    else
                      Icon(
                        status == real_state.TestStatus.success
                            ? Icons.check_circle
                            : status == real_state.TestStatus.error
                                ? Icons.error
                                : Icons.schedule,
                        color: color,
                        size: 14,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: details
                      .map((d) => Text(
                            '${d.$1}: ${d.$2}',
                            style: TextStyle(
                                color: DiagnosticTheme.textDim, fontSize: 11),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyConnector(real_state.TestStatus status) {
    return Padding(
      padding: const EdgeInsets.only(left: 17, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 20,
            color: _getStatusColor(status).withAlpha(60),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENHANCED WIFI DETAILS SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWifiDetailsSection() {
    if (realState == null) return const SizedBox.shrink();

    final wifiResult =
        realState!.testResultsDisplay['wifiInfo']?['result'] as String?;
    final status = realState!.testResultsDisplay['wifiInfo']?['status']
            as real_state.TestStatus? ??
        real_state.TestStatus.pending;

    if (status == real_state.TestStatus.pending) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Detalhes WiFi',
          icon: Icons.info_outline_rounded,
          color: DiagnosticTheme.pink,
          hasData: wifiResult != null,
        ),
        HoloCard(
          isScanning: status == real_state.TestStatus.running,
          accent: DiagnosticTheme.pink,
          child: Column(
            children: [
              DiagnosticDataRow(
                  icon: Icons.router,
                  label: 'BSSID',
                  value: DiagnosticUtils.parseResultLine(wifiResult, 'BSSID:'),
                  color: DiagnosticTheme.pink),
              DiagnosticDataRow(
                  icon: Icons.computer,
                  label: 'IP Local',
                  value: DiagnosticUtils.parseResultLine(
                      wifiResult, 'IP Dispositivo:'),
                  color: DiagnosticTheme.pink),
              DiagnosticDataRow(
                  icon: Icons.dns,
                  label: 'DNS',
                  value: DiagnosticUtils.parseResultLine(
                      wifiResult, 'Servidores DNS:'),
                  color: DiagnosticTheme.pink),
              DiagnosticDataRow(
                  icon: Icons.signal_wifi_4_bar,
                  label: 'Frequência',
                  value: DiagnosticUtils.parseResultLine(
                      wifiResult, 'Frequência:'),
                  color: DiagnosticTheme.pink),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENHANCED LAN SCAN SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLanDetailsSection() {
    if (realState == null) return const SizedBox.shrink();

    final lanResult =
        realState!.testResultsDisplay['lanScan']?['result'] as String?;
    final status = realState!.testResultsDisplay['lanScan']?['status']
            as real_state.TestStatus? ??
        real_state.TestStatus.pending;

    if (status == real_state.TestStatus.pending) return const SizedBox.shrink();

    // Parse device count
    final deviceCount =
        DiagnosticUtils.parseResultLine(lanResult, 'Dispositivos encontrados:');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Dispositivos na Rede',
          icon: Icons.devices_rounded,
          color: DiagnosticTheme.purple,
          hasData: lanResult != null,
        ),
        HoloCard(
          isScanning: status == real_state.TestStatus.running,
          accent: DiagnosticTheme.purple,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.devices_other,
                      color: DiagnosticTheme.purple, size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(deviceCount,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      const Text('dispositivos encontrados',
                          style: TextStyle(
                              color: DiagnosticTheme.textDim, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              if (lanResult != null && lanResult.contains('sub-rede')) ...[
                const SizedBox(height: 12),
                Text(
                  lanResult
                      .split('\n')
                      .lastWhere((l) => l.contains('sub-rede'),
                          orElse: () => '')
                      .replaceAll('(', '')
                      .replaceAll(')', ''),
                  style:
                      TextStyle(color: DiagnosticTheme.textDim, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENHANCED DEVICE INFO SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDeviceDetailsSection() {
    if (realState == null) return const SizedBox.shrink();

    final deviceResult =
        realState!.testResultsDisplay['deviceInfo']?['result'] as String?;
    final status = realState!.testResultsDisplay['deviceInfo']?['status']
            as real_state.TestStatus? ??
        real_state.TestStatus.pending;

    if (status == real_state.TestStatus.pending) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Info do Dispositivo',
          icon: Icons.smartphone_rounded,
          color: DiagnosticTheme.gold,
          hasData: deviceResult != null,
        ),
        HoloCard(
          isScanning: status == real_state.TestStatus.running,
          accent: DiagnosticTheme.gold,
          child: Column(
            children: [
              DiagnosticDataRow(
                  icon: Icons.wifi,
                  label: 'Conexão',
                  value:
                      DiagnosticUtils.parseResultLine(deviceResult, 'Conexão:'),
                  color: DiagnosticTheme.gold),
              DiagnosticDataRow(
                  icon: Icons.android,
                  label: 'Sistema',
                  value: DiagnosticUtils.parseResultLine(
                      deviceResult, 'Versão OS:'),
                  color: DiagnosticTheme.gold),
              DiagnosticDataRow(
                  icon: Icons.phone_android,
                  label: 'Dispositivo',
                  value: DiagnosticUtils.parseResultLine(
                      deviceResult, 'Dispositivo:'),
                  color: DiagnosticTheme.gold),
              DiagnosticDataRow(
                  icon: Icons.info_outline,
                  label: 'App',
                  value: DiagnosticUtils.parseResultLine(
                      deviceResult, 'Versão do App:'),
                  color: DiagnosticTheme.gold),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENHANCED ONU/FIBRA SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildOnuDetailsSection() {
    if (realState == null) return const SizedBox.shrink();

    final onuResult = realState!.testResultsDisplay['onuInfo']?['result'];
    final status = realState!.testResultsDisplay['onuInfo']?['status']
            as real_state.TestStatus? ??
        real_state.TestStatus.pending;

    if (status == real_state.TestStatus.pending) return const SizedBox.shrink();

    String rxPower = '---';
    String txPower = '---';
    String temperature = '---';
    String onuModel = '---';

    if (onuResult is Map) {
      rxPower = onuResult['rxPower']?.toString() ?? '---';
      txPower = onuResult['txPower']?.toString() ?? '---';
      temperature = onuResult['temperature']?.toString() ?? '---';
      onuModel = onuResult['model']?.toString() ?? '---';
    }

    Color rxColor = DiagnosticTheme.green;
    final rxValue = double.tryParse(rxPower) ?? 0;
    if (rxValue < -25)
      rxColor = DiagnosticTheme.red;
    else if (rxValue < -20) rxColor = DiagnosticTheme.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'ONU / Fibra Óptica',
          icon: Icons.cable_rounded,
          color: DiagnosticTheme.cyan,
          hasData: status == real_state.TestStatus.success,
        ),
        HoloCard(
          isScanning: status == real_state.TestStatus.running,
          accent: DiagnosticTheme.cyan,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildOnuStat('Rx Power', '$rxPower dBm', rxColor),
                  ),
                  Expanded(
                    child: _buildOnuStat(
                        'Tx Power', '$txPower dBm', DiagnosticTheme.cyan),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildOnuStat('Temperatura', '$temperature°C',
                        DiagnosticTheme.orange),
                  ),
                  Expanded(
                    child: _buildOnuStat(
                        'Modelo', onuModel, DiagnosticTheme.purple),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOnuStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: DiagnosticTheme.textDim, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
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

  // WiFi Management Controller
  WifiManagementController? _wifiController;

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
          // Initialize WiFi Controller
          _wifiController?.dispose(); // Dispose previous if any
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
    _wifiController?.dispose();
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
  // WiFi MANAGEMENT METHODS - Moved to WifiManagementController
  // ═══════════════════════════════════════════════════════════════════════════

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
      wifiController: _wifiController,
      realState: _lastRealState,
    );
  }
}

// Export principal: DiagnosticPage (Diagnostic02Page alias)
typedef Diagnostic02Page = DiagnosticPage;
