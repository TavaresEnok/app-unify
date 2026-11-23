part of 'diagnostico_service.dart';

/// One execution plan for every diagnostic layout.
extension DiagnosticRuns on DiagnosticoService {
  Future<void> runAllTests() async {
    if (_executionActive ||
        _currentState.isTesting ||
        _streamController.isClosed) {
      return;
    }
    _executionActive = true;
    _currentState = DiagnosticoState.initial().copyWith(
      isTesting: true,
      startedAt: DateTime.now(),
      geralStatusMessage: "Iniciando diagnóstico...",
    );
    _streamController.add(_currentState);

    try {
      _updateStatus("Verificando informações do dispositivo...");
      await runDeviceInfoTest();

      // Novo teste ONU
      if (onuService != null) {
        _updateStatus("Verificando sinal da Fibra (ONU)...");
        await runOnuTest();
      } else {
        _updateTestState(
          'onuInfo',
          TestStatus.error,
          'Consulta de fibra indisponível nesta sessão.',
          availability: TestAvailability.unsupported,
        );
      }

      await runBatteryTest();
      if (!_currentState.isTesting) return;

      bool hasPermission = false;
      if (_isWifiConnected) {
        _updateStatus("Solicitando permissão de localização...");
        hasPermission = await _requestLocationPermission();
        if (!_currentState.isTesting) return;
        if (!hasPermission) {
          _updateTestState(
            'wifiInfo',
            TestStatus.error,
            'Permissão de localização negada.',
            availability: TestAvailability.permissionRequired,
          );
          _updateTestState(
            'pingGateway',
            TestStatus.error,
            'Requer info WiFi (permissão negada).',
            availability: TestAvailability.permissionRequired,
          );
          _updateTestState(
            'lanScan',
            TestStatus.error,
            'Requer permissão de localização.',
            availability: TestAvailability.permissionRequired,
          );
        }
      } else {
        _updateTestState(
          'wifiInfo',
          TestStatus.error,
          'Não conectado ao WiFi.',
          availability: TestAvailability.unsupported,
        );
        _updateTestState(
          'pingGateway',
          TestStatus.error,
          'Não conectado ao WiFi.',
          availability: TestAvailability.unsupported,
        );
        _updateTestState(
          'lanScan',
          TestStatus.error,
          'Não conectado ao WiFi.',
          availability: TestAvailability.unsupported,
        );
      }

      _updateStatus("Verificando Conectividade e IP (IPv4/IPv6)...");
      await runIpTest();
      if (!_currentState.isTesting) return;

      _updateStatus("Testando ping para Google...");
      // 10 pings, keep all for Google
      await runPingTest('8.8.8.8', 'pingGoogle', count: 10);
      if (!_currentState.isTesting) return;

      _updateStatus("Testando ping para Cloudflare...");
      // 10 pings, keep all for Cloudflare
      await runPingTest('1.1.1.1', 'pingCloudflare', count: 10);

      if (!_currentState.isTesting) return;

      if (hasPermission && _isWifiConnected) {
        _updateStatus("Verificando informações de WiFi e DNS...");
        await runWifiTest();

        _updateStatus("Escaneando Rede Local (LAN)...");
        await runLanScanTest();

        if (!_currentState.isTesting) return;
        if (_currentState.testResultsDisplay['wifiInfo']?['status'] ==
            TestStatus.success) {
          await runPingGatewayTest();
          if (!_currentState.isTesting) return;
        }
      }

      // Traceroute test
      await runTracerouteTest();
      if (!_currentState.isTesting) return;

      await runSpeedTestCustom();
      if (!_currentState.isTesting) return;

      await runSpeedTestFastCom();
      if (!_currentState.isTesting) return;

      if (_currentState.isTesting) {
        bool anyError = _currentState.testResultsDisplay.entries.any(
          (entry) => entry.value['status'] == TestStatus.error,
        );
        _updateStatus(
          anyError
              ? "Diagnóstico concluído com erros."
              : "Diagnóstico concluído.",
        );
      }
    } catch (e) {
      if (_currentState.isTesting) {
        _updateStatus("Ocorreu um erro inesperado durante o diagnóstico.");
      }
    } finally {
      _executionActive = false;
      if (_currentState.isTesting) {
        _currentState = _currentState.copyWith(
            isTesting: false, finishedAt: DateTime.now());
        _streamController.add(_currentState);
      } else if (!_streamController.isClosed) {
        // Notify observers that cancellation cleanup released the execution lock.
        _streamController.add(_currentState);
      }
    }
  }

  /// Verificação RÁPIDA (~10-15s) para o momento "minha internet está ruim".
  ///
  /// Roda só o subconjunto que decide o veredito — sinal da fibra (ONU), ping ao
  /// roteador e ping externo (+ Wi-Fi quando disponível). Deixa de fora o que é
  /// lento/pesado: varredura de LAN, traceroute e os dois testes de velocidade.
  /// O objetivo é entregar um diagnóstico acionável em segundos, não um laudo
  /// completo — este continua disponível via [runAllTests].
  Future<void> runQuickCheck() async {
    if (_executionActive ||
        _currentState.isTesting ||
        _streamController.isClosed) {
      return;
    }
    _executionActive = true;
    _currentState = DiagnosticoState.initial().copyWith(
      isTesting: true,
      startedAt: DateTime.now(),
      runMode: DiagnosticRunMode.quick,
      geralStatusMessage: "Verificação rápida...",
    );
    _streamController.add(_currentState);

    try {
      await runDeviceInfoTest();
      if (!_currentState.isTesting) return;

      if (onuService != null) {
        _updateStatus("Verificando sinal da fibra...");
        await runOnuTest();
        if (!_currentState.isTesting) return;
      } else {
        _updateTestState(
          'onuInfo',
          TestStatus.error,
          'Consulta de fibra indisponível nesta sessão.',
          availability: TestAvailability.unsupported,
        );
      }

      if (_isWifiConnected) {
        final permission = await _requestLocationPermission();
        if (!_currentState.isTesting) return;
        if (permission) {
          _updateStatus("Verificando o Wi-Fi...");
          await runWifiTest();
          if (_currentState.testResultsDisplay['wifiInfo']?['status'] ==
              TestStatus.success) {
            _updateStatus("Testando o roteador...");
            await runPingGatewayTest();
            if (!_currentState.isTesting) return;
          }
        } else {
          for (final key in ['wifiInfo', 'pingGateway']) {
            _updateTestState(key, TestStatus.error,
                'Permissão necessária para consultar o Wi-Fi.',
                availability: TestAvailability.permissionRequired);
          }
        }
      } else {
        for (final key in ['wifiInfo', 'pingGateway']) {
          _updateTestState(key, TestStatus.error,
              'Conecte-se ao Wi-Fi para esta verificação.',
              availability: TestAvailability.unsupported);
        }
      }

      _updateStatus("Testando o acesso à internet...");
      // Poucos pacotes: rápido o bastante para o veredito, sem prender o usuário.
      await runPingTest('8.8.8.8', 'pingGoogle', count: 4);
      if (!_currentState.isTesting) return;

      _updateStatus("Verificação concluída.");
    } catch (e) {
      if (_currentState.isTesting) {
        _updateStatus("Ocorreu um erro na verificação rápida.");
      }
    } finally {
      _executionActive = false;
      if (_currentState.isTesting) {
        _currentState = _currentState.copyWith(
            isTesting: false, finishedAt: DateTime.now());
        _streamController.add(_currentState);
      } else if (!_streamController.isClosed) {
        // Notify observers that cancellation cleanup released the execution lock.
        _streamController.add(_currentState);
      }
    }
  }

  Future<void> runSpeedTestsOnly() async {
    if (_executionActive ||
        _currentState.isTesting ||
        _streamController.isClosed) {
      return;
    }
    _executionActive = true;
    _currentState = DiagnosticoState.initial().copyWith(
      isTesting: true,
      startedAt: DateTime.now(),
      runMode: DiagnosticRunMode.speed,
      geralStatusMessage: "Iniciando teste de velocidade...",
    );
    _streamController.add(_currentState);

    try {
      await runSpeedTestCustom();
      if (!_currentState.isTesting) return;

      await runSpeedTestFastCom();
      if (!_currentState.isTesting) return;

      _updateStatus("Teste de velocidade concluído.");
    } catch (e) {
      if (_currentState.isTesting) {
        _updateStatus("Ocorreu um erro durante o teste.");
      }
    } finally {
      _executionActive = false;
      if (_currentState.isTesting) {
        _currentState = _currentState.copyWith(
            isTesting: false, finishedAt: DateTime.now());
        _streamController.add(_currentState);
      } else if (!_streamController.isClosed) {
        // Notify observers that cancellation cleanup released the execution lock.
        _streamController.add(_currentState);
      }
    }
  }
}
