import 'dart:convert';

import 'package:app_provedor_unified/core/models/provider_config.dart';
import 'package:app_provedor_unified/core/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
        expect(jsonDecode(request.body)['providerId'], 'test-provider');
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
}
