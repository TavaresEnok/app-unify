// ARQUIVO: lib/core/services/financeiro_service.dart
// DESCRIÇÃO: Serviço para buscar faturas e solicitar desbloqueio

import 'api_response.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'account_data_cache.dart';
import 'session_token_store.dart';

class FinanceiroService {
  final String apiUrl;
  final String cpfCnpjUnformatted;
  final String providerId;
  final int? contratoId;

  FinanceiroService({
    required this.apiUrl,
    required this.cpfCnpjUnformatted,
    required this.providerId,
    this.contratoId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinanceiroService &&
          runtimeType == other.runtimeType &&
          apiUrl == other.apiUrl &&
          cpfCnpjUnformatted == other.cpfCnpjUnformatted &&
          providerId == other.providerId &&
          contratoId == other.contratoId;

  @override
  int get hashCode => Object.hash(
      runtimeType, apiUrl, cpfCnpjUnformatted, providerId, contratoId);

  /// Chave do cache local das faturas desta conta (sem o CPF em claro).
  String get cacheKey => AccountDataCache.keyFor('invoices',
      providerId: providerId,
      document: cpfCnpjUnformatted,
      contratoId: contratoId);

  /// Tempo máximo de cada tentativa. O proxy desiste em ~5 s; acima disso é
  /// rede do celular travada, e esperar um minuto não ajuda ninguém.
  static Duration attemptTimeout = const Duration(seconds: 15);

  /// Espera antes da segunda tentativa automática.
  static Duration retryDelay = const Duration(milliseconds: 1500);

  /// Busca as faturas do cliente. Em falha passageira (tempo esgotado,
  /// 5xx, rede caiu) tenta mais uma vez em silêncio antes de avisar.
  Future<List<dynamic>> fetchInvoices() async {
    try {
      return await _fetchInvoicesOnce();
    } catch (e) {
      if (!isTransientFailure(e)) rethrow;
      await Future<void>.delayed(retryDelay);
      return _fetchInvoicesOnce();
    }
  }

  /// Falhas que valem uma nova tentativa automática.
  static bool isTransientFailure(Object e) {
    if (e is TimeoutException) return true;
    if (e is ApiException) return e.statusCode >= 500;
    if (e is http.ClientException) return true;
    final text = e.toString();
    return text.contains('SocketException') ||
        text.contains('Connection closed') ||
        text.contains('Connection reset') ||
        text.contains('Failed host lookup');
  }

  Future<List<dynamic>> _fetchInvoicesOnce() async {
    if (cpfCnpjUnformatted.isEmpty) {
      throw Exception("O CPF/CNPJ está vazio.");
    }

    final requestBody = {
      'cpfCnpj': cpfCnpjUnformatted,
      'providerId': providerId,
      if (contratoId != null) 'contratoId': contratoId,
    };

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: await _authenticatedHeaders(),
            body: json.encode(requestBody),
          )
          .timeout(attemptTimeout);

      final responseBody = decodeApiResponse(response,
          fallback:
              'Falha ao carregar faturas. Código: ${response.statusCode}');
      final responseData = responseBody['data'];
      return responseData is List ? responseData : [];
    } on TimeoutException {
      throw TimeoutException(
          'O servidor demorou muito para responder. Verifique sua conexão.');
    }
  }

  Future<bool>? _unlockRequest;

  /// Reutiliza o pedido enquanto a solicitação anterior estiver em andamento.
  Future<bool> solicitarDesbloqueioConfianca() {
    return _unlockRequest ??= _requestUnlock().whenComplete(() {
      _unlockRequest = null;
    });
  }

  Future<bool> _requestUnlock() async {
    try {
      final unlockUrl = apiUrl.replaceAll('get-invoices', 'unlock-trust');

      final requestBody = {
        'cpfCnpj': cpfCnpjUnformatted,
        'providerId': providerId,
        if (contratoId != null) 'contratoId': contratoId,
      };

      final response = await http
          .post(
            Uri.parse(unlockUrl),
            headers: await _authenticatedHeaders(),
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      decodeApiResponse(response,
          fallback:
              'Não foi possível realizar o desbloqueio. Tente novamente.');
      return true;
    } catch (e) {
      throw Exception(
          "Erro ao solicitar desbloqueio: ${e.toString().replaceAll('Exception: ', '')}");
    }
  }

  Future<Map<String, String>> _authenticatedHeaders() async {
    String? token;
    try {
      token = await SessionTokenStore.instance.getToken();
    } catch (_) {}
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
