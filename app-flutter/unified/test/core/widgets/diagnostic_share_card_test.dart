import 'package:app_provedor_unified/core/models/diagnostico_state.dart';
import 'package:app_provedor_unified/core/theme/layout_tokens.dart';
import 'package:app_provedor_unified/core/widgets/diagnostics/diagnostic_share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DiagnosticShareCard renderiza todos os grupos abertos e gera PNG válido',
      (tester) async {
    final initial = DiagnosticoState.initial();
    final results =
        Map<String, Map<String, dynamic>>.from(initial.testResultsDisplay);
    results['deviceInfo'] = {
      'label': 'Celular',
      'status': TestStatus.success,
      'result': 'Modelo: Pixel\nSistema: Android 14',
    };
    results['wifiInfo'] = {
      'label': 'Wi-Fi',
      'status': TestStatus.success,
      'result': 'Frequência: 5 GHz\nForça do Sinal: Excelente',
    };
    results['onuInfo'] = {
      'label': 'Fibra',
      'status': TestStatus.success,
      'result': {
        'isOnline': true,
        'rxPower': -19.4,
        'model': 'HG8145V5',
      },
    };
    results['pingGoogle'] = {
      'label': 'Ping Google',
      'status': TestStatus.success,
      'metrics': {'latencyMs': 11, 'lossPercent': 0},
    };

    final state = initial.copyWith(
      runMode: DiagnosticRunMode.quick,
      startedAt: DateTime(2026, 11, 24, 15, 0),
      finishedAt: DateTime(2026, 11, 24, 15, 1),
      testResultsDisplay: results,
    );

    final captureKey = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      theme: LayoutTokens.of('layout_03').themeData(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 380,
            child: RepaintBoundary(
              key: captureKey,
              child: DiagnosticShareCard(
                state: state,
                providerName: 'Vibe Telecom',
                planName: 'Fibra 600 Mega',
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Diagnóstico de conexão'), findsOneWidget);
    // Todos os grupos aparecem abertos sem necessidade de toque:
    expect(find.text('5 GHz'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('-19,4 dBm, bom'), findsOneWidget);
    expect(find.text('11 ms'), findsOneWidget);
    expect(find.text('Gerado pelo aplicativo Vibe Telecom'), findsOneWidget);

    final bytes = await tester.runAsync(() => captureWidgetAsPng(captureKey));
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(1000));
    // Assinatura PNG: 89 50 4E 47 0D 0A 1A 0A
    expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DiagnosticShareCard exibe servidor Speedtest no modo velocidade',
      (tester) async {
    final initial = DiagnosticoState.initial();
    final results =
        Map<String, Map<String, dynamic>>.from(initial.testResultsDisplay);
    results['speedTestCustom'] = {'status': TestStatus.success};
    results['speedTestFast'] = {'status': TestStatus.success};

    final state = initial.copyWith(
      runMode: DiagnosticRunMode.speed,
      startedAt: DateTime(2026, 11, 24, 15, 0),
      finishedAt: DateTime(2026, 11, 24, 15, 1),
      testResultsDisplay: results,
      customDownloadResultMbps: 485,
      customUploadResultMbps: 240,
      fastDownloadResultMbps: 460,
      speedTestPingLatency: 7,
      speedTestServerName: 'VIBE · Paulista',
      speedTestReferenceServerName: 'Conect Fibra · Abreu e Lima',
    );

    await tester.pumpWidget(MaterialApp(
      theme: LayoutTokens.of('layout_02').themeData(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: DiagnosticShareCard(
            state: state,
            providerName: 'Vibe Telecom',
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Teste de velocidade'), findsOneWidget);
    expect(find.text('485 Mbps'), findsOneWidget);
    expect(find.text('240 Mbps'), findsOneWidget);
    expect(find.text('VIBE · Paulista'), findsOneWidget);
    expect(find.textContaining('Conect Fibra · Abreu e Lima'), findsOneWidget);
    expect(find.text('7 ms'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
