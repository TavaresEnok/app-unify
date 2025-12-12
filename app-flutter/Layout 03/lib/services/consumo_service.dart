// ARQUIVO: lib/services/consumo_service.dart
// (Este é o arquivo novo que estava faltando)

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Para TimeoutException

class ConsumoService {
  final String apiUrl;
  final Map<String, dynamic> sgpParams;
  final String cpfCnpj;
  final String senha;

  ConsumoService({
    required this.apiUrl,
    required this.sgpParams,
    required this.cpfCnpj,
    required this.senha,
  });

  /// Busca os dados de consumo na API.
  Future<Map<String, dynamic>> fetchConsumptionData() async {
    print("--- DEBUG CONSUMO (Service) ---");
    try {
      // Validações
      if (cpfCnpj.isEmpty || senha.isEmpty) {
        throw Exception("CPF/CNPJ ou Senha não podem ser vazios.");
      }
      if ((sgpParams['token'] ?? '').isEmpty || (sgpParams['app'] ?? '').isEmpty) {
        throw Exception("Token ou App Name não configurados no painel.");
      }

      final requestBody = {
        'cpfCnpj': cpfCnpj,
        'senha': senha,
        'sgpParams': sgpParams,
        'sgpBaseUrl': sgpParams['sgpBaseUrl'],
      };

      print("Enviando requisição para $apiUrl com o corpo: ${json.encode(requestBody)}");

      // Requisição HTTP com timeout
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print("Resposta recebida do servidor com status: ${response.statusCode}");
      print("Corpo da resposta: ${response.body}");

      // Processamento da resposta
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body)['data'];
        return responseData as Map<String, dynamic>;
      } else {
        final errorBody = json.decode(response.body)['error'];
        throw Exception(errorBody?['message'] ?? 'Falha ao carregar dados de consumo. Código: ${response.statusCode}');
      }
    } on TimeoutException catch (e) { // Captura Timeout
      print("‼️ ERRO NO BLOCO CATCH (CONSUMO - TIMEOUT): ${e.toString()}");
      throw TimeoutException('O servidor demorou muito para responder. Verifique sua conexão.');
    } catch (e) { // Captura outros erros
      print("‼️ ERRO NO BLOCO CATCH (CONSUMO - GERAL): ${e.toString()}");
      // Retorna a mensagem de erro já tratada
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      print("--- FIM DEBUG CONSUMO (Service) ---");
    }
  }
}