import 'dart:convert';

import 'package:http/http.dart' as http;

/// Avisos de sessão vindos das rotas autenticadas. O [AuthNotifier] registra o
/// logout aqui: um 401 com token válido no cliente significa sessão revogada,
/// conta desativada ou papel alterado no servidor.
class ApiSession {
  static void Function()? onUnauthorized;
}

/// Erro de API com mensagem pronta para o usuário (`toString` devolve só ela,
/// compatível com os `e.toString()` que as telas já exibem).
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

/// Decodifica a resposta de uma rota da API sem estourar com corpo não-JSON
/// (ex.: 502 em HTML do proxy) e traduz falhas em mensagens claras.
///
/// Em 2xx devolve o objeto JSON; em erro lança [ApiException]. Com
/// [authenticated], um 401 também aciona [ApiSession.onUnauthorized].
Map<String, dynamic> decodeApiResponse(
  http.Response response, {
  required String fallback,
  bool authenticated = true,
}) {
  Object? body;
  try {
    body = jsonDecode(response.body);
  } on FormatException {
    body = null;
  }
  final status = response.statusCode;
  if (status >= 200 && status < 300) {
    if (body is Map<String, dynamic>) return body;
    throw ApiException(
        status, 'Resposta inesperada do servidor. Tente novamente.');
  }
  if (status == 401 && authenticated) {
    ApiSession.onUnauthorized?.call();
    throw ApiException(status, 'Sua sessão expirou. Entre novamente.');
  }
  throw ApiException(status, apiErrorMessage(status, body, fallback));
}

/// Frase do servidor quando o sistema do provedor está com muitos acessos.
const erpBusyMessage =
    'Muitos acessos agora. Tente novamente em alguns segundos.';

String apiErrorMessage(int status, Object? body, String fallback) {
  if (status == 429) {
    return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
  }
  if (status >= 500) {
    // Vagas do ERP esgotadas: o servidor já manda a frase pronta para o cliente.
    if (status == 503 && body is Map) {
      final error = body['error'];
      final message = error is Map ? error['message'] : null;
      if (message is String && message.startsWith(erpBusyMessage)) {
        return erpBusyMessage;
      }
    }
    return 'Serviço temporariamente indisponível. Tente novamente em instantes.';
  }
  if (body is Map) {
    final error = body['error'];
    final message = error is Map ? error['message'] : error ?? body['message'];
    if (message is String && message.trim().isNotEmpty) return message;
  }
  return fallback;
}
