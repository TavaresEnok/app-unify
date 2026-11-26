import 'diagnostico_state.dart';

enum DiagnosticOutcome {
  notVerified,
  running,
  measured,
  attention,
  inconclusive,
  unavailable,
  permissionRequired
}

class DiagnosticGroup {
  final String title;
  final String description;
  final List<String> keys;
  const DiagnosticGroup(this.title, this.description, this.keys);
}

/// Presentation is conservative: failure to measure is never proof of an outage.
class DiagnosticPresentation {
  final DiagnosticoState state;
  const DiagnosticPresentation(this.state);
  static const groups = [
    DiagnosticGroup('Seu celular', 'Informações do aparelho e energia.',
        ['deviceInfo', 'batteryInfo']),
    DiagnosticGroup('Sua rede Wi-Fi', 'Rede local e resposta do roteador.',
        ['wifiInfo', 'pingGateway', 'lanScan']),
    DiagnosticGroup('Seu equipamento de fibra',
        'Informações consultadas com o provedor.', ['onuInfo']),
    DiagnosticGroup(
        'Internet e velocidade', 'Respostas externas, velocidade e rota.', [
      'publicIp',
      'pingGoogle',
      'pingCloudflare',
      'traceroute',
      'speedTestCustom',
      'speedTestFast'
    ]),
  ];
  static const quickKeys = [
    'deviceInfo',
    'onuInfo',
    'wifiInfo',
    'pingGateway',
    'pingGoogle'
  ];
  List<String> get plannedKeys => switch (state.runMode) {
        DiagnosticRunMode.quick => quickKeys,
        DiagnosticRunMode.speed => ['speedTestCustom', 'speedTestFast'],
        _ => state.testResultsDisplay.keys.toList(),
      };
  bool get hasResults => state.testResultsDisplay.values.any((e) =>
      e['status'] == TestStatus.success || e['status'] == TestStatus.error);
  int get completed => plannedKeys
      .where((key) => [TestStatus.success, TestStatus.error]
          .contains(state.testResultsDisplay[key]?['status']))
      .length;
  double get progress =>
      plannedKeys.isEmpty ? 0 : completed / plannedKeys.length;
  DiagnosticOutcome outcome(String key) {
    final entry = state.testResultsDisplay[key];
    if (entry?['availability'] == TestAvailability.permissionRequired.name) {
      return DiagnosticOutcome.permissionRequired;
    }
    if (entry?['availability'] == TestAvailability.unsupported.name) {
      return DiagnosticOutcome.unavailable;
    }
    final status = entry?['status'];
    if (status == TestStatus.running) {
      return state.isTesting
          ? DiagnosticOutcome.running
          : DiagnosticOutcome.notVerified;
    }
    if (status == TestStatus.error) return DiagnosticOutcome.inconclusive;
    if (status == TestStatus.success) {
      final metrics = entry?['metrics'];
      if (metrics is Map &&
          metrics['lossPercent'] is num &&
          metrics['lossPercent'] > 0) {
        return DiagnosticOutcome.attention;
      }
      return DiagnosticOutcome.measured;
    }
    return DiagnosticOutcome.notVerified;
  }

  DiagnosticOutcome groupOutcome(DiagnosticGroup group) {
    final values = group.keys.where(plannedKeys.contains).map(outcome).toList();
    for (final priority in [
      DiagnosticOutcome.running,
      DiagnosticOutcome.attention,
      DiagnosticOutcome.inconclusive,
      DiagnosticOutcome.permissionRequired,
      DiagnosticOutcome.unavailable
    ]) {
      if (values.contains(priority)) return priority;
    }
    return values.contains(DiagnosticOutcome.measured)
        ? DiagnosticOutcome.measured
        : DiagnosticOutcome.notVerified;
  }

  String get title => state.isTesting
      ? 'Verificando sua conexão'
      : state.wasInterrupted
          ? 'Verificação interrompida'
          : !hasResults
              ? 'Vamos entender sua conexão?'
              : state.testResultsDisplay.values
                      .any((e) => e['status'] == TestStatus.error)
                  ? 'Algumas verificações ficaram sem resultado'
                  : completed < plannedKeys.length
                      ? 'Verificação parcial'
                      : plannedKeys.every((key) =>
                              outcome(key) == DiagnosticOutcome.measured)
                          ? 'Tudo certo com a sua conexão'
                          : 'Verificação concluída';

  /// Resumo em uma cor para o histórico: tudo medido, algo a conferir ou
  /// nada medido.
  String get tone {
    final outcomes = plannedKeys.map(outcome).toList();
    if (!outcomes.contains(DiagnosticOutcome.measured) &&
        !outcomes.contains(DiagnosticOutcome.attention)) {
      return 'mut';
    }
    return state.wasInterrupted ||
            outcomes.any((value) => value != DiagnosticOutcome.measured)
        ? 'wa'
        : 'ok';
  }

  String get description => !hasResults && !state.isTesting
      ? 'Comece pela verificação rápida. O diagnóstico completo acrescenta velocidade, rota e rede local.'
      : state.isTesting
          ? 'Você pode interromper. Os resultados já obtidos serão mantidos.'
          : 'Veja abaixo o que foi medido e o que ficou sem verificar. Uma consulta sem resposta, sozinha, não comprova falha na internet.';

  /// Etapa em andamento em linguagem do assinante (`DGSTEPS` do protótipo).
  /// O motor descreve tecnicamente ("Testando Download (Fast.com)... 73.8
  /// Mbps (7%)"); aqui vira "Medindo o download…".
  static String stepLabel(String raw) {
    final text = raw.toLowerCase();
    String pick() {
      if (text.contains('upload')) return 'Medindo o upload';
      if (text.contains('download')) return 'Medindo o download';
      if (text.contains('latência')) return 'Medindo a latência';
      if (text.contains('roteador')) return 'Testando o roteador';
      if (text.contains('google') || text.contains('cloudflare')) {
        return 'Medindo o ping externo';
      }
      if (text.contains('fibra') || text.contains('onu')) {
        return 'Lendo o sinal da fibra';
      }
      if (text.contains('permiss')) return 'Aguardando a permissão';
      if (text.contains('lan') && text.contains('rede')) {
        return 'Contando aparelhos na rede';
      }
      if (text.contains('wifi') || text.contains('wi-fi')) {
        return 'Verificando o Wi-Fi';
      }
      if (text.contains('ip')) return 'Consultando o IP público';
      if (text.contains('dispositivo')) return 'Lendo dados do celular';
      if (text.contains('servidor')) return 'Preparando o teste';
      if (text.contains('internet')) return 'Testando o acesso à internet';
      return raw.replaceAll(RegExp(r'\.+$'), '').trim();
    }

    final label = pick();
    return label.isEmpty ? 'Verificando…' : '$label…';
  }

  static String label(DiagnosticOutcome outcome) => switch (outcome) {
        DiagnosticOutcome.notVerified => 'Não verificado',
        DiagnosticOutcome.running => 'Verificando…',
        DiagnosticOutcome.measured => 'Dados obtidos',
        DiagnosticOutcome.attention => 'Resposta com perdas',
        DiagnosticOutcome.inconclusive => 'Não foi possível concluir',
        DiagnosticOutcome.unavailable => 'Não disponível nesta conexão',
        DiagnosticOutcome.permissionRequired => 'Permissão necessária',
      };
  static String origin(String key) => switch (key) {
        'onuInfo' => 'Informado pelo equipamento, via provedor',
        'traceroute' => 'Executado no servidor, não neste celular',
        'publicIp' => 'Consulta externa feita pelo celular',
        _ => 'Medido neste celular',
      };
  static String _ms(num value) =>
      value < 1 ? 'menos de 1 ms' : '${value.round()} ms';

  String shareText(String providerName) {
    final header = <String>['Verificação de conexão — $providerName', title];
    final when = state.finishedAt;
    if (when != null) {
      final local = when.toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      header.add('Horário: ${two(local.day)}/${two(local.month)}/${local.year} '
          'às ${two(local.hour)}:${two(local.minute)}');
    }

    final groupLines = <String>[
      for (final group in groups)
        '${group.title}: ${label(groupOutcome(group))}',
      'Concluídas: $completed de ${plannedKeys.length} verificações selecionadas.',
    ];

    // Only allowlisted numeric metrics; no CPF, credentials, SSID, MAC or IP.
    final metricLines = <String>[];
    for (final key in ['pingGateway', 'pingGoogle', 'pingCloudflare']) {
      final metrics = state.testResultsDisplay[key]?['metrics'];
      if (metrics is Map && metrics['latencyMs'] is num) {
        final name = const {
          'pingGateway': 'Roteador',
          'pingGoogle': 'Resposta externa 1',
          'pingCloudflare': 'Resposta externa 2'
        }[key];
        final loss = metrics['lossPercent'];
        metricLines.add('$name: latência ${_ms(metrics['latencyMs'] as num)}; '
            'perda ${loss is num ? '${loss.round()}%' : 'não informada'}.');
      }
    }
    if (state.testResultsDisplay['speedTestCustom']?['status'] ==
        TestStatus.success) {
      final server = state.speedTestServerName;
      metricLines
          .add('Velocidade neste celular${server != null ? ' ($server)' : ''}: '
              '${state.customDownloadResultMbps.round()} Mbps de download; '
              '${state.customUploadResultMbps.round()} Mbps de upload.');
    }

    final sections = <String>[
      header.join('\n'),
      groupLines.join('\n'),
      if (metricLines.isNotEmpty) metricLines.join('\n'),
      'Resultados sem resposta não confirmam, sozinhos, falta de internet.',
    ];
    return sections.join('\n\n');
  }
}
