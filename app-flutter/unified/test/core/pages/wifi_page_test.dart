import 'dart:async';
import 'dart:convert';

import 'package:app_provedor_unified/core/navigation/customer_shell_scope.dart';
import 'package:app_provedor_unified/core/pages/customer/connection_hub_page.dart';
import 'package:app_provedor_unified/core/providers/customer_capabilities_provider.dart';
import 'package:app_provedor_unified/core/providers/equipment_status_provider.dart';
import 'package:app_provedor_unified/core/providers/providers.dart';
import 'package:app_provedor_unified/core/services/session_token_store.dart';
import 'package:app_provedor_unified/core/services/tr069_service.dart';
import 'package:app_provedor_unified/core/theme/layout_tokens.dart';
import 'package:app_provedor_unified/layouts/layout_03/wifi_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../tool/capture_preview.dart';

String _jwt() {
  String part(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final exp =
      DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch ~/
          1000;
  return '${part({'alg': 'none'})}.${part({'sub': 'u', 'exp': exp})}.sig';
}

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json; charset=utf-8'});

Map<String, dynamic> _caps({bool deviceManaged = true}) => {
      'data': {
        'enabled': true,
        'deviceManaged': deviceManaged,
        'driver': 'sgp',
        'features': {'wifi': true, 'hosts': true},
      }
    };

Map<String, dynamic> _status() => {
      'data': {
        'online': null,
        'driver': 'sgp',
        'manufacturer': 'Intelbras',
        'model': 'NV21',
        'firmware': 'V7.0.1',
        'passwordReadable': false,
        'deviceManaged': true,
        'wifiNetworks': [
          {
            'id': '1-1',
            'ssid': 'Casa 5G',
            'band': '5GHz',
            'channel': '44',
            'enabled': true,
            'mode': 'ac'
          },
          for (var i = 2; i <= 5; i++)
            {'id': '1-$i', 'ssid': 'v$i', 'band': '5GHz', 'enabled': false},
          {
            'id': '1-6',
            'ssid': 'Casa',
            'band': '2.4GHz',
            'channel': '11',
            'enabled': true
          },
          for (var i = 7; i <= 10; i++)
            {'id': '1-$i', 'ssid': 'v$i', 'band': '2.4GHz', 'enabled': false},
        ],
        'hosts': [
          {'hostname': 'Notebook', 'mac': 'AA', 'interfaceType': 'wifi_2g'},
          {
            'hostname': 'AA:BB:CC:DD:EE:FF',
            'mac': 'AA:BB:CC:DD:EE:FF',
            'interfaceType': 'wifi_2g'
          },
        ],
        'fiber': {'online': true, 'rxPowerDbm': -19.3, 'source': 'snapshot'},
      }
    };

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR');
    SessionTokenStore.instance.setTokenForTest(_jwt());
  });
  tearDown(() => SessionTokenStore.instance.setTokenForTest(null));

  Future<List<String>> pumpWifi(
      WidgetTester tester, http.Response? Function(http.Request) reply,
      {List<String>? navigated}) async {
    final paths = <String>[];
    final client = MockClient((req) async {
      paths.add(req.url.path);
      final r = reply(req);
      if (r == null) return Completer<http.Response>().future;
      return r;
    });
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        configurationProvider.overrideWith((_) => DemoConfig('layout_02')),
        authNotifierProvider.overrideWith(DemoAuth.new),
        tr069ServiceFactoryProvider.overrideWithValue(
            (apiUrl) => Tr069Service(apiUrl: apiUrl, client: client)),
      ],
      child: MaterialApp(
        theme: LayoutTokens.of('layout_02').themeData(),
        home: Builder(
          builder: (context) => CustomerShellScope(
            frame: (_, page) => page,
            navigate: (route) => navigated?.add(route),
            child: const Scaffold(body: WifiPage()),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    return paths;
  }

  testWidgets('sem roteador gerenciado: aviso claro e botão do suporte',
      (tester) async {
    final navigated = <String>[];
    final paths = await pumpWifi(tester, (req) {
      if (req.url.path.endsWith('/tr069/capabilities')) {
        return _json(_caps(deviceManaged: false));
      }
      if (req.url.path.endsWith('/tr069/status')) {
        return _json({
          'error': {'message': 'Gerenciador CPE não definido'}
        }, 422);
      }
      return _json({}, 404);
    }, navigated: navigated);
    await tester.pumpAndSettle();
    expect(find.text('Seu roteador ainda não é gerenciado pelo app'),
        findsOneWidget);
    expect(find.text('Consultar novamente'), findsOneWidget,
        reason: 'só o botão do rodapé');
    expect(paths.where((p) => p.contains('cpe/wifi/list')), isEmpty);
    await tester.tap(find.text('Falar com o suporte'));
    await tester.pump();
    expect(navigated, ['support']);
  });

  testWidgets(
      'roteador gerenciado: uma leitura, redes ativas, fibra e aparelhos',
      (tester) async {
    final paths = await pumpWifi(tester, (req) {
      if (req.url.path.endsWith('/tr069/capabilities')) return _json(_caps());
      if (req.url.path.endsWith('/tr069/status')) return _json(_status());
      if (req.url.path.endsWith('/tr069/wifi')) return null; // nunca responde
      return _json({}, 404);
    });
    await tester.pumpAndSettle();

    // Só as duas redes ativas, com faixa, canal e geração.
    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Casa 5G'), findsOneWidget);
    expect(find.text('v2'), findsNothing);
    expect(find.text('Wi-Fi 5 GHz · Canal 44 · Wi-Fi 5 (ac)'), findsOneWidget);
    expect(find.text('8 redes desativadas do roteador não aparecem aqui.'),
        findsOneWidget);
    // Fibra e roteador sem "Online" inventado.
    expect(find.textContaining('Sinal -19,3 dBm (Excelente)'), findsOneWidget);
    expect(find.text('Roteador Intelbras NV21'), findsOneWidget);
    expect(find.textContaining('Dados da última leitura do roteador'),
        findsOneWidget);
    // Aparelhos vieram no status: nada de segunda chamada.
    expect(find.text('Aparelho sem nome'), findsOneWidget);
    expect(find.text('AA:BB:CC:DD:EE:FF'), findsNothing);
    expect(paths.where((p) => p.endsWith('/tr069/hosts')), isEmpty);
    expect(paths.where((p) => p.endsWith('/tr069/status')), hasLength(1));
    expect(paths.where((p) => p.contains('cpe/wifi/list')), isEmpty);

    // Roteador que não informa a senha: o campo é obrigatório.
    await tester.tap(find.text('Casa'));
    await tester.pumpAndSettle();
    expect(find.text('Senha do Wi-Fi'), findsOneWidget);
    expect(find.textContaining('Deixe em branco'), findsNothing);
    await tester.tap(find.text('Salvar alterações'));
    await tester.pump();
    expect(find.text('Digite a senha do Wi-Fi (a atual ou uma nova).'),
        findsOneWidget);
    expect(paths.where((p) => p.endsWith('/tr069/wifi')), isEmpty);

    // Roteador demorando: mensagem amigável e envio travado por 1 minuto.
    await tester.enterText(find.byType(TextField).last, 'senhaforte1');
    await tester.tap(find.text('Salvar alterações'));
    await tester.pump();
    expect(find.text('Enviando ao roteador…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 46));
    expect(find.text(Tr069Service.slowRouterMessage), findsOneWidget);
    expect(find.text('Aguarde 1 minuto para tentar de novo'), findsOneWidget);
    await tester.tap(find.text('Aguarde 1 minuto para tentar de novo'));
    await tester.pump();
    expect(paths.where((p) => p.endsWith('/tr069/wifi')), hasLength(1));
    // Sair e voltar para a mesma rede não libera o envio antes do prazo.
    Navigator.of(tester.element(find.text('Alterar rede Wi-Fi'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Casa'));
    await tester.pumpAndSettle();
    expect(find.text('Aguarde 1 minuto para tentar de novo'), findsOneWidget);
    await tester.pump(const Duration(seconds: 61));
    expect(find.text('Salvar alterações'), findsOneWidget);
  });

  testWidgets('disponibilidade do Wi-Fi segue o deviceManaged do servidor',
      (tester) async {
    for (final (managed, expected) in [(false, false), (true, true)]) {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(overrides: [
        configurationProvider.overrideWith((_) => DemoConfig('layout_02')),
        authNotifierProvider.overrideWith(DemoAuth.new),
        tr069ServiceFactoryProvider.overrideWithValue((apiUrl) => Tr069Service(
            apiUrl: apiUrl,
            client:
                MockClient((_) async => _json(_caps(deviceManaged: managed))))),
      ]);
      addTearDown(container.dispose);
      await container.read(authNotifierProvider.future);
      final value = await tester.runAsync(
          () => container.read(wifiManagementAvailableProvider.future));
      expect(value, expected);
    }
  });

  testWidgets('Conexão mostra o cartão "Seu equipamento"', (tester) async {
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/tr069/capabilities')) return _json(_caps());
      if (req.url.path.endsWith('/tr069/status')) return _json(_status());
      return _json({}, 404);
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        configurationProvider.overrideWith((_) => DemoConfig('layout_02')),
        authNotifierProvider.overrideWith(DemoAuth.new),
        wifiManagementAvailableProvider.overrideWith((_) async => true),
        tr069ServiceFactoryProvider.overrideWithValue(
            (apiUrl) => Tr069Service(apiUrl: apiUrl, client: client)),
      ],
      child: MaterialApp(
        theme: LayoutTokens.of('layout_02').themeData(),
        home: const Scaffold(body: ConnectionHubPage(onNavigate: _ignore)),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Seu equipamento'), findsOneWidget);
    expect(find.textContaining('Sinal -19,3 dBm'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget,
        reason: 'só a fibra tem estado ao vivo; o roteador não ganha selo');
  });

  testWidgets('Conexão sem gerenciador não mostra o cartão', (tester) async {
    final client = MockClient((req) async => _json({
          'data': {'enabled': false, 'driver': 'none'}
        }));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        configurationProvider.overrideWith((_) => DemoConfig('layout_02')),
        authNotifierProvider.overrideWith(DemoAuth.new),
        wifiManagementAvailableProvider.overrideWith((_) async => false),
        tr069ServiceFactoryProvider.overrideWithValue(
            (apiUrl) => Tr069Service(apiUrl: apiUrl, client: client)),
      ],
      child: MaterialApp(
        theme: LayoutTokens.of('layout_02').themeData(),
        home: const Scaffold(body: ConnectionHubPage(onNavigate: _ignore)),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Seu equipamento'), findsNothing);
    expect(find.text('Minha rede Wi-Fi'), findsNothing);
  });
}

void _ignore(String route) {}
