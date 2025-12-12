// ARQUIVO: lib/services/promessa_service.dart
// (Novo arquivo para a lógica da Promessa de Pagamento)

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Para TimeoutException

class PromessaService {
  final String apiUrl;
  final Map<String, dynamic> sgpParams;
  final String cpfCnpj;

  PromessaService({
    required this.apiUrl,
    required this.sgpParams,
    required this.cpfCnpj,
  });

  /// Tenta realizar a promessa de pagamento.
  Future<String> makePaymentPromise() async {
    print("--- DEBUG PROMESSA (Service) ---");
    try {
      // Validações
      if ((sgpParams['token'] ?? '').isEmpty || (sgpParams['app'] ?? '').isEmpty) {
        throw Exception("Token ou App Name não configurados no painel.");
      }

      final requestBody = {
        'cpfCnpj': cpfCnpj,
        'sgpParams': sgpParams,
        'sgpBaseUrl': sgpParams['sgpBaseUrl'], // ADICIONADO
      };

      print("Enviando requisição para $apiUrl com o corpo: ${json.encode(requestBody)}");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 45)); // Timeout

      print("Resposta recebida do servidor com status: ${response.statusCode}");
      print("Corpo da resposta: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Retorna a mensagem de sucesso [cite: 236, 661]
        return responseData['message'] ?? 'Promessa realizada com sucesso!';
      } else {
        // Retorna a mensagem de erro do SGP [cite: 234, 659]
        final errorBody = json.decode(response.body)['error'];
        throw Exception(errorBody['message'] ?? 'Ocorreu um erro desconhecido.');
      }
    } on TimeoutException catch (e) {
      print("‼️ ERRO NO BLOCO CATCH (PROMESSA - TIMEOUT): ${e.toString()}");
      throw TimeoutException('O servidor demorou muito para responder.');
    } catch (e) {
      print("‼️ ERRO NO BLOCO CATCH (PROMESSA - GERAL): ${e.toString()}");
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      print("--- FIM DEBUG PROMESSA (Service) ---");
    }
  }
}