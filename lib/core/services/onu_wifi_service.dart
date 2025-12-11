// ARQUIVO: lib/core/services/onu_wifi_service.dart
// DESCRIÇÃO: Serviço para buscar sinal da ONU e gerenciar WiFi via SGP/TR069

import 'dart:convert';
import 'package:http/http.dart' as http;

class OnuData {
  final double signalRx;
  final double signalTx;
  final String connectionStatus;
  final int oltId;
  final int slot;
  final int pon;
  final int onuId;
  final double? temperature;
  final double? oltTemperature;
  final double? voltage;
  final String model;
  final String? serialNumber;

  OnuData({
    required this.signalRx,
    required this.signalTx,
    required this.connectionStatus,
    required this.oltId,
    required this.slot,
    required this.pon,
    required this.onuId,
    this.temperature,
    this.oltTemperature,
    this.voltage,
    required this.model,
    this.serialNumber,
  });

  factory OnuData.fromJson(Map<String, dynamic> json) {
    return OnuData(
      signalRx: (json['signalRx'] ?? -999).toDouble(),
      signalTx: (json['signalTx'] ?? -999).toDouble(),
      connectionStatus: json['connectionStatus'] ?? 'unknown',
      oltId: json['oltId'] ?? 0,
      slot: json['slot'] ?? 0,
      pon: json['pon'] ?? 0,
      onuId: json['onuId'] ?? 0,
      temperature: json['temperature']?.toDouble(),
      oltTemperature: json['oltTemperature']?.toDouble(),
      voltage: json['voltage']?.toDouble(),
      model: json['model'] ?? 'Desconhecido',
      serialNumber: json['serialNumber'],
    );
  }

  /// Qualidade do sinal baseada no RX
  String get signalQuality {
    if (signalRx >= -23) return 'Excelente';
    if (signalRx >= -25) return 'Bom';
    if (signalRx >= -27) return 'Regular';
    return 'Ruim';
  }

  /// Cor do sinal baseada no RX
  bool get isSignalGood => signalRx >= -25;
}

class WifiNetwork {
  final String id;
  final String ssid;
  final String frequency; // 2.4GHz ou 5GHz
  final bool enabled;
  final String? password;

  WifiNetwork({
    required this.id,
    required this.ssid,
    required this.frequency,
    required this.enabled,
    this.password,
  });

  factory WifiNetwork.fromJson(Map<String, dynamic> json) {
    return WifiNetwork(
      id: json['id']?.toString() ?? '',
      ssid: json['ssid'] ?? json['nome'] ?? '',
      frequency: json['frequency'] ?? json['frequencia'] ?? '2.4GHz',
      enabled: json['enabled'] ?? json['ativo'] ?? true,
      password: json['password'] ?? json['senha'],
    );
  }
}

class OnuWifiService {
  final String apiUrl;
  final String cpfCnpj;
  final String? senha;
  final String? contrato;
  final Map<String, String> sgpParams;

  OnuWifiService({
    required this.apiUrl,
    required this.cpfCnpj,
    this.senha,
    this.contrato,
    required this.sgpParams,
  });

  /// Helper to get base proxy URL
  String get _baseUrl {
    // Remove trailing slash and any path like /get-invoices
    String base = apiUrl.trim();
    // If URL ends with a path like /get-invoices, remove it
    final uri = Uri.tryParse(base);
    if (uri != null) {
      return '${uri.scheme}://${uri.host}:${uri.port}';
    }
    // Fallback: remove trailing slash
    return base.replaceAll(RegExp(r'/$'), '');
  }

  /// Busca dados da ONU (sinal, temperatura, etc)
  Future<OnuData> fetchOnuSignal() async {
    final url = '$_baseUrl/diagnostic/onu-signal';
    print('[ONU-Service] Calling: $url');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'cpfCnpj': cpfCnpj,
              'senha': senha,
              'contrato': contrato,
              'sgpParams': sgpParams,
              'sgpBaseUrl': sgpParams['sgpBaseUrl'],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return OnuData.fromJson(data['data']);
        }
        throw Exception('Dados da ONU não encontrados');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Erro ao buscar ONU');
      }
    } catch (e) {
      throw Exception('Erro ao buscar sinal da ONU: $e');
    }
  }

  /// Lista redes WiFi do CPE/Roteador
  Future<List<WifiNetwork>> fetchWifiNetworks() async {
    final url = '$_baseUrl/cpe/wifi/list';
    print('[WiFi-Service] Calling: $url');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'cpfCnpj': cpfCnpj,
              'senha': senha,
              'contrato': contrato,
              'sgpParams': sgpParams,
              'sgpBaseUrl': sgpParams['sgpBaseUrl'],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'] is List) {
          return (data['data'] as List)
              .map((w) => WifiNetwork.fromJson(w))
              .toList();
        }
        return [];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Erro ao buscar WiFi');
      }
    } catch (e) {
      throw Exception('Erro ao buscar redes WiFi: $e');
    }
  }

  /// Atualiza configuração WiFi (nome e senha)
  Future<bool> updateWifi({
    required String wifiId,
    required String ssid,
    required String password,
  }) async {
    final url = '$_baseUrl/cpe/wifi/update';
    print('[WiFi-Service] Calling: $url');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'cpfCnpj': cpfCnpj,
              'senha': senha,
              'contrato': contrato,
              'wifiId': wifiId,
              'ssid': ssid,
              'password': password,
              'sgpParams': sgpParams,
              'sgpBaseUrl': sgpParams['sgpBaseUrl'],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Erro ao atualizar WiFi');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar WiFi: $e');
    }
  }
}
