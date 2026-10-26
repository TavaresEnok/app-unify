part of '../diagnostic_02_page.dart';

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
    this.batteryLevel = -1,
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
