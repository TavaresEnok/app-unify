import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:app_provedor_unified/core/services/onu_wifi_service.dart';

import 'onu_wifi_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late MockClient mockClient;
  late OnuWifiService service;

  setUp(() {
    mockClient = MockClient();
    service = OnuWifiService(
      apiUrl: 'http://test.api',
      cpfCnpj: '12345678900',
      sgpParams: {'sgpBaseUrl': 'http://sgp', 'token': 'abc', 'appName': 'app'},
      client: mockClient,
    );
  });

  group('OnuWifiService', () {
    test('fetchOnuSignal returns OnuData on success (200)', () async {
      final jsonResponse = {
        'data': {
          'connectionStatus': 'Online',
          'signalRx': -20.5,
          'signalTx': 2.5,
          'temperature': 40.0,
          'model': 'HG8245H',
          'oltId': 1,
          'slot': 1,
          'pon': 1,
          'onuId': 1,
          'isOnline': true
        }
      };

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(json.encode(jsonResponse), 200));

      final result = await service.fetchOnuSignal();

      expect(result.signalRx, -20.5);
      expect(result.model, 'HG8245H');
      expect(result.isOnline, true);
    });

    test('fetchWifiNetworks returns list on success', () async {
      final jsonResponse = {
        'data': [
          {'id': '1', 'ssid': 'Wifi A', 'frequency': '2.4GHz', 'enabled': true},
          {'id': '2', 'ssid': 'Wifi B', 'frequency': '5GHz', 'enabled': false},
        ]
      };

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(json.encode(jsonResponse), 200));

      final networks = await service.fetchWifiNetworks();

      expect(networks.length, 2);
      expect(networks[0].ssid, 'Wifi A');
      expect(networks[1].frequency, '5GHz');
    });

    test('updateWifi returns true on success', () async {
      final jsonResponse = {'success': true};

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(json.encode(jsonResponse), 200));

      final result = await service.updateWifi(
          wifiId: '1', ssid: 'New SSID', password: 'pass');

      expect(result, true);
    });

    test('fetchOnuSignal throws exception on 500', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      expect(service.fetchOnuSignal(), throwsException);
    });
  });
}
