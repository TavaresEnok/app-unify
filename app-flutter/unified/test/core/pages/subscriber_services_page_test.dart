import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_provedor_unified/core/models/provider_config.dart';
import 'package:app_provedor_unified/core/pages/customer/subscriber_services_page.dart';
import 'package:app_provedor_unified/core/pages/customer/connection_hub_page.dart';
import 'package:app_provedor_unified/core/pages/customer/customer_support_page.dart';
import 'package:app_provedor_unified/core/pages/customer/customer_account_page.dart';
import 'package:app_provedor_unified/core/pages/shared_faq_page.dart';
import 'package:app_provedor_unified/core/pages/shared_contrato_page.dart';
import 'package:app_provedor_unified/core/painel_page.dart';
import 'package:app_provedor_unified/core/providers/configuration_provider.dart';
import 'package:app_provedor_unified/core/providers/connectivity_provider.dart';
import 'package:app_provedor_unified/core/providers/customer_capabilities_provider.dart';
import 'package:app_provedor_unified/core/providers/financeiro_provider.dart';
import 'package:app_provedor_unified/core/providers/providers.dart';
import '../../../tool/capture_preview.dart';

class TestConfig extends ConfigurationProvider {
  TestConfig(
      {bool invoices = true,
      bool wifiEnabled = true,
      List<Map<String, dynamic>> promotions = const []})
      : data = ProviderConfig.fromJson({
          'name': 'Provedor de teste',
          'apiUrl': 'https://example.invalid/api',
          'layoutType': 'layout_02',
          'features': {'invoices': invoices},
          'menuConfig': {
            'items': {
              'wifi': {'enabled': wifiEnabled}
            }
          },
          'promotions': {'enabled': true, 'items': promotions},
        }, 'test');

  final ProviderConfig data;
  @override
  ProviderConfig get providerConfig => data;
  @override
  bool get isLoading => false;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR');
  });

  Future<void> showCatalogue(WidgetTester tester,
      {bool wifiEnabled = true,
      bool wifiAvailable = false,
      bool invoices = true,
      List<Map<String, dynamic>> promotions = const [],
      ValueChanged<String>? onNavigate}) async {
    await tester.pumpWidget(ProviderScope(
        overrides: [
          configurationProvider.overrideWith((_) => TestConfig(
              invoices: invoices,
              wifiEnabled: wifiEnabled,
              promotions: promotions)),
          authNotifierProvider.overrideWith(DemoAuth.new),
          financeiroViewModelProvider.overrideWith((_) => DemoFinance()),
          wifiManagementAvailableProvider
              .overrideWith((_) async => wifiAvailable),
        ],
        child: MaterialApp(
            home: Scaffold(
                body: SubscriberServicesPage(
                    onNavigate: onNavigate ?? (_) {})))));
    await tester.pumpAndSettle();
  }

  testWidgets('ordem e destinos das sete ações principais', (tester) async {
    final routes = <String>[];
    await showCatalogue(tester, onNavigate: routes.add);
    final labels = tester
        .widgetList<Text>(find.descendant(
            of: find.byType(SubscriberServicesPage),
            matching: find.byType(Text)))
        .map((widget) => widget.data)
        .toList();
    // Os dois primeiros textos são o título e o subtítulo do cabeçalho.
    expect(
        labels.take(2), ['Todos os serviços', 'Do mais usado ao menos usado']);
    expect(labels.skip(2).take(7), [
      'Faturas',
      'Suporte',
      'Consumo',
      'Velocidade',
      'Meu IP',
      'Diagnóstico',
      'Tracert'
    ]);
    for (final label in [
      'Faturas',
      'Suporte',
      'Consumo',
      'Velocidade',
      'Meu IP',
      'Diagnóstico',
      'Tracert'
    ]) {
      await tester.ensureVisible(find.text(label));
      await tester.pump();
      await tester.tap(find.text(label));
    }
    expect(routes, [
      'invoices',
      'support',
      'internet_usage',
      'speed_test',
      'my_ip',
      'network_diagnostic',
      'trace_route'
    ]);
  });

  for (final (flag, available) in [
    (true, true),
    (true, false),
    (false, true),
    (false, false)
  ]) {
    testWidgets('Wi-Fi respeita flag $flag e disponibilidade $available',
        (tester) async {
      await showCatalogue(tester, wifiEnabled: flag, wifiAvailable: available);
      expect(find.text('Meu Wi-Fi'),
          flag && available ? findsOneWidget : findsNothing);
    });
  }

  testWidgets('Faturas desabilitadas ocultam seus atalhos relacionados',
      (tester) async {
    await showCatalogue(tester, invoices: false);
    for (final label in [
      'Faturas',
      'Pagar fatura',
      'Documento da fatura',
      'Liberar internet'
    ]) {
      expect(find.text(label), findsNothing);
    }
  });

  testWidgets('Ofertas exigem promoção ativa e utilizam rota de ofertas',
      (tester) async {
    final routes = <String>[];
    await showCatalogue(tester,
        promotions: [
          {'id': '1', 'title': 'Oferta real', 'active': true},
        ],
        onNavigate: routes.add);
    expect(find.text('Ofertas'), findsOneWidget);
    await tester.ensureVisible(find.text('Ofertas'));
    await tester.pump();
    await tester.tap(find.text('Ofertas'));
    expect(routes, ['promotions']);
    await tester.pumpWidget(const SizedBox());
    await showCatalogue(tester, promotions: [
      {'id': '2', 'title': 'Oferta vencida', 'endDate': '2000-01-01'},
      {'id': '3', 'title': 'Oferta inativa', 'active': false},
    ]);
    expect(find.text('Ofertas'), findsNothing);
  });

  testWidgets('catálogo se adapta a 320 dp com texto ampliado', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 720);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          configurationProvider.overrideWith((_) => TestConfig()),
          authNotifierProvider.overrideWith(DemoAuth.new),
          financeiroViewModelProvider.overrideWith((_) => DemoFinance()),
          wifiManagementAvailableProvider.overrideWith((_) async => true),
        ],
        child: MaterialApp(
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.8)),
                child: child!),
            home: const Scaffold(
                body: SubscriberServicesPage(onNavigate: _ignore)))));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Meu Wi-Fi'), findsOneWidget);
  });

  testWidgets('telas compartilhadas cabem em 320 dp com texto ampliado',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 720);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pages = <Widget>[
      const ConnectionHubPage(onNavigate: _ignore),
      const CustomerSupportPage(onNavigate: _ignore),
      const CustomerAccountPage(onNavigate: _ignore),
      const FaqPage(onNavigate: _ignore),
      const ContratoPage(onNavigate: _ignore),
    ];
    for (final page in pages) {
      await tester.pumpWidget(ProviderScope(
          overrides: [
            configurationProvider.overrideWith((_) => TestConfig()),
            authNotifierProvider.overrideWith(DemoAuth.new),
            wifiManagementAvailableProvider.overrideWith((_) async => true),
          ],
          child: MaterialApp(
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.8)),
                  child: child!),
              home: Scaffold(body: page))));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: page.runtimeType.toString());
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('Ver todos na home abre o catálogo pelo shell', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      configurationProvider.overrideWith((_) => TestConfig()),
      authNotifierProvider.overrideWith(DemoAuth.new),
      financeiroViewModelProvider.overrideWith((_) => DemoFinance()),
      wifiManagementAvailableProvider.overrideWith((_) async => false),
      connectivityStatusProvider
          .overrideWith((_) => Stream.value(ConnectivityResult.wifi)),
    ], child: const MaterialApp(home: PainelPage(refreshOnOpen: false))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ver todos'));
    await tester.tap(find.text('Ver todos'));
    await tester.pumpAndSettle();
    expect(find.text('Todos os serviços'), findsOneWidget);
    expect(find.byType(SubscriberServicesPage), findsOneWidget);
  });
}

void _ignore(String route) {}
