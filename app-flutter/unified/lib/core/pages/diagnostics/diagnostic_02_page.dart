// Página de Diagnóstico - NOVA UI com Gráfico em Tempo Real
// Two-screen flow: Welcome Screen → Diagnostic with Live Graph
// INTEGRAÇÃO COM SERVIÇOS REAIS - Janeiro 2026

import 'dart:async';

import 'package:flutter/material.dart';
// Required for debugPrint
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

part 'parts/diagnostic_02_models.dart';
part 'parts/diagnostic_02_screen.dart';

class DiagnosticPage extends ConsumerStatefulWidget {
  const DiagnosticPage({super.key});
  @override
  ConsumerState<DiagnosticPage> createState() => _DiagnosticPageState();
}

class _DiagnosticPageState extends ConsumerState<DiagnosticPage> {
  static String? _safeResultString(dynamic result) {
    if (result == null) return null;
    if (result is String) return result;
    if (result is Map) {
      return result['display'] as String? ??
          result['displayText'] as String? ??
          result['stateStr'] as String? ??
          result.toString();
    }
    return result.toString();
  }

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
      if (devInfo['status'] == real_state.TestStatus.success) {
        completedSteps.add(DiagStep.device);
      }
      if (devInfo['status'] == real_state.TestStatus.running) {
        currentStep = DiagStep.device;
      }

      final res = devInfo['result'];
      debugPrint('[DiagUI] DeviceInfo Result: $res'); // Debug log

      if (res != null && res is Map) {
        // Parsing seguro com logs
        final rawLevel = res['batteryLevel'];
        final level = int.tryParse(rawLevel?.toString() ?? '100') ?? 100;
        final charging = res['isCharging'] == true;

        debugPrint('[DiagUI] Parsed Battery: $level%, Charging: $charging');

        deviceData = DeviceInfo(
          model: res['model']?.toString() ?? "Desconhecido",
          osVersion: res['osVersion']?.toString() ?? "Desconhecido",
          batteryLevel: level,
          isCharging: charging,
        );
      } else if (res is String) {
        // Se for string, provavelmente é erro ou mensagem de status simples
        debugPrint('[DiagUI] Bateria retornou String: $res');
        deviceData = DeviceInfo(
          model: "Erro ao ler bateria",
          osVersion: "Verifique permissões",
          batteryLevel: -1,
          isCharging: false,
        );
      } else {
        debugPrint(
          '[DiagUI] DeviceInfo caiu no fallback! Res type: ${res.runtimeType}',
        );
        // Fallback apenas se for null ou tipo desconhecido
        deviceData = DeviceInfo(
          model: "Dados Indisponíveis",
          osVersion: "-",
          batteryLevel: -1,
          isCharging: false,
        );
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
      if (wifiRes['status'] == real_state.TestStatus.success) {
        completedSteps.add(DiagStep.wifi);
      }

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
      if (onuRes['status'] == real_state.TestStatus.running) {
        currentStep = DiagStep.onu;
      }
      if (onuRes['status'] == real_state.TestStatus.success) {
        completedSteps.add(DiagStep.onu);
      }

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
      if (lanRes['status'] == real_state.TestStatus.running) {
        currentStep = DiagStep.lan;
      }
      if (lanRes['status'] == real_state.TestStatus.success) {
        completedSteps.add(DiagStep.lan);
      }

      final res = lanRes['result'];
      if (res is List) {
        for (var item in res) {
          if (item is Map) {
            lanDevices.add(
              LanDevice(
                name: item['name']?.toString() ??
                    item['ip']?.toString() ??
                    'Unknown',
                ip: item['ip']?.toString() ?? '',
                mac: item['mac']?.toString() ?? '',
                vendor: item['vendor']?.toString() ?? '',
              ),
            );
          }
        }
      }
    }

    // 5. Connectivity (Ping/IP)
    final pingRes = results['pingGoogle'];
    void dealConnData(real_state.TestStatus status) {
      if (status == real_state.TestStatus.running) {
        currentStep = DiagStep.connectivity;
      }
      if (status == real_state.TestStatus.success) {
        completedSteps.add(DiagStep.connectivity);
      }
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
      if (traceRes['status'] == real_state.TestStatus.running) {
        currentStep = DiagStep.tracert;
      }
      if (traceRes['status'] == real_state.TestStatus.success) {
        completedSteps.add(DiagStep.tracert);
      }

      final resultStr = _safeResultString(traceRes['result']) ?? "";
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
      if (speedRes?['status'] == real_state.TestStatus.success) {
        completedSteps.add(DiagStep.speed);
      }
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
