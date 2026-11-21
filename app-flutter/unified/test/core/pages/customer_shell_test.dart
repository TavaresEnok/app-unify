import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:app_provedor_unified/core/painel_page.dart';
import 'package:app_provedor_unified/core/pages/customer/connection_hub_page.dart';
import 'package:app_provedor_unified/core/pages/customer/customer_support_page.dart';
import 'package:app_provedor_unified/core/pages/customer/subscriber_services_page.dart';
import 'package:app_provedor_unified/core/vibe/vibe_nav_bar.dart';
import 'package:app_provedor_unified/core/providers/providers.dart';
import 'package:app_provedor_unified/core/providers/connectivity_provider.dart';
import 'package:app_provedor_unified/core/providers/financeiro_provider.dart';
import 'package:app_provedor_unified/core/theme/layout_tokens.dart';
import '../../../tool/capture_preview.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR');
  });
  for (final id in [
    'layout_02',
    'layout_03',
    'layout_04',
    'layout_05',
    'layout_06'
  ]) {
    testWidgets('$id has the same destinations and account back navigation',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
          overrides: [
            configurationProvider.overrideWith((_) => DemoConfig(id)),
            authNotifierProvider.overrideWith(DemoAuth.new),
            financeiroViewModelProvider.overrideWith((_) => DemoFinance()),
            connectivityStatusProvider
                .overrideWith((_) => Stream.value(ConnectivityResult.wifi)),
          ],
          child: MaterialApp(
              theme: LayoutTokens.of(id).themeData(),
              home: const PainelPage(refreshOnOpen: false))));
      await tester.pumpAndSettle();
      Finder nav(String label) => find.descendant(
          of: find.byType(VibeNavBar), matching: find.text(label));
      for (final label in ['Início', 'Faturas', 'Conexão', 'Suporte']) {
        expect(nav(label), findsOneWidget);
      }
      await tester.tap(nav('Conexão'));
      await tester.pumpAndSettle();
      expect(find.byType(ConnectionHubPage), findsOneWidget);
      await tester.tap(nav('Início'));
      await tester.pumpAndSettle();
      // Minha conta fica em Todos os serviços em todos os layouts.
      await tester.ensureVisible(find.text('Ver todos').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver todos').first);
      await tester.pumpAndSettle();
      expect(find.byType(SubscriberServicesPage), findsOneWidget);
      await tester.ensureVisible(find.text('Minha conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Minha conta'));
      await tester.pumpAndSettle();
      expect(find.text('Meu contrato'), findsOneWidget);
      expect(find.byType(VibeNavBar), findsOneWidget);
      await tester.tap(find
          .byWidgetPredicate(
              (w) => w is Semantics && w.properties.label == 'Voltar')
          .last);
      await tester.pumpAndSettle();
      expect(find.byType(SubscriberServicesPage), findsOneWidget);
      await tester.tap(nav('Suporte'));
      await tester.pumpAndSettle();
      expect(find.byType(CustomerSupportPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
