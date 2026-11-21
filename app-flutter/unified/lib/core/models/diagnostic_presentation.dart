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
  String shareText(String providerName) {
    final lines = <String>['Verificação de conexão — $providerName', title];
    final when = state.finishedAt;
    if (when != null) lines.add('Horário: ${when.toLocal().toIso8601String()}');
    for (final group in groups) {
      lines.add('${group.title}: ${label(groupOutcome(group))}');
    }
    lines.add(
        'Concluídas: $completed de ${plannedKeys.length} verificações selecionadas.');
    lines.add(
        'Resultados sem resposta não confirmam, sozinhos, falta de internet.');
    // Only allowlisted numeric metrics; no CPF, credentials, SSID, MAC or IP.
    for (final key in ['pingGateway', 'pingGoogle', 'pingCloudflare']) {
      final metrics = state.testResultsDisplay[key]?['metrics'];
      if (metrics is Map && metrics['latencyMs'] is num) {
        final name = const {
          'pingGateway': 'Roteador',
          'pingGoogle': 'Resposta externa 1',
          'pingCloudflare': 'Resposta externa 2'
        }[key];
        lines.add(
            '$name: latência ${metrics['latencyMs']} ms; perda ${metrics['lossPercent'] ?? 'não informada'}%.');
      }
    }
    if (state.testResultsDisplay['speedTestCustom']?['status'] ==
        TestStatus.success) {
      lines.add(
          'Velocidade neste celular: ${state.customDownloadResultMbps.toStringAsFixed(1)} Mbps de download; ${state.customUploadResultMbps.toStringAsFixed(1)} Mbps de upload.');
    }
    return lines.join('\n');
  }
}
