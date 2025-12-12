import '../models/diagnostic_result.dart';
import '../models/diagnostic_category.dart';
import '../models/local_test_results.dart';
import '../models/onu_signal_data.dart';
import 'network_test_service.dart';
import 'sgp_diagnostic_service.dart';

// Service orquestrador de diagnóstico completo
class DiagnosticService {
  final NetworkTestService _networkTest;
  final SGPDiagnosticService? _sgpService;

  DiagnosticService({
    NetworkTestService? networkTest,
    SGPDiagnosticService? sgpService,
  })  : _networkTest = networkTest ?? NetworkTestService(),
        _sgpService = sgpService;

  /// Executar diagnóstico completo
  Future<DiagnosticResult> runFullDiagnostic({
    String? cpfCnpj,
    int? contractId,
  }) async {
    print('🚀 Iniciando diagnóstico completo...');

    // 1. Executar testes locais
    final localTests = await _runLocalTests();

    // 2. Buscar dados do SGP (se disponível)
    OnuSignalData? onuData;
    if (_sgpService != null && cpfCnpj != null && contractId != null) {
      onuData = await _sgpService!.getOnuSignal(
        cpfCnpj: cpfCnpj,
        contractId: contractId,
      );
    }

    // 3. Analisar resultados
    final result = _analyzeResults(localTests, onuData);

    print('✅ Diagnóstico concluído: ${result.problem}');
    return result;
  }

  /// Executar testes locais de rede
  Future<LocalTestResults> _runLocalTests() async {
    print('  📊 Executando testes locais...');

    final latency = await _networkTest.measureLatency();
    final dnsStatus = await _networkTest.checkDNS();
    final download = await _networkTest.measureDownloadSpeed();
    final upload = await _networkTest.measureUploadSpeed();

    return LocalTestResults(
      latency: latency,
      download: download,
      upload: upload,
      dnsStatus: dnsStatus,
      wifiSignal: null, // Requer plugin specific
      wifiChannel: null,
      wifiFrequency: null,
    );
  }

  /// Analisar resultados e retornar diagnóstico
  DiagnosticResult _analyzeResults(
    LocalTestResults localTests,
    OnuSignalData? onuData,
  ) {
    print('  🔍 Analisando resultados...');

    // REGRA 1: Sinal ONU Crítico
    if (onuData != null && onuData.isSignalCritical) {
      return DiagnosticResult(
        problem: 'Sinal óptico muito fraco',
        category: DiagnosticCategory.FIBER_ISSUE,
        confidence: 0.95,
        solution:
            'Necessário visita técnica. O sinal da fibra está abaixo do ideal (-26 dBm). '
            'Isso pode indicar problema no cabo óptico, conector sujo ou emenda com perda.',
        estimatedTime: '1-2 horas',
        localTests: localTests,
        onuData: onuData,
      );
    }

    // REGRA 2: Sinal ONU Degradado
    if (onuData != null && onuData.isSignalDegraded) {
      return DiagnosticResult(
        problem: 'Sinal óptico degradado',
        category: DiagnosticCategory.FIBER_ISSUE,
        confidence: 0.85,
        solution:
            'Recomendamos abrir chamado técnico. O sinal está degradado (-23 a -26 dBm). '
            'Pode haver lentidão ou instabilidade na conexão.',
        estimatedTime: '1-2 horas',
        localTests: localTests,
        onuData: onuData,
      );
    }

    // REGRA 3: DNS falhando
    if (!localTests.dnsStatus) {
      return DiagnosticResult(
        problem: 'Problema de DNS detectado',
        category: DiagnosticCategory.DEVICE_ISSUE,
        confidence: 0.80,
        solution: 'Sua internet está funcionando, mas o DNS está com falha. '
            'Tente reiniciar o roteador ou configurar DNS manual (8.8.8.8).',
        estimatedTime: '5-10 minutos',
        localTests: localTests,
        onuData: onuData,
      );
    }

    // REGRA 4: Latência muito alta (mas sinal OK)
    if (localTests.latency != null &&
        localTests.latency! > 100 &&
        (onuData == null || onuData.isSignalHealthy)) {
      return DiagnosticResult(
        problem: 'Latência alta detectada',
        category: DiagnosticCategory.WIFI_ISSUE,
        confidence: 0.70,
        solution:
            'O sinal da fibra está OK, mas a latência está alta (${localTests.latency}ms). '
            'Pode ser problema no WiFi. Tente aproximar-se do roteador ou usar cabo.',
        estimatedTime: 'Imediato',
        localTests: localTests,
        onuData: onuData,
      );
    }

    //REGRA 5: Velocidade muito baixa (mas sinal OK)
    if (localTests.download != null &&
        localTests.download! < 10 &&
        (onuData == null || onuData.isSignalHealthy)) {
      return DiagnosticResult(
        problem: 'Velocidade abaixo do esperado',
        category: DiagnosticCategory.WIFI_ISSUE,
        confidence: 0.75,
        solution:
            'Velocidade de download está baixa (${localTests.download?.toStringAsFixed(1)} Mbps). '
            'Verifique se outros dispositivos estão usando a internet ou tente reiniciar o roteador.',
        estimatedTime: '5 minutos',
        localTests: localTests,
        onuData: onuData,
      );
    }

    // REGRA 6: Tudo OK!
    return DiagnosticResult(
      problem: 'Conexão saudável',
      category: DiagnosticCategory.ALL_GOOD,
      confidence: 1.0,
      solution:
          'Todos os testes passaram! Sua conexão está funcionando perfeitamente.',
      estimatedTime: null,
      localTests: localTests,
      onuData: onuData,
    );
  }
}
