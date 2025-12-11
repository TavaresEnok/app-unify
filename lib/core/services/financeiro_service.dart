// ARQUIVO: lib/core/services/financeiro_service.dart
// DESCRIÇÃO: Serviço para buscar faturas e solicitar desbloqueio

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class FinanceiroService {
  final String apiUrl;
  final String cpfCnpjUnformatted;
  final String? senha;
  final Map<String, dynamic> sgpParams;

  FinanceiroService({
    required this.apiUrl,
    required this.cpfCnpjUnformatted,
    this.senha,
    required this.sgpParams,
  });

  /// Busca as faturas do cliente
  Future<List<dynamic>> fetchInvoices() async {
    try {
      if (cpfCnpjUnformatted.isEmpty) {
        throw Exception("O CPF/CNPJ está vazio.");
      }
      if ((sgpParams['token'] ?? '').isEmpty ||
          (sgpParams['app'] ?? '').isEmpty) {
        throw Exception("Token ou App Name não configurados.");
      }

      final requestBody = {
        'cpfCnpj': cpfCnpjUnformatted,
        'senha': senha,
        'sgpParams': sgpParams,
        'sgpBaseUrl': sgpParams['sgpBaseUrl'],
      };

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        final responseData = responseBody['data'];
        return responseData is List ? responseData : [];
      } else {
        final errorMessage = responseBody['error']?['message'] ??
            responseBody['error'] ??
            'Falha ao carregar faturas. Código: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      throw TimeoutException(
          'O servidor demorou muito para responder. Verifique sua conexão.');
    } catch (e) {
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  /// Solicita desbloqueio por confiança
  Future<bool> solicitarDesbloqueioConfianca() async {
    try {
      final unlockUrl = apiUrl.replaceAll('get-invoices', 'unlock-trust');

      final requestBody = {
        'cpfCnpj': cpfCnpjUnformatted,
        'senha': senha,
        'sgpParams': sgpParams,
        'sgpBaseUrl': sgpParams['sgpBaseUrl'],
      };

      final response = await http
          .post(
            Uri.parse(unlockUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      } else {
        final body = json.decode(response.body);
        throw Exception(body['message'] ??
            'Não foi possível realizar o desbloqueio. Tente novamente.');
      }
    } catch (e) {
      throw Exception(
          "Erro ao solicitar desbloqueio: ${e.toString().replaceAll('Exception: ', '')}");
    }
  }
}
