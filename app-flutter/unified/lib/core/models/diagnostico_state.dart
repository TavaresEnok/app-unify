import 'package:fl_chart/fl_chart.dart';

enum TestStatus { pending, running, success, error }

enum DiagnosticRunMode { quick, complete, speed }

enum TestAvailability { available, unsupported, permissionRequired }

class DiagnosticoState {
  final bool isTesting;
  final bool wasInterrupted;
  final DiagnosticRunMode runMode;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String geralStatusMessage;
  final Map<String, Map<String, dynamic>> testResultsDisplay;
  final double? speedTestPingLatency;

  // Dados para o gráfico e resultados de velocidade
  final double customDownloadResultMbps;
  final double customUploadResultMbps;
  final double fastDownloadResultMbps;
  final double fastUploadResultMbps;
  final String? speedTestServerName;
  final String? speedTestReferenceServerName;
  final List<FlSpot> downloadHistory;
  final List<FlSpot> uploadHistory;
  final List<FlSpot> fastDownloadHistory;
  final List<FlSpot> fastUploadHistory;

  DiagnosticoState({
    required this.isTesting,
    this.wasInterrupted = false,
    this.runMode = DiagnosticRunMode.complete,
    this.startedAt,
    this.finishedAt,
    required this.geralStatusMessage,
    required this.testResultsDisplay,
    this.speedTestPingLatency,
    this.customDownloadResultMbps = 0,
    this.customUploadResultMbps = 0,
    this.fastDownloadResultMbps = 0,
    this.fastUploadResultMbps = 0,
    this.speedTestServerName,
    this.speedTestReferenceServerName,
    this.downloadHistory = const [],
    this.uploadHistory = const [],
    this.fastDownloadHistory = const [],
    this.fastUploadHistory = const [],
  });

  factory DiagnosticoState.initial() {
    return DiagnosticoState(
      isTesting: false,
      geralStatusMessage: "Vamos verificar sua conexão?",
      testResultsDisplay: {
        'onuInfo': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Sinal da fibra (ONU)'
        },
        'traceroute': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Traceroute — rota do servidor'
        },
        'deviceInfo': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Informações do Dispositivo'
        },
        'batteryInfo': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Bateria e Energia'
        },
        'wifiInfo': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Informações de WiFi e DNS'
        },
        'lanScan': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Dispositivos na Rede (LAN)'
        },
        'publicIp': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'IP Público'
        },
        'pingGateway': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Ping para o Roteador'
        },
        'pingGoogle': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Ping para Google DNS'
        },
        'pingCloudflare': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Ping para Cloudflare DNS'
        },
        'speedTestCustom': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Teste de Velocidade (Servidor do Provedor)'
        },
        'speedTestFast': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Teste de Velocidade (Referência Fast.com)'
        },
      },
    );
  }

  DiagnosticoState copyWith({
    bool? isTesting,
    bool? wasInterrupted,
    DiagnosticRunMode? runMode,
    DateTime? startedAt,
    DateTime? finishedAt,
    String? geralStatusMessage,
    Map<String, Map<String, dynamic>>? testResultsDisplay,
    double? speedTestPingLatency,
    double? customDownloadResultMbps,
    double? customUploadResultMbps,
    double? fastDownloadResultMbps,
    double? fastUploadResultMbps,
    String? speedTestServerName,
    String? speedTestReferenceServerName,
    List<FlSpot>? downloadHistory,
    List<FlSpot>? uploadHistory,
    List<FlSpot>? fastDownloadHistory,
    List<FlSpot>? fastUploadHistory,
  }) {
    return DiagnosticoState(
      isTesting: isTesting ?? this.isTesting,
      wasInterrupted: wasInterrupted ?? this.wasInterrupted,
      runMode: runMode ?? this.runMode,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      geralStatusMessage: geralStatusMessage ?? this.geralStatusMessage,
      testResultsDisplay: testResultsDisplay ?? this.testResultsDisplay,
      speedTestPingLatency: speedTestPingLatency ?? this.speedTestPingLatency,
      customDownloadResultMbps:
          customDownloadResultMbps ?? this.customDownloadResultMbps,
      customUploadResultMbps:
          customUploadResultMbps ?? this.customUploadResultMbps,
      fastDownloadResultMbps:
          fastDownloadResultMbps ?? this.fastDownloadResultMbps,
      fastUploadResultMbps: fastUploadResultMbps ?? this.fastUploadResultMbps,
      speedTestServerName: speedTestServerName ?? this.speedTestServerName,
      speedTestReferenceServerName:
          speedTestReferenceServerName ?? this.speedTestReferenceServerName,
      downloadHistory: downloadHistory ?? this.downloadHistory,
      uploadHistory: uploadHistory ?? this.uploadHistory,
      fastDownloadHistory: fastDownloadHistory ?? this.fastDownloadHistory,
      fastUploadHistory: fastUploadHistory ?? this.fastUploadHistory,
    );
  }
}
