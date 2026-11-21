import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/models/diagnostico_state.dart';
import 'package:app_provedor_unified/core/models/diagnostic_presentation.dart';

void main() {
  test('all existing tests remain reachable through four groups', () {
    expect(DiagnosticPresentation.groups.expand((g) => g.keys).toSet(),
        DiagnosticoState.initial().testResultsDisplay.keys.toSet());
  });
  test('failed ping never becomes proof of an internet outage', () {
    final state = DiagnosticoState.initial().copyWith(testResultsDisplay: {
      'pingGoogle': {
        'status': TestStatus.error,
        'result': 'Host inacessível',
        'metrics': {'lossPercent': 100}
      },
    });
    final view = DiagnosticPresentation(state);
    expect(view.outcome('pingGoogle'), DiagnosticOutcome.inconclusive);
    expect(view.description, contains('não comprova'));
    expect(view.title, isNot(contains('sem internet')));
  });
  test('permission, unavailable and measurement failure stay distinct', () {
    final view = DiagnosticPresentation(
        DiagnosticoState.initial().copyWith(testResultsDisplay: {
      'wifiInfo': {
        'status': TestStatus.error,
        'availability': 'permissionRequired'
      },
      'pingGateway': {
        'status': TestStatus.error,
        'availability': 'unsupported'
      },
      'onuInfo': {'status': TestStatus.error},
    }));
    expect(view.outcome('wifiInfo'), DiagnosticOutcome.permissionRequired);
    expect(view.outcome('pingGateway'), DiagnosticOutcome.unavailable);
    expect(view.outcome('onuInfo'), DiagnosticOutcome.inconclusive);
  });
  test('canceled measurements stop showing a running spinner', () {
    final view = DiagnosticPresentation(DiagnosticoState.initial()
        .copyWith(wasInterrupted: true, testResultsDisplay: {
      'wifiInfo': {'status': TestStatus.running}
    }));
    expect(view.outcome('wifiInfo'), DiagnosticOutcome.notVerified);
    expect(view.title, 'Verificação interrompida');
  });
  test('quick progress excludes tests outside its execution plan', () {
    final entries = DiagnosticoState.initial().testResultsDisplay;
    for (final key in DiagnosticPresentation.quickKeys) {
      entries[key]!['status'] = TestStatus.success;
    }
    final view = DiagnosticPresentation(DiagnosticoState.initial().copyWith(
        runMode: DiagnosticRunMode.quick, testResultsDisplay: entries));
    expect(view.completed, 5);
    expect(view.progress, 1);
  });
  test('shared summary includes no raw network or customer identifiers', () {
    final view = DiagnosticPresentation(
        DiagnosticoState.initial().copyWith(testResultsDisplay: {
      'wifiInfo': {
        'status': TestStatus.success,
        'result': {
          'ssid': 'PRIVATE_SSID',
          'password': 'PRIVATE_PASSWORD',
          'bssid': 'PRIVATE_MAC'
        }
      },
      'publicIp': {'status': TestStatus.success, 'result': 'PRIVATE_IP'},
      'pingGoogle': {
        'status': TestStatus.success,
        'metrics': {'latencyMs': 20, 'lossPercent': 0, 'host': 'PRIVATE_HOST'}
      },
    }));
    final text = view.shareText('Provedor');
    for (final secret in [
      'PRIVATE_SSID',
      'PRIVATE_PASSWORD',
      'PRIVATE_MAC',
      'PRIVATE_IP',
      'PRIVATE_HOST'
    ]) {
      expect(text, isNot(contains(secret)));
    }
    expect(text, contains('20 ms'));
    expect(DiagnosticPresentation.origin('traceroute'), contains('servidor'));
  });
}
