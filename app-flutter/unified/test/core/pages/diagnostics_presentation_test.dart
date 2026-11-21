import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/models/usuario.dart';
import 'package:app_provedor_unified/core/models/provider_config.dart';
import 'package:app_provedor_unified/core/providers/configuration_provider.dart';
import 'package:app_provedor_unified/core/providers/customer_capabilities_provider.dart';
import 'package:app_provedor_unified/core/models/diagnostico_state.dart';
import 'package:app_provedor_unified/core/notifiers/auth_notifier.dart';
import 'package:app_provedor_unified/core/providers/providers.dart';
import 'package:app_provedor_unified/core/pages/shared_diagnostico_page.dart';
import 'package:app_provedor_unified/core/widgets/diagnostics/measurement_card.dart';
import 'package:app_provedor_unified/core/widgets/diagnostics/diagnostic_view.dart';
import 'package:app_provedor_unified/core/models/diagnostic_presentation.dart';
import 'package:app_provedor_unified/layout_selector.dart';

class NoSession extends AuthNotifier {
  @override
  FutureOr<Usuario?> build() => null;
}

class DiagnosticConfig extends ConfigurationProvider {
  DiagnosticConfig(bool wifiEnabled)
      : data = ProviderConfig.fromJson({
          'name': 'Provedor de teste',
          'apiUrl': 'https://example.invalid/api',
          'layoutType': 'layout_02',
          'menuConfig': {
            'items': {
              'wifi': {'enabled': wifiEnabled}
            }
          },
        }, 'test');
  final ProviderConfig data;
  @override
  ProviderConfig get providerConfig => data;
}

void main() {
  for (final (menu, available) in [
    (true, true),
    (true, false),
    (false, true),
    (false, false)
  ]) {
    testWidgets(
        'diagnóstico exige menu $menu e capacidade $available para Wi-Fi',
        (tester) async {
      await tester.pumpWidget(ProviderScope(overrides: [
        authNotifierProvider.overrideWith(NoSession.new),
        configurationProvider.overrideWith((_) => DiagnosticConfig(menu)),
        wifiManagementAvailableProvider.overrideWith((_) async => available),
      ], child: const MaterialApp(home: DiagnosticoPage())));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Outras ferramentas'), 200);
      await tester.tap(find.text('Outras ferramentas'));
      await tester.pumpAndSettle();
      expect(find.text('Minha rede Wi-Fi'),
          menu && available ? findsOneWidget : findsNothing);
      expect(find.text('Ping'), findsOneWidget);
    });
  }

  for (final style in [
    'default',
    'diagnostic_02',
    'diagnostic_03',
    'diagnostic_05',
    'diagnostic_06',
    'diagnostic_07'
  ]) {
    testWidgets('$style exposes the same tests and actions', (tester) async {
      await tester.pumpWidget(ProviderScope(
          overrides: [authNotifierProvider.overrideWith(NoSession.new)],
          child: MaterialApp(
              home: LayoutSelector.getDiagnosticByStyle(
                  layoutType: 'layout_06', diagnosticStyle: style))));
      await tester.pump();
      expect(find.byType(DiagnosticoPage), findsOneWidget);
      expect(find.text('Verificação rápida'), findsOneWidget);
      expect(find.text('Diagnóstico completo'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Seu celular'), 160,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Seu celular'), findsOneWidget);
      expect(find.byType(DiagnosticView), findsOneWidget);
      expect(DiagnosticPresentation.groups.expand((g) => g.keys).toSet(),
          DiagnosticoState.initial().testResultsDisplay.keys.toSet());
      expect(tester.takeException(), isNull);
    });
  }
  test('missing optical readings never become fabricated measurements', () {
    expect(
        MeasurementCard.displayResult(
            {'rxPower': null, 'txPower': null, 'temperature': null}),
        contains('Indisponível'));
    expect(MeasurementCard.displayResult(null), 'Ainda não medido.');
  });
}
