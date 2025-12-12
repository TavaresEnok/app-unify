// ARQUIVO: lib/services/financeiro_service.dart (CORRIGIDO)

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

  Future<List<dynamic>> fetchInvoices() async {
    print("--- DEBUG FATURAS (Service V3) ---");
    try {
      if (cpfCnpjUnformatted.isEmpty) {
        throw Exception("O CPF/CNPJ chegou VAZIO para o serviço de Faturas.");
      }
      if ((sgpParams['token'] ?? '').isEmpty || (sgpParams['app'] ?? '').isEmpty) {
        throw Exception("Token ou App Name não configurados no painel.");
      }

      final requestBody = {
        'cpfCnpj': cpfCnpjUnformatted,
        'senha': senha,
        'sgpParams': sgpParams,
        'sgpBaseUrl': sgpParams['sgpBaseUrl'], // ADICIONADO AQUI
      };

      print("Enviando requisição para $apiUrl com o corpo: ${json.encode(requestBody)}");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 60));

      print("Resposta recebida do servidor com status: ${response.statusCode}");

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        final responseData = responseBody['data'];
        return responseData is List ? responseData : [];
      } else {
        final errorMessage = responseBody['error']?['message'] ?? responseBody['error'] ?? 'Falha ao carregar faturas. Código: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      print("‼️ ERRO NO BLOCO CATCH (FATURAS - TIMEOUT)");
      throw TimeoutException('O servidor demorou muito para responder (Faturas). Verifique sua conexão.');
    } catch (e) {
      print("‼️ ERRO NO BLOCO CATCH (FATURAS - GERAL): ${e.toString()}");
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      print("--- FIM DEBUG FATURAS (Service V3) ---");
    }
  }

  Future<bool> solicitarDesbloqueioConfianca() async {
    try {
      // Tenta usar o endpoint de desbloqueio baseado na URL base de faturas
      // Se apiUrl for ".../get-invoices", virará ".../unlock-trust"
      final unlockUrl = apiUrl.replaceAll('get-invoices', 'unlock-trust'); 
      
      final requestBody = {
        'cpfCnpj': cpfCnpjUnformatted,
        'senha': senha,
        'sgpParams': sgpParams,
        'sgpBaseUrl': sgpParams['sgpBaseUrl'], // ADICIONADO AQUI TAMBÉM
      };

      final response = await http.post(
        Uri.parse(unlockUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      } else {
        final body = json.decode(response.body);
        throw Exception(body['message'] ?? 'Não foi possível realizar o desbloqueio. Tente novamente ou contate o suporte.');
      }
    } catch (e) {
      throw Exception("Erro ao solicitar desbloqueio: ${e.toString().replaceAll('Exception: ', '')}");
    }
  }
}
