import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';
import 'package:app_provedor_unified/core/services/diagnostico_service.dart';
import 'package:app_provedor_unified/core/services/onu_wifi_service.dart';
import 'package:app_provedor_unified/core/models/provider_config.dart';
import 'package:app_provedor_unified/core/models/diagnostico_state.dart';
// Fix: singular

import 'diagnostico_service_test.mocks.dart';

@GenerateMocks([
  http.Client,
  Battery,
  NetworkInfo,
  Connectivity,
  LocalNetworkScanner,
  FlutterInternetSpeedTest,
  OnuWifiService,
  PingFactory,
  Ping,
])
void main() {
  late MockClient mockClient;
  late MockBattery mockBattery;
  late MockNetworkInfo mockNetworkInfo;
  late MockConnectivity mockConnectivity;
  late MockLocalNetworkScanner mockLanScanner;
  late MockFlutterInternetSpeedTest mockSpeedTest;
  late MockOnuWifiService mockOnuService;
  late MockPingFactory mockPingFactory;
  late MockPing mockPing;
  late DiagnosticoService service;

  const providerConfig = ProviderConfig(
    id: 'test-id',
    name: 'Test',
    apiUrl: 'http://test.api',
    config: ConfigSection(
      themeColor: '#000000',
      logoUrl: '',
      loginQuote: '',
      integrations: SgpIntegration(
        apiToken: 'token',
        appName: 'Test',
        sgpBaseUrl: 'http://sgp.test',
      ),
      faq: [],
      tips: [],
      supportContacts: [],
      imageCarousel: [],
    ),
    features: FeaturesSection(consumption: true, support: true),
    menuConfig: MenuConfig(order: [], items: {}),
  );

  setUp(() {
    mockClient = MockClient();
    mockBattery = MockBattery();
    mockNetworkInfo = MockNetworkInfo();
    mockConnectivity = MockConnectivity();
    mockLanScanner = MockLocalNetworkScanner();
    mockSpeedTest = MockFlutterInternetSpeedTest();
    mockOnuService = MockOnuWifiService();
    mockPingFactory = MockPingFactory();
    mockPing = MockPing();

    service = DiagnosticoService(
      providerConfig: providerConfig,
      client: mockClient,
      battery: mockBattery,
      networkInfo: mockNetworkInfo,
      connectivity: mockConnectivity,
      lanScanner: mockLanScanner,
      speedTest: mockSpeedTest,
      onuService: mockOnuService,
      pingFactory: mockPingFactory,
    );
  });

  group('DiagnosticoService', () {
    test('runBatteryTest updates state with battery level and state', () async {
      when(mockBattery.batteryLevel).thenAnswer((_) async => 85);
      when(mockBattery.batteryState)
          .thenAnswer((_) async => BatteryState.discharging);

      service.setTestingState(true);
      await service.runBatteryTest();

      expect(service.currentState.testResultsDisplay['batteryInfo']?['status'],
          TestStatus.success);
      final result = service.currentState.testResultsDisplay['batteryInfo']
          ?['result'] as Map<String, dynamic>;
      expect(result['batteryLevel'], 85);
      expect(result['stateStr'], 'Descarregando');
    });

    test('runDeviceInfoTest updates state with connection and device info',
        () async {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.wifi);

      final mockPackageInfo = PackageInfo(
        appName: 'TestApp',
        packageName: 'com.test',
        version: '1.0.0',
        buildNumber: '1',
      );

      service = DiagnosticoService(
        providerConfig: providerConfig,
        connectivity: mockConnectivity,
        packageInfo: mockPackageInfo,
      );

      service.setTestingState(true);
      await service.runDeviceInfoTest();

      expect(service.currentState.testResultsDisplay['deviceInfo']?['status'],
          TestStatus.success);
      expect(service.currentState.testResultsDisplay['deviceInfo']?['result'],
          contains('Conexão: WiFi'));
      expect(service.currentState.testResultsDisplay['deviceInfo']?['result'],
          contains('v1.0.0'));
    });

    test('runLanScanTest reports devices found by the scanner', () async {
      when(mockNetworkInfo.getWifiIP()).thenAnswer((_) async => '192.168.1.25');
      when(mockLanScanner.countActiveHosts('192.168.1'))
          .thenAnswer((_) async => 3);

      service.setTestingState(true);
      await service.runLanScanTest();

      expect(service.currentState.testResultsDisplay['lanScan']?['status'],
          TestStatus.success);
      expect(service.currentState.testResultsDisplay['lanScan']?['result'],
          contains('Dispositivos encontrados: 3'));
    });

    test('runPingTest handles success and calculates jitter', () async {
      const pingData1 =
          PingData(response: PingResponse(time: Duration(milliseconds: 10)));
      const pingData2 =
          PingData(response: PingResponse(time: Duration(milliseconds: 20)));

      when(mockPingFactory.create('8.8.8.8',
              count: anyNamed('count'),
              timeout: anyNamed('timeout'),
              interval: anyNamed('interval')))
          .thenReturn(mockPing);

      when(mockPing.stream)
          .thenAnswer((_) => Stream.fromIterable([pingData1, pingData2]));

      service.setTestingState(true);
      await service.runPingTest('8.8.8.8', 'pingGoogle', count: 2);

      final result = service.currentState.testResultsDisplay['pingGoogle']
          ?['result'] as String;
      expect(service.currentState.testResultsDisplay['pingGoogle']?['status'],
          TestStatus.success);
      expect(result, contains('Latência: 15ms'));
      expect(result, contains('Jitter: 10.0ms'));
      expect(result, contains('Perda: 0%'));
    });

    test('runPingTest handles total failure', () async {
      when(mockPingFactory.create('invalid',
              count: anyNamed('count'),
              timeout: anyNamed('timeout'),
              interval: anyNamed('interval')))
          .thenReturn(mockPing);

      when(mockPing.stream).thenAnswer((_) => Stream.fromIterable([]));

      service.setTestingState(true);
      await service.runPingTest('invalid', 'pingGoogle', count: 5);

      expect(service.currentState.testResultsDisplay['pingGoogle']?['status'],
          TestStatus.error);
      expect(service.currentState.testResultsDisplay['pingGoogle']?['result'],
          contains('Host inacessível'));
    });
  });
}
