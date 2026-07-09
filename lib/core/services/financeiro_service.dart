// ARQUIVO: lib/core/services/financeiro_service.dart
// DESCRIÇÃO: Serviço para buscar faturas e solicitar desbloqueio

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FinanceiroService {
  final String apiUrl;
  final String cpfCnpjUnformatted;
  final String? senha;
  final String providerId;
  final String sgpBaseUrl;

  FinanceiroService({
    required this.apiUrl,
    required this.cpfCnpjUnformatted,
    this.senha,
    required this.providerId,
    required this.sgpBaseUrl,
  });

  /// Busca as faturas do cliente
  Future<List<dynamic>> fetchInvoices() async {
    try {
      // [MOCK] If no providerId configured, return mock data for UI testing
      if (providerId.isEmpty) {
        // Retrieve colors to use the correct formatting if needed (though model parses strings mostly)
        return _getMockInvoices();
      }

      if (cpfCnpjUnformatted.isEmpty) {
        throw Exception("O CPF/CNPJ está vazio.");
      }

      final requestBody = {
        'cpfCnpj': cpfCnpjUnformatted,
        'senha': senha,
        'providerId': providerId,
        'sgpBaseUrl': sgpBaseUrl,
      };

      String? token;
      try {
        token = await FirebaseAuth.instance.currentUser?.getIdToken();
      } catch (e) {
        // ignore
      }

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 15)); // Reduced timeout for faster fallback

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        final responseData = responseBody['data'];
        final invoices = responseData is List ? responseData : [];
        // Save to cache
        try {
           final box = Hive.box('faturas_cache');
           await box.put(cpfCnpjUnformatted, json.encode(invoices));
        } catch (_) {}
        return invoices;
      } else {
        final errorMessage = responseBody['error']?['message'] ??
            responseBody['error'] ??
            'Falha ao carregar faturas. Código: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Offline fallback
      if (e.toString().contains('SocketException') || e is TimeoutException) {
        try {
          final box = Hive.box('faturas_cache');
          final cached = box.get(cpfCnpjUnformatted);
          if (cached != null) {
            return json.decode(cached) as List<dynamic>;
          }
        } catch (_) {}
        throw Exception('Sem conexão com a internet e sem dados salvos offline.');
      }
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
      // Constrói a URL de unlock a partir da base da API (não depende de 'get-invoices' estar na URL)
      final uri = Uri.parse(apiUrl);
      final unlockUri = uri.replace(path: '/unlock-trust');
      final unlockUrl = unlockUri.toString();

      final requestBody = {
        'cpfCnpj': cpfCnpjUnformatted,
        'senha': senha,
        'providerId': providerId,
        'sgpBaseUrl': sgpBaseUrl,
      };

      String? token;
      try {
        token = await FirebaseAuth.instance.currentUser?.getIdToken();
      } catch (e) {
        // ignore
      }

      final response = await http
          .post(
            Uri.parse(unlockUrl),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
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
