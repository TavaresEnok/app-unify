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
    int explicitTimeouts = 0;
    PingSummary? summary;
    PingError? commandError;
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
        if (data.summary != null) {
          summary = data.summary;
          return;
        }
        final error = data.error;
        if (error != null && error.error != ErrorType.requestTimedOut) {
          commandError = error;
          return;
        }
        if (data.response == null && error == null) return;
        final isFirst = currentIndex == 0;
        currentIndex++;
        if (discardFirst && isFirst) return;
        if (error?.error == ErrorType.requestTimedOut) {
          explicitTimeouts++;
          responses.add({'sequence': data.response?.seq, 'timeout': true});
        } else if (data.response != null) {
          packetsReceived++;
          final time = data.response!.time?.inMilliseconds;
          if (time != null) {
            latencies.add(time);
            responses.add({'sequence': data.response!.seq, 'timeMs': time});
          }
        }
        _updateTestState(key, TestStatus.running, 'Recebendo respostas...',
            metrics: {'host': host, 'responses': List.of(responses)});
      },
      onDone: () {
        if (completer.isCompleted) return;
        final nativeSummary = discardFirst ? null : summary;
        final sent = nativeSummary?.transmitted ??
            (packetsReceived + explicitTimeouts == count ? count : null);
        final received =
            nativeSummary?.received ?? (sent != null ? packetsReceived : null);
        final loss = sent != null && sent > 0 && received != null
            ? ((sent - received).clamp(0, sent) / sent * 100)
            : null;
        final metrics = <String, dynamic>{
          'host': host,
          'responses': List.of(responses),
          if (sent != null) 'packetsSent': sent,
          if (received != null) 'packetsReceived': received,
          if (loss != null) 'lossPercent': loss,
        };
        if (commandError != null) {
          final message = commandError!.error == ErrorType.unknownHost
              ? 'Não foi possível encontrar o domínio informado.'
              : 'Não foi possível executar o ping.';
          _updateTestState(key, TestStatus.error, message, metrics: metrics);
        } else if (latencies.isEmpty) {
          _updateTestState(key, TestStatus.error, 'Host inacessível',
              metrics: {...metrics, 'reachable': false});
        } else {
          final avg =
              (latencies.reduce((a, b) => a + b) / latencies.length).round();
          var diff = 0;
          for (var i = 0; i < latencies.length - 1; i++) {
            diff += (latencies[i] - latencies[i + 1]).abs();
          }
          final jitter =
              latencies.length > 1 ? diff / (latencies.length - 1) : 0.0;
          final sorted = [...latencies]..sort();
          _updateTestState(
            key,
            TestStatus.success,
            'Latência: ${avg}ms\nJitter: ${jitter.toStringAsFixed(1)}ms'
            '${loss == null ? '' : '\nPerda: ${loss.toStringAsFixed(0)}%'}',
            metrics: {
              ...metrics,
              'reachable': true,
              'latencyMs': avg.toDouble(),
              'jitterMs': double.parse(jitter.toStringAsFixed(1)),
              'minMs': sorted.first.toDouble(),
              'maxMs': sorted.last.toDouble(),
            },
          );
        }
        completer.complete();
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
