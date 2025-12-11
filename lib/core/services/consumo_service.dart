// ARQUIVO: lib/core/services/consumo_service.dart
// DESCRIÇÃO: Serviço para buscar dados de consumo de internet

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

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

  /// Busca os dados de consumo na API
  Future<Map<String, dynamic>> fetchConsumptionData() async {
    try {
      if (cpfCnpj.isEmpty || senha.isEmpty) {
        throw Exception("CPF/CNPJ ou Senha não podem ser vazios.");
      }

      final requestBody = {
        'cpfCnpj': cpfCnpj,
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
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body)['data'];
        return responseData as Map<String, dynamic>;
      } else {
        final errorBody = json.decode(response.body)['error'];
        throw Exception(errorBody?['message'] ??
            'Falha ao carregar dados de consumo. Código: ${response.statusCode}');
      }
    } on TimeoutException {
      throw TimeoutException(
          'O servidor demorou muito para responder. Verifique sua conexão.');
    } catch (e) {
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }
}
