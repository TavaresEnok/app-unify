import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/models/diagnostico_state.dart';
import 'package:app_provedor_unified/core/widgets/diagnostics/diagnostic_view.dart';
import 'package:app_provedor_unified/core/theme/layout_tokens.dart';
import 'package:app_provedor_unified/core/vibe/vibe_page_parts.dart';
import 'package:app_provedor_unified/core/vibe/vibe_tokens.dart';

void main() {
  testWidgets('advanced tools respect provider capabilities', (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(
        theme: LayoutTokens.of('layout_06').themeData(),
        home: Scaffold(
            body: DiagnosticView(
                state: DiagnosticoState.initial(),
                toolEnabled: (route) => route != 'wifi',
                onTool: (route) => selected = route))));
    await tester.scrollUntilVisible(find.text('Outras ferramentas'), 220);
    await tester.tap(find.text('Outras ferramentas'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Teste de ping'));
    await tester.pumpAndSettle();
    expect(find.text('Minha rede Wi-Fi'), findsNothing);
    await tester.tap(find.text('Teste de ping'));
    expect(selected, 'ping');
  });
  testWidgets(
      'speed mode uses a clear action and does not offer a quick network check',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: LayoutTokens.of('layout_02').themeData(),
        home: Scaffold(
            body: DiagnosticView(
                state: DiagnosticoState.initial()
                    .copyWith(runMode: DiagnosticRunMode.speed),
                onQuick: () {}))));
    expect(find.text('Iniciar teste'), findsOneWidget);
    expect(find.text('Verificação rápida'), findsNothing);
    expect(find.text('Diagnóstico completo'), findsNothing);
  });
  testWidgets(
      'diagnostic summary and actions remain reachable at 200% text size',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: LayoutTokens.of('layout_06').themeData(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: Scaffold(
            body: DiagnosticView(
                state: DiagnosticoState.initial(), onQuick: () {}))));
    await tester.scrollUntilVisible(find.text('Verificação rápida'), 120);
    expect(tester.takeException(), isNull);
  });
  testWidgets('running and incomplete states show actual progress and warning',
      (tester) async {
    final base = DiagnosticoState.initial();
    final results =
        Map<String, Map<String, dynamic>>.from(base.testResultsDisplay);
    results['deviceInfo'] = {
      'label': 'Aparelho',
      'status': TestStatus.success,
      'result': 'OK'
    };
    results['pingGoogle'] = {
      'label': 'Ping externo',
      'status': TestStatus.error
    };
    final running = base.copyWith(
      runMode: DiagnosticRunMode.quick,
      startedAt: DateTime(2026),
      isTesting: true,
      geralStatusMessage: 'Verificando a rede',
      testResultsDisplay: results,
    );
    var cancelled = false;
    Widget page(DiagnosticoState state) => MaterialApp(
          home: Scaffold(
              body: DiagnosticView(
                  state: state, onCancel: () => cancelled = true)),
        );
    await tester.pumpWidget(page(running));
    expect(find.text('Verificando a rede…'), findsOneWidget);
    expect(find.text('3 de 5'), findsOneWidget);
    await tester.tap(find.text('Parar'));
    expect(cancelled, isTrue);
    await tester.pumpWidget(page(running.copyWith(isTesting: false)));
    expect(find.text('Algumas verificações ficaram sem resultado'),
        findsOneWidget);
    expect(tester.widget<VibeStatusCircle>(find.byType(VibeStatusCircle)).tone,
        VibeTone.warning);
  });
}
