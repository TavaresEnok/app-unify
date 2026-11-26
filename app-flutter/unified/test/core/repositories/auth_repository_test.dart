import 'dart:convert';

import 'package:app_provedor_unified/core/models/provider_config.dart';
import 'package:app_provedor_unified/core/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const config = ProviderConfig(
    id: 'test-provider',
    name: 'Test Provider',
    apiUrl: 'https://api.test',
    config: ConfigSection(
      themeColor: '#000000',
      logoUrl: '',
      loginQuote: '',
      integrations: SgpIntegration(),
      faq: [],
      tips: [],
      supportContacts: [],
      imageCarousel: [],
    ),
    features: FeaturesSection(consumption: true, support: true),
    menuConfig: MenuConfig(order: [], items: {}),
  );

  test('rejects a successful response without a Firebase custom token', () {
    final repository = AuthRepository(
      client: MockClient((request) async {
        expect(request.url.toString(), 'https://api.test/check-cpf');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['providerId'], 'test-provider');
        expect(body['cpf'], '12345678900');
        expect(body.containsKey('senha'), isFalse);
        return http.Response(
          jsonEncode({'nome': 'Cliente', 'status': 'Bloqueado'}),
          200,
        );
      }),
    );

    expect(
      repository.performLoginApi('12345678900', config),
      throwsA(
        predicate(
          (error) => error.toString().contains('Acesso indisponível'),
        ),
      ),
    );
  });

  test('maps server failures to a stable user-facing message', () {
    final repository = AuthRepository(
      client: MockClient(
        (_) async => http.Response('<!DOCTYPE html>', 503),
      ),
    );

    expect(
      repository.performLoginApi('12345678900', config),
      throwsA(
        predicate(
          (error) => error.toString().contains('temporariamente indisponível'),
        ),
      ),
    );
  });

  group('sessão que não cai sozinha', () {
    test('recusa do provedor é definitiva; falha temporária não', () async {
      Future<Object?> errorFor(int status, String body) async {
        final repository = AuthRepository(
            client: MockClient((_) async => http.Response(body, status)));
        try {
          await repository.performLoginApi('12345678900', config);
        } catch (e) {
          return e;
        }
        return null;
      }

      expect(await errorFor(200, jsonEncode({'status': 'Cancelado'})),
          isA<LoginRejectedException>());
      expect(await errorFor(404, '{}'), isA<LoginRejectedException>());
      expect(
          await errorFor(503, '<html>'), isNot(isA<LoginRejectedException>()));
      expect(await errorFor(429, '{}'), isNot(isA<LoginRejectedException>()));
    });

    test('dados salvos abrem a conta mesmo sem token válido', () async {
      SharedPreferences.setMockInitialValues({
        'userCpfCnpj': '12345678900',
        'userName': 'Cliente',
        'userPlan': 'Plano',
        'userStatus': 'Online',
        'billValue': '99,90',
        'billDueDate': '10/12/2026',
      });
      final user = await AuthRepository(
              client: MockClient((_) async => http.Response('', 500)))
          .loadUserFromStorage();
      expect(user?.cpfCnpj, '12345678900');
    });
  });
}
