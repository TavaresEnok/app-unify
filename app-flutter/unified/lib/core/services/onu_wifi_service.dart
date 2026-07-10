// ARQUIVO: lib/core/services/onu_wifi_service.dart
// DESCRIÇÃO: Serviço para buscar sinal da ONU e gerenciar WiFi via SGP/TR069

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final double? biasCurrent;

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
    this.biasCurrent,
  });

  factory OnuData.fromJson(Map<String, dynamic> json) {
    // SGP field mapping based on real API response
    // info_rx might be string "-23.188", needs parsing
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    final rawRx = json['info_rx'] ?? json['rx_power'] ?? json['signalRx'];
    final rawTx = json['info_tx'] ?? json['tx_power'] ?? json['signalTx'];
    final rawTemp = json['temperature'] ?? json['temp'];
    final rawVoltage = json['voltage'];

    final status = json['connectionStatus']?.toString() ??
        json['status_connection']?.toString() ??
        (json['online'] == true ? 'Online' : 'Offline');

    return OnuData(
      signalRx: parseDouble(rawRx),
      signalTx: parseDouble(rawTx),
      connectionStatus: status,
      isOnline:
          status.toLowerCase().contains('online') || json['online'] == true,
      oltId: json['olt_id'] ?? json['oltId'] ?? 0,
      oltName: json['olt_name'] ?? json['oltName'],
      slot: json['slot'] ?? 0,
      pon: json['pon'] ?? 0,
      onuId: json['onuid'] ?? json['onuId'] ?? 0,
      temperature: parseDouble(rawTemp),
      voltage: parseDouble(rawVoltage),
      model: json['type'] ?? json['model'] ?? 'Desconhecido',
      serialNumber: json['phy_addr'] ?? json['serialNumber'],
      mode: json['mode'],
      vlan: json['vlan'],
      cto: json['cto'],
      lastUpdate: json['info_date'] ?? json['lastUpdate'],
      biasCurrent: parseDouble(
          json['info_bias'] ?? json['bias_current'] ?? json['bias']),
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
  final String? channel;
  final String? security;

  WifiNetwork({
    required this.id,
    required this.ssid,
    required this.frequency,
    required this.enabled,
    this.password,
    this.channel,
    this.security,
  });

  factory WifiNetwork.fromJson(Map<String, dynamic> json) {
    return WifiNetwork(
      id: json['id']?.toString() ?? '',
      ssid: json['ssid'] ?? json['nome'] ?? '',
      frequency: json['frequency'] ?? json['frequencia'] ?? '2.4GHz',
      enabled: json['enabled'] ?? json['ativo'] ?? true,
      password: json['password'] ?? json['senha'],
      channel: json['channel']?.toString() ?? json['canal']?.toString(),
      security: json['security'] ??
          json['encryption'] ??
          json['auth_mode'] ??
          json['seguranca'],
    );
  }
}

class OnuWifiService {
  final String apiUrl;
  final String cpfCnpj;
  final String? senha;
  final String? contrato;
  final Map<String, String> sgpParams;
  final http.Client client;

  OnuWifiService({
    required this.apiUrl,
    required this.cpfCnpj,
    this.senha,
    this.contrato,
    required this.sgpParams,
    http.Client? client,
  }) : client = client ?? http.Client();

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
    if (kDebugMode) debugPrint('[ONU-Service] Iniciando consulta de sinal.');

    try {
      String? token;
      try {
        token = await FirebaseAuth.instance.currentUser?.getIdToken();
      } catch (_) {}
      final response = await client
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
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
          throw Exception(
            error['error']?['message'] ??
                'Erro no servidor (${response.statusCode})',
          );
        } catch (_) {
          throw Exception('Erro no servidor (${response.statusCode})');
        }
      }
    } on http.ClientException catch (_) {
      throw Exception(
        'Servidor indisponível.\nVerifique se o servidor local está rodando.',
      );
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
        'Erro ao buscar sinal: ${e.toString().replaceAll("Exception:", "").trim()}',
      );
    }
  }

  /// Lista redes WiFi do CPE/Roteador
  Future<List<WifiNetwork>> fetchWifiNetworks() async {
    final url = '$_baseUrl/cpe/wifi/list';
    if (kDebugMode) debugPrint('[WiFi-Service] Consultando redes.');

    try {
      String? token;
      try {
        token = await FirebaseAuth.instance.currentUser?.getIdToken();
      } catch (_) {}
      final response = await client
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
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
          throw Exception(
            error['error']?['message'] ??
                'Erro no servidor (${response.statusCode})',
          );
        } catch (_) {
          throw Exception('Erro no servidor (${response.statusCode})');
        }
      }
    } on http.ClientException catch (_) {
      throw Exception(
        'Servidor indisponível.\nVerifique se o servidor local está rodando.',
      );
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
        'Erro ao buscar WiFi: ${e.toString().replaceAll("Exception:", "").trim()}',
      );
    }
  }

  /// Atualiza configuração WiFi (nome e senha)
  Future<bool> updateWifi({
    required String wifiId,
    required String ssid,
    required String password,
  }) async {
    final url = '$_baseUrl/cpe/wifi/update';
    if (kDebugMode) debugPrint('[WiFi-Service] Atualizando configuracao.');

    try {
      String? token;
      try {
        token = await FirebaseAuth.instance.currentUser?.getIdToken();
      } catch (_) {}
      final response = await client
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
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
          throw Exception(
            error['error']?['message'] ??
                'Erro no servidor (${response.statusCode})',
          );
        } catch (_) {
          throw Exception('Erro no servidor (${response.statusCode})');
        }
      }
    } on http.ClientException catch (_) {
      throw Exception(
        'Servidor indisponível.\nVerifique se o servidor local está rodando.',
      );
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        throw Exception('Sem conexão com o servidor local.');
      }
      throw Exception(
        'Erro ao atualizar WiFi: ${e.toString().replaceAll("Exception:", "").trim()}',
      );
    }
  }
}
