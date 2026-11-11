import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Busca a configuração pública (marca, menus, textos) do provedor no backend.
///
/// As regras do Firestore só liberam a leitura direta da projeção plana de
/// marca; a configuração completa vem de `GET /public/providers/{id}/config`,
/// sanitizada pelo servidor. A URL que respondeu passa a ser a `apiUrl` do app.
class ProviderConfigApi {
  ProviderConfigApi({http.Client? client}) : _client = client ?? http.Client();

  /// Gravada no build do APK (`--dart-define=PUBLIC_API_URL=...`).
  static const compiledBaseUrl = String.fromEnvironment('PUBLIC_API_URL');

  final http.Client _client;

  /// Devolve o mapa da configuração com `apiUrl` preenchida, ou `null` quando
  /// a URL é inválida, o servidor falha ou a resposta não tem o formato esperado.
  Future<Map<String, dynamic>?> fetch(String baseUrl, String providerId) async {
    final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(
        '$base/public/providers/${Uri.encodeComponent(providerId)}/config');
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return null;
    }
    try {
      final response = await _client.get(uri, headers: const {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      if (body is! Map || body['data'] is! Map) return null;
      final data = (body['data'] as Map)
          .map((key, value) => MapEntry(key.toString(), value));
      return {...data, 'apiUrl': base};
    } on Object {
      // Rede, timeout ou corpo não-JSON (ex.: 502 em HTML): quem chama
      // tenta a próxima fonte.
      return null;
    }
  }
}
