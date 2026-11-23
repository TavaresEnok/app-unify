import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

@immutable
class Tr069Features {
  final bool wifi;
  final bool reboot;
  final bool hosts;
  final bool guestWifi;
  final bool channelOptimize;
  final bool speedDiagnostic;

  const Tr069Features({
    this.wifi = false,
    this.reboot = false,
    this.hosts = false,
    this.guestWifi = false,
    this.channelOptimize = false,
    this.speedDiagnostic = false,
  });

  factory Tr069Features.fromJson(Map<String, dynamic> json) => Tr069Features(
        wifi: json['wifi'] == true,
        reboot: json['reboot'] == true,
        hosts: json['hosts'] == true,
        guestWifi: json['guestWifi'] == true,
        channelOptimize: json['channelOptimize'] == true,
        speedDiagnostic: json['speedDiagnostic'] == true,
      );
}

@immutable
class Tr069Capabilities {
  final bool enabled;
  final String driver;
  final Tr069Features features;

  const Tr069Capabilities({
    this.enabled = false,
    this.driver = 'none',
    this.features = const Tr069Features(),
  });

  factory Tr069Capabilities.fromJson(Map<String, dynamic> json) =>
      Tr069Capabilities(
        enabled: json['enabled'] == true,
        driver: json['driver']?.toString() ?? 'none',
        features: json['features'] is Map
            ? Tr069Features.fromJson(
                Map<String, dynamic>.from(json['features'] as Map))
            : const Tr069Features(),
      );
}

@immutable
class Tr069WifiNetwork {
  final String id;
  final String ssid;
  final String band;
  final String channel;
  final bool enabled;
  final bool isGuest;

  const Tr069WifiNetwork({
    required this.id,
    required this.ssid,
    required this.band,
    required this.channel,
    required this.enabled,
    required this.isGuest,
  });

  factory Tr069WifiNetwork.fromJson(Map<String, dynamic> json) =>
      Tr069WifiNetwork(
        id: json['id']?.toString() ?? '',
        ssid: json['ssid']?.toString() ?? '',
        band: json['band']?.toString() ?? '',
        channel: json['channel']?.toString() ?? 'Auto',
        enabled: json['enabled'] != false,
        isGuest: json['isGuest'] == true,
      );
}

@immutable
class Tr069Host {
  final String hostname;
  final String mac;
  final String ip;
  final String interfaceType;
  final int? rssiDbm;
  final String signalQuality;

  const Tr069Host({
    required this.hostname,
    required this.mac,
    required this.ip,
    required this.interfaceType,
    this.rssiDbm,
    required this.signalQuality,
  });

  factory Tr069Host.fromJson(Map<String, dynamic> json) => Tr069Host(
        hostname: json['hostname']?.toString() ?? 'Dispositivo',
        mac: json['mac']?.toString() ?? '',
        ip: json['ip']?.toString() ?? '',
        interfaceType: json['interfaceType']?.toString() ?? 'unknown',
        rssiDbm: json['rssiDbm'] is num ? (json['rssiDbm'] as num).round() : null,
        signalQuality: json['signalQuality']?.toString() ?? 'unknown',
      );

  String get interfaceLabel => switch (interfaceType) {
        'ethernet' => 'Cabo',
        'wifi_5g' => 'Wi-Fi 5 GHz',
        'wifi_2g' => 'Wi-Fi 2.4 GHz',
        _ => 'Rede local',
      };

  String get qualityLabel => switch (signalQuality) {
        'wired' => 'Cabo',
        'excellent' => 'Sinal excelente',
        'good' => 'Sinal bom',
        'fair' => 'Sinal médio',
        'weak' => 'Sinal fraco',
        _ => '',
      };
}

@immutable
class Tr069Overview {
  final bool online;
  final String driver;
  final String manufacturer;
  final String model;
  final String firmware;
  final int? uptimeSeconds;
  final bool lanBottleneck100Mbps;
  final int? planDownloadMbps;
  final double? opticalRxDbm;
  final List<Tr069WifiNetwork> wifiNetworks;
  final int hostsCount;

  const Tr069Overview({
    required this.online,
    required this.driver,
    required this.manufacturer,
    required this.model,
    required this.firmware,
    this.uptimeSeconds,
    required this.lanBottleneck100Mbps,
    this.planDownloadMbps,
    this.opticalRxDbm,
    required this.wifiNetworks,
    required this.hostsCount,
  });

  factory Tr069Overview.fromJson(Map<String, dynamic> json) {
    final rawWifis = json['wifiNetworks'];
    return Tr069Overview(
      online: json['online'] == true,
      driver: json['driver']?.toString() ?? 'sgp',
      manufacturer: json['manufacturer']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      firmware: json['firmware']?.toString() ?? '',
      uptimeSeconds: json['uptimeSeconds'] is num
          ? (json['uptimeSeconds'] as num).round()
          : null,
      lanBottleneck100Mbps: json['lanBottleneck100Mbps'] == true,
      planDownloadMbps: json['planDownloadMbps'] is num
          ? (json['planDownloadMbps'] as num).round()
          : null,
      opticalRxDbm: json['opticalRxDbm'] is num
          ? (json['opticalRxDbm'] as num).toDouble()
          : null,
      wifiNetworks: rawWifis is List
          ? rawWifis
              .whereType<Map>()
              .map((m) =>
                  Tr069WifiNetwork.fromJson(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
      hostsCount:
          json['hostsCount'] is num ? (json['hostsCount'] as num).round() : 0,
    );
  }
}

@immutable
class Tr069Diagnostic {
  final String summary;
  final double? pingMs;
  final double? downloadMbps;
  final String verdict;

  const Tr069Diagnostic({
    required this.summary,
    this.pingMs,
    this.downloadMbps,
    required this.verdict,
  });

  factory Tr069Diagnostic.fromJson(Map<String, dynamic> json) =>
      Tr069Diagnostic(
        summary: json['summary']?.toString() ?? 'Diagnóstico concluído.',
        pingMs:
            json['pingMs'] is num ? (json['pingMs'] as num).toDouble() : null,
        downloadMbps: json['downloadMbps'] is num
            ? (json['downloadMbps'] as num).toDouble()
            : null,
        verdict: json['verdict']?.toString() ?? 'unavailable',
      );
}

class Tr069Service {
  final String? apiUrl;
  final http.Client _client;
  final bool _ownsClient;

  Tr069Service({required this.apiUrl, http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  void dispose() {
    if (_ownsClient) _client.close();
  }

  String? get _base {
    final trimmed = apiUrl?.trim().replaceAll(RegExp(r'/+$'), '') ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<String?> _token() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  Future<Tr069Capabilities> fetchCapabilities() async {
    final base = _base;
    if (base == null) return const Tr069Capabilities();
    final token = await _token();
    if (token == null || token.isEmpty) return const Tr069Capabilities();
    try {
      final res = await _client
          .get(
            Uri.parse('$base/tr069/capabilities'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return const Tr069Capabilities();
      final body = jsonDecode(res.body);
      final data = body is Map ? body['data'] : null;
      if (data is Map) {
        return Tr069Capabilities.fromJson(Map<String, dynamic>.from(data));
      }
      return const Tr069Capabilities();
    } catch (_) {
      return const Tr069Capabilities();
    }
  }

  Future<Tr069Overview?> fetchStatus({String? contratoId}) async {
    final base = _base;
    final token = await _token();
    if (base == null || token == null || token.isEmpty) return null;
    final q = contratoId != null && contratoId.isNotEmpty
        ? '?contratoId=${Uri.encodeQueryComponent(contratoId)}'
        : '';
    final res = await _client
        .get(
          Uri.parse('$base/tr069/status$q'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body, 'Falha ao consultar roteador.'));
    }
    final body = jsonDecode(res.body);
    final data = body is Map ? body['data'] : null;
    return data is Map
        ? Tr069Overview.fromJson(Map<String, dynamic>.from(data))
        : null;
  }

  Future<List<Tr069Host>> fetchHosts({String? contratoId}) async {
    final base = _base;
    final token = await _token();
    if (base == null || token == null || token.isEmpty) return const [];
    final q = contratoId != null && contratoId.isNotEmpty
        ? '?contratoId=${Uri.encodeQueryComponent(contratoId)}'
        : '';
    final res = await _client
        .get(
          Uri.parse('$base/tr069/hosts$q'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return const [];
    final body = jsonDecode(res.body);
    final data = body is Map ? body['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((m) => Tr069Host.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<String> updateWifi({
    required String wifiId,
    String? ssid,
    String? password,
    bool? enabled,
    bool isGuest = false,
    String? contratoId,
  }) async {
    final base = _base;
    final token = await _token();
    if (base == null || token == null || token.isEmpty) {
      throw Exception('Sessão indisponível.');
    }
    final res = await _client
        .post(
          Uri.parse('$base/tr069/wifi'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'wifiId': wifiId,
            if (ssid != null && ssid.isNotEmpty) 'ssid': ssid,
            if (password != null && password.isNotEmpty) 'password': password,
            if (enabled != null) 'enabled': enabled,
            'isGuest': isGuest,
            if (contratoId != null && contratoId.isNotEmpty)
              'contratoId': contratoId,
          }),
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode >= 400) {
      throw Exception(_extractError(res.body, 'Falha ao atualizar Wi-Fi.'));
    }
    final body = jsonDecode(res.body);
    return (body is Map ? body['message']?.toString() : null) ??
        'Wi-Fi atualizado!';
  }

  Future<String> reboot({String? contratoId}) async {
    final base = _base;
    final token = await _token();
    if (base == null || token == null || token.isEmpty) {
      throw Exception('Sessão indisponível.');
    }
    final res = await _client
        .post(
          Uri.parse('$base/tr069/reboot'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            if (contratoId != null && contratoId.isNotEmpty)
              'contratoId': contratoId,
          }),
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode >= 400) {
      throw Exception(_extractError(res.body, 'Não foi possível reiniciar.'));
    }
    final body = jsonDecode(res.body);
    return (body is Map ? body['message']?.toString() : null) ??
        'Reinicialização enviada!';
  }

  Future<String> optimizeWifi({String? contratoId}) async {
    final base = _base;
    final token = await _token();
    if (base == null || token == null || token.isEmpty) {
      throw Exception('Sessão indisponível.');
    }
    final res = await _client
        .post(
          Uri.parse('$base/tr069/optimize-wifi'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            if (contratoId != null && contratoId.isNotEmpty)
              'contratoId': contratoId,
          }),
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode >= 400) {
      throw Exception(
          _extractError(res.body, 'Não foi possível otimizar o canal.'));
    }
    final body = jsonDecode(res.body);
    return (body is Map ? body['message']?.toString() : null) ??
        'Canal otimizado!';
  }

  Future<Tr069Diagnostic> runDiagnostic({
    String target = '8.8.8.8',
    String? contratoId,
  }) async {
    final base = _base;
    final token = await _token();
    if (base == null || token == null || token.isEmpty) {
      throw Exception('Sessão indisponível.');
    }
    final res = await _client
        .post(
          Uri.parse('$base/tr069/diagnostic'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'target': target,
            if (contratoId != null && contratoId.isNotEmpty)
              'contratoId': contratoId,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode >= 400) {
      throw Exception(
          _extractError(res.body, 'Falha no diagnóstico do roteador.'));
    }
    final body = jsonDecode(res.body);
    final data = body is Map ? body['data'] : null;
    if (data is Map) {
      return Tr069Diagnostic.fromJson(Map<String, dynamic>.from(data));
    }
    return const Tr069Diagnostic(
        summary: 'Diagnóstico disparado no roteador.', verdict: 'unavailable');
  }

  String _extractError(String body, String fallback) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map) {
        final err = parsed['error'];
        if (err is Map && err['message'] != null) {
          return err['message'].toString();
        }
        if (parsed['message'] != null) return parsed['message'].toString();
      }
    } catch (_) {}
    return fallback;
  }
}
