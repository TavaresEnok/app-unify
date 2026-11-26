import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'session_token_store.dart';

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

/// Erro de uma chamada TR-069 com o status HTTP, para a tela escolher a
/// mensagem certa (roteador não gerenciado, demora, falha comum).
class Tr069Exception implements Exception {
  final String message;
  final int? statusCode;
  final bool timeout;
  const Tr069Exception(this.message, {this.statusCode, this.timeout = false});

  /// O serviço deste assinante não tem roteador gerenciado pelo app.
  bool get unmanaged => statusCode == 422 || statusCode == 404;

  @override
  String toString() => message;
}

@immutable
class Tr069Capabilities {
  final bool enabled;
  final String driver;
  final Tr069Features features;

  /// `false` quando o serviço deste assinante não tem roteador gerenciado.
  /// `null` em servidores antigos que não informam (trata como hoje).
  final bool? deviceManaged;

  const Tr069Capabilities({
    this.enabled = false,
    this.driver = 'none',
    this.features = const Tr069Features(),
    this.deviceManaged,
  });

  /// Há o que gerenciar no roteador deste assinante.
  bool get manageable => enabled && deviceManaged != false;

  factory Tr069Capabilities.fromJson(Map<String, dynamic> json) =>
      Tr069Capabilities(
        enabled: json['enabled'] == true,
        deviceManaged: json['deviceManaged'] is bool
            ? json['deviceManaged'] as bool
            : null,
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
  final String mode;
  final String bandwidth;

  const Tr069WifiNetwork({
    required this.id,
    required this.ssid,
    required this.band,
    required this.channel,
    required this.enabled,
    required this.isGuest,
    this.mode = '',
    this.bandwidth = '',
  });

  factory Tr069WifiNetwork.fromJson(Map<String, dynamic> json) =>
      Tr069WifiNetwork(
        id: json['id']?.toString() ?? '',
        ssid: json['ssid']?.toString() ?? '',
        band: json['band']?.toString() ?? '',
        channel: json['channel']?.toString() ?? 'Auto',
        enabled: json['enabled'] != false,
        isGuest: json['isGuest'] == true,
        mode: json['mode']?.toString().trim() ?? '',
        bandwidth: json['bandwidth']?.toString().trim() ?? '',
      );

  bool get is5GHz => band.contains('5');

  /// "Wi-Fi 5 GHz" / "Wi-Fi 2,4 GHz".
  String get bandLabel => band.isEmpty
      ? 'Wi-Fi'
      : is5GHz
          ? 'Wi-Fi 5 GHz'
          : 'Wi-Fi 2,4 GHz';

  /// Geração do Wi-Fi pelo modo informado pelo roteador (ac → Wi-Fi 5).
  String get generationLabel {
    final m = mode.toLowerCase();
    if (m.contains('ax')) return 'Wi-Fi 6 (ax)';
    if (m.contains('ac')) return 'Wi-Fi 5 (ac)';
    if (m == 'n' || m.endsWith('/n') || m.endsWith('n')) return 'Wi-Fi 4 (n)';
    return '';
  }

  String get channelLabel {
    final c = channel.trim();
    if (c.isEmpty || c.toLowerCase() == 'auto' || c == '0') {
      return 'Canal automático';
    }
    return 'Canal $c';
  }

  /// "Wi-Fi 5 GHz · Canal 44 · Wi-Fi 5 (ac)".
  String get summary => [
        bandLabel,
        channelLabel,
        if (generationLabel.isNotEmpty) generationLabel,
      ].join(' · ');

  /// Redes que o assinante vê: as ativas (2,4 GHz antes de 5 GHz). Sem
  /// nenhuma ativa, a primeira de cada faixa. Redes virtuais desativadas
  /// ficam de fora; as de visitante entram quando o recurso existe.
  static List<Tr069WifiNetwork> visible(List<Tr069WifiNetwork> all,
      {bool includeGuest = false}) {
    final main = all.where((n) => !n.isGuest).toList();
    var shown = main.where((n) => n.enabled).toList();
    if (shown.isEmpty) {
      final seen = <bool>{};
      shown = [
        for (final n in main)
          if (seen.add(n.is5GHz)) n
      ];
    }
    shown.sort((a, b) => (a.is5GHz ? 1 : 0).compareTo(b.is5GHz ? 1 : 0));
    return [
      ...shown,
      if (includeGuest) ...all.where((n) => n.isGuest),
    ];
  }
}

/// Estado da fibra (ONU) do assinante, do ERP ou da OLT.
@immutable
class Tr069Fiber {
  final bool? online;
  final double? rxPowerDbm;
  final double? txPowerDbm;
  final DateTime? onlineSince;
  final String? lastDownCause;
  final double? distanceMeters;
  final String source;

  const Tr069Fiber({
    this.online,
    this.rxPowerDbm,
    this.txPowerDbm,
    this.onlineSince,
    this.lastDownCause,
    this.distanceMeters,
    this.source = 'snapshot',
  });

  static double? _num(Object? v) => v is num ? v.toDouble() : null;

  factory Tr069Fiber.fromJson(Map<String, dynamic> json) => Tr069Fiber(
        online: json['online'] is bool ? json['online'] as bool : null,
        rxPowerDbm: _num(json['rxPowerDbm']),
        txPowerDbm: _num(json['txPowerDbm']),
        onlineSince: DateTime.tryParse(json['onlineSince']?.toString() ?? ''),
        lastDownCause:
            (json['lastDownCause']?.toString().trim().isEmpty ?? true)
                ? null
                : json['lastDownCause'].toString().trim(),
        distanceMeters: _num(json['distanceMeters']),
        source: json['source']?.toString() ?? 'snapshot',
      );

  /// Mesmas faixas do diagnóstico (OnuData.signalQuality).
  String get signalLabel {
    final rx = rxPowerDbm;
    if (rx == null) return '';
    if (rx >= -23) return 'Excelente';
    if (rx >= -25) return 'Bom';
    if (rx >= -27) return 'Regular';
    return 'Fraco';
  }

  bool get signalWeak => rxPowerDbm != null && rxPowerDbm! < -27;
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

  static const unnamed = 'Aparelho sem nome';

  factory Tr069Host.fromJson(Map<String, dynamic> json) {
    final mac = json['mac']?.toString() ?? '';
    final raw = json['hostname']?.toString().trim() ?? '';
    // Servidores antigos mandam o MAC no lugar do nome.
    final looksLikeMac =
        RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$').hasMatch(raw);
    return Tr069Host(
      hostname:
          raw.isEmpty || looksLikeMac || raw.toUpperCase() == mac.toUpperCase()
              ? unnamed
              : raw,
      mac: mac,
      ip: json['ip']?.toString() ?? '',
      interfaceType: json['interfaceType']?.toString() ?? 'unknown',
      rssiDbm: json['rssiDbm'] is num ? (json['rssiDbm'] as num).round() : null,
      signalQuality: json['signalQuality']?.toString() ?? 'unknown',
    );
  }

  String get interfaceLabel => switch (interfaceType) {
        'ethernet' => 'Cabo',
        'wifi_5g' => 'Wi-Fi 5 GHz',
        'wifi_2g' => 'Wi-Fi 2,4 GHz',
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
  /// `null`: o gerenciador não sabe se o roteador está ligado agora.
  final bool? online;
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

  /// Quando os dados do roteador foram lidos (null = desconhecido).
  final DateTime? snapshotAt;
  final Tr069Fiber? fiber;

  /// Aparelhos vindos junto do status (null: servidor antigo, sem a lista).
  final List<Tr069Host>? hosts;

  /// `false`: o roteador não informa a senha salva; é preciso digitá-la.
  final bool? passwordReadable;

  /// `false`: só há dados da fibra; o roteador não é gerenciado pelo app.
  final bool? deviceManaged;

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
    this.snapshotAt,
    this.fiber,
    this.hosts,
    this.passwordReadable,
    this.deviceManaged,
  });

  factory Tr069Overview.fromJson(Map<String, dynamic> json) {
    final rawWifis = json['wifiNetworks'];
    final rawHosts = json['hosts'];
    final rawFiber = json['fiber'];
    return Tr069Overview(
      online: json['online'] is bool ? json['online'] as bool : null,
      snapshotAt: DateTime.tryParse(json['snapshotAt']?.toString() ?? ''),
      fiber: rawFiber is Map
          ? Tr069Fiber.fromJson(Map<String, dynamic>.from(rawFiber))
          : null,
      hosts: rawHosts is List
          ? rawHosts
              .whereType<Map>()
              .map((m) => Tr069Host.fromJson(Map<String, dynamic>.from(m)))
              .toList()
          : null,
      passwordReadable: json['passwordReadable'] is bool
          ? json['passwordReadable'] as bool
          : null,
      deviceManaged:
          json['deviceManaged'] is bool ? json['deviceManaged'] as bool : null,
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

  /// Há roteador com dados para mostrar (e não só a fibra).
  bool get hasRouter =>
      deviceManaged != false &&
      (wifiNetworks.isNotEmpty ||
          model.isNotEmpty ||
          manufacturer.isNotEmpty ||
          firmware.isNotEmpty);
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
      return await SessionTokenStore.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<Tr069Capabilities> fetchCapabilities({String? contratoId}) async =>
      await fetchCapabilitiesOrNull(contratoId: contratoId) ??
      const Tr069Capabilities();

  /// Como [fetchCapabilities], mas `null` quando a consulta falha (rede,
  /// sessão, servidor), para distinguir "desligado" de "não sei".
  Future<Tr069Capabilities?> fetchCapabilitiesOrNull(
      {String? contratoId}) async {
    final base = _base;
    if (base == null) return null;
    final token = await _token();
    if (token == null || token.isEmpty) return null;
    try {
      final res = await _client.get(
        Uri.parse('$base/tr069/capabilities${_contractQuery(contratoId)}'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      final data = body is Map ? body['data'] : null;
      if (data is Map) {
        return Tr069Capabilities.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String _contractQuery(String? contratoId) =>
      contratoId != null && contratoId.isNotEmpty
          ? '?contratoId=${Uri.encodeQueryComponent(contratoId)}'
          : '';

  static const slowRouterMessage =
      'O roteador está demorando para responder. Aguarde 1 minuto e toque em Consultar novamente antes de tentar de novo.';

  Future<Tr069Overview?> fetchStatus({String? contratoId}) async {
    final base = _base;
    final token = await _token();
    if (base == null || token == null || token.isEmpty) return null;
    final http.Response res;
    try {
      res = await _client.get(
        Uri.parse('$base/tr069/status${_contractQuery(contratoId)}'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw const Tr069Exception(
          'O roteador está demorando para responder. Tente de novo em instantes.',
          timeout: true);
    }
    if (res.statusCode != 200) {
      throw Tr069Exception(
          _extractError(res.body, 'Falha ao consultar roteador.'),
          statusCode: res.statusCode);
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
    final res = await _client.get(
      Uri.parse('$base/tr069/hosts${_contractQuery(contratoId)}'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 25));
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
    final http.Response res;
    try {
      res = await _client
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
          // Acima do teto API→proxy→ERP (40 s): a escrita pode levar 3 chamadas.
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw const Tr069Exception(slowRouterMessage, timeout: true);
    }
    if (res.statusCode >= 400) {
      throw Tr069Exception(_extractError(res.body, 'Falha ao atualizar Wi-Fi.'),
          statusCode: res.statusCode);
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
