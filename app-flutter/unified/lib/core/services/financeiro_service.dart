// ARQUIVO: lib/core/services/financeiro_service.dart
// DESCRIÇÃO: Serviço para buscar faturas e solicitar desbloqueio

import 'api_response.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class FinanceiroService {
  final String apiUrl;
  final String cpfCnpjUnformatted;
  final String providerId;

  FinanceiroService({
    required this.apiUrl,
    required this.cpfCnpjUnformatted,
    required this.providerId,
  });

  /// Busca as faturas do cliente
  Future<List<dynamic>> fetchInvoices() async {
    try {
      if (cpfCnpjUnformatted.isEmpty) {
        throw Exception("O CPF/CNPJ está vazio.");
      }

      final requestBody = {
        'cpfCnpj': cpfCnpjUnformatted,
        'providerId': providerId,
      };

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: await _authenticatedHeaders(),
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      final responseBody = decodeApiResponse(response,
          fallback: 'Falha ao carregar faturas. Código: ${response.statusCode}');
      final responseData = responseBody['data'];
      return responseData is List ? responseData : [];
    } on TimeoutException {
      throw TimeoutException(
          'O servidor demorou muito para responder. Verifique sua conexão.');
    } catch (e) {
      // If we are debugging/testing, maybe fallback to mock on error too?
      // For now, let's stick to explicit mock only if config is missing.
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  /// Solicita desbloqueio por confiança
  Future<bool> solicitarDesbloqueioConfianca() async {
    try {
      final unlockUrl = apiUrl.replaceAll('get-invoices', 'unlock-trust');

      final requestBody = {
        'cpfCnpj': cpfCnpjUnformatted,
        'providerId': providerId,
      };

      final response = await http
          .post(
            Uri.parse(unlockUrl),
            headers: await _authenticatedHeaders(),
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      decodeApiResponse(response,
          fallback: 'Não foi possível realizar o desbloqueio. Tente novamente.');
      return true;
    } catch (e) {
      throw Exception(
          "Erro ao solicitar desbloqueio: ${e.toString().replaceAll('Exception: ', '')}");
    }
  }

  Future<Map<String, String>> _authenticatedHeaders() async {
    String? token;
    try {
      token = await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {}
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
