import 'dart:async';
import 'dart:convert';

import 'package:app_provedor_unified/core/models/provider_config.dart';
import 'package:app_provedor_unified/core/navigation/customer_routes.dart';
import 'package:app_provedor_unified/core/pages/shared_contrato_page.dart';
import 'package:app_provedor_unified/core/pages/shared_notification_page.dart';
import 'package:app_provedor_unified/core/pages/unified_login_page.dart';
import 'package:app_provedor_unified/core/providers/configuration_provider.dart';
import 'package:app_provedor_unified/core/providers/connectivity_provider.dart';
import 'package:app_provedor_unified/core/services/deep_link_service.dart';
import 'package:app_provedor_unified/core/services/provider_config_api.dart';
import 'package:app_provedor_unified/core/services/push_notification_service.dart';
import 'package:app_provedor_unified/core/services/session_token_store.dart';
import 'package:app_provedor_unified/core/services/tr069_service.dart';
import 'package:app_provedor_unified/core/utils/app_formatters.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _jwt() {
  String part(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final exp =
      DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch ~/
          1000;
  return '${part({'alg': 'none'})}.${part({'sub': 'u', 'exp': exp})}.sig';
}

Map<String, dynamic> _net(String id, String band, bool enabled,
        {String channel = '11', String mode = ''}) =>
    {
      'id': id,
      'ssid': 'Rede $id',
      'band': band,
      'channel': channel,
      'enabled': enabled,
      'isGuest': false,
      if (mode.isNotEmpty) 'mode': mode,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TR-069: modelos', () {
    test('capabilities: deviceManaged false esconde o Wi-Fi; ausente segue',
        () {
      expect(
          Tr069Capabilities.fromJson(
              const {'enabled': true, 'deviceManaged': false}).manageable,
          isFalse);
      expect(Tr069Capabilities.fromJson(const {'enabled': true}).manageable,
          isTrue);
      expect(Tr069Capabilities.fromJson(const {'enabled': true}).deviceManaged,
          isNull);
      expect(
          Tr069Capabilities.fromJson(
              const {'enabled': false, 'deviceManaged': true}).manageable,
          isFalse);
    });

    test('redes: só as ativas, 2,4 GHz antes de 5 GHz', () {
      final all = [
        _net('1-1', '5GHz', true, channel: '44', mode: 'ac'),
        for (var i = 2; i <= 5; i++) _net('1-$i', '5GHz', false),
        _net('1-6', '2.4GHz', true),
        for (var i = 7; i <= 10; i++) _net('1-$i', '2.4GHz', false),
      ].map(Tr069WifiNetwork.fromJson).toList();
      final shown = Tr069WifiNetwork.visible(all);
      expect(shown.map((n) => n.id), ['1-6', '1-1']);
      expect(shown.last.summary, 'Wi-Fi 5 GHz · Canal 44 · Wi-Fi 5 (ac)');
      expect(shown.first.summary, 'Wi-Fi 2,4 GHz · Canal 11');
    });

    test('redes: sem nenhuma ativa, a primeira de cada faixa', () {
      final all = [
        _net('a', '5GHz', false),
        _net('b', '5GHz', false),
        _net('c', '2.4GHz', false),
      ].map(Tr069WifiNetwork.fromJson).toList();
      expect(Tr069WifiNetwork.visible(all).map((n) => n.id), ['c', 'a']);
    });

    test('aparelho sem nome não mostra o MAC', () {
      final host = Tr069Host.fromJson(
          const {'hostname': 'AA:BB:CC:DD:EE:FF', 'mac': 'aa:bb:cc:dd:ee:ff'});
      expect(host.hostname, Tr069Host.unnamed);
      expect(Tr069Host.fromJson(const {'hostname': '', 'mac': 'x'}).hostname,
          Tr069Host.unnamed);
      expect(
          Tr069Host.fromJson(const {'hostname': 'Galaxy', 'mac': 'x'}).hostname,
          'Galaxy');
    });

    test('status: fibra, roteador sem estado ao vivo, aparelhos e senha', () {
      final o = Tr069Overview.fromJson({
        'online': null,
        'model': 'NV21',
        'wifiNetworks': [_net('1', '2.4GHz', true)],
        'hosts': const [
          {'hostname': 'Note', 'mac': 'm', 'interfaceType': 'wifi_2g'}
        ],
        'passwordReadable': false,
        'snapshotAt': '2026-11-26T10:00:00Z',
        'fiber': const {'online': true, 'rxPowerDbm': -19.3, 'source': 'olt'},
      });
      expect(o.online, isNull);
      expect(o.hosts, hasLength(1));
      expect(o.passwordReadable, isFalse);
      expect(o.snapshotAt, isNotNull);
      expect(o.fiber!.signalLabel, 'Excelente');
      expect(o.hasRouter, isTrue);
      // Servidor antigo: sem hosts no status, sem fibra.
      final old = Tr069Overview.fromJson(const {'online': true});
      expect(old.hosts, isNull);
      expect(old.fiber, isNull);
      expect(old.online, isTrue);
    });
  });

  group('TR-069: serviço', () {
    setUp(() => SessionTokenStore.instance.setTokenForTest(_jwt()));
    tearDown(() => SessionTokenStore.instance.setTokenForTest(null));

    test('422 no status vira "roteador não gerenciado"', () async {
      final service = Tr069Service(
          apiUrl: 'https://x.test/api',
          client: MockClient((_) async => http.Response(
              jsonEncode({
                'error': {'message': 'Gerenciador CPE não definido'}
              }),
              422)));
      await expectLater(
          service.fetchStatus(contratoId: '1'),
          throwsA(isA<Tr069Exception>()
              .having((e) => e.unmanaged, 'unmanaged', isTrue)));
    });

    test('capabilities: falha vira null (não "desligado")', () async {
      final service = Tr069Service(
          apiUrl: 'https://x.test/api',
          client: MockClient((_) async => http.Response('erro', 502)));
      expect(await service.fetchCapabilitiesOrNull(), isNull);
      expect((await service.fetchCapabilities()).enabled, isFalse);
    });

    test('capabilities manda o contrato na consulta', () async {
      final calls = <Uri>[];
      final service = Tr069Service(
          apiUrl: 'https://x.test/api',
          client: MockClient((req) async {
            calls.add(req.url);
            return http.Response(
                jsonEncode({
                  'data': {'enabled': true, 'deviceManaged': false}
                }),
                200);
          }));
      final caps = await service.fetchCapabilitiesOrNull(contratoId: '3894');
      expect(caps!.manageable, isFalse);
      expect(calls.single.queryParameters['contratoId'], '3894');
    });

    testWidgets('troca do Wi-Fi: demora vira mensagem amigável',
        (tester) async {
      final never = Completer<http.Response>();
      final service = Tr069Service(
          apiUrl: 'https://x.test/api',
          client: MockClient((_) => never.future));
      Object? error;
      unawaited(service
          .updateWifi(wifiId: '1', ssid: 'Casa', password: '12345678')
          .catchError((Object e) {
        error = e;
        return '';
      }));
      await tester.pump(const Duration(seconds: 44));
      expect(error, isNull, reason: 'espera mais que o teto do servidor');
      await tester.pump(const Duration(seconds: 2));
      expect(error, isA<Tr069Exception>());
      expect((error as Tr069Exception).timeout, isTrue);
      expect(error.toString(), Tr069Service.slowRouterMessage);
      expect(error.toString(), isNot(contains('TimeoutException')));
    });
  });

  group('Versão do app', () {
    test('compara versões número a número', () {
      expect(AppVersionPolicy.compare('1.0.9', '1.0.10'), -1);
      expect(AppVersionPolicy.compare('1.0.10', '1.0.10'), 0);
      expect(AppVersionPolicy.compare('1.1', '1.0.99'), 1);
      expect(AppVersionPolicy.compare('1.0.42+42', '1.0.42'), 0);
    });

    test('mínima bloqueia, mais recente só sugere', () {
      final p = AppVersionPolicy.fromJson({
        'minVersion': '1.0.40',
        'latestVersion': '1.0.50',
        'storeUrl': 'https://play.google.com/store/apps/details?id=x',
      })!;
      expect(p.requiresUpdate('1.0.39'), isTrue);
      expect(p.requiresUpdate('1.0.40'), isFalse);
      expect(p.suggestsUpdate('1.0.45'), isTrue);
      expect(p.suggestsUpdate('1.0.50'), isFalse);
      expect(p.storeUrl, startsWith('https://'));
    });

    test('forceUpdate=false desliga o bloqueio', () {
      expect(
          AppVersionPolicy.fromJson(
              {'minVersion': '9.0.0', 'forceUpdate': false}),
          isNull);
      final p = AppVersionPolicy.fromJson({
        'minVersion': '9.0.0',
        'latestVersion': '9.0.0',
        'forceUpdate': false
      })!;
      expect(p.requiresUpdate('1.0.0'), isFalse);
      expect(p.suggestsUpdate('1.0.0'), isTrue);
    });

    test('config sem appVersion não pede atualização', () {
      final c = ProviderConfig.fromJson(const {'name': 'X'}, 'x');
      expect(c.appVersion, isNull);
    });
  });

  group('Privacidade', () {
    test('usa a URL do servidor ou a do provedor; ignora http', () {
      final fromServer = ProviderConfig.fromJson(const {
        'privacyPolicyUrl':
            'https://appisp.com.br/api/public/providers/x/privacidade',
        'dataDeletionUrl':
            'https://appisp.com.br/api/public/providers/x/exclusao-de-dados',
      }, 'x');
      expect(fromServer.privacyPolicyUrl, contains('/privacidade'));
      expect(fromServer.dataDeletionUrl, contains('/exclusao-de-dados'));
      final fromOther = ProviderConfig.fromJson(const {
        'other': {'privacyPolicyUrl': 'https://provedor.test/privacidade'}
      }, 'x');
      expect(fromOther.privacyPolicyUrl, 'https://provedor.test/privacidade');
      final insecure = ProviderConfig.fromJson(
          const {'privacyPolicyUrl': 'http://provedor.test/p'}, 'x');
      expect(insecure.privacyPolicyUrl, isEmpty);
    });
  });

  group('Rotas de push e links', () {
    test('rotas com detalhe ou parâmetros abrem a tela existente', () {
      expect(CustomerRoutes.normalize('/suporte'), 'support');
      expect(CustomerRoutes.normalize('/suporte/chamado/123'), 'support');
      expect(CustomerRoutes.normalize('/chamados'), 'support');
      expect(CustomerRoutes.normalize('/faturas?id=1'), 'invoices');
      expect(CustomerRoutes.normalize('/diagnostico'), 'network_diagnostic');
      expect(CustomerRoutes.normalize('wifi'), 'wifi');
    });

    test('toque no aviso leva à tela dele', () {
      expect(notificationTarget('/faturas'), 'invoices');
      expect(notificationTarget('/diagnostico'), 'network_diagnostic');
      expect(notificationTarget(null), isNull);
      expect(notificationTarget('/notificacoes'), isNull);
      expect(notificationTarget('https://site.test'), isNull);
      // Rota desconhecida não ganha "Ver detalhes" que levaria a uma página
      // de "Recurso indisponível".
      expect(notificationTarget('/promo-black-friday'), isNull);
      expect(notificationTarget('/fatura/123'), 'invoices');
      expect(notificationTarget('invoice'), 'invoices');
    });

    test('provedorapp://faturas vira a rota /faturas', () {
      expect(DeepLinkService.routeFor(Uri.parse('provedorapp://faturas')),
          '/faturas');
      expect(DeepLinkService.routeFor(Uri.parse('https://x.test/faturas')),
          isNull);
    });

    test('push em primeiro plano usa o id da campanha', () {
      expect(
          PushNotificationService.foregroundNotificationId(
              {'campaignId': 'camp-1'}, 'fcm-9'),
          'camp-1');
      expect(PushNotificationService.foregroundNotificationId({}, 'fcm-9'),
          'fcm-9');
    });
  });

  group('Contrato e login', () {
    test('vencimento "Dia 9" e "9" viram "Todo dia 9"', () {
      expect(AppFormatters.dueDayOf('Dia 9'), 9);
      expect(AppFormatters.dueDayOf('9'), 9);
      expect(AppFormatters.dueDayOf('dia 20'), 20);
      expect(ContratoPage.dueDay('Dia 9'), 'Todo dia 9');
      expect(AppFormatters.dueDayOf('Mensal'), isNull);
    });

    test('CPF/CNPJ conferidos antes de ir ao provedor', () {
      expect(validateDocument(''), contains('digite'));
      expect(validateDocument('123.456'),
          'CPF incompleto. Confira os 11 números.');
      expect(validateDocument('529.982.247-25'), isNull);
      expect(validateDocument('529.982.247-24'),
          'CPF inválido. Confira os números.');
      expect(validateDocument('111.111.111-11'), isNotNull);
      expect(validateDocument('11.222.333/0001-81'), isNull);
      expect(validateDocument('11.222.333/0001-80'),
          'CNPJ inválido. Confira os números.');
      expect(validateDocument('112223330001'), contains('CNPJ incompleto'));
    });

    test('máscara mantém o cursor no dígito editado', () {
      final f = CpfCnpjInputFormatter();
      // "529.982.247-25" e o usuário apaga o "9" (posição 4 → 3 dígitos antes).
      const old = TextEditingValue(
          text: '529.982.247-25',
          selection: TextSelection.collapsed(offset: 5));
      const edited = TextEditingValue(
          text: '529.82.247-25', selection: TextSelection.collapsed(offset: 4));
      final out = f.formatEditUpdate(old, edited);
      expect(out.text, '529.822.472-5');
      final before = out.text
          .substring(0, out.selection.baseOffset)
          .replaceAll(RegExp(r'[^0-9]'), '');
      expect(before, '529');
    });
  });

  group('Rede do celular', () {
    test('abre sem rede: o aviso aparece já na leitura inicial', () async {
      final changes = StreamController<ConnectivityResult>();
      final stream = seededConnectivity(
          () async => ConnectivityResult.none, changes.stream);
      expect(await stream.first, ConnectivityResult.none);
      await changes.close();
    });

    test('troca Wi-Fi → dados não pisca "sem rede"', () async {
      final changes = StreamController<ConnectivityResult>();
      final seen = <ConnectivityResult>[];
      final sub = seededConnectivity(
              () async => ConnectivityResult.wifi, changes.stream,
              noneGrace: const Duration(milliseconds: 80))
          .listen(seen.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      changes.add(ConnectivityResult.none);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      changes.add(ConnectivityResult.mobile);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(seen, [ConnectivityResult.wifi, ConnectivityResult.mobile]);
      changes.add(ConnectivityResult.none);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(seen.last, ConnectivityResult.none);
      await sub.cancel();
      await changes.close();
    });
  });

  group('Abertura do app', () {
    test('com cache, não espera a rede para abrir', () async {
      SharedPreferences.setMockInitialValues({
        'provider_config_vibe': jsonEncode({'name': 'Cache'}),
      });
      final pending = Completer<http.Response>();
      final provider = ConfigurationProvider(
        api: ProviderConfigApi(client: MockClient((_) => pending.future)),
        apiBaseUrl: 'https://appisp.com.br/api',
      );
      await provider
          .loadConfig('vibe', preferCache: true)
          .timeout(const Duration(seconds: 2));
      expect(provider.isLoading, isFalse);
      expect(provider.providerConfig!.name, 'Cache');
      pending.complete(http.Response(
          jsonEncode({
            'data': {'name': 'Servidor'}
          }),
          200));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(provider.providerConfig!.name, 'Servidor');
    });
  });
}
