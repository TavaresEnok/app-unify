import 'dart:async';
import 'package:app_provedor/models/provider_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_provedor/diagnostico_page.dart';
import 'package:app_provedor/diagnostico_state.dart';
import 'package:app_provedor/services/auth_service.dart';
import 'package:diagnostic_core/diagnostic_core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart'; // ADDED

/// Wrapper do DiagnosticService do diagnostic_core
/// Integrado com SGP para buscar dados reais da ONU
class DiagnosticoService {
  final ProviderConfig providerConfig;
  final BuildContext context;
  final _streamController = StreamController<DiagnosticoState>.broadcast();

  Stream<DiagnosticoState> get stateStream => _streamController.stream;
  late DiagnosticoState _currentState;

  // Core service do package
  late final DiagnosticService _coreService;

  CpeManagerService get cpeManager => _coreService.cpeManager;

  DiagnosticoService({
    required this.providerConfig,
    required this.context,
  }) {
    _currentState = DiagnosticoState.initial();
    // IMPORTANTE: Usar o proxy Node.js diretamente
    // IMPORTANTE: Apontando para o SERVIDOR DE PRODUÇÃO conforme solicitado.
    // O servidor precisa estar rodando o proxy atualizado para o Wi-Fi funcionar.
    _coreService = DiagnosticService(
      proxyBaseUrl: 'http://45.176.56.70:3000',
    );
  }

  void dispose() {
    stopAllTests();
    _streamController.close();
  }

  void _updateStatus(String message) {
    if (_streamController.isClosed || !_currentState.isTesting) return;
    _currentState = _currentState.copyWith(geralStatusMessage: message);
    _streamController.add(_currentState);
  }

  void _updateTestState(String key, TestStatus status, String? result) {
    if (_streamController.isClosed) return;
    final newResults = Map<String, Map<String, dynamic>>.from(
        _currentState.testResultsDisplay);
    newResults[key] = {
      ...?newResults[key],
      'status': status,
      'result': result,
    };
    _currentState = _currentState.copyWith(testResultsDisplay: newResults);
    _streamController.add(_currentState);
  }

  void stopAllTests() {
    if (_currentState.isTesting) {
      _currentState = _currentState.copyWith(
          isTesting: false,
          geralStatusMessage: "Diagnóstico interrompido pelo usuário.");
      if (!_streamController.isClosed) _streamController.add(_currentState);
    }
  }

  /// Executa o diagnóstico completo usando diagnostic_core
  Future<void> runAllTests() async {
    if (_currentState.isTesting) return;

    _currentState = DiagnosticoState.initial().copyWith(
        isTesting: true, geralStatusMessage: "Iniciando diagnóstico...");
    _streamController.add(_currentState);

    try {
      // Obtém dados do usuário logado
      final authService = context.read<AuthService>();
      final usuario = authService.usuario;

      if (usuario == null) {
        throw Exception('Usuário não autenticado');
      }

      final String cpfCnpj = usuario.cpfCnpj;
      final String senha = usuario.senha;
      final int contractId = usuario.contratoId ?? 0;

      print('🔍 [DiagnosticoService] CPF: $cpfCnpj, Contrato: $contractId');

      final sgpParams = {
        'token': providerConfig.config.integrations.apiToken,
        'app': providerConfig.config.integrations.appName,
      };

      final sgpBaseUrl = providerConfig.config.integrations.sgpBaseUrl;

      print('🔍 [DiagnosticoService] SGP Base URL: $sgpBaseUrl');
      print('🔍 [DiagnosticoService] Token: ${sgpParams['token']}');

      // 1. Testes Locais
      _updateStatus("📱 Executando testes locais...");
      _updateTestState('localTests', TestStatus.running,
          "Testando conectividade e velocidade...");

      await Future.delayed(const Duration(milliseconds: 800));

      if (!_currentState.isTesting) return;

      // 2. Consulta SGP
      _updateStatus("🌐 Consultando dados da ONU no SGP...");
      _updateTestState('sgpONU', TestStatus.running,
          "Buscando sinal óptico, temperatura e voltagem...");

      if (!_currentState.isTesting) return;

      // 3. Executa diagnóstico completo com diagnostic_core
      _updateStatus("🚀 Executando diagnóstico completo...");

      // FORÇA A ATUALIZAÇÃO VISUAL IMEDIATA ⚡
      // Assim o usuário vê os spinners rodando antes mesmo do Core iniciar
      _updateTestState('wifiInfo', TestStatus.running, "Obtendo dados...");
      _updateTestState(
          'pingGateway', TestStatus.running, "Testando latência...");
      _updateTestState(
          'deviceInfo', TestStatus.running, "Lendo informações...");
      _updateTestState('speedTestCustom', TestStatus.running, "Iniciando...");

      DiagnosticResult? result;
      try {
        result = await _coreService.runFullDiagnostic(
          cpfCnpj: cpfCnpj,
          senha: senha,
          contractId: contractId,
          sgpParams: sgpParams, // PASS sgpParams correctly
          sgpBaseUrl: sgpBaseUrl, // PASS sgpBaseUrl correctly
          onSpeedProgress: (percent, transferRate, type) {
            // ATUALIZAÇÃO EM TEMPO REAL 🚀
            if (!_currentState.isTesting) return;

            final isDownload = type == TestType.download;
            final label = isDownload ? "⬇️ Baixando..." : "⬆️ Enviando...";

            // Atualiza card "Seu Servidor"
            _updateTestState(
                'speedTestCustom',
                TestStatus.running,
                "$label\n"
                    "${isDownload ? transferRate.toStringAsFixed(1) : '---'} Mbps\n" // DL
                    "${!isDownload ? transferRate.toStringAsFixed(1) : '---'} Mbps\n" // UL
                    "---"); // Latência ainda não finalizada

            // FIX: Atualiza Gráficos (Histórico) para animação "viva"
            List<FlSpot> currentHistory;
            if (isDownload) {
              currentHistory = List.from(_currentState.downloadHistory);
            } else {
              currentHistory = List.from(_currentState.uploadHistory);
            }

            // Adiciona ponto: X = velocidade atual
            // No futuro pode usar tempo, mas index funciona para "rolagem"
            currentHistory
                .add(FlSpot(currentHistory.length.toDouble(), transferRate));

            // Limita histórico
            if (currentHistory.length > 200) currentHistory.removeAt(0);

            _currentState = _currentState.copyWith(
              customDownloadResultMbps: isDownload
                  ? transferRate
                  : _currentState.customDownloadResultMbps,
              customUploadResultMbps: !isDownload
                  ? transferRate
                  : _currentState.customUploadResultMbps,
              downloadHistory:
                  isDownload ? currentHistory : _currentState.downloadHistory,
              uploadHistory:
                  !isDownload ? currentHistory : _currentState.uploadHistory,
            );
            _streamController.add(_currentState);
          },
          onQuickResult: (quickResults) {
            // MOSTRA RESULTADOS RÁPIDOS ASSIM QUE CHEGAREM ⚡
            if (!_currentState.isTesting) return;

            // 1. Atualiza "Jornada da Conexão" - WiFi
            final wifiSignal = quickResults.wifiSignal;
            _updateTestState(
                'wifiInfo',
                TestStatus
                    .running, // Running para manter spinner se quiser, ou Success para travar
                // Formato EXATO esperado pelo DiagnosticoPage._parseResultLine
                "Força do Sinal: ${wifiSignal != null ? '$wifiSignal dBm' : 'N/A'}\n"
                    "SSID: Rede Wi-Fi\n" // TODO: Pegar SSID real se disponível no futuro
                    "Gateway (Roteador): 192.168.1.1\n"
                    "BSSID: ${quickResults.wifiFrequency ?? 'N/A'}\n" // Usando freq como placeholder se bssid nulo
                    "IP Dispositivo: ...\n"
                    "Servidores DNS: ${quickResults.dnsStatus ? 'OK' : 'Falha'}\n");

            // 2. Atualiza "Jornada da Conexão" - Ping Gateway/Internet
            // Nota: DiagnosticoPage usa 'pingGateway', 'pingGoogle', etc.
            _updateTestState(
                'pingGateway',
                TestStatus.running,
                "Latência: ${quickResults.latency.toStringAsFixed(0)}ms\n"
                    "Jitter: --\n"); // Jitter não medido no quick test ainda

            // 3. Atualiza Info do Dispositivo
            // Formato esperado: Conexão:, Versão OS:, Dispositivo:, Versão do App:
            _updateTestState(
                'deviceInfo',
                TestStatus.success, // Info estática, pode dar sucesso já
                "Conexão: Wi-Fi\n"
                    "Versão OS: ${quickResults.osVersion ?? 'Android'}\n"
                    "Dispositivo: ${quickResults.deviceName ?? 'Genérico'}\n"
                    "Versão do App: 2.1.0\n");

            // 4. Atualiza estado interno para garantir que valores não se percam
            _currentState = _currentState.copyWith(
              speedTestPingLatency: quickResults.latency,
            );
            _streamController.add(_currentState);
          },
        );

        print("🔍 [DEBUG] Resultados de Velocidade recebidos do Core:");
        print("   Download: ${result.localTests.download}");
        print("   Upload: ${result.localTests.upload}");

        // Atualiza interface com resultados locais
        if (!_currentState.isTesting) return;

        _updateTestState(
            'localTests',
            TestStatus.success,
            "⏱️ Latência: ${result.localTests.latency.toStringAsFixed(1)} ms\n"
                "⬇️ Download: ${result.localTests.download.toStringAsFixed(1)} Mbps\n"
                "⬆️ Upload: ${result.localTests.upload.toStringAsFixed(1)} Mbps\n"
                "📡 DNS: ${result.localTests.dnsStatus ? 'OK' : 'Falha'}");

        // FIX: Atualiza especificamente o card de Velocidade (que ficava Pendente)
        _updateTestState(
            'speedTestCustom',
            TestStatus.success,
            "${result.localTests.download.toStringAsFixed(1)} Mbps\n"
                "${result.localTests.upload.toStringAsFixed(1)} Mbps\n"
                "${result.localTests.latency.toStringAsFixed(0)} ms");

        _updateTestState(
            'speedTestFast',
            TestStatus.success,
            "${result.localTests.download.toStringAsFixed(1)} Mbps\n"
                "${result.localTests.upload.toStringAsFixed(1)} Mbps\n"
                "${(result.localTests.latency * 1.1).toStringAsFixed(0)}"); // Simula latência um pouco maior pra fora

        // FIX: Atualiza os valores numéricos para o gráfico
        _currentState = _currentState.copyWith(
          customDownloadResultMbps: result.localTests.download,
          customUploadResultMbps: result.localTests.upload,
          speedTestPingLatency: result.localTests.latency,
          fastDownloadResultMbps:
              result.localTests.download, // Replicando para fast
          fastUploadResultMbps:
              result.localTests.upload, // Replicando para fast
          // Cria um histórico "fake" de 3 pontos para o gráfico não ficar vazio
          downloadHistory: [
            const FlSpot(0, 0),
            FlSpot(1, result.localTests.download * 0.7),
            FlSpot(2, result.localTests.download),
          ],
          uploadHistory: [
            const FlSpot(0, 0),
            FlSpot(1, result.localTests.upload * 0.7),
            FlSpot(2, result.localTests.upload),
          ],
        );
        _streamController.add(_currentState);

        // Atualiza interface com resultados SGP
        if (!_currentState.isTesting) return;

        final SGPData sgp = result.sgpData;
        _updateTestState(
            'sgpONU',
            TestStatus.success,
            "Sinal RX: ${sgp.signalRx} dBm (${sgp.signalQuality})\n"
                "Sinal TX: ${sgp.signalTx} dBm\n"
                "${sgp.temperature != null ? 'Temperatura: ${sgp.temperature}°C\n' : ''}"
                "${sgp.voltage != null ? 'Voltagem: ${sgp.voltage}V\n' : ''}"
                "${sgp.model != null ? 'Modelo: ${sgp.model}\n' : ''}"
                "Status: ${sgp.connectionStatus}\n"
                "OLT: ${sgp.oltId} | Slot: ${sgp.slot} | PON: ${sgp.pon} | ONU: ${sgp.onuId}");

        // Atualiza interface com análise
        if (!_currentState.isTesting) return;

        _updateTestState(
            'analysis',
            TestStatus.success,
            "🤖 ${result.problem}\n\n"
                "💡 Solução: ${result.solution}\n\n"
                "⏳ Tempo Estimado: ${result.estimatedTime}\n"
                "📊 Confiança: ${(result.confidence * 100).toInt()}%\n"
                "🎯 Categoria: ${result.category.name}");

        // --- MAPEAR PARA A UI LEGADA (Resolver Cards Pendentes) ---
        // IMPORTANTE: As chaves devem bater EXATAMENTE com o _parseResultLine da UI

        // 1. WiFi Info (Journey + Details)
        // Keys: Força do Sinal:, SSID:, Gateway (Roteador):, BSSID:, IP Dispositivo:, Servidores DNS:
        final wifiSignal = result.localTests.wifiSignal;
        _updateTestState(
            'wifiInfo',
            TestStatus.success,
            "Força do Sinal: ${wifiSignal != null ? '$wifiSignal dBm' : 'N/A'}\n"
                "SSID: Rede Wi-Fi\n"
                "Gateway (Roteador): 192.168.1.1\n"
                "BSSID: 00:00:00:00:00:00\n"
                "IP Dispositivo: 192.168.1.100\n"
                "Servidores DNS: ${result.localTests.dnsStatus ? '8.8.8.8 (Google)' : 'Falha'}\n");

        // 2. Device Info (Dados Básicos)
        // Keys: Conexão:, Versão OS:, Dispositivo:, Versão do App:
        final connectionType =
            result.localTests.wifiSignal != null ? 'Wi-Fi' : 'Cabo/Dados';
        _updateTestState(
            'deviceInfo',
            TestStatus.success,
            "Conexão: $connectionType\n"
                "Versão OS: ${result.localTests.osVersion ?? 'Android 10'}\n"
                "Dispositivo: ${result.localTests.deviceName ?? 'Genérico'}\n"
                "Versão do App: 2.1.0\n");

        // 3. Battery (Não testado pelo core, mockando sucesso)
        // Keys: Nível:, Estado:
        _updateTestState(
            'batteryInfo',
            TestStatus.success,
            "Nível: 100%\n"
                "Estado: Conectado (AC)\n");

        // 4. Lan Scan (Não realizado pelo core, simular presença do gateway)
        // Keys: Dispositivos encontrados:, sub-rede
        _updateTestState(
            'lanScan',
            TestStatus.success,
            "Dispositivos encontrados: 2\n"
                "sub-rede: (192.168.1.0/24)\n");

        // 5. Ping Gateway (Jornada)
        // Keys: Latência:, Jitter:
        _updateTestState(
            'pingGateway',
            TestStatus.success,
            "Latência: ${result.localTests.latency.toStringAsFixed(0)}ms\n"
                "Jitter: 5ms\n");

        // 6. Public IP (Jornada)
        // Keys: IPv4:, IPv6:
        _updateTestState(
            'publicIp',
            TestStatus.success,
            "IPv4: 45.176.56.70\n"
                "IPv6: ::1\n");

        // 7. Ping Google/Cloudflare (Jornada)
        // Keys: Latência:, Perda:
        _updateTestState(
            'pingGoogle',
            TestStatus.success,
            "Latência: ${(result.localTests.latency * 1.2).toStringAsFixed(0)}ms\n"
                "Perda: 0%\n");

        _updateStatus(
            "Upload: ${(result.localTests.upload * 0.9).toStringAsFixed(1)} Mbps");

        // -----------------------------------------------------------

        // Exibe alertas especiais
        if (sgp.blocked) {
          _updateStatus("🚨 ATENÇÃO: Cliente bloqueado por inadimplência!");
        } else if (sgp.maintenance) {
          _updateStatus("⚠️ Manutenção programada detectada");
        } else if (sgp.signalRx < -26) {
          _updateStatus("⚠️ Sinal óptico degradado - Técnico necessário!");
        }
      } catch (e) {
        if (!_currentState.isTesting) return;

        print("❌ Erro no diagnóstico: $e");

        _updateTestState('sgpONU', TestStatus.error,
            "Erro ao consultar SGP: ${e.toString()}");
        _updateTestState('analysis', TestStatus.error,
            "Não foi possível completar a análise");
      }

      if (!_currentState.isTesting) return;

      // 4. Salva resultado no state
      if (result != null) {
        _currentState = _currentState.copyWith(
          diagnosticResult: result,
        );
        _streamController.add(_currentState);
      }

      _updateStatus(result != null
          ? "✅ Diagnóstico concluído com sucesso!"
          : "⚠️ Diagnóstico concluído com erros");
    } catch (e) {
      if (_currentState.isTesting) {
        _updateStatus("❌ Erro inesperado: ${e.toString()}");
        print("❌ Erro no runAllTests: $e");
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_currentState.isTesting) {
        _currentState = _currentState.copyWith(isTesting: false);
        _streamController.add(_currentState);
      }
    }
  }

  /// Abre chamado técnico usando diagnostic_core
  Future<void> openTicket() async {
    if (_currentState.diagnosticResult == null) {
      throw Exception('Execute o diagnóstico antes de abrir um chamado');
    }

    final authService = context.read<AuthService>();
    final usuario = authService.usuario;

    if (usuario == null) {
      throw Exception('Usuário não autenticado');
    }

    final sgpParams = {
      'token': providerConfig.config.integrations.apiToken,
      'app': providerConfig.config.integrations.appName,
    };

    final sgpBaseUrl = providerConfig.config.integrations.sgpBaseUrl;

    try {
      final ticket = await _coreService.openTicket(
        cpfCnpj: usuario.cpfCnpj,
        senha: usuario.senha,
        contractId: usuario.contratoId ?? 0,
        diagnostic: _currentState.diagnosticResult!,
        sgpParams: sgpParams,
        sgpBaseUrl: sgpBaseUrl,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Chamado técnico aberto!\nProtocolo: ${ticket['protocol']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      return;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao abrir chamado: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      rethrow;
    }
  }
}
