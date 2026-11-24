import 'traceroute_service.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
import 'package:network_tools/network_tools.dart';
import 'package:path_provider/path_provider.dart';
import 'onu_wifi_service.dart';
import 'ookla_speedtest_service.dart';

part 'diagnostic_ping.dart';
part 'diagnostic_runs.dart';

/// Abstração para permitir o mock de Ping em testes
abstract class PingFactory {
  Ping create(
    String host, {
    int? count,
    Duration? timeout,
    Duration? interval,
    bool? ipv6,
  });
}

class DefaultPingFactory implements PingFactory {
  @override
  Ping create(
    String host, {
    int? count,
    Duration? timeout,
    Duration? interval,
    bool? ipv6,
  }) =>
      Ping(
        host,
        count: count,
        timeout: timeout?.inSeconds ?? 2,
        interval: interval?.inSeconds ?? 1,
        ipv6: ipv6 ?? false,
      );
}

abstract interface class LocalNetworkScanner {
  Future<int> countActiveHosts(String subnet);
}

class NetworkToolsLocalScanner implements LocalNetworkScanner {
  static Future<void>? _initFuture;
  void Function()? _cancel;
  void cancel() => _cancel?.call();

  static Future<void> _ensureConfigured() {
    return _initFuture ??= () async {
      final dir = await getTemporaryDirectory();
      await configureNetworkTools(dir.path);
    }()
        .catchError((Object error) {
      _initFuture = null;
      throw error;
    });
  }

  @override
  Future<int> countActiveHosts(String subnet) async {
    await _ensureConfigured();
    final completer = Completer<int>();
    var count = 0;
    final subscription =
        HostScannerService.instance.getAllPingableDevices(subnet).listen(
      (_) => count++,
      onDone: () {
        if (!completer.isCompleted) completer.complete(count);
      },
      onError: (Object error) {
        if (!completer.isCompleted) completer.completeError(error);
      },
    );
    void cancel() {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Varredura interrompida.'));
      }
    }

    _cancel = cancel;
    final timer = Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer
            .completeError(TimeoutException('A rede não respondeu a tempo.'));
      }
    });
    try {
      return await completer.future;
    } finally {
      timer.cancel();
      await subscription.cancel();
      _cancel = null;
    }
  }
}

class DiagnosticoService {
  final ProviderConfig providerConfig;
  final BuildContext? context;
  DiagnosticoState get currentState => _currentState;
  bool get canStart =>
      !_executionActive &&
      !_currentState.isTesting &&
      !_streamController.isClosed;

  @visibleForTesting
  void setTestingState(bool isTesting) {
    _currentState = _currentState.copyWith(isTesting: isTesting);
  }

  final OnuWifiService? onuService;
  final http.Client client;
  final bool _ownsClient;
  bool _executionActive = false;
  void Function()? _cancelPing;
  void Function()? _cancelSpeedTest;
  final NetworkInfo _networkInfo;
  final Connectivity _connectivity;
  final Battery _battery;
  final LocalNetworkScanner _lanScanner;
  final FlutterInternetSpeedTest internetSpeedTest;
  final OoklaSpeedtestService _ooklaSpeedTest;
  final DeviceInfoPlugin _deviceInfo;
  final PackageInfo? _packageInfo;
  final PingFactory _pingFactory;

  final _streamController = StreamController<DiagnosticoState>.broadcast();
  Stream<DiagnosticoState> get stateStream => _streamController.stream;
  late DiagnosticoState _currentState;

  bool _isWifiConnected = false;
  static const platform = MethodChannel('br.com.ajust.app_provedor/wifi_info');
  Timer? _realtimeUpdateTimer;
  OoklaServerPlan? _activeOoklaPlan;
  OoklaCancelToken? _ooklaCancel;

  double _customPeakDownloadMbps = 0;
  double _customPeakUploadMbps = 0;
  double _fastPeakDownloadMbps = 0;
  double _fastPeakUploadMbps = 0;
  int _downloadHistoryCounter = 0;
  int _uploadHistoryCounter = 0;
  int _fastDownloadHistoryCounter = 0;
  int _fastUploadHistoryCounter = 0;

  DiagnosticoService({
    required this.providerConfig,
    this.context,
    this.onuService,
    http.Client? client,
    NetworkInfo? networkInfo,
    Connectivity? connectivity,
    Battery? battery,
    LocalNetworkScanner? lanScanner,
    FlutterInternetSpeedTest? speedTest,
    OoklaSpeedtestService? ooklaSpeedTest,
    DeviceInfoPlugin? deviceInfo,
    PackageInfo? packageInfo,
    PingFactory? pingFactory,
  })  : client = client ?? http.Client(),
        _ownsClient = client == null,
        _networkInfo = networkInfo ?? NetworkInfo(),
        _connectivity = connectivity ?? Connectivity(),
        _battery = battery ?? Battery(),
        _lanScanner = lanScanner ?? NetworkToolsLocalScanner(),
        internetSpeedTest = speedTest ?? FlutterInternetSpeedTest(),
        _ooklaSpeedTest = ooklaSpeedTest ?? OoklaSpeedtestService(),
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
        _packageInfo = packageInfo,
        _pingFactory = pingFactory ?? DefaultPingFactory() {
    _currentState = DiagnosticoState.initial();
  }

  void dispose() {
    stopAllTests();
    _streamController.close();
    if (_ownsClient) client.close();
  }

  void _updateStatus(String message) {
    if (_streamController.isClosed || !_currentState.isTesting) return;
    _currentState = _currentState.copyWith(geralStatusMessage: message);
    _streamController.add(_currentState);
  }

  /// [metrics] carrega os valores JÁ TIPADOS da medição (ex.: latência, jitter,
  /// perda). O campo `result` continua sendo o texto/mapa de exibição usado
  /// pelas telas; `metrics` existe para que relatório, laudo e persistência não
  /// precisem reparsear string formatada.
  void _updateTestState(
    String key,
    TestStatus status,
    dynamic result, {
    Map<String, dynamic>? metrics,
    TestAvailability availability = TestAvailability.available,
  }) {
    if (_streamController.isClosed || !_currentState.isTesting) return;
    final newResults = Map<String, Map<String, dynamic>>.from(
      _currentState.testResultsDisplay,
    );
    newResults[key] = {
      ...?newResults[key],
      'status': status,
      'result': result,
      'availability': availability.name,
      if (status == TestStatus.success || status == TestStatus.error)
        'measuredAt': DateTime.now().toIso8601String(),
      if (metrics != null) 'metrics': metrics,
    };
    if (key == 'wifiInfo' && status == TestStatus.success) {
      String? gatewayIp;
      if (result is String) {
        // Legacy: resultado como string formatada
        gatewayIp = _parseResultLine(result, "Gateway (Roteador):");
        if (gatewayIp == "---") gatewayIp = null;
      } else if (result is Map) {
        // Resultado como Map (formato atual)
        final gw = result['gateway'] as String?;
        if (gw != null && gw.isNotEmpty && gw != 'N/A') gatewayIp = gw;
      }
      if (gatewayIp != null) {
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
    if (_lanScanner is NetworkToolsLocalScanner) _lanScanner.cancel();
    _cancelPing?.call();
    _cancelPing = null;
    _ooklaCancel?.cancel();
    _ooklaCancel = null;
    _activeOoklaPlan = null;
    _cancelSpeedTest?.call();
    _cancelSpeedTest = null;
    internetSpeedTest.cancelTest();
    _realtimeUpdateTimer?.cancel();
    _realtimeUpdateTimer = null;
    if (_currentState.isTesting) {
      _currentState = _currentState.copyWith(
        isTesting: false,
        finishedAt: DateTime.now(),
        wasInterrupted: true,
        geralStatusMessage: "Diagnóstico interrompido pelo usuário.",
      );
      if (!_streamController.isClosed) _streamController.add(_currentState);
    }
  }

  @visibleForTesting
  Future<void> runBatteryTest() async {
    if (!_currentState.isTesting) return;
    _updateTestState(
      'batteryInfo',
      TestStatus.running,
      "Verificando bateria...",
    );
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      String stateStr = "Desconhecido";
      bool isCharging = false;
      if (state == BatteryState.charging) {
        stateStr = "Carregando";
        isCharging = true;
      } else if (state == BatteryState.discharging) {
        stateStr = "Descarregando";
      } else if (state == BatteryState.full) {
        stateStr = "Cheia";
      }

      String warning = "";
      if (level < 20 && state != BatteryState.charging) {
        warning = "\n⚠️ Bateria baixa! O Wi-Fi pode perder potência.";
      }

      // Atualizar com dados estruturados para a UI poder ler
      final resultText = "Nível: $level%\nEstado: $stateStr$warning";
      _updateTestState(
        'batteryInfo',
        TestStatus.success,
        {
          'batteryLevel': level,
          'isCharging': isCharging,
          'stateStr': stateStr,
          'displayText': resultText,
        },
        metrics: {
          'batteryLevel': level,
          'isCharging': isCharging,
          'state': stateStr,
        },
      );
    } catch (e) {
      _updateTestState(
        'batteryInfo',
        TestStatus.error,
        "Erro ao ler bateria: $e",
      );
    }
  }

  @visibleForTesting
  Future<void> runLanScanTest() async {
    if (!_currentState.isTesting) return;
    _updateTestState(
      'lanScan',
      TestStatus.running,
      "Escaneando rede local (pode demorar)...",
    );
    try {
      final String? ip = await _networkInfo.getWifiIP();
      final lastDot = ip?.lastIndexOf('.') ?? -1;
      if (ip == null || lastDot <= 0) {
        _updateTestState(
          'lanScan',
          TestStatus.error,
          "Não foi possível obter o IP para escanear.",
        );
        return;
      }
      final String subnet = ip.substring(0, lastDot);
      final hostCount = await _lanScanner.countActiveHosts(subnet);

      if (!_currentState.isTesting) return;
      _updateTestState(
        'lanScan',
        TestStatus.success,
        "Dispositivos encontrados: $hostCount\n(Na sub-rede $subnet.x)",
      );
    } catch (e) {
      if (!_currentState.isTesting) return;
      _updateTestState('lanScan', TestStatus.error, "Erro no scanner: $e");
    }
  }

  @visibleForTesting
  Future<void> runDeviceInfoTest() async {
    if (!_currentState.isTesting) return;
    _updateTestState('deviceInfo', TestStatus.running, "Coletando...");
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
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
        connectionType = "VPN";
        _updateStatus("VPN (Pode afetar a velocidade!)");
      }

      final packageInfo = _packageInfo ?? await PackageInfo.fromPlatform();
      final appVersion =
          "v${packageInfo.version} (Build ${packageInfo.buildNumber})";
      final deviceInfo = _deviceInfo;
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
      _updateTestState(
        'deviceInfo',
        TestStatus.error,
        "Erro ao obter dados do dispositivo.",
      );
    }
  }

  @visibleForTesting
  Future<void> runIpTest() async {
    if (!_currentState.isTesting) return;
    _updateTestState('publicIp', TestStatus.running, "Buscando IPv4 e IPv6...");
    try {
      String ipV4 = "N/A";
      String org = "N/A";
      String ipV6 = "Não detectado";

      try {
        final response = await client
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
          final responseV6 = await client
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
        _updateTestState(
          'publicIp',
          TestStatus.success,
          'IPv4: $ipV4\nIPv6: $ipV6\nProvedor: $org',
        );
      } else {
        _updateTestState(
          'publicIp',
          TestStatus.error,
          'Falha ao conectar aos servidores de IP.',
        );
      }
    } catch (e) {
      if (!_currentState.isTesting) return;
      _updateTestState('publicIp', TestStatus.error, 'Erro: ${e.toString()}');
    }
  }

  Future<bool> _requestLocationPermission() async {
    if (!Platform.isAndroid) return true;
    var status = await Permission.location.request();
    if (!status.isGranted) {
      final ctx = context;
      if (ctx != null && ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text(
              'Permita a localização para o app ler o nome e o sinal do Wi-Fi.',
            ),
          ),
        );
      }
      return false;
    }
    return true;
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

  @visibleForTesting
  Future<void> runOnuTest() async {
    if (!_currentState.isTesting || onuService == null) return;
    _updateTestState(
      'onuInfo',
      TestStatus.running,
      "Verificando sinal da Fibra Óptica (ONU)...",
    );
    try {
      final onuData = await onuService!.fetchOnuSignal();

      // Return data as Map for diagnostic pages to properly display
      final resultMap = {
        'rxPower': onuData.signalRx,
        'txPower': onuData.signalTx,
        'temperature': onuData.temperature,
        'voltage': onuData.voltage,
        'isOnline': onuData.isOnline,
        'status': onuData.connectionStatus,
        'model': onuData.model,
        'serialNumber': onuData.serialNumber,
        'oltName': onuData.oltName,
        'slot': onuData.slot,
        'pon': onuData.pon,
        'onuId': onuData.onuId,
        'signalQuality': onuData.signalQuality,
        'mode': onuData.mode,
        'vlan': onuData.vlan,
        'cto': onuData.cto,
        'lastUpdate': onuData.lastUpdate,
      };

      _updateTestState('onuInfo', TestStatus.success, resultMap);
    } catch (e) {
      // Se falhar o remoto, não é crítico, apenas avisamos
      // _updateTestState('onuInfo', TestStatus.error, "Erro ONU: $e");
      // Mas para UX, talvez seja melhor mostrar aviso
      _updateTestState(
        'onuInfo',
        TestStatus.error,
        "Falha ao obter dados da ONU:\n${e.toString().replaceAll('Exception:', '').trim()}",
      );
    }
  }

  @visibleForTesting
  Future<void> runTracerouteTest() async {
    if (!_currentState.isTesting) return;
    _updateTestState(
      'traceroute',
      TestStatus.running,
      "Iniciando Rastreamento de Rota (Tracert)...",
    );

    const target = '8.8.8.8';

    try {
      final trace =
          await TracerouteService(client).run(providerConfig.apiUrl, target);
      final hopsData = trace.hops;

      if (hopsData.isNotEmpty) {
        List<String> hops = [];
        for (final hop in hopsData) {
          final hopNum = hop['hop'];
          final ip = hop['ip'] ?? '*';
          final time = hop['time'] ?? '*';
          hops.add("$hopNum: $ip ($time)");
        }
        _updateTestState('traceroute', TestStatus.success, hops.join('\n'),
            metrics: {
              'origin': 'server',
              'reached': trace.reached,
              'timedOut': trace.timedOut
            });
      } else {
        _updateTestState(
          'traceroute',
          TestStatus.error,
          "Nenhum resultado de traceroute recebido.",
        );
      }
    } catch (e) {
      if (!_currentState.isTesting) return;
      _updateTestState(
        'traceroute',
        TestStatus.error,
        "Erro no Tracert: ${e.toString().replaceAll('Exception:', '').trim()}",
      );
    }
  }

  @visibleForTesting
  Future<void> runWifiTest() async {
    if (!_currentState.isTesting) return;
    _updateTestState(
      'wifiInfo',
      TestStatus.running,
      "Buscando dados de WiFi/DNS...",
    );

    // Se temos serviço remoto e permissão, tentamos buscar dados do roteador também
    List<WifiNetwork>? remoteNetworks;
    if (onuService != null) {
      try {
        remoteNetworks = await onuService!.fetchWifiNetworks();
      } catch (_) {
        // Ignora erro remoto aqui, foca no local first
      }
    }

    try {
      String? wifiName = (await _networkInfo.getWifiName())?.replaceAll(
        "\"",
        "",
      );
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
            "ALERTA: Falha ao chamar o MethodChannel 'getWifiDetails'. O código nativo pode estar faltando. $e",
          );
        }
      }

      try {
        final stopwatch = Stopwatch()..start();
        await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        stopwatch.stop();
        dnsTimeMs = stopwatch.elapsedMilliseconds;
      } catch (_) {
        dnsTimeMs = -1;
      }

      String resultString =
          "SSID: ${wifiName ?? 'N/A'}\nFrequência: $wifiFrequencyBand\nForça do Sinal: $wifiSignalStrength\nBSSID: ${wifiBSSID ?? 'N/A'}\nIP Dispositivo: ${wifiIPv4 ?? 'N/A'}\nGateway (Roteador): ${wifiGatewayIP ?? 'N/A'}\nServidores DNS:\n$dnsServers\nTempo DNS: ${dnsTimeMs >= 0 ? '$dnsTimeMs ms' : 'Falha'}";

      String? remoteChannel;
      String? remoteSecurity;

      // Append Remote info if available
      if (remoteNetworks != null && remoteNetworks.isNotEmpty) {
        final mySsid = wifiName;
        // Find matching remote network
        final match = remoteNetworks.firstWhere(
          (n) => n.ssid == mySsid,
          orElse: () => WifiNetwork(
            id: '',
            ssid: '',
            frequency: '',
            enabled: false,
          ),
        );
        if (match.id.isNotEmpty) {
          resultString +=
              "\n\n[Roteador Remoto]\nSSID: ${match.ssid}\nFreq: ${match.frequency}";
          if (match.channel != null) {
            resultString += "\nCanal: ${match.channel}";
            remoteChannel = match.channel;
          }
          if (match.security != null) {
            resultString += "\nSegurança: ${match.security}";
            remoteSecurity = match.security;
          }
        }
      }

      final resultMap = {
        'ssid': wifiName ?? 'N/A',
        'frequency': wifiFrequencyBand,
        'signalStrength': wifiSignalStrength,
        'bssid': wifiBSSID ?? 'N/A',
        'ip': wifiIPv4 ?? 'N/A',
        'gateway': wifiGatewayIP ?? 'N/A',
        'dns': dnsServers,
        'dnsTime': dnsTimeMs,
        'channel': remoteChannel ?? 'N/A',
        'security': remoteSecurity ?? 'N/A',
        'display': resultString // Legacy string support
      };

      _updateTestState('wifiInfo', TestStatus.success, resultMap);
    } catch (e) {
      if (!_currentState.isTesting) return;
      _updateTestState(
        'wifiInfo',
        TestStatus.error,
        'Erro ao obter informações: ${e.toString()}',
      );
    }
  }

  @visibleForTesting
  Future<void> runPingGatewayTest() async {
    if (!_currentState.isTesting) return;
    _updateTestState(
      'pingGateway',
      TestStatus.running,
      "Aguardando IP do Roteador...",
    );
    final String? gatewayIp =
        _currentState.testResultsDisplay['wifiInfo']?['gatewayIp'] as String?;
    if (gatewayIp != null && gatewayIp.isNotEmpty) {
      _updateStatus("Testando ping para o Roteador ($gatewayIp)...");
      // Use 10 pings + discardFirst for router
      await runPingTest(
        gatewayIp,
        'pingGateway',
        count: 10,
        discardFirst: true,
      );
    } else {
      if (_currentState.isTesting &&
          _currentState.testResultsDisplay['pingGateway']?['status'] !=
              TestStatus.error) {
        _updateTestState(
          'pingGateway',
          TestStatus.error,
          'Não foi possível obter IP do roteador no teste WiFi.',
        );
      }
    }
  }

  Future<bool> _tryRunOoklaServer(
    OoklaServer server, {
    required bool isReference,
  }) async {
    if (!_currentState.isTesting) return false;
    final token = OoklaCancelToken();
    _ooklaCancel = token;
    final testKey = isReference ? 'speedTestFast' : 'speedTestCustom';

    if (isReference) {
      _fastDownloadHistoryCounter = 0;
      _fastUploadHistoryCounter = 0;
      _fastPeakDownloadMbps = 0;
      _fastPeakUploadMbps = 0;
      _currentState = _currentState.copyWith(
        fastDownloadHistory: [],
        fastUploadHistory: [],
        speedTestReferenceServerName: server.displayName,
      );
    } else {
      _downloadHistoryCounter = 0;
      _uploadHistoryCounter = 0;
      _customPeakDownloadMbps = 0;
      _customPeakUploadMbps = 0;
      _currentState = _currentState.copyWith(
        downloadHistory: [],
        uploadHistory: [],
        speedTestServerName: server.displayName,
      );
    }
    _streamController.add(_currentState);

    _updateStatus(
      'Conectado ao Speedtest: ${server.displayName}'
      '${server.latencyMs.isFinite ? ' (${server.latencyMs.round()} ms)' : ''}...',
    );

    try {
      final result = await _ooklaSpeedTest.runSpeedTest(
        server: server,
        cancelToken: token,
        onProgress: (percent, mbps, isUpload) {
          if (!_currentState.isTesting || token.isCancelled) return;
          _updateStatus(
            '${isUpload ? 'Testando Upload' : 'Testando Download'} '
            '(${server.displayName})... '
            '${mbps.toStringAsFixed(1)} Mbps (${percent.round()}%)',
          );
          if (isReference) {
            if (!isUpload) {
              if (mbps > _fastPeakDownloadMbps) _fastPeakDownloadMbps = mbps;
              final hist = List<FlSpot>.from(_currentState.fastDownloadHistory);
              if (hist.length >= 120) hist.removeAt(0);
              hist.add(FlSpot(_fastDownloadHistoryCounter.toDouble(), mbps));
              _fastDownloadHistoryCounter++;
              _currentState = _currentState.copyWith(
                fastDownloadHistory: hist,
                fastDownloadResultMbps: mbps,
              );
            } else {
              if (mbps > _fastPeakUploadMbps) _fastPeakUploadMbps = mbps;
              final hist = List<FlSpot>.from(_currentState.fastUploadHistory);
              if (hist.length >= 120) hist.removeAt(0);
              hist.add(FlSpot(_fastUploadHistoryCounter.toDouble(), mbps));
              _fastUploadHistoryCounter++;
              _currentState = _currentState.copyWith(
                fastUploadHistory: hist,
                fastUploadResultMbps: mbps,
              );
            }
          } else {
            if (!isUpload) {
              if (mbps > _customPeakDownloadMbps) _customPeakDownloadMbps = mbps;
              final hist = List<FlSpot>.from(_currentState.downloadHistory);
              if (hist.length >= 120) hist.removeAt(0);
              hist.add(FlSpot(_downloadHistoryCounter.toDouble(), mbps));
              _downloadHistoryCounter++;
              _currentState = _currentState.copyWith(
                downloadHistory: hist,
                customDownloadResultMbps: mbps,
              );
            } else {
              if (mbps > _customPeakUploadMbps) _customPeakUploadMbps = mbps;
              final hist = List<FlSpot>.from(_currentState.uploadHistory);
              if (hist.length >= 120) hist.removeAt(0);
              hist.add(FlSpot(_uploadHistoryCounter.toDouble(), mbps));
              _uploadHistoryCounter++;
              _currentState = _currentState.copyWith(
                uploadHistory: hist,
                customUploadResultMbps: mbps,
              );
            }
          }
          _streamController.add(_currentState);
        },
      );

      if (!_currentState.isTesting || token.isCancelled) return true;
      if (result.downloadMbps <= 0 && result.uploadMbps <= 0) {
        return false;
      }

      var lat = result.latencyMs;
      if (lat <= 0) {
        lat = _extractLatencyFromResult(
          _currentState.testResultsDisplay['pingGoogle']?['result'],
        );
      }

      _updateTestState(
        testKey,
        TestStatus.success,
        'Download: ${result.downloadMbps.toStringAsFixed(1)} Mbps\n'
        'Upload: ${result.uploadMbps.toStringAsFixed(1)} Mbps\n'
        'Ping: ${lat.toStringAsFixed(0)} ms\n'
        'Servidor: ${server.displayName}',
      );

      if (isReference) {
        _currentState = _currentState.copyWith(
          fastDownloadResultMbps: result.downloadMbps,
          fastUploadResultMbps: result.uploadMbps,
          speedTestReferenceServerName: server.displayName,
        );
      } else {
        _currentState = _currentState.copyWith(
          customDownloadResultMbps: result.downloadMbps,
          customUploadResultMbps: result.uploadMbps,
          speedTestPingLatency: lat > 0 ? lat : _currentState.speedTestPingLatency,
          speedTestServerName: server.displayName,
        );
      }
      _streamController.add(_currentState);
      return true;
    } catch (_) {
      return token.isCancelled;
    } finally {
      if (identical(_ooklaCancel, token)) _ooklaCancel = null;
    }
  }

  @visibleForTesting
  Future<void> runSpeedTestCustom() async {
    if (!_currentState.isTesting) return;
    String? customUrl = providerConfig.config.other?.speedTestUrl;

    if (!OoklaSpeedtestService.isExplicitNonOoklaUrl(customUrl)) {
      _updateTestState(
        'speedTestCustom',
        TestStatus.running,
        'Localizando servidor Speedtest mais próximo...',
      );
      final discoveryToken = OoklaCancelToken();
      _ooklaCancel = discoveryToken;
      OoklaServerPlan? plan;
      try {
        plan = await _ooklaSpeedTest.discoverAndSelect(
          client: client,
          providerName: providerConfig.name,
          providerId: providerConfig.id,
          configuredUrl: customUrl,
          cancelToken: discoveryToken,
        );
      } finally {
        if (identical(_ooklaCancel, discoveryToken)) _ooklaCancel = null;
      }
      if (!_currentState.isTesting || discoveryToken.isCancelled) return;
      if (plan != null) {
        _activeOoklaPlan = plan;
        final ok = await _tryRunOoklaServer(plan.primary, isReference: false);
        if (ok || !_currentState.isTesting) return;
      }
    }

    // Fallback: URL customizada explícita (não-Ookla) ou servidor próprio /speedtest/.
    String defaultSpeedTestUrl =
        'https://librespeed.org'; // Fallback of fallback
    try {
      final apiUri = Uri.parse(providerConfig.apiUrl);
      if (apiUri.host.isNotEmpty) {
        // Caminho público estável, independente da porta interna.
        defaultSpeedTestUrl =
            '${apiUri.scheme}://${apiUri.authority}/speedtest/';
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

    _updateTestState(
      'speedTestCustom',
      TestStatus.running,
      "Iniciando teste (Servidor Próprio)...",
    );

    String serverLimitNote = '';
    try {
      final base = Uri.parse(customUrl);
      final capabilitiesUrl = base.replace(
          path: '${base.path.replaceAll(RegExp(r"/+$"), "")}/capabilities',
          query: '');
      final response =
          await client.get(capabilitiesUrl).timeout(const Duration(seconds: 3));
      final capabilities = jsonDecode(response.body);
      if (capabilities is Map && capabilities['maxMbps'] is num) {
        serverLimitNote =
            '\nServidor compartilhado: até ${capabilities["maxMbps"]} Mbps. O resultado não comprova a velocidade total do plano.';
      }
    } catch (_) {/* Servidores externos podem não publicar capacidades. */}
    if (!_currentState.isTesting) return;

    final completer = Completer<void>();
    _downloadHistoryCounter = 0;
    _uploadHistoryCounter = 0;
    _customPeakDownloadMbps = 0;
    _customPeakUploadMbps = 0;
    _currentState = _currentState.copyWith(
      downloadHistory: [],
      uploadHistory: [],
    );
    _streamController.add(_currentState);

    // Timer de segurança
    Timer? maxDurationTimer;

    void cancelTimer() {
      maxDurationTimer?.cancel();
    }

    void cancelSpeedTest() {
      cancelTimer();
      if (!completer.isCompleted) completer.complete();
    }

    _cancelSpeedTest = cancelSpeedTest;

    try {
      // 0. Latency Check to Custom Server
      double customLatency = 0;
      try {
        final uri = Uri.parse(customUrl);
        final pingHost = uri.host;
        if (pingHost.isNotEmpty) {
          _updateStatus("Medindo latência para $pingHost...");
          final ping = _pingFactory.create(
            pingHost,
            count: 3,
            timeout: const Duration(seconds: 1),
          );
          final pingCompleter = Completer<void>();
          double totalTime = 0;
          int successCount = 0;
          late final StreamSubscription<PingData> pingSub;
          pingSub = ping.stream.listen(
            (event) {
              if (event.response != null && event.response!.time != null) {
                totalTime += event.response!.time!.inMilliseconds;
                successCount++;
              }
            },
            onDone: () {
              if (!pingCompleter.isCompleted) pingCompleter.complete();
            },
            onError: (_) {
              if (!pingCompleter.isCompleted) pingCompleter.complete();
            },
          );
          final pingTimeout = Timer(const Duration(seconds: 5), () {
            pingSub.cancel();
            ping.stop();
            if (!pingCompleter.isCompleted) pingCompleter.complete();
          });
          void cancelLatencyPing() {
            pingSub.cancel();
            ping.stop();
            if (!pingCompleter.isCompleted) pingCompleter.complete();
          }

          _cancelPing = cancelLatencyPing;
          try {
            await pingCompleter.future;
          } finally {
            pingTimeout.cancel();
            await pingSub.cancel();
            ping.stop();
            if (identical(_cancelPing, cancelLatencyPing)) _cancelPing = null;
          }
          if (!_currentState.isTesting) return;
          if (successCount > 0) {
            customLatency = totalTime / successCount;
            _updateStatus(
              "Latência medida: ${customLatency.toStringAsFixed(1)} ms",
            );
          }
        }
      } catch (e) {
        // Ignorar erro de ping no debug
      }

      if (!_currentState.isTesting) return;

      // 1. Timer de segurança apenas (60s para garantir que complete todo o teste)
      maxDurationTimer = Timer(const Duration(seconds: 60), () {
        if (!completer.isCompleted && _currentState.isTesting) {
          if (_lanScanner is NetworkToolsLocalScanner) _lanScanner.cancel();
          _cancelPing?.call();
          _cancelPing = null;
          internetSpeedTest.cancelTest();
          // Se temos dados, usar como resultado final
          if (_customPeakDownloadMbps > 0) {
            _updateTestState(
              'speedTestCustom',
              TestStatus.success,
              "Download: ${_customPeakDownloadMbps.toStringAsFixed(1)} Mbps\nUpload: ${_customPeakUploadMbps.toStringAsFixed(1)} Mbps",
            );
          } else {
            _updateTestState(
              'speedTestCustom',
              TestStatus.error,
              "Tempo limite atingido.",
            );
          }
          if (!completer.isCompleted) completer.complete();
        }
      });

      internetSpeedTest.startTesting(
        downloadTestServer: customUrl,
        uploadTestServer: customUrl,
        fileSizeInBytes: 5000000, // 5MB - Teste rápido
        onStarted: () {
          if (!_currentState.isTesting) {
            if (_lanScanner is NetworkToolsLocalScanner) _lanScanner.cancel();
            _cancelPing?.call();
            _cancelPing = null;
            internetSpeedTest.cancelTest();
            cancelSpeedTest();
            return;
          }
          _updateStatus("Testando Download (Servidor Personalizado)...");
        },
        onCancel: cancelSpeedTest,
        onCompleted: (TestResult download, TestResult upload) {
          cancelTimer();
          if (!_currentState.isTesting) {
            if (!completer.isCompleted) completer.complete();
            return;
          }
          final downloadMbps = download.transferRate;
          final uploadMbps = upload.transferRate;

          // Usar latência customizada se disponível
          double latencia = customLatency;
          if (latencia == 0) {
            latencia = _extractLatencyFromResult(
              _currentState.testResultsDisplay['pingGoogle']?['result'],
            );
          }
          if (latencia == 0) {
            latencia = _extractLatencyFromResult(
              _currentState.testResultsDisplay['pingCloudflare']?['result'],
            );
          }

          _updateTestState(
            'speedTestCustom',
            TestStatus.success,
            "Download: ${downloadMbps.toStringAsFixed(1)} Mbps\nUpload: ${uploadMbps.toStringAsFixed(1)} Mbps\nPing: ${latencia.toStringAsFixed(0)} ms$serverLimitNote",
          );

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

          if (isDownload) {
            _updateStatus(
              "Testando Download... ${rate.toStringAsFixed(1)} Mbps (${percent.toStringAsFixed(0)}%)",
            );
            if (rate > _customPeakDownloadMbps) _customPeakDownloadMbps = rate;
            final newHistory = List<FlSpot>.from(_currentState.downloadHistory);
            if (newHistory.length >= 120) newHistory.removeAt(0);
            newHistory.add(FlSpot(_downloadHistoryCounter.toDouble(), rate));
            _downloadHistoryCounter++;
            _currentState = _currentState.copyWith(
              downloadHistory: newHistory,
              customDownloadResultMbps: rate,
            );
          } else {
            _updateStatus(
              "Testando Upload... ${rate.toStringAsFixed(1)} Mbps (${percent.toStringAsFixed(0)}%)",
            );
            if (rate > _customPeakUploadMbps) _customPeakUploadMbps = rate;
            final newHistory = List<FlSpot>.from(_currentState.uploadHistory);
            if (newHistory.length >= 120) newHistory.removeAt(0);
            newHistory.add(FlSpot(_uploadHistoryCounter.toDouble(), rate));
            _uploadHistoryCounter++;
            _currentState = _currentState.copyWith(
              uploadHistory: newHistory,
              customUploadResultMbps: rate,
            );
          }
          _streamController.add(_currentState);
        },
        onError: (String errorMessage, String speedTestError) {
          cancelTimer();
          if (!_currentState.isTesting) {
            if (!completer.isCompleted) completer.complete();
            return;
          }

          String cleanError = errorMessage;
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
      await completer.future;
    } catch (e) {
      cancelTimer();
      _updateTestState(
        'speedTestCustom',
        TestStatus.error,
        "Erro ao iniciar: $e",
      );
      if (!completer.isCompleted) completer.complete();
    } finally {
      cancelTimer();
      if (identical(_cancelSpeedTest, cancelSpeedTest)) {
        _cancelSpeedTest = null;
      }
    }
  }

  @visibleForTesting
  Future<void> runSpeedTestFastCom() async {
    if (!_currentState.isTesting) return;

    var reference = _activeOoklaPlan?.reference;
    if (reference == null && _activeOoklaPlan == null) {
      final token = OoklaCancelToken();
      _ooklaCancel = token;
      try {
        final plan = await _ooklaSpeedTest.discoverAndSelect(
          client: client,
          providerName: providerConfig.name,
          providerId: providerConfig.id,
          configuredUrl: providerConfig.config.other?.speedTestUrl,
          cancelToken: token,
        );
        _activeOoklaPlan = plan;
        reference = plan?.reference;
      } finally {
        if (identical(_ooklaCancel, token)) _ooklaCancel = null;
      }
      if (!_currentState.isTesting || token.isCancelled) return;
    }

    if (reference != null) {
      _updateTestState(
        'speedTestFast',
        TestStatus.running,
        'Conectando à referência (${reference.displayName})...',
      );
      final ok = await _tryRunOoklaServer(reference, isReference: true);
      if (ok || !_currentState.isTesting) return;
    }

    _updateTestState(
      'speedTestFast',
      TestStatus.running,
      "Iniciando teste (Fast.com)...",
    );
    final completer = Completer<void>();
    _fastDownloadHistoryCounter = 0;
    _fastUploadHistoryCounter = 0;
    _fastPeakDownloadMbps = 0;
    _fastPeakUploadMbps = 0;
    _currentState = _currentState.copyWith(
      fastDownloadHistory: [],
      fastUploadHistory: [],
    );
    _streamController.add(_currentState);

    // SAFETY TIMEOUT: Ensure test doesn't hang forever
    Timer? safeguardTimer;

    void cancelSpeedTest() {
      safeguardTimer?.cancel();
      if (!completer.isCompleted) completer.complete();
    }

    _cancelSpeedTest = cancelSpeedTest;

    try {
      safeguardTimer = Timer(const Duration(seconds: 45), () {
        if (!completer.isCompleted && _currentState.isTesting) {
          if (_lanScanner is NetworkToolsLocalScanner) _lanScanner.cancel();
          _cancelPing?.call();
          _cancelPing = null;
          internetSpeedTest.cancelTest();
          _updateTestState(
            'speedTestFast',
            TestStatus.error,
            "Tempo limite excedido (Fast.com).",
          );
          if (!completer.isCompleted) completer.complete();
        }
      });

      internetSpeedTest.startTesting(
        fileSizeInBytes: 5000000, // 5MB - Teste rápido
        onStarted: () {
          if (!_currentState.isTesting) {
            if (_lanScanner is NetworkToolsLocalScanner) _lanScanner.cancel();
            _cancelPing?.call();
            _cancelPing = null;
            internetSpeedTest.cancelTest();
            cancelSpeedTest();
            return;
          }
          _updateStatus("Testando Download (Fast.com)...");
        },
        onCancel: cancelSpeedTest,
        onCompleted: (TestResult download, TestResult upload) {
          safeguardTimer?.cancel();
          if (!_currentState.isTesting) {
            if (!completer.isCompleted) completer.complete();
            return;
          }
          final downloadMbps = download.transferRate;
          final uploadMbps = upload.transferRate;
          _updateTestState(
            'speedTestFast',
            TestStatus.success,
            "Download: ${downloadMbps.toStringAsFixed(1)} Mbps\nUpload: ${uploadMbps.toStringAsFixed(1)} Mbps",
          );
          _currentState = _currentState.copyWith(
            fastDownloadResultMbps: downloadMbps,
            fastUploadResultMbps: uploadMbps,
          );
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
              if (_lanScanner is NetworkToolsLocalScanner) _lanScanner.cancel();
              _cancelPing?.call();
              _cancelPing = null;
              internetSpeedTest.cancelTest();
              _updateTestState(
                'speedTestFast',
                TestStatus.error,
                "Teste travado (sem progresso).",
              );
              if (!completer.isCompleted) completer.complete();
            }
          });

          if (isDownload) {
            _updateStatus(
              "Testando Download (Fast.com)... ${rate.toStringAsFixed(1)} Mbps (${percent.toStringAsFixed(0)}%)",
            );
            if (rate > _fastPeakDownloadMbps) _fastPeakDownloadMbps = rate;
            final newHistory = List<FlSpot>.from(
              _currentState.fastDownloadHistory,
            );
            if (newHistory.length >= 120) newHistory.removeAt(0);
            newHistory.add(
              FlSpot(_fastDownloadHistoryCounter.toDouble(), rate),
            );
            _fastDownloadHistoryCounter++;
            _currentState = _currentState.copyWith(
              fastDownloadHistory: newHistory,
              fastDownloadResultMbps: rate,
            );
          } else {
            _updateStatus(
              "Testando Upload (Fast.com)... ${rate.toStringAsFixed(1)} Mbps (${percent.toStringAsFixed(0)}%)",
            );
            if (rate > _fastPeakUploadMbps) _fastPeakUploadMbps = rate;
            final newHistory = List<FlSpot>.from(
              _currentState.fastUploadHistory,
            );
            if (newHistory.length >= 120) newHistory.removeAt(0);
            newHistory.add(FlSpot(_fastUploadHistoryCounter.toDouble(), rate));
            _fastUploadHistoryCounter++;
            _currentState = _currentState.copyWith(
              fastUploadHistory: newHistory,
              fastUploadResultMbps: rate,
            );
          }
          _streamController.add(_currentState);
        },
        onError: (String errorMessage, String speedTestError) {
          safeguardTimer?.cancel();
          if (!_currentState.isTesting) {
            if (!completer.isCompleted) completer.complete();
            return;
          }
          _updateTestState(
            'speedTestFast',
            TestStatus.error,
            "Erro: $errorMessage",
          );
          if (!completer.isCompleted) completer.complete();
        },
      );
      await completer.future;
    } catch (e) {
      safeguardTimer?.cancel();
      _updateTestState(
        'speedTestFast',
        TestStatus.error,
        "Erro ao iniciar: $e",
      );
      if (!completer.isCompleted) completer.complete();
    } finally {
      safeguardTimer?.cancel();
      if (identical(_cancelSpeedTest, cancelSpeedTest)) {
        _cancelSpeedTest = null;
      }
    }
  }
}
