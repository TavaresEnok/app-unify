// ARQUIVO: lib/core/services/consumo_service.dart
// DESCRIÇÃO: Serviço para buscar dados de consumo de internet

import 'api_response.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'session_token_store.dart';

class ConsumoService {
  final String apiUrl;
  final String providerId;
  final String cpfCnpj;
  final int? contratoId;

  ConsumoService({
    required this.apiUrl,
    required this.providerId,
    required this.cpfCnpj,
    this.contratoId,
  });

  /// Espera antes da segunda tentativa automática em 5xx (como nas faturas).
  static Duration retryDelay = const Duration(milliseconds: 1500);

  /// Busca os dados de consumo na API
  /// [month] Mês (1-12)
  /// [year] Ano (ex: 2024)
  Future<Map<String, dynamic>> fetchConsumptionData(
      {int? month, int? year}) async {
    try {
      try {
        return await _fetchOnce(month: month, year: year);
      } on ApiException catch (e) {
        // ERP ocupado/instável (5xx): uma nova tentativa em silêncio.
        if (e.statusCode < 500) rethrow;
        await Future<void>.delayed(retryDelay);
        return await _fetchOnce(month: month, year: year);
      }
    } on TimeoutException {
      throw TimeoutException(
          'O servidor demorou muito para responder. Verifique sua conexão.');
    } catch (e) {
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<Map<String, dynamic>> _fetchOnce({int? month, int? year}) async {
    if (cpfCnpj.isEmpty) {
      throw Exception("O CPF/CNPJ está vazio.");
    }

    final requestBody = {
      'cpfCnpj': cpfCnpj,
      'providerId': providerId,
      if (contratoId != null) 'contratoId': contratoId,
      if (month != null) 'mes': month,
      if (year != null) 'ano': year,
    };
    String? token;
    try {
      token = await SessionTokenStore.instance.getToken();
    } catch (_) {}

    final response = await http
        .post(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: json.encode(requestBody),
        )
        .timeout(const Duration(seconds: 30));

    final responseData = decodeApiResponse(response,
            fallback:
                'Falha ao carregar dados de consumo. Código: ${response.statusCode}')[
        'data'];
    if (responseData is! Map<String, dynamic>) {
      throw ApiException(response.statusCode,
          'Resposta inesperada do servidor. Tente novamente.');
    }
    return responseData;
  }
}
