// ARQUIVO: lib/core/services/consumo_service.dart
// DESCRIÇÃO: Serviço para buscar dados de consumo de internet

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  /// [month] Mês (1-12)
  /// [year] Ano (ex: 2024)
  Future<Map<String, dynamic>> fetchConsumptionData(
      {int? month, int? year}) async {
    try {
      if (cpfCnpj.isEmpty || senha.isEmpty) {
        throw Exception("CPF/CNPJ ou Senha não podem ser vazios.");
      }

      final requestBody = {
        'cpfCnpj': cpfCnpj,
        'senha': senha,
        'sgpParams': sgpParams,
        'sgpBaseUrl': sgpParams['sgpBaseUrl'],
        if (month != null) 'mes': month,
        if (year != null) 'ano': year,
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
          .timeout(const Duration(seconds: 15)); // Reduced timeout for fallback

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body)['data'];
        
        final String cacheKey = '$cpfCnpj-${month ?? 'all'}-${year ?? 'all'}';
        try {
          final box = Hive.box('consumo_cache');
          await box.put(cacheKey, json.encode(responseData));
        } catch (_) {}

        return responseData is Map<String, dynamic> ? responseData : {};
      } else {
        throw Exception(
            "Falha ao buscar dados de consumo. Erro: ${response.statusCode}");
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e is TimeoutException) {
        final String cacheKey = '$cpfCnpj-${month ?? 'all'}-${year ?? 'all'}';
        try {
          final box = Hive.box('consumo_cache');
          final cached = box.get(cacheKey);
          if (cached != null) {
            return json.decode(cached) as Map<String, dynamic>;
          }
        } catch (_) {}
        throw Exception('Sem conexão com a internet e sem dados de consumo salvos.');
      }
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }
}
