import 'dart:convert';

import 'package:app_provedor_unified/core/providers/configuration_provider.dart';
import 'package:app_provedor_unified/core/services/provider_config_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _apiConfig = {
  'id': 'vibe',
  'name': 'Vibe Telecom',
  'layoutType': 'layout_05',
  'themeColor': '#112233',
  'config': {
    'faq': [
      {'id': '1', 'question': 'Q', 'answer': 'A'}
    ]
  },
};

MockClient _client(List<Uri> calls, http.Response Function(Uri) reply) =>
    MockClient((request) async {
      calls.add(request.url);
      return reply(request.url);
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('carrega pela API e usa a URL que respondeu como apiUrl', () async {
    final calls = <Uri>[];
    var firestoreCalls = 0;
    final provider = ConfigurationProvider(
      api: ProviderConfigApi(
          client: _client(calls,
              (_) => http.Response(jsonEncode({'data': _apiConfig}), 200))),
      apiBaseUrl: 'https://appisp.com.br/api/',
      firestoreLoader: (_) async {
        firestoreCalls++;
        return null;
      },
    );

    await provider.loadConfig('vibe');

    expect(calls.single.toString(),
        'https://appisp.com.br/api/public/providers/vibe/config');
    expect(firestoreCalls, 0);
    expect(provider.errorMessage, isNull);
    expect(provider.providerConfig!.name, 'Vibe Telecom');
    expect(provider.providerConfig!.layoutType, 'layout_05');
    expect(provider.providerConfig!.apiUrl, 'https://appisp.com.br/api');
    expect(provider.providerConfig!.config.faq.single.question, 'Q');

    final cached = (await SharedPreferences.getInstance())
        .getString('provider_config_vibe');
    expect(jsonDecode(cached!)['apiUrl'], 'https://appisp.com.br/api');
  });

  test('cai no Firestore quando a API falha ou responde fora do formato',
      () async {
    for (final reply in [
      http.Response('<html>502 Bad Gateway</html>', 502),
      http.Response('<html>ok</html>', 200),
      http.Response(jsonEncode({'data': 'texto'}), 200),
    ]) {
      final provider = ConfigurationProvider(
        api: ProviderConfigApi(client: _client([], (_) => reply)),
        apiBaseUrl: 'https://appisp.com.br/api',
        firestoreLoader: (_) async => {
          'name': 'Do Firestore',
          'apiUrl': 'https://legado.example/api'
        },
      );

      await provider.loadConfig('vibe');

      expect(provider.providerConfig!.name, 'Do Firestore');
      expect(provider.providerConfig!.apiUrl, 'https://legado.example/api');
    }
  });

  test('sem URL gravada, tenta a apiUrl do cache antes do Firestore', () async {
    SharedPreferences.setMockInitialValues({
      'provider_config_vibe':
          jsonEncode({'name': 'Cache', 'apiUrl': 'https://cache.example/api'}),
    });
    final calls = <Uri>[];
    final provider = ConfigurationProvider(
      api: ProviderConfigApi(
          client: _client(calls,
              (_) => http.Response(jsonEncode({'data': _apiConfig}), 200))),
      apiBaseUrl: '',
      firestoreLoader: (_) async => fail('não deveria ler o Firestore'),
    );

    await provider.loadConfig('vibe');

    expect(calls.single.host, 'cache.example');
    expect(provider.providerConfig!.name, 'Vibe Telecom');
  });

  test('mantém o cache quando API e Firestore falham', () async {
    SharedPreferences.setMockInitialValues({
      'provider_config_vibe': jsonEncode({'name': 'Cache'}),
    });
    final provider = ConfigurationProvider(
      api: ProviderConfigApi(
          client: _client([], (_) => throw http.ClientException('offline'))),
      apiBaseUrl: 'https://appisp.com.br/api',
      firestoreLoader: (_) async =>
          throw Exception('permission-denied (regras novas)'),
    );

    await provider.loadConfig('vibe');

    expect(provider.providerConfig!.name, 'Cache');
    expect(provider.errorMessage, isNull);
    expect(provider.isLoading, isFalse);
  });

  test('ProviderConfigApi recusa URLs que não são http(s)', () async {
    final calls = <Uri>[];
    final api = ProviderConfigApi(
        client: _client(calls, (_) => http.Response('{}', 200)));
    expect(await api.fetch('file:///etc', 'vibe'), isNull);
    expect(await api.fetch('javascript:alert(1)', 'vibe'), isNull);
    expect(calls, isEmpty);
  });
}
