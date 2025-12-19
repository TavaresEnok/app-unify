import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/diagnostico_state.dart';
import '../models/provider_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:lan_scanner/lan_scanner.dart';

class PingParams {
  final String host;
  final int count;
  final bool discardFirst;
  PingParams(
      {required this.host, required this.count, this.discardFirst = false});
}

Future<String> _pingTestRunner(PingParams params) async {
  final completer = Completer<String>();
  final latencies = <int>[];
  int packetsReceived = 0;
  StreamSubscription<PingData>? subscription;

  // Se discardFirst for true, pedimos 1 pacote extra para compensar
  final int totalCount = params.discardFirst ? params.count + 1 : params.count;

  final ping = Ping(params.host,
      count: totalCount, timeout: 2, interval: 1, ipv6: false);

  int currentIndex = 0;

  subscription = ping.stream.listen((PingData data) {
    if (data.response != null) {
      final isFirst = currentIndex == 0;
      currentIndex++;

      if (params.discardFirst && isFirst) {
        // Ignora o primeiro pacote (warm-up no ARP/Route table)
        return;
      }

      packetsReceived++;
      final time = data.response!.time?.inMilliseconds;
      if (time != null) {
        latencies.add(time);
      }
    }
  }, onDone: () {
    // Se discardFirst=true, packetsLost calcula baseado no params.count (pois pedimos +1 mas ignoramos 1)
    // Se recebemos totalCount, packetsReceived será totalCount - 1 (se o primeiro chegou).
    // Mas simplificando: params.count é o alvo.

    int packetsLost = params.count - packetsReceived;
    if (packetsLost < 0) packetsLost = 0; // Garantia

    double lossPercentage = (packetsLost / params.count) * 100;

    if (!completer.isCompleted) {
      if (latencies.isEmpty) {
        completer.complete('Host inacessível\nPerda: 100%');
      } else {
        int avgLatency =
            (latencies.reduce((a, b) => a + b) / latencies.length).round();
        double jitter = 0.0;
        if (latencies.length > 1) {
          int totalDiff = 0;
          for (int i = 0; i < latencies.length - 1; i++) {
            totalDiff += (latencies[i] - latencies[i + 1]).abs();
          }
          // Use (latencies.length - 1) for Jitter calculation
          jitter = totalDiff / (latencies.length - 1);
        }
        completer.complete(
            'Latência: ${avgLatency}ms\nJitter: ${jitter.toStringAsFixed(1)}ms\nPerda: ${lossPercentage.toStringAsFixed(0)}%');
      }
    }
    subscription?.cancel();
  }, onError: (e) {
    if (!completer.isCompleted) {
      completer.complete('Erro no Ping: ${e.toString()}');
    }
    subscription?.cancel();
  });

  Future.delayed(Duration(seconds: (totalCount * 2) + 5), () {
    if (!completer.isCompleted) {
      subscription?.cancel();
      completer.complete('Erro: Teste de ping expirou (Timeout)');
    }
  });

  return completer.future;
}

class DiagnosticoService {
  final ProviderConfig providerConfig;
  final BuildContext? context;
  final _streamController = StreamController<DiagnosticoState>.broadcast();
  Stream<DiagnosticoState> get stateStream => _streamController.stream;
  late DiagnosticoState _currentState;

  final NetworkInfo _networkInfo = NetworkInfo();
  bool _isWifiConnected = false;
  static const platform = MethodChannel('br.com.ajust.app_provedor/wifi_info');
  final internetSpeedTest = FlutterInternetSpeedTest();
  final Battery _battery = Battery();
  final LanScanner _lanScanner = LanScanner();
  Timer? _realtimeUpdateTimer;

  double _customPeakDownloadMbps = 0;
  double _customPeakUploadMbps = 0;
  double _fastPeakDownloadMbps = 0;
  double _fastPeakUploadMbps = 0;
  int _downloadHistoryCounter = 0;
  int _uploadHistoryCounter = 0;
  int _fastDownloadHistoryCounter = 0;
  int _fastUploadHistoryCounter = 0;

  DiagnosticoService({required this.providerConfig, this.context}) {
    _currentState = DiagnosticoState.initial();
  }

  void dispose() {
    stopAllTests();
    _streamController.close();
  }

  void _updateStatus(String message) {
    if (_streamController.isClosed || !_currentState.isTesting) return;
    _currentState = _currentState.copyWith(geralStatusMessage: message);
    _streamController.add(_currentState);
  }

  void _updateTestState(String key, TestStatus status, String? result) {
    if (_streamController.isClosed) return;
    final newResults = Map<String, Map<String, dynamic>>.from(
        _currentState.testResultsDisplay);
    newResults[key] = {
      ...?newResults[key],
      'status': status,
      'result': result,
    };
    if (key == 'wifiInfo' && status == TestStatus.success) {
      final gatewayIp = _parseResultLine(result, "Gateway (Roteador):");
      if (gatewayIp != "---") {
        newResults[key]?['gatewayIp'] = gatewayIp;
      }
    }
    _currentState = _currentState.copyWith(testResultsDisplay: newResults);
    _streamController.add(_currentState);
  }

  String _parseResultLine(String? resultText, String key) {
    if (resultText == null || resultText.isEmpty) return "---";
    try {
      return resultText
          .split('\n')
          .firstWhere((l) => l.startsWith(key), orElse: () => "$key ---")
          .split(':')
          .sublist(1)
          .join(':')
          .trim();
    } catch (e) {
      return "---";
    }
  }

  double _extractLatencyFromResult(String? result) {
    if (result == null) return 0.0;
    try {
      final latencyPart = result
          .split('\n')
          .firstWhere((l) => l.contains('Latência'), orElse: () => '');
      final match = RegExp(r'(\d+)ms').firstMatch(latencyPart);
      if (match != null) {
        return double.tryParse(match.group(1) ?? '0') ?? 0.0;
      }
    } catch (e) {
      return 0.0;
    }
    return 0.0;
  }

  void stopAllTests() {
    internetSpeedTest.cancelTest();
    _realtimeUpdateTimer?.cancel();
    _realtimeUpdateTimer = null;
    if (_currentState.isTesting) {
      _currentState = _currentState.copyWith(
          isTesting: false,
          geralStatusMessage: "Diagnóstico interrompido pelo usuário.");
      if (!_streamController.isClosed) _streamController.add(_currentState);
    }
  }

  Future<void> _runBatteryTest() async {
    if (!_currentState.isTesting) return;
    _updateTestState(
        'batteryInfo', TestStatus.running, "Verificando bateria...");
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      String stateStr = "Desconhecido";
      if (state == BatteryState.charging) {
        stateStr = "Carregando";
      } else if (state == BatteryState.discharging) {
        stateStr = "Descarregando";
      } else if (state == BatteryState.full) {
        stateStr = "Cheia";
      }

      String warning = "";
      if (level < 20 && state != BatteryState.charging) {
        warning = "\n⚠️ Bateria baixa! O Wi-Fi pode perder potência.";
      }

      _updateTestState('batteryInfo', TestStatus.success,
          "Nível: $level%\nEstado: $stateStr$warning");
    } catch (e) {
      _updateTestState(
          'batteryInfo', TestStatus.error, "Erro ao ler bateria: $e");
    }
  }

  Future<void> _runLanScanTest() async {
    if (!_currentState.isTesting) return;
    _updateTestState('lanScan', TestStatus.running,
        "Escaneando rede local (pode demorar)...");
    try {
      final String? ip = await _networkInfo.getWifiIP();
      if (ip == null) {
        _updateTestState('lanScan', TestStatus.error,
            "Não foi possível obter o IP para escanear.");
        return;
      }
      final String subnet = ip.substring(0, ip.lastIndexOf('.'));
      final List<Host> hosts = await _lanScanner.quickIcmpScanAsync(subnet);

      if (!_currentState.isTesting) return;
      _updateTestState('lanScan', TestStatus.success,
          "Dispositivos encontrados: ${hosts.length}\n(Na sub-rede $subnet.x)");
    } catch (e) {
      if (!_currentState.isTesting) return;
      _updateTestState('lanScan', TestStatus.error, "Erro no scanner: $e");
    }
  }

  Future<void> _runPingTest(String host, String key,
      {int count = 5, bool discardFirst = false}) async {
    if (!_currentState.isTesting) return;
    _updateTestState(key, TestStatus.running, "Iniciando...");
    try {
      final params =
          PingParams(host: host, count: count, discardFirst: discardFirst);
      final String result = await compute(_pingTestRunner, params);
      if (!_currentState.isTesting) return;
      if (result.startsWith('Erro')) {
        _updateTestState(key, TestStatus.error, result);
      } else {
        _updateTestState(key, TestStatus.success, result);
      }
    } catch (e) {
      if (!_currentState.isTesting) return;
      _updateTestState(key, TestStatus.error,
          'Erro fatal ao executar o Isolate de ping: ${e.toString()}');
    }
  }

  Future<void> _runDeviceInfoTest() async {
    if (!_currentState.isTesting) return;
    _updateTestState('deviceInfo', TestStatus.running, "Coletando...");
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _isWifiConnected = connectivityResult == ConnectivityResult.wifi;
      String connectionType = "Desconhecida";
      if (_isWifiConnected) {
        connectionType = "WiFi";
      } else if (connectivityResult == ConnectivityResult.mobile) {
        connectionType = "Dados Móveis (4G/5G)";
      } else if (connectivityResult == ConnectivityResult.ethernet) {
        connectionType = "Cabo (Ethernet)";
      } else if (connectivityResult == ConnectivityResult.none) {
        connectionType = "Sem Conexão";
      } else if (connectivityResult == ConnectivityResult.vpn) {
        connectionType = "VPN (Pode afetar a velocidade!)";
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion =
          "v${packageInfo.version} (Build ${packageInfo.buildNumber})";
      final deviceInfo = DeviceInfoPlugin();
      String deviceModel = "N/A";
      String osVersion = "N/A";
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = "${androidInfo.manufacturer} ${androidInfo.model}";
        osVersion =
            "Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.model;
        osVersion = "iOS ${iosInfo.systemVersion}";
      }
      final resultString =
          "Conexão: $connectionType\nDispositivo: $deviceModel\nVersão OS: $osVersion\nVersão do App: $appVersion";
      _updateTestState('deviceInfo', TestStatus.success, resultString);
    } catch (e) {
      _updateTestState('deviceInfo', TestStatus.error,
          "Erro ao obter dados do dispositivo.");
    }
  }

  Future<void> _runIpTest() async {
    if (!_currentState.isTesting) return;
    _updateTestState('publicIp', TestStatus.running, "Buscando IPv4 e IPv6...");
    try {
      String ipV4 = "N/A";
      String org = "N/A";
      String ipV6 = "Não detectado";

      try {
        final response = await http
            .get(Uri.parse('https://ipinfo.io/json'))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          ipV4 = data['ip'] ?? 'N/A';
          org = data['org'] ?? 'N/A';
        }
      } catch (_) {}

      if (_currentState.isTesting) {
        try {
          final responseV6 = await http
              .get(Uri.parse('https://api64.ipify.org?format=json'))
              .timeout(const Duration(seconds: 5));
          if (responseV6.statusCode == 200) {
            final dataV6 = json.decode(responseV6.body);
            final ip = dataV6['ip'] as String?;
            if (ip != null && ip.contains(':')) {
              ipV6 = "Sim ($ip)";
            } else if (ip != null && ip == ipV4) {
              ipV6 = "Não (IPv4 apenas)";
            }
          }
        } catch (_) {
          ipV6 = "Falha ao verificar";
        }
      }

      if (!_currentState.isTesting) return;

      if (ipV4 != "N/A") {
        _updateTestState('publicIp', TestStatus.success,
            'IPv4: $ipV4\nIPv6: $ipV6\nProvedor: $org');
      } else {
        _updateTestState('publicIp', TestStatus.error,
            'Falha ao conectar aos servidores de IP.');
      }
    } catch (e) {
      if (!_currentState.isTesting) return;
      _updateTestState('publicIp', TestStatus.error, 'Erro: ${e.toString()}');
    }
  }

  Future<bool> _requestLocationPermission() async {
    if (!Platform.isAndroid) return true;
    var status = await Permission.location.request();
    if (context == null || !context!.mounted) return false;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context!).showSnackBar(const SnackBar(
          content: Text(
              'Permissão de localização é necessária para obter informações de WiFi.')));
    }
    return status.isGranted;
  }

  String _getFrequencyBand(int? frequency) {
    if (frequency == null || frequency == -1) return "N/A";
    if (frequency >= 2400 && frequency < 3000) return "2.4 GHz";
    if (frequency >= 5000 && frequency < 6000) return "5 GHz";
    return "$frequency MHz (Desconhecido)";
  }

  String _getSignalQuality(int? rssi) {
    if (rssi == null || rssi == -127) return "N/A";
    if (rssi >= -67) return "Excelente ($rssi dBm)";
    if (rssi >= -70) return "Boa ($rssi dBm)";
    if (rssi >= -80) return "Razoável ($rssi dBm)";
    if (rssi >= -90) return "Fraca ($rssi dBm)";
    return "Muito Fraca ($rssi dBm)";
  }

  Future<void> _runWifiTest() async {
    if (!_currentState.isTesting) return;
    _updateTestState(
        'wifiInfo', TestStatus.running, "Buscando dados de WiFi/DNS...");
    try {
      String? wifiName =
          (await _networkInfo.getWifiName())?.replaceAll("\"", "");
      String? wifiBSSID = await _networkInfo.getWifiBSSID();
      String? wifiIPv4 = await _networkInfo.getWifiIP();
      String? wifiGatewayIP = await _networkInfo.getWifiGatewayIP();
      String wifiFrequencyBand = "N/A";
      String wifiSignalStrength = "N/A";
      String dnsServers = "N/A";
      int dnsTimeMs = 0;

      if (Platform.isAndroid) {
        try {
          final Map<dynamic, dynamic>? wifiDetails =
              await platform.invokeMethod('getWifiDetails');
          final int? frequency = wifiDetails?['frequency'] as int?;
          final int? rssi = wifiDetails?['rssi'] as int?;
          final List<dynamic>? dnsList =
              wifiDetails?['dnsServers'] as List<dynamic>?;
          wifiFrequencyBand = _getFrequencyBand(frequency);
          wifiSignalStrength = _getSignalQuality(rssi);
          dnsServers = (dnsList != null && dnsList.isNotEmpty)
              ? dnsList.join('\n')
              : "Nenhum DNS encontrado";
        } catch (e) {
          debugPrint(
              "ALERTA: Falha ao chamar o MethodChannel 'getWifiDetails'. O código nativo pode estar faltando. $e");
        }
      }

      try {
        final stopwatch = Stopwatch()..start();
        await InternetAddress.lookup('google.com');
        stopwatch.stop();
        dnsTimeMs = stopwatch.elapsedMilliseconds;
      } catch (_) {
        dnsTimeMs = -1;
      }

      final resultString =
          "SSID: ${wifiName ?? 'N/A'}\nFrequência: $wifiFrequencyBand\nForça do Sinal: $wifiSignalStrength\nBSSID: ${wifiBSSID ?? 'N/A'}\nIP Dispositivo: ${wifiIPv4 ?? 'N/A'}\nGateway (Roteador): ${wifiGatewayIP ?? 'N/A'}\nServidores DNS:\n$dnsServers\nTempo DNS: ${dnsTimeMs >= 0 ? '$dnsTimeMs ms' : 'Falha'}";
      _updateTestState('wifiInfo', TestStatus.success, resultString);
    } catch (e) {
      if (!_currentState.isTesting) return;
      _updateTestState('wifiInfo', TestStatus.error,
          'Erro ao obter informações: ${e.toString()}');
    }
  }

  Future<void> _runPingGatewayTest() async {
    if (!_currentState.isTesting) return;
    _updateTestState(
        'pingGateway', TestStatus.running, "Aguardando IP do Roteador...");
    final String? gatewayIp =
        _currentState.testResultsDisplay['wifiInfo']?['gatewayIp'] as String?;
    if (gatewayIp != null && gatewayIp.isNotEmpty) {
      _updateStatus("Testando ping para o Roteador ($gatewayIp)...");
      // Use 10 pings + discardFirst for router
      await _runPingTest(gatewayIp, 'pingGateway',
          count: 10, discardFirst: true);
    } else {
      if (_currentState.isTesting &&
          _currentState.testResultsDisplay['pingGateway']?['status'] !=
              TestStatus.error) {
        _updateTestState('pingGateway', TestStatus.error,
            'Não foi possível obter IP do roteador no teste WiFi.');
      }
    }
  }

  Future<void> _runSpeedTestCustom() async {
    if (!_currentState.isTesting) return;
    String? customUrl = providerConfig.config.other?.speedTestUrl;

    // Default: Infer local server from API URL (same host, port 3001)
    String defaultSpeedTestUrl =
        'https://librespeed.org'; // Fallback of fallback
    try {
      final apiUri = Uri.parse(providerConfig.apiUrl);
      if (apiUri.host.isNotEmpty) {
        // Assume SpeedTest is adjacent on port 3001
        defaultSpeedTestUrl = 'http://${apiUri.host}:3001';
      }
    } catch (_) {
      // Ignore parse error, stick to librespeed
    }

    // Validate URL - use inferred default if invalid or empty
    if (customUrl == null ||
        customUrl.isEmpty ||
        Uri.tryParse(customUrl)?.hasAbsolutePath != true) {
      customUrl = defaultSpeedTestUrl;
      _updateStatus("Usando servidor padrão: $customUrl");
    }

    _updateTestState('speedTestCustom', TestStatus.running,
        "Iniciando teste (Servidor Próprio)...");

    final completer = Completer<void>();
    _downloadHistoryCounter = 0;
    _uploadHistoryCounter = 0;
    _customPeakDownloadMbps = 0;
    _customPeakUploadMbps = 0;
    _currentState =
        _currentState.copyWith(downloadHistory: [], uploadHistory: []);
    _streamController.add(_currentState);

    // TIMERS
    Timer? stallTimer;
    Timer? maxDurationTimer;

    void cancelTimers() {
      stallTimer?.cancel();
      maxDurationTimer?.cancel();
    }

    try {
      // 1. Max Duration Timer: Hard limit per test (prevents 2 min waits)
      maxDurationTimer = Timer(const Duration(seconds: 40), () {
        if (!completer.isCompleted && _currentState.isTesting) {
          internetSpeedTest.cancelTest();
          // Accept current result as final if we timed out but had data
          _updateTestState(
              'speedTestCustom', TestStatus.success, "Tempo limite atingido.");
          if (!completer.isCompleted) completer.complete();
        }
      });

      internetSpeedTest.startTesting(
        downloadTestServer: customUrl,
        uploadTestServer: customUrl,
        // fileSize: 20000000, // Optional: Limit file size if supported to speed up
        onStarted: () {
          if (!_currentState.isTesting) {
            internetSpeedTest.cancelTest();
            return;
          }
          _updateStatus("Testando Download (Servidor Personalizado)...");
        },
        onCompleted: (TestResult download, TestResult upload) {
          cancelTimers();
          if (!_currentState.isTesting) return;
          final downloadMbps = download.transferRate;
          final uploadMbps = upload.transferRate;

          _updateTestState('speedTestCustom', TestStatus.success,
              "Download: ${downloadMbps.toStringAsFixed(1)} Mbps\nUpload: ${uploadMbps.toStringAsFixed(1)} Mbps");

          double latencia = _extractLatencyFromResult(
              _currentState.testResultsDisplay['pingGoogle']?['result']);
          if (latencia == 0) {
            latencia = _extractLatencyFromResult(
                _currentState.testResultsDisplay['pingCloudflare']?['result']);
          }

          _currentState = _currentState.copyWith(
            customDownloadResultMbps: downloadMbps,
            customUploadResultMbps: uploadMbps,
            speedTestPingLatency: latencia,
          );
          _streamController.add(_currentState);
          if (!completer.isCompleted) completer.complete();
        },
        onProgress: (double percent, TestResult data) {
          if (!_currentState.isTesting) return;
          final rate = data.transferRate;
          final isDownload = data.type == TestType.download;

          // 2. Stall Timer: Reset only on progress
          stallTimer?.cancel();
          stallTimer = Timer(const Duration(seconds: 15), () {
            if (!completer.isCompleted && _currentState.isTesting) {
              internetSpeedTest.cancelTest();
              _updateTestState('speedTestCustom', TestStatus.error,
                  "Teste travado (sem progresso).");
              if (!completer.isCompleted) completer.complete();
            }
          });

          if (isDownload) {
            _updateStatus(
                "Testando Download... ${rate.toStringAsFixed(1)} Mbps (${percent.toStringAsFixed(0)}%)");
            if (rate > _customPeakDownloadMbps) _customPeakDownloadMbps = rate;
            final newHistory = List<FlSpot>.from(_currentState.downloadHistory);
            newHistory.add(FlSpot(_downloadHistoryCounter.toDouble(), rate));
            _downloadHistoryCounter++;
            _currentState = _currentState.copyWith(
                downloadHistory: newHistory, customDownloadResultMbps: rate);
          } else {
            _updateStatus(
                "Testando Upload... ${rate.toStringAsFixed(1)} Mbps (${percent.toStringAsFixed(0)}%)");
            if (rate > _customPeakUploadMbps) _customPeakUploadMbps = rate;
            final newHistory = List<FlSpot>.from(_currentState.uploadHistory);
            newHistory.add(FlSpot(_uploadHistoryCounter.toDouble(), rate));
            _uploadHistoryCounter++;
            _currentState = _currentState.copyWith(
                uploadHistory: newHistory, customUploadResultMbps: rate);
          }
          _streamController.add(_currentState);
        },
        onError: (String errorMessage, String speedTestError) {
          cancelTimers();
          if (!_currentState.isTesting) return;

          String cleanError = errorMessage;
          // Enhanced Error Parsing
          if (errorMessage.toLowerCase().contains("socketexception") ||
              errorMessage.toLowerCase().contains("connection refused") ||
              errorMessage.contains("CONNECTION_ERROR") ||
              errorMessage.contains("HTTP 404")) {
            cleanError = "Servidor indisponível.\nVerifique a conexão ou URL.";
          }

          _updateTestState('speedTestCustom', TestStatus.error, cleanError);
          if (!completer.isCompleted) completer.complete();
        },
      );
    } catch (e) {
      cancelTimers();
      _updateTestState(
          'speedTestCustom', TestStatus.error, "Erro ao iniciar: $e");
      if (!completer.isCompleted) completer.complete();
    }

    return completer.future;
  }

  Future<void> _runSpeedTestFastCom() async {
    if (!_currentState.isTesting) return;
    _updateTestState(
        'speedTestFast', TestStatus.running, "Iniciando teste (Fast.com)...");
    final completer = Completer<void>();
    _fastDownloadHistoryCounter = 0;
    _fastUploadHistoryCounter = 0;
    _fastPeakDownloadMbps = 0;
    _fastPeakUploadMbps = 0;
    _currentState =
        _currentState.copyWith(fastDownloadHistory: [], fastUploadHistory: []);
    _streamController.add(_currentState);

    // SAFETY TIMEOUT: Ensure test doesn't hang forever
    Timer? safeguardTimer;

    try {
      safeguardTimer = Timer(const Duration(seconds: 45), () {
        if (!completer.isCompleted && _currentState.isTesting) {
          internetSpeedTest.cancelTest();
          _updateTestState('speedTestFast', TestStatus.error,
              "Tempo limite excedido (Fast.com).");
          if (!completer.isCompleted) completer.complete();
        }
      });

      internetSpeedTest.startTesting(
        onStarted: () {
          if (!_currentState.isTesting) {
            internetSpeedTest.cancelTest();
            return;
          }
          _updateStatus("Testando Download (Fast.com)...");
        },
        onCompleted: (TestResult download, TestResult upload) {
          safeguardTimer?.cancel();
          if (!_currentState.isTesting) return;
          final downloadMbps = download.transferRate;
          final uploadMbps = upload.transferRate;
          _updateTestState('speedTestFast', TestStatus.success,
              "Download: ${downloadMbps.toStringAsFixed(1)} Mbps\nUpload: ${uploadMbps.toStringAsFixed(1)} Mbps");
          _currentState = _currentState.copyWith(
              fastDownloadResultMbps: downloadMbps,
              fastUploadResultMbps: uploadMbps);
          _streamController.add(_currentState);
          if (!completer.isCompleted) completer.complete();
        },
        onProgress: (double percent, TestResult data) {
          if (!_currentState.isTesting) return; // Prevent Zombie updates
          final rate = data.transferRate;
          final isDownload = data.type == TestType.download;

          // Restart safeguard on progress
          safeguardTimer?.cancel();
          safeguardTimer = Timer(const Duration(seconds: 20), () {
            if (!completer.isCompleted && _currentState.isTesting) {
              internetSpeedTest.cancelTest();
              _updateTestState('speedTestFast', TestStatus.error,
                  "Teste travado (sem progresso).");
              if (!completer.isCompleted) completer.complete();
            }
          });

          if (isDownload) {
            _updateStatus(
                "Testando Download (Fast.com)... ${rate.toStringAsFixed(1)} Mbps (${percent.toStringAsFixed(0)}%)");
            if (rate > _fastPeakDownloadMbps) _fastPeakDownloadMbps = rate;
            final newHistory =
                List<FlSpot>.from(_currentState.fastDownloadHistory);
            newHistory
                .add(FlSpot(_fastDownloadHistoryCounter.toDouble(), rate));
            _fastDownloadHistoryCounter++;
            _currentState = _currentState.copyWith(
                fastDownloadHistory: newHistory, fastDownloadResultMbps: rate);
          } else {
            _updateStatus(
                "Testando Upload (Fast.com)... ${rate.toStringAsFixed(1)} Mbps (${percent.toStringAsFixed(0)}%)");
            if (rate > _fastPeakUploadMbps) _fastPeakUploadMbps = rate;
            final newHistory =
                List<FlSpot>.from(_currentState.fastUploadHistory);
            newHistory.add(FlSpot(_fastUploadHistoryCounter.toDouble(), rate));
            _fastUploadHistoryCounter++;
            _currentState = _currentState.copyWith(
                fastUploadHistory: newHistory, fastUploadResultMbps: rate);
          }
          _streamController.add(_currentState);
        },
        onError: (String errorMessage, String speedTestError) {
          safeguardTimer?.cancel();
          if (!_currentState.isTesting) return;
          _updateTestState(
              'speedTestFast', TestStatus.error, "Erro: $errorMessage");
          if (!completer.isCompleted) completer.complete();
        },
      );
    } catch (e) {
      safeguardTimer?.cancel();
      _updateTestState(
          'speedTestFast', TestStatus.error, "Erro ao iniciar: $e");
      if (!completer.isCompleted) completer.complete();
    }

    return completer.future;
  }

  Future<void> runAllTests() async {
    if (_currentState.isTesting) return;
    _currentState = DiagnosticoState.initial().copyWith(
        isTesting: true, geralStatusMessage: "Iniciando diagnóstico...");
    _streamController.add(_currentState);

    try {
      _updateStatus("Verificando informações do dispositivo...");
      await _runDeviceInfoTest();
      await _runBatteryTest();
      if (!_currentState.isTesting) return;

      bool hasPermission = false;
      if (_isWifiConnected) {
        _updateStatus("Solicitando permissão de localização...");
        hasPermission = await _requestLocationPermission();
        if (!_currentState.isTesting) return;
        if (!hasPermission) {
          _updateTestState(
              'wifiInfo', TestStatus.error, 'Permissão de localização negada.');
          _updateTestState('pingGateway', TestStatus.error,
              'Requer info WiFi (permissão negada).');
        }
      } else {
        _updateTestState(
            'wifiInfo', TestStatus.error, 'Não conectado ao WiFi.');
        _updateTestState(
            'pingGateway', TestStatus.error, 'Não conectado ao WiFi.');
      }

      _updateStatus("Verificando Conectividade e IP (IPv4/IPv6)...");
      await _runIpTest();
      if (!_currentState.isTesting) return;

      _updateStatus("Testando ping para Google...");
      // 10 pings, keep all for Google
      await _runPingTest('8.8.8.8', 'pingGoogle', count: 10);
      if (!_currentState.isTesting) return;

      _updateStatus("Testando ping para Cloudflare...");
      // 10 pings, keep all for Cloudflare
      await _runPingTest('1.1.1.1', 'pingCloudflare', count: 10);

      if (!_currentState.isTesting) return;

      if (hasPermission && _isWifiConnected) {
        _updateStatus("Verificando informações de WiFi e DNS...");
        await _runWifiTest();

        _updateStatus("Escaneando Rede Local (LAN)...");
        await _runLanScanTest();

        if (!_currentState.isTesting) return;
        if (_currentState.testResultsDisplay['wifiInfo']?['status'] ==
            TestStatus.success) {
          await _runPingGatewayTest();
          if (!_currentState.isTesting) return;
        }
      }

      await _runSpeedTestCustom();
      if (!_currentState.isTesting) return;

      await _runSpeedTestFastCom();
      if (!_currentState.isTesting) return;

      if (_currentState.isTesting) {
        bool anyError = _currentState.testResultsDisplay.entries
            .any((entry) => entry.value['status'] == TestStatus.error);
        _updateStatus(anyError
            ? "Diagnóstico concluído com erros."
            : "Diagnóstico concluído.");
      }
    } catch (e) {
      if (_currentState.isTesting) {
        _updateStatus("Ocorreu um erro inesperado durante o diagnóstico.");
      }
    } finally {
      if (_currentState.isTesting) {
        _currentState = _currentState.copyWith(isTesting: false);
        _streamController.add(_currentState);
      }
    }
  }

  Future<void> runSpeedTestsOnly() async {
    if (_currentState.isTesting) return;
    _currentState = DiagnosticoState.initial().copyWith(
        isTesting: true,
        geralStatusMessage: "Iniciando teste de velocidade...");
    _streamController.add(_currentState);

    try {
      await _runSpeedTestCustom();
      if (!_currentState.isTesting) return;

      await _runSpeedTestFastCom();
      if (!_currentState.isTesting) return;

      _updateStatus("Teste de velocidade concluído.");
    } catch (e) {
      if (_currentState.isTesting) {
        _updateStatus("Ocorreu um erro durante o teste.");
      }
    } finally {
      if (_currentState.isTesting) {
        _currentState = _currentState.copyWith(isTesting: false);
        _streamController.add(_currentState);
      }
    }
  }
}
