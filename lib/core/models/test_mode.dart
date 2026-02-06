// Test Modes - Personalized diagnostic test configurations

enum TestMode {
  quick, // Ping + Speed only (~30s)
  gaming, // Latency + Jitter + Stability focused
  streaming, // Download sustained load
  complete, // All tests (default)
}

extension TestModeExtension on TestMode {
  String get displayName {
    switch (this) {
      case TestMode.quick:
        return 'Rápido';
      case TestMode.gaming:
        return 'Gaming';
      case TestMode.streaming:
        return 'Streaming';
      case TestMode.complete:
        return 'Completo';
    }
  }

  String get description {
    switch (this) {
      case TestMode.quick:
        return 'Ping + Velocidade • ~30s';
      case TestMode.gaming:
        return 'Latência + Estabilidade • ~45s';
      case TestMode.streaming:
        return 'Download sustentado • ~50s';
      case TestMode.complete:
        return 'Diagnóstico completo • ~2min';
    }
  }

  String get icon {
    switch (this) {
      case TestMode.quick:
        return '⚡';
      case TestMode.gaming:
        return '🎮';
      case TestMode.streaming:
        return '📺';
      case TestMode.complete:
        return '🔍';
    }
  }

  List<String> get includedTests {
    switch (this) {
      case TestMode.quick:
        return ['ping', 'speed'];
      case TestMode.gaming:
        return ['ping', 'jitter', 'packetLoss', 'gateway'];
      case TestMode.streaming:
        return ['ping', 'downloadSpeed', 'stability'];
      case TestMode.complete:
        return [
          'battery',
          'deviceInfo',
          'wifi',
          'onu',
          'lan',
          'ip',
          'ping',
          'traceroute',
          'speed'
        ];
    }
  }

  Duration get estimatedDuration {
    switch (this) {
      case TestMode.quick:
        return const Duration(seconds: 30);
      case TestMode.gaming:
        return const Duration(seconds: 45);
      case TestMode.streaming:
        return const Duration(seconds: 50);
      case TestMode.complete:
        return const Duration(minutes: 2);
    }
  }
}
