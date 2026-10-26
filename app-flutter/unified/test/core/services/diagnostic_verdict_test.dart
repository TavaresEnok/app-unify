import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/models/diagnostic_report.dart';
import 'package:app_provedor_unified/core/services/diagnostic_verdict.dart';

DiagnosticReport buildReport({
  OnuMetrics? onu,
  WifiMetrics? wifi,
  PingMetrics? gateway,
  PingMetrics? google,
  SpeedMetrics? speed,
  String plan = 'VIBE 500 MEGA',
}) {
  return DiagnosticReport(
    generatedAt: DateTime(2026, 7, 17, 10, 30),
    customer: ReportCustomer.fromPlan(
      name: 'Cliente Teste',
      cpfCnpj: '055.843.264-61',
      planName: plan,
      contractId: 223260,
    ),
    provider: const ReportProvider(id: 'vibe', name: 'Vibe Telecom'),
    onu: onu,
    wifi: wifi,
    gatewayPing: gateway,
    googlePing: google,
    speed: speed,
  );
}

const healthyGateway =
    PingMetrics(host: '192.168.0.1', reachable: true, lossPercent: 0, latencyMs: 3, jitterMs: 1);
const healthyExternal =
    PingMetrics(host: '8.8.8.8', reachable: true, lossPercent: 0, latencyMs: 12, jitterMs: 2);
const healthyWifi = WifiMetrics(ssid: 'CASA', frequency: '5 GHz', signalStrength: '-45 dBm');
const healthyOnu = OnuMetrics(rxPower: -18, txPower: 2, status: 'Online', signalQuality: 'Boa');

void main() {
  final engine = DiagnosticVerdictEngine();

  group('cenário saudável', () {
    test('não gera achados e conclui que está tudo bem', () {
      final verdict = engine.evaluate(buildReport(
        onu: healthyOnu,
        wifi: healthyWifi,
        gateway: healthyGateway,
        google: healthyExternal,
        speed: const SpeedMetrics(downloadMbps: 480, uploadMbps: 240, pingMs: 10),
      ));

      expect(verdict.severity, VerdictSeverity.ok);
      expect(verdict.findings, isEmpty);
      expect(verdict.needsProviderSupport, isFalse);
      expect(verdict.headline, contains('funcionando bem'));
    });
  });

  group('fibra / ONU', () {
    test('RX abaixo de -25 dBm é crítico e exige o provedor', () {
      final verdict = engine.evaluate(buildReport(
        onu: const OnuMetrics(rxPower: -27.5, status: 'Online'),
        gateway: healthyGateway,
        google: healthyExternal,
      ));

      final finding = verdict.findings.first;
      expect(verdict.severity, VerdictSeverity.critical);
      expect(finding.area, VerdictArea.fiber);
      expect(finding.title, contains('muito baixo'));
      expect(finding.detail, contains('-27.5'));
      expect(verdict.needsProviderSupport, isTrue);
    });

    test('RX entre -20 e -25 dBm é apenas atenção', () {
      final verdict = engine.evaluate(buildReport(
        onu: const OnuMetrics(rxPower: -22, status: 'Online'),
        gateway: healthyGateway,
        google: healthyExternal,
      ));

      expect(verdict.severity, VerdictSeverity.attention);
      expect(verdict.findings.first.area, VerdictArea.fiber);
    });

    test('ONU offline é crítico', () {
      final verdict = engine.evaluate(buildReport(
        onu: const OnuMetrics(status: 'Offline'),
        gateway: healthyGateway,
        google: healthyExternal,
      ));

      expect(verdict.severity, VerdictSeverity.critical);
      expect(verdict.findings.first.title, contains('sem conexão'));
      expect(verdict.needsProviderSupport, isTrue);
    });

    test('sinal alto demais também é sinalizado', () {
      final verdict = engine.evaluate(buildReport(
        onu: const OnuMetrics(rxPower: -5, status: 'Online'),
        gateway: healthyGateway,
        google: healthyExternal,
      ));

      expect(verdict.findings.first.title, contains('alto demais'));
    });
  });

  group('separa problema dentro x fora de casa', () {
    test('roteador ok mas internet inacessível aponta rede do provedor', () {
      final verdict = engine.evaluate(buildReport(
        gateway: healthyGateway,
        google: const PingMetrics(host: '8.8.8.8', reachable: false, lossPercent: 100),
      ));

      final finding = verdict.findings.first;
      expect(finding.area, VerdictArea.providerNetwork);
      expect(finding.detail, contains('fora da sua casa'));
      expect(verdict.needsProviderSupport, isTrue);
    });

    test('roteador inacessível aponta o roteador, não o provedor', () {
      final verdict = engine.evaluate(buildReport(
        gateway: const PingMetrics(host: 'gw', reachable: false, lossPercent: 100),
        google: const PingMetrics(host: '8.8.8.8', reachable: false, lossPercent: 100),
      ));

      expect(verdict.findings.any((f) => f.area == VerdictArea.router), isTrue);
      expect(verdict.needsProviderSupport, isFalse);
    });

    test('perda externa acima de 5% é crítica', () {
      final verdict = engine.evaluate(buildReport(
        gateway: healthyGateway,
        google: const PingMetrics(
            host: '8.8.8.8', reachable: true, lossPercent: 8, latencyMs: 20),
      ));

      expect(verdict.severity, VerdictSeverity.critical);
      expect(verdict.findings.first.area, VerdictArea.providerNetwork);
    });

    test('jitter alto é sinalizado', () {
      final verdict = engine.evaluate(buildReport(
        gateway: healthyGateway,
        google: const PingMetrics(
            host: '8.8.8.8', reachable: true, lossPercent: 0, latencyMs: 20, jitterMs: 45),
      ));

      expect(verdict.findings.any((f) => f.title.contains('oscilando')), isTrue);
    });
  });

  group('velocidade vs plano contratado', () {
    test('muito abaixo do plano com Wi-Fi bom é crítico', () {
      final verdict = engine.evaluate(buildReport(
        wifi: healthyWifi,
        gateway: healthyGateway,
        google: healthyExternal,
        speed: const SpeedMetrics(downloadMbps: 90, uploadMbps: 40),
      ));

      final speedFinding =
          verdict.findings.firstWhere((f) => f.area == VerdictArea.speed);
      expect(speedFinding.severity, VerdictSeverity.critical);
      expect(speedFinding.detail, contains('18%'));
    });

    test('Wi-Fi fraco rebaixa a severidade e explica o resultado', () {
      final verdict = engine.evaluate(buildReport(
        wifi: const WifiMetrics(ssid: 'CASA', signalStrength: '-75 dBm'),
        gateway: healthyGateway,
        google: healthyExternal,
        speed: const SpeedMetrics(downloadMbps: 90, uploadMbps: 40),
      ));

      final speedFinding =
          verdict.findings.firstWhere((f) => f.area == VerdictArea.speed);
      expect(speedFinding.severity, VerdictSeverity.attention);
      expect(speedFinding.recommendation, contains('perto do roteador'));
    });

    test('velocidade dentro do esperado não gera achado', () {
      final verdict = engine.evaluate(buildReport(
        wifi: healthyWifi,
        gateway: healthyGateway,
        google: healthyExternal,
        speed: const SpeedMetrics(downloadMbps: 320, uploadMbps: 150),
      ));

      expect(verdict.findings.where((f) => f.area == VerdictArea.speed), isEmpty);
    });

    test('sem plano reconhecível não avalia velocidade', () {
      final verdict = engine.evaluate(buildReport(
        plan: 'PLANO EMPRESARIAL',
        wifi: healthyWifi,
        gateway: healthyGateway,
        google: healthyExternal,
        speed: const SpeedMetrics(downloadMbps: 10, uploadMbps: 5),
      ));

      expect(verdict.findings.where((f) => f.area == VerdictArea.speed), isEmpty);
    });
  });

  group('Wi-Fi', () {
    test('sinal muito fraco é crítico mas não culpa o provedor', () {
      final verdict = engine.evaluate(buildReport(
        wifi: const WifiMetrics(ssid: 'CASA', signalStrength: '-85 dBm'),
        gateway: healthyGateway,
        google: healthyExternal,
      ));

      expect(verdict.severity, VerdictSeverity.critical);
      expect(verdict.findings.first.area, VerdictArea.wifi);
      expect(verdict.needsProviderSupport, isFalse);
    });
  });

  group('ReportCustomer', () {
    test('infere a velocidade contratada do nome do plano', () {
      expect(ReportCustomer.parseContractedMbps('VIBE 500 MEGA'), 500);
      expect(ReportCustomer.parseContractedMbps('FIBRA 1 GIGA'), 1000);
      expect(ReportCustomer.parseContractedMbps('Plano 300MB'), 300);
      expect(ReportCustomer.parseContractedMbps('PLANO ESPECIAL'), isNull);
    });

    test('mascara o documento para circular fora do app', () {
      final customer = ReportCustomer.fromPlan(
        name: 'X',
        cpfCnpj: '055.843.264-61',
        planName: 'VIBE 500 MEGA',
      );
      expect(customer.maskedDocument, '***.264.61');
      expect(customer.maskedDocument, isNot(contains('055')));
    });
  });
}
