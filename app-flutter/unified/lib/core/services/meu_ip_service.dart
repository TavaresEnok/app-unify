import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class MeuIpService {
  final String _apiUrl = 'https://ipinfo.io/json';

  /// Busca os dados de IP do serviço ipinfo.io
  Future<Map<String, dynamic>> fetchIpInfo() async {
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Não foi possível obter os dados de IP. Código: ${response.statusCode}');
      }
    } on TimeoutException {
      throw TimeoutException('O servidor (ipinfo.io) demorou para responder.');
    } catch (e) {
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }
}
