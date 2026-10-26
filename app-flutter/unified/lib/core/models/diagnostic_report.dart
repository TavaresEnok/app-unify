import 'diagnostico_state.dart';

/// Modelo TIPADO de um diagnóstico concluído.
///
/// Existe para quebrar a dívida central do fluxo: `testResultsDisplay[key]
/// ['result']` é ora `String`, ora `Map`, e cada consumidor (PDF, telas,
/// integrações) reparseava o texto já formatado com regex. Aqui a conversão
/// acontece UMA vez, e relatório, laudo, persistência e payload de chamado
/// passam a ler dados estruturados.
class DiagnosticReport {
  final DateTime generatedAt;
  final ReportCustomer customer;
  final ReportProvider provider;

  final WifiMetrics? wifi;
  final OnuMetrics? onu;
  final DeviceMetrics? device;
  final PingMetrics? gatewayPing;
  final PingMetrics? googlePing;
  final PingMetrics? cloudflarePing;
  final SpeedMetrics? speed;
  final PublicIpInfo? publicIp;
  final List<TracerouteHop> traceroute;
  final int? lanDeviceCount;

  const DiagnosticReport({
    required this.generatedAt,
    required this.customer,
    required this.provider,
    this.wifi,
    this.onu,
    this.device,
    this.gatewayPing,
    this.googlePing,
    this.cloudflarePing,
    this.speed,
    this.publicIp,
    this.traceroute = const [],
    this.lanDeviceCount,
  });

  /// Melhor medição de latência externa disponível (Google, senão Cloudflare).
  PingMetrics? get externalPing {
    final g = googlePing;
    if (g != null && g.reachable) return g;
    final c = cloudflarePing;
    if (c != null && c.reachable) return c;
    return g ?? c;
  }

  factory DiagnosticReport.fromState(
    DiagnosticoState state, {
    required ReportCustomer customer,
    required ReportProvider provider,
    DateTime? generatedAt,
  }) {
    final d = state.testResultsDisplay;

    return DiagnosticReport(
      generatedAt: generatedAt ?? DateTime.now(),
      customer: customer,
      provider: provider,
      wifi: WifiMetrics.fromEntry(d['wifiInfo']),
      onu: OnuMetrics.fromEntry(d['onuInfo']),
      device: DeviceMetrics.fromEntries(d['deviceInfo'], d['batteryInfo']),
      gatewayPing: PingMetrics.fromEntry(d['pingGateway'], fallbackHost: 'Roteador'),
      googlePing: PingMetrics.fromEntry(d['pingGoogle'], fallbackHost: '8.8.8.8'),
      cloudflarePing:
          PingMetrics.fromEntry(d['pingCloudflare'], fallbackHost: '1.1.1.1'),
      speed: SpeedMetrics.fromState(state),
      publicIp: PublicIpInfo.fromEntry(d['publicIp']),
      traceroute: TracerouteHop.parseAll(_resultString(d['traceroute'])),
      lanDeviceCount: _firstInt(_resultString(d['lanScan'])),
    );
  }

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toIso8601String(),
        'customer': customer.toJson(),
        'provider': provider.toJson(),
        if (wifi != null) 'wifi': wifi!.toJson(),
        if (onu != null) 'onu': onu!.toJson(),
        if (device != null) 'device': device!.toJson(),
        if (gatewayPing != null) 'gatewayPing': gatewayPing!.toJson(),
        if (googlePing != null) 'googlePing': googlePing!.toJson(),
        if (cloudflarePing != null) 'cloudflarePing': cloudflarePing!.toJson(),
        if (speed != null) 'speed': speed!.toJson(),
        if (publicIp != null) 'publicIp': publicIp!.toJson(),
        if (traceroute.isNotEmpty)
          'traceroute': traceroute.map((h) => h.toJson()).toList(),
        if (lanDeviceCount != null) 'lanDeviceCount': lanDeviceCount,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Identificação
// ─────────────────────────────────────────────────────────────────────────────

class ReportCustomer {
  final String name;
  final String cpfCnpj;
  final int? contractId;
  final String planName;

  /// Velocidade contratada em Mbps, inferida do nome do plano (ex.: "VIBE 500
  /// MEGA" → 500, "FIBRA 1 GIGA" → 1000). Null quando não dá para inferir.
  final double? contractedDownloadMbps;

  const ReportCustomer({
    required this.name,
    required this.cpfCnpj,
    required this.planName,
    this.contractId,
    this.contractedDownloadMbps,
  });

  factory ReportCustomer.fromPlan({
    required String name,
    required String cpfCnpj,
    required String planName,
    int? contractId,
  }) {
    return ReportCustomer(
      name: name,
      cpfCnpj: cpfCnpj,
      planName: planName,
      contractId: contractId,
      contractedDownloadMbps: parseContractedMbps(planName),
    );
  }

  /// CPF/CNPJ parcialmente mascarado — o relatório circula por WhatsApp, então
  /// não expomos o documento inteiro. O contrato identifica o cliente no SGP.
  String get maskedDocument {
    final digits = cpfCnpj.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 5) return '***';
    return '***.${digits.substring(digits.length - 5, digits.length - 2)}.${digits.substring(digits.length - 2)}';
  }

  static double? parseContractedMbps(String plan) {
    final match = RegExp(r'(\d+(?:[.,]\d+)?)\s*(GIGA|GB|G\b|MEGA|MB|M\b)',
            caseSensitive: false)
        .firstMatch(plan);
    if (match == null) return null;
    final value = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (value == null) return null;
    final unit = match.group(2)!.toUpperCase();
    final isGiga = unit.startsWith('G');
    return isGiga ? value * 1000 : value;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'document': maskedDocument,
        'contractId': contractId,
        'planName': planName,
        'contractedDownloadMbps': contractedDownloadMbps,
      };
}

class ReportProvider {
  final String id;
  final String name;
  final String? logoUrl;

  const ReportProvider({required this.id, required this.name, this.logoUrl});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

// ─────────────────────────────────────────────────────────────────────────────
// Métricas
// ─────────────────────────────────────────────────────────────────────────────

class PingMetrics {
  final String host;
  final bool reachable;
  final double? latencyMs;
  final double? jitterMs;
  final double lossPercent;
  final double? minMs;
  final double? maxMs;

  const PingMetrics({
    required this.host,
    required this.reachable,
    required this.lossPercent,
    this.latencyMs,
    this.jitterMs,
    this.minMs,
    this.maxMs,
  });

  /// Lê primeiro `metrics` (tipado, emitido pelo serviço). Só cai para o parse
  /// do texto quando a medição veio de uma versão antiga do estado.
  static PingMetrics? fromEntry(Map<String, dynamic>? entry,
      {required String fallbackHost}) {
    if (entry == null) return null;
    final m = entry['metrics'];
    if (m is Map) {
      return PingMetrics(
        host: (m['host'] ?? fallbackHost).toString(),
        reachable: m['reachable'] == true,
        latencyMs: _toDouble(m['latencyMs']),
        jitterMs: _toDouble(m['jitterMs']),
        lossPercent: _toDouble(m['lossPercent']) ?? 0,
        minMs: _toDouble(m['minMs']),
        maxMs: _toDouble(m['maxMs']),
      );
    }

    final text = _resultString(entry);
    if (text == null || text.isEmpty) return null;
    final latency = _labelledDouble(text, 'Latência');
    return PingMetrics(
      host: fallbackHost,
      reachable: latency != null,
      latencyMs: latency,
      jitterMs: _labelledDouble(text, 'Jitter'),
      lossPercent: _labelledDouble(text, 'Perda') ?? (latency == null ? 100 : 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'host': host,
        'reachable': reachable,
        'latencyMs': latencyMs,
        'jitterMs': jitterMs,
        'lossPercent': lossPercent,
      };
}

class SpeedMetrics {
  final double downloadMbps;
  final double uploadMbps;
  final double? pingMs;
  final double? referenceDownloadMbps;

  const SpeedMetrics({
    required this.downloadMbps,
    required this.uploadMbps,
    this.pingMs,
    this.referenceDownloadMbps,
  });

  static SpeedMetrics? fromState(DiagnosticoState state) {
    if (state.customDownloadResultMbps <= 0 &&
        state.customUploadResultMbps <= 0) {
      return null;
    }
    return SpeedMetrics(
      downloadMbps: state.customDownloadResultMbps,
      uploadMbps: state.customUploadResultMbps,
      pingMs: state.speedTestPingLatency,
      referenceDownloadMbps: state.fastDownloadResultMbps > 0
          ? state.fastDownloadResultMbps
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'downloadMbps': downloadMbps,
        'uploadMbps': uploadMbps,
        'pingMs': pingMs,
        'referenceDownloadMbps': referenceDownloadMbps,
      };
}

class OnuMetrics {
  final double? rxPower;
  final double? txPower;
  final String status;
  final String signalQuality;
  final String model;
  final String serialNumber;
  final String oltName;
  final String slot;
  final String pon;
  final String onuId;
  final String mode;
  final String vlan;
  final String lastUpdate;
  final double? temperature;

  const OnuMetrics({
    this.rxPower,
    this.txPower,
    this.status = '---',
    this.signalQuality = '---',
    this.model = '---',
    this.serialNumber = '---',
    this.oltName = '---',
    this.slot = '---',
    this.pon = '---',
    this.onuId = '---',
    this.mode = '---',
    this.vlan = '---',
    this.lastUpdate = '---',
    this.temperature,
  });

  bool get isOnline => status.toLowerCase().contains('online');

  static OnuMetrics? fromEntry(Map<String, dynamic>? entry) {
    final raw = entry?['result'];
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    return OnuMetrics(
      rxPower: _toDouble(m['rxPower']),
      txPower: _toDouble(m['txPower']),
      status: _text(m['status']),
      signalQuality: _text(m['signalQuality']),
      model: _text(m['model']),
      serialNumber: _text(m['serialNumber']),
      oltName: _text(m['oltName']),
      slot: _text(m['slot']),
      pon: _text(m['pon']),
      onuId: _text(m['onuId']),
      mode: _text(m['mode']),
      vlan: _text(m['vlan']),
      lastUpdate: _text(m['lastUpdate']),
      temperature: _toDouble(m['temperature']),
    );
  }

  Map<String, dynamic> toJson() => {
        'rxPower': rxPower,
        'txPower': txPower,
        'status': status,
        'signalQuality': signalQuality,
        'model': model,
        'serialNumber': serialNumber,
        'oltName': oltName,
        'slot': slot,
        'pon': pon,
        'onuId': onuId,
      };
}

class WifiMetrics {
  final String ssid;
  final String frequency;
  final String signalStrength;
  final String bssid;
  final String ip;
  final String gateway;
  final String dns;
  final String channel;
  final String security;
  final double? dnsTimeMs;

  const WifiMetrics({
    this.ssid = '---',
    this.frequency = '---',
    this.signalStrength = '---',
    this.bssid = '---',
    this.ip = '---',
    this.gateway = '---',
    this.dns = '---',
    this.channel = '---',
    this.security = '---',
    this.dnsTimeMs,
  });

  /// dBm extraído de textos como "-58 dBm (Bom)".
  double? get signalDbm {
    final match = RegExp(r'-?\d+').firstMatch(signalStrength);
    return match == null ? null : double.tryParse(match.group(0)!);
  }

  bool get is5GHz => frequency.contains('5');

  static WifiMetrics? fromEntry(Map<String, dynamic>? entry) {
    final raw = entry?['result'];
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    return WifiMetrics(
      ssid: _text(m['ssid']),
      frequency: _text(m['frequency']),
      signalStrength: _text(m['signalStrength']),
      bssid: _text(m['bssid']),
      ip: _text(m['ip']),
      gateway: _text(m['gateway']),
      dns: _text(m['dns']),
      channel: _text(m['channel']),
      security: _text(m['security']),
      dnsTimeMs: _toDouble(m['dnsTime']),
    );
  }

  Map<String, dynamic> toJson() => {
        'ssid': ssid,
        'frequency': frequency,
        'signalStrength': signalStrength,
        'ip': ip,
        'gateway': gateway,
        'channel': channel,
        'security': security,
        'dnsTimeMs': dnsTimeMs,
      };
}

class DeviceMetrics {
  final String model;
  final String os;
  final String appVersion;
  final String connectionType;
  final int? batteryLevel;
  final String batteryState;

  const DeviceMetrics({
    this.model = '---',
    this.os = '---',
    this.appVersion = '---',
    this.connectionType = '---',
    this.batteryLevel,
    this.batteryState = '---',
  });

  static DeviceMetrics? fromEntries(
      Map<String, dynamic>? deviceEntry, Map<String, dynamic>? batteryEntry) {
    final text = _resultString(deviceEntry);
    if (text == null && batteryEntry == null) return null;

    final batteryRaw = batteryEntry?['result'];
    final battery = batteryRaw is Map ? Map<String, dynamic>.from(batteryRaw) : null;

    return DeviceMetrics(
      model: _labelled(text, 'Dispositivo'),
      os: _labelled(text, 'Versão OS'),
      appVersion: _labelled(text, 'Versão do App'),
      connectionType: _labelled(text, 'Conexão'),
      batteryLevel: battery?['batteryLevel'] is num
          ? (battery!['batteryLevel'] as num).toInt()
          : null,
      batteryState: _text(battery?['stateStr']),
    );
  }

  Map<String, dynamic> toJson() => {
        'model': model,
        'os': os,
        'appVersion': appVersion,
        'connectionType': connectionType,
        'batteryLevel': batteryLevel,
      };
}

class PublicIpInfo {
  final String ipv4;
  final String ipv6;
  final String isp;

  const PublicIpInfo({this.ipv4 = '---', this.ipv6 = '---', this.isp = '---'});

  static PublicIpInfo? fromEntry(Map<String, dynamic>? entry) {
    final text = _resultString(entry);
    if (text == null || text.isEmpty) return null;
    return PublicIpInfo(
      ipv4: _labelled(text, 'IPv4'),
      ipv6: _labelled(text, 'IPv6'),
      isp: _labelled(text, 'Provedor'),
    );
  }

  Map<String, dynamic> toJson() => {'ipv4': ipv4, 'ipv6': ipv6, 'isp': isp};
}

class TracerouteHop {
  final int hop;
  final String host;
  final String latency;

  const TracerouteHop(
      {required this.hop, required this.host, required this.latency});

  /// Formato emitido pelo serviço: "1: 172.21.0.1 (0.004 ms)".
  static List<TracerouteHop> parseAll(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final hops = <TracerouteHop>[];
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final colon = trimmed.indexOf(':');
      if (colon < 0) continue;
      final number = int.tryParse(trimmed.substring(0, colon).trim());
      if (number == null) continue;
      var rest = trimmed.substring(colon + 1).trim();
      var latency = '---';
      final open = rest.lastIndexOf('(');
      final close = rest.lastIndexOf(')');
      if (open >= 0 && close > open) {
        latency = rest.substring(open + 1, close).trim();
        rest = rest.substring(0, open).trim();
      }
      hops.add(TracerouteHop(hop: number, host: rest, latency: latency));
    }
    return hops;
  }

  Map<String, dynamic> toJson() =>
      {'hop': hop, 'host': host, 'latency': latency};
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers de extração
// ─────────────────────────────────────────────────────────────────────────────

String? _resultString(Map<String, dynamic>? entry) {
  final r = entry?['result'];
  if (r == null) return null;
  if (r is String) return r;
  if (r is Map) return (r['display'] ?? r['displayText'])?.toString();
  return r.toString();
}

String _text(dynamic value, {String fallback = '---'}) {
  if (value == null) return fallback;
  final s = value.toString().trim();
  return s.isEmpty || s == 'null' ? fallback : s;
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(',', '.'));
}

String _labelled(String? text, String label) {
  if (text == null) return '---';
  for (final line in text.split('\n')) {
    if (line.trimLeft().startsWith('$label:')) {
      final value = line.substring(line.indexOf(':') + 1).trim();
      return value.isEmpty ? '---' : value;
    }
  }
  return '---';
}

double? _labelledDouble(String text, String label) {
  final value = _labelled(text, label);
  if (value == '---') return null;
  final match = RegExp(r'-?\d+(?:[.,]\d+)?').firstMatch(value);
  return match == null
      ? null
      : double.tryParse(match.group(0)!.replaceAll(',', '.'));
}

int? _firstInt(String? text) {
  if (text == null) return null;
  final match = RegExp(r'\d+').firstMatch(text);
  return match == null ? null : int.tryParse(match.group(0)!);
}
