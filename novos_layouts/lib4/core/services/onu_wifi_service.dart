// ARQUIVO: lib/core/services/onu_wifi_service.dart
// DESCRIÇÃO: Serviço para buscar sinal da ONU e gerenciar WiFi via SGP/TR069

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class OnuData {
  final double? signalRx; // null if N/A or offline
  final double? signalTx; // null if N/A or offline
  final String connectionStatus;
  final bool isOnline;
  final int oltId;
  final String? oltName;
  final int slot;
  final int pon;
  final int onuId;
  final double? temperature;
  final double? voltage;
  final String model;
  final String? serialNumber;
  // New fields from SGP
  final String? mode; // Bridge, Router, etc
  final int? vlan;
  final String? cto; // CTO location
  final String? lastUpdate;

  OnuData({
    this.signalRx,
    this.signalTx,
    required this.connectionStatus,
    required this.isOnline,
    required this.oltId,
    this.oltName,
    required this.slot,
    required this.pon,
    required this.onuId,
    this.temperature,
    this.voltage,
    required this.model,
    this.serialNumber,
    this.mode,
    this.vlan,
    this.cto,
    this.lastUpdate,
  });

  factory OnuData.fromJson(Map<String, dynamic> json) {
    final status = json['connectionStatus']?.toString() ?? 'unknown';
    return OnuData(
      signalRx: json['signalRx']?.toDouble(),
      signalTx: json['signalTx']?.toDouble(),
      connectionStatus: status,
      isOnline: status.toLowerCase() == 'online',
      oltId: json['oltId'] ?? 0,
      oltName: json['oltName'],
      slot: json['slot'] ?? 0,
      pon: json['pon'] ?? 0,
      onuId: json['onuId'] ?? 0,
      temperature: json['temperature']?.toDouble(),
      voltage: json['voltage']?.toDouble(),
      model: json['model'] ?? 'Desconhecido',
      serialNumber: json['serialNumber'],
      mode: json['mode'],
      vlan: json['vlan'],
      cto: json['cto'],
      lastUpdate: json['lastUpdate'],
    );
  }

  /// Qualidade do sinal baseada no RX
  String get signalQuality {
    if (signalRx == null) return 'Sem dados';
    if (signalRx! >= -23) return 'Excelente';
    if (signalRx! >= -25) return 'Bom';
    if (signalRx! >= -27) return 'Regular';
    return 'Ruim';
  }

  /// Cor do sinal baseada no RX
  bool get isSignalGood => signalRx != null && signalRx! >= -25;

  /// Retorna string formatada do sinal RX
  String get signalRxDisplay =>
      signalRx != null ? '${signalRx!.toStringAsFixed(1)} dBm' : 'N/A';

  /// Retorna string formatada do sinal TX
  String get signalTxDisplay =>
      signalTx != null ? '${signalTx!.toStringAsFixed(1)} dBm' : 'N/A';
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
    debugPrint('[ONU-Service] Calling: $url');

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
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return OnuData.fromJson(data['data']);
        }
        throw Exception('Dados da ONU não encontrados.');
      } else {
        // Tenta parsear erro do servidor
        try {
          final error = json.decode(response.body);
          throw Exception(error['error']?['message'] ??
              'Erro no servidor (${response.statusCode})');
        } catch (_) {
          throw Exception('Erro no servidor (${response.statusCode})');
        }
      }
    } on http.ClientException catch (_) {
      throw Exception(
          'Servidor indisponível.\nVerifique se o servidor local está rodando.');
    } on FormatException catch (_) {
      throw Exception('Resposta inválida do servidor.');
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        throw Exception('Sem conexão com o servidor local.');
      }
      if (e.toString().contains('Timeout')) {
        throw Exception('Tempo limite excedido ao conectar ao servidor.');
      }
      throw Exception(
          'Erro ao buscar sinal: ${e.toString().replaceAll("Exception:", "").trim()}');
    }
  }

  /// Lista redes WiFi do CPE/Roteador
  Future<List<WifiNetwork>> fetchWifiNetworks() async {
    final url = '$_baseUrl/cpe/wifi/list';
    debugPrint('[WiFi-Service] Calling: $url');

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
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'] is List) {
          return (data['data'] as List)
              .map((w) => WifiNetwork.fromJson(w))
              .toList();
        }
        return [];
      } else {
        try {
          final error = json.decode(response.body);
          throw Exception(error['error']?['message'] ??
              'Erro no servidor (${response.statusCode})');
        } catch (_) {
          throw Exception('Erro no servidor (${response.statusCode})');
        }
      }
    } on http.ClientException catch (_) {
      throw Exception(
          'Servidor indisponível.\nVerifique se o servidor local está rodando.');
    } on FormatException catch (_) {
      throw Exception('Resposta inválida do servidor.');
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        throw Exception('Sem conexão com o servidor local.');
      }
      if (e.toString().contains('Timeout')) {
        throw Exception('Tempo limite excedido ao conectar ao servidor.');
      }
      throw Exception(
          'Erro ao buscar WiFi: ${e.toString().replaceAll("Exception:", "").trim()}');
    }
  }

  /// Atualiza configuração WiFi (nome e senha)
  Future<bool> updateWifi({
    required String wifiId,
    required String ssid,
    required String password,
  }) async {
    final url = '$_baseUrl/cpe/wifi/update';
    debugPrint('[WiFi-Service] Calling: $url');

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
        try {
          final error = json.decode(response.body);
          throw Exception(error['error']?['message'] ??
              'Erro no servidor (${response.statusCode})');
        } catch (_) {
          throw Exception('Erro no servidor (${response.statusCode})');
        }
      }
    } on http.ClientException catch (_) {
      throw Exception(
          'Servidor indisponível.\nVerifique se o servidor local está rodando.');
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        throw Exception('Sem conexão com o servidor local.');
      }
      throw Exception(
          'Erro ao atualizar WiFi: ${e.toString().replaceAll("Exception:", "").trim()}');
    }
  }
}
