import 'package:fl_chart/fl_chart.dart';
import 'package:diagnostic_core/diagnostic_core.dart';
import 'diagnostico_page.dart'; // Importa o enum TestStatus

class DiagnosticoState {
  final bool isTesting;
  final String geralStatusMessage;
  final Map<String, Map<String, dynamic>> testResultsDisplay;
  final double? speedTestPingLatency;
  final DiagnosticResult?
      diagnosticResult; // NOVO - Resultado do diagnostic_core

  // Dados para o gráfico e resultados de velocidade
  final double customDownloadResultMbps;
  final double customUploadResultMbps;
  final double fastDownloadResultMbps;
  final double fastUploadResultMbps;
  final List<FlSpot> downloadHistory;
  final List<FlSpot> uploadHistory;
  final List<FlSpot> fastDownloadHistory;
  final List<FlSpot> fastUploadHistory;

  DiagnosticoState({
    required this.isTesting,
    required this.geralStatusMessage,
    required this.testResultsDisplay,
    this.speedTestPingLatency,
    this.diagnosticResult,
    this.customDownloadResultMbps = 0,
    this.customUploadResultMbps = 0,
    this.fastDownloadResultMbps = 0,
    this.fastUploadResultMbps = 0,
    this.downloadHistory = const [],
    this.uploadHistory = const [],
    this.fastDownloadHistory = const [],
    this.fastUploadHistory = const [],
  });

  factory DiagnosticoState.initial() {
    return DiagnosticoState(
      isTesting: false,
      geralStatusMessage: "Pronto para iniciar o diagnóstico completo.",
      testResultsDisplay: {
        'localTests': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Testes Locais'
        },
        'sgpONU': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Dados da ONU (SGP)'
        },
        'analysis': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Análise Inteligente'
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
    String? geralStatusMessage,
    Map<String, Map<String, dynamic>>? testResultsDisplay,
    double? speedTestPingLatency,
    DiagnosticResult? diagnosticResult,
    double? customDownloadResultMbps,
    double? customUploadResultMbps,
    double? fastDownloadResultMbps,
    double? fastUploadResultMbps,
    List<FlSpot>? downloadHistory,
    List<FlSpot>? uploadHistory,
    List<FlSpot>? fastDownloadHistory,
    List<FlSpot>? fastUploadHistory,
  }) {
    return DiagnosticoState(
      isTesting: isTesting ?? this.isTesting,
      geralStatusMessage: geralStatusMessage ?? this.geralStatusMessage,
      testResultsDisplay: testResultsDisplay ?? this.testResultsDisplay,
      speedTestPingLatency: speedTestPingLatency ?? this.speedTestPingLatency,
      diagnosticResult: diagnosticResult ?? this.diagnosticResult,
      customDownloadResultMbps:
          customDownloadResultMbps ?? this.customDownloadResultMbps,
      customUploadResultMbps:
          customUploadResultMbps ?? this.customUploadResultMbps,
      fastDownloadResultMbps:
          fastDownloadResultMbps ?? this.fastDownloadResultMbps,
      fastUploadResultMbps: fastUploadResultMbps ?? this.fastUploadResultMbps,
      downloadHistory: downloadHistory ?? this.downloadHistory,
      uploadHistory: uploadHistory ?? this.uploadHistory,
      fastDownloadHistory: fastDownloadHistory ?? this.fastDownloadHistory,
      fastUploadHistory: fastUploadHistory ?? this.fastUploadHistory,
    );
  }
}
