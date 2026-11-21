import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/models/diagnostico_state.dart';
import 'package:app_provedor_unified/core/pages/shared_speed_test_page.dart';
import 'package:app_provedor_unified/core/providers/connectivity_provider.dart';

void main() {
  Future<void> showView(WidgetTester tester, DiagnosticoState state,
      {ConnectivityResult network = ConnectivityResult.wifi,
      VoidCallback? onStart,
      VoidCallback? onStop,
      VoidCallback? onShare}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        connectivityStatusProvider.overrideWith((_) => Stream.value(network))
      ],
      child: MaterialApp(
          home: Scaffold(
              body: SpeedTestView(
        state: state,
        onStart: onStart ?? () {},
        onStop: onStop ?? () {},
        onShare: onShare ?? () {},
      ))),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('sem conexão mostra estado vazio', (tester) async {
    await showView(tester, DiagnosticoState.initial(),
        network: ConnectivityResult.none);
    expect(find.text('Sem conexão com a internet'), findsOneWidget);
    expect(find.text('Iniciar teste'), findsNothing);
  });

  testWidgets('apresenta progresso real e permite parar', (tester) async {
    var stopped = false;
    final state = DiagnosticoState.initial().copyWith(
      runMode: DiagnosticRunMode.speed,
      isTesting: true,
      startedAt: DateTime(2026),
      geralStatusMessage: 'Testando Upload...',
      customDownloadResultMbps: 120,
      customUploadResultMbps: 30,
      downloadHistory: [const FlSpot(0, 120)],
      uploadHistory: [const FlSpot(0, 30)],
    );
    await showView(tester, state, onStop: () => stopped = true);
    expect(find.text('120.0 Mbps'), findsOneWidget);
    expect(find.text('30.0 Mbps'), findsOneWidget);
    await tester.ensureVisible(find.text('Parar'));
    await tester.tap(find.text('Parar'));
    expect(stopped, isTrue);
  });

  testWidgets('resultado real mostra referência e permite compartilhar',
      (tester) async {
    var shared = false;
    final initial = DiagnosticoState.initial();
    final results =
        Map<String, Map<String, dynamic>>.from(initial.testResultsDisplay);
    results['speedTestCustom'] = {'status': TestStatus.success};
    results['speedTestFast'] = {'status': TestStatus.success};
    final state = initial.copyWith(
      runMode: DiagnosticRunMode.speed,
      startedAt: DateTime(2026),
      testResultsDisplay: results,
      customDownloadResultMbps: 420,
      customUploadResultMbps: 200,
      fastDownloadResultMbps: 390,
      speedTestPingLatency: 11,
    );
    await showView(tester, state, onShare: () => shared = true);
    expect(find.text('420.0 Mbps'), findsOneWidget);
    expect(find.text('390.0 Mbps'), findsOneWidget);
    await tester.ensureVisible(find.text('Compartilhar'));
    await tester.tap(find.text('Compartilhar'));
    expect(shared, isTrue);
  });

  testWidgets('upload parcial não inventa download zero', (tester) async {
    final state = DiagnosticoState.initial().copyWith(
      runMode: DiagnosticRunMode.speed,
      startedAt: DateTime(2026),
      wasInterrupted: true,
      customUploadResultMbps: 25,
      uploadHistory: [const FlSpot(0, 25)],
    );
    await showView(tester, state);
    expect(find.text('25.0 Mbps'), findsOneWidget);
    expect(find.text('0.0 Mbps'), findsNothing);
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('interrupção preserva medições e escala de texto',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = DiagnosticoState.initial().copyWith(
      runMode: DiagnosticRunMode.speed,
      startedAt: DateTime(2026),
      wasInterrupted: true,
      customDownloadResultMbps: 25,
      downloadHistory: [const FlSpot(0, 25)],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        connectivityStatusProvider
            .overrideWith((_) => Stream.value(ConnectivityResult.wifi))
      ],
      child: MaterialApp(
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!),
          home: Scaffold(
              body: SpeedTestView(
                  state: state,
                  onStart: () {},
                  onStop: () {},
                  onShare: () {}))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('25.0 Mbps'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Testar de novo'), 150);
    expect(tester.takeException(), isNull);
  });
}
