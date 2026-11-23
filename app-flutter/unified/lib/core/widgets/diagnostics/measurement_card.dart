import 'package:flutter/material.dart';
import '../../models/diagnostico_state.dart';
import '../../models/diagnostic_presentation.dart';

/// Displays only measured values, shared by all diagnostic styles.
class MeasurementCard extends StatelessWidget {
  final String testKey;
  final bool isTesting;
  final Map<String, dynamic> measurement;
  const MeasurementCard(
      {super.key,
      required this.testKey,
      required this.measurement,
      this.isTesting = true});

  static const _labels = {
    'rxPower': 'Sinal recebido (dBm)',
    'txPower': 'Sinal transmitido (dBm)',
    'temperature': 'Temperatura (°C)',
    'voltage': 'Tensão (V)',
    'isOnline': 'Conectado',
    'status': 'Estado',
    'model': 'Modelo',
    'serialNumber': 'Número de série',
    'oltName': 'OLT',
    'slot': 'Slot',
    'pon': 'PON',
    'onuId': 'ONU',
    'signalQuality': 'Qualidade do sinal',
    'mode': 'Modo',
    'vlan': 'VLAN',
    'cto': 'CTO',
    'lastUpdate': 'Atualização',
    'batteryLevel': 'Bateria',
    'isCharging': 'Carregando',
    'stateStr': 'Estado',
  };

  static String displayResult(dynamic result) {
    if (result == null) return 'Ainda não medido.';
    if (result is! Map) return result.toString();
    if (result['display'] is String) return result['display'] as String;
    return result.entries.where((e) => _labels.containsKey(e.key)).map((entry) {
      final value = entry.value;
      final formatted = value == null
          ? 'Indisponível'
          : entry.key == 'batteryLevel' && value is num
              ? '${value.round()}%'
              : value is bool
                  ? (value ? 'Sim' : 'Não')
                  : '$value';
      return '${_labels[entry.key]}: $formatted';
    }).join('\n');
  }

  static String _time(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return 'Não informado';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final status = measurement['status'] as TestStatus? ?? TestStatus.pending;
    final state = DiagnosticoState(
        isTesting: isTesting,
        geralStatusMessage: '',
        testResultsDisplay: {testKey: measurement});
    final outcome = DiagnosticPresentation(state).outcome(testKey);
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final label = DiagnosticPresentation.label(outcome);
    final trace = testKey == 'traceroute';
    final metrics = measurement['metrics'];
    return Card(
        child: ExpansionTile(
      key: PageStorageKey(testKey),
      initiallyExpanded: status == TestStatus.error,
      leading: status == TestStatus.running && isTesting
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(
              status == TestStatus.error
                  ? Icons.error_outline
                  : status == TestStatus.success
                      ? Icons.check_circle_outline
                      : Icons.pending_outlined,
              color: color),
      title: Text(measurement['label']?.toString() ?? testKey),
      subtitle: Text(label),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (trace)
          const Text('Rota medida a partir do servidor, não do aparelho.'),
        Text(DiagnosticPresentation.origin(testKey),
            style: TextStyle(color: color, fontSize: 12)),
        const SizedBox(height: 8),
        if (status == TestStatus.error)
          Text(outcome == DiagnosticOutcome.permissionRequired
              ? 'Autorize o acesso às informações do Wi-Fi para executar este teste.'
              : outcome == DiagnosticOutcome.unavailable
                  ? 'Este teste depende de uma conexão Wi-Fi disponível neste celular.'
                  : 'Não conseguimos obter um resultado confiável. Tente novamente. Isso, sozinho, não confirma um problema na conexão.')
        else if (status == TestStatus.success)
          SelectableText(displayResult(measurement['result']))
        else
          const Text('Ainda não há resultado para esta verificação.'),
        if (measurement['measuredAt'] is String) ...[
          const SizedBox(height: 8),
          Text(
              'Horário da consulta: ${_time(measurement['measuredAt'] as String)}',
              style: TextStyle(color: color, fontSize: 12)),
        ],
        if (trace && metrics is Map)
          Text(metrics['reached'] == true
              ? 'Destino alcançado.'
              : 'Rota parcial: o destino não confirmou resposta.'),
      ],
    ));
  }
}
