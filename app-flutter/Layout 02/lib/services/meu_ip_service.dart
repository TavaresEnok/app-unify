// ARQUIVO: lib/services/meu_ip_service.dart
// (Novo arquivo para a lógica da página "Meu IP")

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Para TimeoutException

class MeuIpService {
  // A URL é pública e fixa, não precisa vir do providerConfig
  final String _apiUrl = 'https://ipinfo.io/json';

  /// Busca os dados de IP do serviço ipinfo.io
  Future<Map<String, dynamic>> fetchIpInfo() async {
    print("--- DEBUG IP (Service) ---");
    try {
      final response = await http.get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10)); // Timeout de 10s

      print("Resposta IPInfo: ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Não foi possível obter os dados de IP. Código: ${response.statusCode}');
      }
    } on TimeoutException {
      print("‼️ ERRO NO BLOCO CATCH (IP - TIMEOUT)");
      throw TimeoutException('O servidor (ipinfo.io) demorou para responder.');
    } catch (e) {
      print("‼️ ERRO NO BLOCO CATCH (IP - GERAL): ${e.toString()}");
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }
}
