// ARQUIVO: lib/services/login_service.dart
// (Novo arquivo para a lógica de Login)

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Para TimeoutException

class LoginService {
  final String apiUrl;
  final Map<String, dynamic> sgpParams;
  final String cpfCnpjUnformatted;

  LoginService({
    required this.apiUrl,
    required this.sgpParams,
    required this.cpfCnpjUnformatted,
  });

  /// Busca os dados do cliente para o login.
  Future<Map<String, dynamic>> login() async {
    print("--- DEBUG LOGIN (Service) ---");
    try {
      // Validações
      if ((sgpParams['token'] ?? '').isEmpty || (sgpParams['app'] ?? '').isEmpty) {
        throw Exception("Token ou App Name não configurados no painel.");
      }
      if (cpfCnpjUnformatted.isEmpty) {
        throw Exception("CPF/CNPJ não podem ser vazios.");
      }

      final requestBody = {
        "cpfCnpj": cpfCnpjUnformatted,
        "sgpParams": sgpParams,
        "sgpBaseUrl": sgpParams['sgpBaseUrl'], // [FIX] Envia na raiz do JSON também
      };

      print("Enviando requisição para $apiUrl com o corpo: ${json.encode(requestBody)}");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 120)); // Timeout longo para login

      print("Resposta recebida do servidor com status: ${response.statusCode}");
      print("Corpo da resposta: ${response.body}");

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        // CORREÇÃO: O servidor retorna os dados do usuário diretamente, não um customToken.
        // O campo 'data' contém o mapa com as informações do cliente.
        final data = responseBody['data'];
        if (data is Map<String, dynamic>) {
            // Adicionamos o customToken como nulo para o fluxo antigo funcionar sem quebrar o novo.
            data['customToken'] = null;
            return data;
        } else {
          throw Exception('O campo \'data\' na resposta do servidor não é um mapa válido.');
        }
      } else {
        final e = json.decode(response.body)['error'];
        throw Exception(e?['message'] ?? 'Não foi possível fazer o login. Verifique os dados e tente novamente.');
      }
    } on TimeoutException {
      print("‼️ ERRO NO BLOCO CATCH (LOGIN - TIMEOUT)");
      throw TimeoutException('O servidor demorou muito para responder. Verifique sua conexão.');
    } catch (e) {
      print("‼️ ERRO NO BLOCO CATCH (LOGIN - GERAL): ${e.toString()}");
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      print("--- FIM DEBUG LOGIN (Service) ---");
    }
  }
}
