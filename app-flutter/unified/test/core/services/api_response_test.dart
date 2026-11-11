import 'dart:convert';

import 'package:app_provedor_unified/core/services/api_response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  tearDown(() => ApiSession.onUnauthorized = null);

  test('devolve o objeto JSON em 2xx', () {
    final body = decodeApiResponse(
        http.Response(jsonEncode({'data': 1}), 200),
        fallback: 'x');
    expect(body['data'], 1);
  });

  test('502 em HTML vira mensagem clara, sem FormatException', () {
    expect(
      () => decodeApiResponse(http.Response('<html>Bad Gateway</html>', 502),
          fallback: 'x'),
      throwsA(isA<ApiException>().having((e) => e.toString(), 'mensagem',
          contains('temporariamente indisponível'))),
    );
  });

  test('200 com corpo inválido não estoura com tipo errado', () {
    expect(
      () => decodeApiResponse(http.Response('[1,2]', 200), fallback: 'x'),
      throwsA(isA<ApiException>()),
    );
  });

  test('usa a mensagem do servidor em 4xx e o fallback sem ela', () {
    expect(
      () => decodeApiResponse(
          http.Response(jsonEncode({'error': {'message': 'Contrato não encontrado.'}}), 404),
          fallback: 'x'),
      throwsA(isA<ApiException>().having(
          (e) => e.message, 'mensagem', 'Contrato não encontrado.')),
    );
    expect(
      () => decodeApiResponse(http.Response('', 400), fallback: 'Falhou.'),
      throwsA(isA<ApiException>().having((e) => e.message, 'mensagem', 'Falhou.')),
    );
  });

  test('401 autenticado avisa a sessão; 401 de login não', () {
    var avisos = 0;
    ApiSession.onUnauthorized = () => avisos++;
    expect(
        () => decodeApiResponse(http.Response('{}', 401), fallback: 'x'),
        throwsA(isA<ApiException>().having(
            (e) => e.message, 'mensagem', contains('sessão expirou'))));
    expect(
        () => decodeApiResponse(
            http.Response(jsonEncode({'error': {'message': 'Credenciais inválidas.'}}), 401),
            fallback: 'x',
            authenticated: false),
        throwsA(isA<ApiException>().having(
            (e) => e.message, 'mensagem', 'Credenciais inválidas.')));
    expect(avisos, 1);
  });
}
