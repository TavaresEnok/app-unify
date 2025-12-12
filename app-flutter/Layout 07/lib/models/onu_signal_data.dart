// Dados de sinal da ONU obtidos via SGP API
class OnuSignalData {
  final double signalRx; // Sinal recebido em dBm
  final double signalTx; // Sinal transmitido em dBm
  final String connectionStatus; // online, offline, etc
  final int? oltId;
  final int? slot;
  final int? pon;
  final int? onuId;

  OnuSignalData({
    required this.signalRx,
    required this.signalTx,
    required this.connectionStatus,
    this.oltId,
    this.slot,
    this.pon,
    this.onuId,
  });

  // Qualidade do sinal baseada em RX
  bool get isSignalHealthy => signalRx >= -23 && signalRx <= -18;
  bool get isSignalDegraded => signalRx >= -26 && signalRx < -23;
  bool get isSignalCritical => signalRx < -26;

  String get signalQuality {
    if (isSignalHealthy) return 'Excelente';
    if (isSignalDegraded) return 'Degradado';
    return 'Crítico';
  }

  String get signalQualityIcon {
    if (isSignalHealthy) return '✅';
    if (isSignalDegraded) return '⚠️';
    return '❌';
  }

  // Porcentagem para barra de progresso (0.0 a 1.0)
  double get signalPercentage {
    // -18 dBm = 100% (excelente)
    // -28 dBm = 0% (crítico)
    final normalized = (signalRx + 28) / 10; // Normaliza entre -28 e -18
    return normalized.clamp(0.0, 1.0);
  }

  factory OnuSignalData.fromJson(Map<String, dynamic> json) {
    return OnuSignalData(
      signalRx: (json['signalRx'] as num?)?.toDouble() ?? -999.0,
      signalTx: (json['signalTx'] as num?)?.toDouble() ?? -999.0,
      connectionStatus: json['connectionStatus'] as String? ?? 'unknown',
      oltId: json['oltId'] as int?,
      slot: json['slot'] as int?,
      pon: json['pon'] as int?,
      onuId: json['onuId'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'signalRx': signalRx,
        'signalTx': signalTx,
        'connectionStatus': connectionStatus,
        'oltId': oltId,
        'slot': slot,
        'pon': pon,
        'onuId': onuId,
      };
}
