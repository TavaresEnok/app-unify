import 'package:app_provedor_unified/core/pages/customer/homes/home_blocks.dart';
import 'package:app_provedor_unified/core/pages/customer/homes/home_centered.dart';
import 'package:app_provedor_unified/core/pages/customer/homes/home_dock.dart';
import 'package:app_provedor_unified/core/pages/customer/homes/home_ribbon.dart';
import 'package:app_provedor_unified/core/pages/customer/homes/home_sheet.dart';
import 'package:app_provedor_unified/core/providers/customer_capabilities_provider.dart';
import 'package:app_provedor_unified/core/providers/financeiro_provider.dart';
import 'package:app_provedor_unified/core/providers/providers.dart';
import 'package:app_provedor_unified/core/theme/layout_tokens.dart';
import 'package:app_provedor_unified/layout_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../tool/capture_preview.dart';
import '../controllers/approved_invoice_test.dart' show SevenInvoiceService;

Widget _dashboard(String layout) => LayoutSelector.getDashboard(
    layoutType: layout,
    customerName: 'Cliente',
    planName: 'Fibra',
    connectionStatus: 'Ativo',
    billAmount: 0,
    billDueDate: DateTime(2026, 11, 20),
    usedGb: 0,
    totalGb: 0,
    downloadMbps: 0,
    uploadMbps: 0,
    onNavigate: (_) {});

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  // Cada layout abre a sua tela definitiva de layout-app/vibe-5-definitivas.html.
  const homeByLayout = {
    'layout_02': VibeSheetHome,
    'layout_03': VibeDockHome,
    'layout_04': VibeBlocksHome,
    'layout_05': VibeRibbonHome,
    'layout_06': VibeCenteredHome,
    'layout_01': VibeCenteredHome,
    'legacy': VibeCenteredHome,
  };

  testWidgets('Blocos escuros keeps services visible below seven invoices',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 720);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final finance = FinanceiroProvider(SevenInvoiceService());
    await finance.fetchHistory();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        configurationProvider.overrideWith((_) => DemoConfig('layout_04')),
        authNotifierProvider.overrideWith(DemoAuth.new),
        financeiroViewModelProvider.overrideWith((_) => finance),
        wifiManagementAvailableProvider.overrideWith((_) async => false),
      ],
      child: MaterialApp(
          theme: LayoutTokens.of('layout_04')
              .withBrightness(Brightness.light)
              .themeData(),
          home: Scaffold(
            bottomNavigationBar: const SizedBox(height: 64),
            body: _dashboard('layout_04'),
          )),
    ));
    await tester.pump();
    expect(find.text('Faturas').hitTestable(), findsOneWidget);
    expect(find.text('Suporte').hitTestable(), findsOneWidget);
    expect(find.text('Copiar Pix').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final entry in homeByLayout.entries) {
    testWidgets('${entry.key} opens its definitive dashboard', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          configurationProvider.overrideWith((_) => DemoConfig(entry.key)),
          authNotifierProvider.overrideWith(DemoAuth.new),
          financeiroViewModelProvider.overrideWith((_) => DemoFinance()),
          wifiManagementAvailableProvider.overrideWith((_) async => false),
        ],
        child: MaterialApp(
          theme: LayoutTokens.of(entry.key).themeData(),
          home: Scaffold(body: _dashboard(entry.key)),
        ),
      ));
      await tester.pump();
      expect(find.byType(entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
