import 'dart:async';
import 'dart:convert';

import 'package:app_provedor_unified/core/models/provider_config.dart';
import 'package:app_provedor_unified/core/pages/customer/customer_home_page.dart';
import 'package:app_provedor_unified/core/pages/shared_consumo_page.dart';
import 'package:app_provedor_unified/core/pages/shared_financeiro_page.dart';
import 'package:app_provedor_unified/core/providers/configuration_provider.dart';
import 'package:app_provedor_unified/core/providers/connectivity_provider.dart';
import 'package:app_provedor_unified/core/providers/consumo_provider.dart';
import 'package:app_provedor_unified/core/providers/customer_capabilities_provider.dart';
import 'package:app_provedor_unified/core/providers/financeiro_provider.dart';
import 'package:app_provedor_unified/core/providers/providers.dart';
import 'package:app_provedor_unified/core/services/financeiro_service.dart';
import 'package:app_provedor_unified/core/services/provider_config_api.dart';
import 'package:app_provedor_unified/core/theme/layout_tokens.dart';
import 'package:app_provedor_unified/core/vibe/vibe_page_parts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../tool/capture_preview.dart'
    show DemoAuth, DemoConfig, DemoNotifications;

class _StabilityConfig extends DemoConfig {
  _StabilityConfig(super.layout)
      : _override = ProviderConfig.fromJson(
          jsonDecode(jsonEncode({
            'name': 'Vibe Telecom',
            'apiUrl': 'https://example.invalid/api',
            'layoutType': layout,
            'themeColor': '#0891B2',
            'promotions': [
              {
                'id': 'p1',
                'title': 'Wi-Fi Turbo',
                'description': 'Mais velocidade em casa',
                'badge': 'Oferta',
                'active': true,
              }
            ],
            'menuConfig': <String, dynamic>{},
          })),
          'demo',
        );

  final ProviderConfig _override;

  @override
  ProviderConfig get providerConfig => _override;
}

class _DeferredFinanceService extends FinanceiroService {
  _DeferredFinanceService()
      : super(
            apiUrl: 'https://example.invalid/get-invoices',
            cpfCnpjUnformatted: '00000000000',
            providerId: 'demo',
            contratoId: 1);

  final completer = Completer<List<dynamic>>();

  @override
  Future<List<dynamic>> fetchInvoices() => completer.future;
}

class _TestConsumoViewModel extends ConsumoViewModel {
  _TestConsumoViewModel(ConsumoState initial) : super(null) {
    state = initial;
  }

  @override
  Future<void> loadData() async {}
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final homeAnchors = <String, String>{
    'layout_02': 'Faturas',
    'layout_03': 'Meus serviços',
    'layout_04': 'Faturas',
    'layout_05': 'Seus atalhos',
    'layout_06': 'Ver todos',
  };

  for (final entry in homeAnchors.entries) {
    testWidgets(
        '${entry.key}: cartão da fatura mantém altura durante o carregamento',
        (tester) async {
      // Ahem (fonte padrão de teste) tem largura ~1.8x maior que Plus Jakarta
      // Sans; 500 dp evita quebra artificial de linha em botões e Wrap.
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final service = _DeferredFinanceService();
      final finance = FinanceiroProvider(service);
      final pendingFetch = finance.fetchHistory();

      await tester.pumpWidget(ProviderScope(
        overrides: [
          configurationProvider.overrideWith((_) => _StabilityConfig(entry.key)),
          authNotifierProvider.overrideWith(DemoAuth.new),
          financeiroViewModelProvider.overrideWith((_) => finance),
          notificationProvider.overrideWith((_) => DemoNotifications()),
          wifiManagementAvailableProvider.overrideWith((_) async => false),
          connectivityStatusProvider
              .overrideWith((_) => Stream.value(ConnectivityResult.wifi)),
        ],
        child: MaterialApp(
          theme: LayoutTokens.of(entry.key).themeData(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Scaffold(
            body: CustomerHomePage(layoutType: entry.key, onNavigate: (_) {}),
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('Consultando suas faturas…'), findsOneWidget);
      final loadingAnchorY = tester.getTopLeft(find.text(entry.value).first).dy;

      final due = DateTime.now().add(const Duration(days: 5));
      service.completer.complete([
        {
          'numero': 'INV-101',
          'valor': 119.90,
          'vencimento': DateFormat('yyyy-MM-dd').format(due),
          'status': 'aberto',
          'pixCopiaECola': '000201010211',
          'urlBoleto': 'https://example.invalid/boleto.pdf',
        }
      ]);
      await pendingFetch;
      await tester.pump();

      expect(find.text('Consultando suas faturas…'), findsNothing);
      final loadedAnchorY = tester.getTopLeft(find.text(entry.value).first).dy;
      expect((loadedAnchorY - loadingAnchorY).abs(), lessThanOrEqualTo(8.0));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('ConsumoPage mantém dimensões do cartão principal ao carregar',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final today = DateTime.now();
    final vm = _TestConsumoViewModel(ConsumoState(
      selectedMonth: today.month,
      selectedYear: today.year,
      isLoading: true,
    ));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(DemoAuth.new),
        consumoViewModelProvider.overrideWith((_) => vm),
      ],
      child: MaterialApp(
        theme: LayoutTokens.of('layout_02').themeData(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const ConsumoPage(),
      ),
    ));
    await tester.pump();

    expect(find.text('Carregando consumo…'), findsOneWidget);
    final loadingHeight = tester.getSize(find.byType(VibeCard).first).height;

    vm.state = ConsumoState(
      selectedMonth: today.month,
      selectedYear: today.year,
      isLoading: false,
      data: {
        'usedGb': 142.0,
        'period': DateFormat('MM/yyyy').format(today),
        'details': [
          {'day': 1, 'gb': 10.0},
          {'day': 2, 'gb': 20.0},
        ],
      },
    );
    await tester.pump();

    final loadedHeight = tester.getSize(find.byType(VibeCard).first).height;
    expect((loadedHeight - loadingHeight).abs(), lessThanOrEqualTo(24.0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('FinanceiroPage renderiza skeleton no formato do cartão principal',
      (tester) async {
    final service = _DeferredFinanceService();
    final finance = FinanceiroProvider(service);
    unawaited(finance.fetchHistory());

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(DemoAuth.new),
        financeiroViewModelProvider.overrideWith((_) => finance),
      ],
      child: MaterialApp(
        theme: LayoutTokens.of('layout_02').themeData(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const FinanceiroPage(),
      ),
    ));
    await tester.pump();

    expect(find.text('Consultando suas faturas…'), findsOneWidget);
    expect(find.byType(VibeCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('ConfigurationProvider não volta isLoading=true ao atualizar em segundo plano',
      () async {
    var calls = 0;
    final provider = ConfigurationProvider(
      api: ProviderConfigApi(
        client: MockClient((_) async {
          calls++;
          return http.Response(
            jsonEncode({
              'data': {
                'id': 'vibe',
                'name': 'Vibe Telecom',
                'layoutType': 'layout_03',
                'themeColor': '#112233',
                'config': <String, dynamic>{},
              }
            }),
            200,
          );
        }),
      ),
      apiBaseUrl: 'https://appisp.com.br/api',
    );

    await provider.loadConfig('vibe');
    expect(provider.isLoading, isFalse);

    final observedLoadingDuringRefresh = <bool>[];
    provider.addListener(() => observedLoadingDuringRefresh.add(provider.isLoading));
    await provider.loadConfig('vibe');

    expect(calls, 2);
    expect(observedLoadingDuringRefresh, everyElement(isFalse));
  });

  test('FinanceiroService implementa igualdade por valor', () {
    final a = FinanceiroService(
      apiUrl: 'https://appisp.com.br/api/get-invoices',
      cpfCnpjUnformatted: '12345678900',
      providerId: 'vibe',
      contratoId: 42,
    );
    final b = FinanceiroService(
      apiUrl: 'https://appisp.com.br/api/get-invoices',
      cpfCnpjUnformatted: '12345678900',
      providerId: 'vibe',
      contratoId: 42,
    );
    final c = FinanceiroService(
      apiUrl: 'https://appisp.com.br/api/get-invoices',
      cpfCnpjUnformatted: '12345678900',
      providerId: 'vibe',
      contratoId: 99,
    );

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(c)));
  });
}
