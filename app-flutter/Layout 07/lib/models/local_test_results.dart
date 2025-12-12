// Resultados dos testes locais (dispositivo do cliente)
class LocalTestResults {
  final double? latency; // ms
  final double? download; // Mbps
  final double? upload; // Mbps
  final bool dnsStatus; // true = DNS funcionando
  final int? wifiSignal; // dBm (-30 a -90)
  final int? wifiChannel;
  final String? wifiFrequency; // "2.4GHz" ou "5GHz"

  LocalTestResults({
    this.latency,
    this.download,
    this.upload,
    required this.dnsStatus,
    this.wifiSignal,
    this.wifiChannel,
    this.wifiFrequency,
  });

  bool get isLatencyGood => latency != null && latency! < 50;
  bool get isLatencyOk => latency != null && latency! >= 50 && latency! < 100;
  bool get isLatencyBad => latency != null && latency! >= 100;

  String get latencyStatus {
    if (latency == null) return 'Indisponível';
    if (isLatencyGood) return 'Excelente';
    if (isLatencyOk) return 'Normal';
    return 'Alta';
  }

  String get latencyIcon {
    if (latency == null) return '❓';
    if (isLatencyGood) return '✅';
    if (isLatencyOk) return '⚠️';
    return '❌';
  }

  factory LocalTestResults.fromJson(Map<String, dynamic> json) {
    return LocalTestResults(
      latency: (json['latency'] as num?)?.toDouble(),
      download: (json['download'] as num?)?.toDouble(),
      upload: (json['upload'] as num?)?.toDouble(),
      dnsStatus: json['dnsStatus'] as bool? ?? false,
      wifiSignal: json['wifiSignal'] as int?,
      wifiChannel: json['wifiChannel'] as int?,
      wifiFrequency: json['wifiFrequency'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'latency': latency,
        'download': download,
        'upload': upload,
        'dnsStatus': dnsStatus,
        'wifiSignal': wifiSignal,
        'wifiChannel': wifiChannel,
        'wifiFrequency': wifiFrequency,
      };
}
