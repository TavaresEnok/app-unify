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
      // [MOCK] If no token/app configured, return mock data for UI testing
      if ((sgpParams['token'] ?? '').isEmpty ||
          (sgpParams['app'] ?? '').isEmpty) {
        // Retrieve colors to use the correct formatting if needed (though model parses strings mostly)
        return _getMockInvoices();
      }

      if (cpfCnpjUnformatted.isEmpty) {
        throw Exception("O CPF/CNPJ está vazio.");
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
      // If we are debugging/testing, maybe fallback to mock on error too?
      // For now, let's stick to explicit mock only if config is missing.
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  List<dynamic> _getMockInvoices() {
    final now = DateTime.now();
    return [
      {
        'id': 123456,
        'vencimento': now.add(const Duration(days: 5)).toIso8601String(),
        'valor': 99.90,
        'status': 'pendente',
        'linha_digitavel':
            '84670000001 4 59900296202 5 20424263400 3 10328905230',
        'pix_copia_cola':
            '00020101021226870014br.gov.bcb.pix2565qrcode.pix.com.br...',
        'url_boleto': 'https://example.com/boleto',
      },
      {
        'id': 123455,
        'vencimento': now.subtract(const Duration(days: 25)).toIso8601String(),
        'valor': 99.90,
        'status': 'pago',
        'data_pagamento':
            now.subtract(const Duration(days: 26)).toIso8601String(),
        'valor_pago': 99.90,
      },
      {
        'id': 123454,
        'vencimento': now.subtract(const Duration(days: 55)).toIso8601String(),
        'valor': 99.90,
        'status': 'pago',
        'data_pagamento':
            now.subtract(const Duration(days: 56)).toIso8601String(),
        'valor_pago': 99.90,
      },
    ];
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
