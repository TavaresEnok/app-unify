part of 'diagnostico_service.dart';

extension DiagnosticPing on DiagnosticoService {
  Future<void> runPingOnly(String host) async {
    if (_executionActive ||
        _currentState.isTesting ||
        _streamController.isClosed) {
      return;
    }
    final valid = host.isNotEmpty &&
        host.length <= 253 &&
        !host.startsWith('-') &&
        RegExp(r'^[a-zA-Z0-9.:_-]+$').hasMatch(host);
    if (!valid) throw const FormatException('Informe um IP ou domínio válido.');
    _executionActive = true;
    _currentState = DiagnosticoState.initial()
        .copyWith(isTesting: true, geralStatusMessage: 'Testando $host...');
    _streamController.add(_currentState);
    try {
      await runPingTest(host, 'pingGoogle', count: 5);
    } finally {
      _executionActive = false;
      if (!_streamController.isClosed && _currentState.isTesting) {
        _currentState = _currentState.copyWith(
            isTesting: false, geralStatusMessage: 'Teste de ping concluído.');
        _streamController.add(_currentState);
      }
    }
  }

  Future<void> runPingTest(
    String host,
    String key, {
    int count = 5,
    bool discardFirst = false,
  }) async {
    if (!_currentState.isTesting) return;
    _updateTestState(key, TestStatus.running, "Iniciando...");

    final completer = Completer<void>();
    final latencies = <int>[];
    final responses = <Map<String, dynamic>>[];
    int packetsReceived = 0;
    StreamSubscription<PingData>? subscription;

    // Se discardFirst for true, pedimos 1 pacote extra para compensar
    final int totalCount = discardFirst ? count + 1 : count;

    final ping = _pingFactory.create(
      host,
      count: totalCount,
      timeout: const Duration(seconds: 2),
      interval: const Duration(seconds: 1),
    );

    int currentIndex = 0;

    subscription = ping.stream.listen(
      (PingData data) {
        if (data.response != null) {
          final isFirst = currentIndex == 0;
          currentIndex++;

          if (discardFirst && isFirst) return;

          packetsReceived++;
          final time = data.response!.time?.inMilliseconds;
          if (time != null) {
            latencies.add(time);
            responses.add({'sequence': data.response!.seq, 'timeMs': time});
            _updateTestState(key, TestStatus.running, 'Recebendo respostas...',
                metrics: {'host': host, 'responses': List.of(responses)});
          }
        }
      },
      onDone: () {
        int packetsLost = count - packetsReceived;
        if (packetsLost < 0) packetsLost = 0;
        double lossPercentage = (packetsLost / count) * 100;

        if (!completer.isCompleted) {
          if (latencies.isEmpty) {
            _updateTestState(
              key,
              TestStatus.error,
              'Host inacessível\nPerda: 100%',
              metrics: {
                'host': host,
                'responses': List.of(responses),
                'reachable': false,
                'lossPercent': 100.0,
                'packetsSent': count,
                'packetsReceived': 0,
              },
            );
          } else {
            int avgLatency =
                (latencies.reduce((a, b) => a + b) / latencies.length).round();
            double jitter = 0.0;
            if (latencies.length > 1) {
              int totalDiff = 0;
              for (int i = 0; i < latencies.length - 1; i++) {
                totalDiff += (latencies[i] - latencies[i + 1]).abs();
              }
              jitter = totalDiff / (latencies.length - 1);
            }
            final sorted = [...latencies]..sort();
            _updateTestState(
              key,
              TestStatus.success,
              'Latência: ${avgLatency}ms\nJitter: ${jitter.toStringAsFixed(1)}ms\nPerda: ${lossPercentage.toStringAsFixed(0)}%',
              metrics: {
                'host': host,
                'responses': List.of(responses),
                'reachable': true,
                'latencyMs': avgLatency.toDouble(),
                'jitterMs': double.parse(jitter.toStringAsFixed(1)),
                'lossPercent': double.parse(lossPercentage.toStringAsFixed(0)),
                'minMs': sorted.first.toDouble(),
                'maxMs': sorted.last.toDouble(),
                'packetsSent': count,
                'packetsReceived': packetsReceived,
              },
            );
          }
          completer.complete();
        }
        subscription?.cancel();
      },
      onError: (e) {
        if (!completer.isCompleted) {
          _updateTestState(
            key,
            TestStatus.error,
            'Erro no Ping: ${e.toString()}',
          );
          completer.complete();
        }
        subscription?.cancel();
      },
    );

    // Timeout de segurança
    final timer = Timer(Duration(seconds: (totalCount * 2) + 5), () {
      if (!completer.isCompleted) {
        subscription?.cancel();
        _updateTestState(
          key,
          TestStatus.error,
          'Erro: Teste de ping expirou (Timeout)',
        );
        completer.complete();
      }
    });

    void cancel() {
      subscription?.cancel();
      ping.stop();
      if (!completer.isCompleted) completer.complete();
    }

    _cancelPing = cancel;
    try {
      await completer.future;
    } finally {
      timer.cancel();
      await subscription.cancel();
      ping.stop();
      if (identical(_cancelPing, cancel)) _cancelPing = null;
    }
  }
}
