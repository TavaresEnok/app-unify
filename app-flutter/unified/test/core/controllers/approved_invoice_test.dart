import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:app_provedor_unified/core/models/fatura.dart';
import 'package:app_provedor_unified/core/pages/shared_financeiro_page.dart';
import 'package:app_provedor_unified/core/providers/financeiro_provider.dart';
import 'package:app_provedor_unified/core/services/financeiro_service.dart';
import 'package:app_provedor_unified/core/pages/customer/customer_home_page.dart';
import 'package:app_provedor_unified/core/providers/connectivity_provider.dart';
import 'package:app_provedor_unified/core/providers/customer_capabilities_provider.dart';
import 'package:app_provedor_unified/core/providers/providers.dart';
import 'package:app_provedor_unified/core/theme/layout_tokens.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../tool/capture_preview.dart' show DemoAuth, DemoConfig;

class TestUrlLauncher extends UrlLauncherPlatform {
  String? opened;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    opened = url;
    return true;
  }
}

class InvoiceService extends FinanceiroService {
  InvoiceService()
      : super(
            apiUrl: 'https://example.test/get-invoices',
            cpfCnpjUnformatted: '1',
            providerId: 'p');

  @override
  Future<List<dynamic>> fetchInvoices() async => [
        {
          'id': 'a',
          'valor': 50.25,
          'vencimento': '2026-01-15',
          'status': 'pendente',
          'pix_copia_cola': 'PIX-A',
          'link': 'https://example.test/a'
        },
        {
          'id': 'b',
          'valor': 80.75,
          'vencimento': '2026-02-15',
          'status': 'pendente',
          'pix_copia_cola': 'PIX-B',
          'link': 'https://example.test/b'
        },
      ];
}

class SevenInvoiceService extends InvoiceService {
  @override
  Future<List<dynamic>> fetchInvoices() async => [
        for (var month = 1; month <= 7; month++)
          {
            'id': 'bill-$month',
            'valor': 69.90,
            'vencimento': '2027-0$month-06',
            'status': 'pendente',
            'pix_copia_cola': 'PIX-$month'
          }
      ];
}

class MixedInvoiceService extends InvoiceService {
  @override
  Future<List<dynamic>> fetchInvoices() async => [
        ...await super.fetchInvoices(),
        {'id': 'invalid', 'status': 'pendente', 'vencimento': '2026-03-15'},
      ];
}

class PaidAndIncompleteService extends MixedInvoiceService {
  @override
  Future<List<dynamic>> fetchInvoices() async => [
        ...await super.fetchInvoices(),
        {
          'id': 'paid',
          'status': 'pago',
          'vencimento': '2025-12-15',
          'valor': 42
        },
      ];
}

class ChangingInvoiceService extends InvoiceService {
  bool changed = false;
  @override
  Future<List<dynamic>> fetchInvoices() async {
    if (!changed) return super.fetchInvoices();
    return [
      {
        'id': 'a',
        'valor': 50.25,
        'vencimento': '2026-01-15',
        'status': 'pendente',
        'pix_copia_cola': 'PIX-NEW'
      },
      {
        'id': 'b',
        'valor': 80.75,
        'vencimento': '2026-02-15',
        'status': 'pendente',
        'pix_copia_cola': 'PIX-B'
      },
    ];
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  test('parser accepts both API payment field conventions', () {
    final invoice = Fatura.fromJson({
      'id': 10,
      'valor': '1.234,50',
      'vencimento': '20/11/2026',
      'pago': false,
      'linha_digitavel_pix': 'PIX',
      'link': 'https://example.test/boleto'
    });
    expect(invoice.valor, 1234.5);
    expect(invoice.pixCopiaECola, 'PIX');
    expect(invoice.isPago, false);
    expect(invoice.urlBoleto, 'https://example.test/boleto');
  });

  test('parser rejects missing amount, due date and status', () {
    final valid = <String, dynamic>{
      'valor': 90,
      'vencimento': '2026-11-20',
      'status': 'pendente'
    };
    for (final field in ['valor', 'vencimento', 'status']) {
      final incomplete = Map<String, dynamic>.from(valid)..remove(field);
      expect(() => Fatura.fromJson(incomplete), throwsFormatException);
    }
  });

  test('keeps valid invoices and flags incomplete records', () async {
    final provider = FinanceiroProvider(MixedInvoiceService());
    await provider.fetchHistory();
    expect(provider.state, FinanceiroState.success);
    expect(provider.invoices.length, 2);
    expect(provider.incompleteInvoices, 1);
    provider.dispose();
  });

  testWidgets('finance page displays paid tab and incomplete warning',
      (tester) async {
    final provider = FinanceiroProvider(PaidAndIncompleteService());
    await provider.fetchHistory();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        financeiroViewModelProvider.overrideWith((ref) => provider),
        authNotifierProvider.overrideWith(DemoAuth.new),
      ],
      child: const MaterialApp(home: Scaffold(body: FinanceiroPage())),
    ));
    expect(find.textContaining('dados incompletos'), findsOneWidget);
    expect(find.text('Em aberto (2)'), findsOneWidget);
    await tester.tap(find.text('Pagas'));
    await tester.pumpAndSettle();
    expect(find.textContaining('42,00'), findsOneWidget);
    expect(find.text('Paga'), findsOneWidget);
  });

  testWidgets('cada cartão do Início paga a própria fatura', (tester) async {
    final launcher = _useLauncher();
    final copied = _useClipboard();
    final provider = FinanceiroProvider(InvoiceService());
    await provider.fetchHistory();
    await _pumpHome(tester, 'layout_02', provider);
    expect(
        find.byWidgetPredicate(
            (w) => w is Text && w.semanticsLabel == 'R\$ 50,25'),
        findsOneWidget);
    await tester.tap(find.text('Copiar Pix'));
    await tester.pump();
    expect(copied(), 'PIX-A');
    await tester.tap(find.text('Ver boleto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir documento'));
    await tester.pumpAndSettle();
    expect(launcher.opened, 'https://example.test/a');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Copiar Pix de fevereiro'));
    await tester.pump();
    await tester.tap(find.text('Copiar Pix de fevereiro'));
    await tester.pump();
    expect(copied(), 'PIX-B');
    await tester.tap(find.text('Boleto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir documento'));
    await tester.pumpAndSettle();
    expect(launcher.opened, 'https://example.test/b');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dock: a fatura escolhida define valor, Pix e boleto',
      (tester) async {
    final launcher = _useLauncher();
    final copied = _useClipboard();
    final provider = FinanceiroProvider(InvoiceService());
    await provider.fetchHistory();
    await _pumpHome(tester, 'layout_03', provider);
    expect(find.text('2 faturas em aberto'), findsOneWidget);
    expect(find.text('Fatura de janeiro'), findsOneWidget);
    await tester.tap(find.text('Fevereiro'));
    await tester.pump();
    expect(find.text('Fatura de fevereiro'), findsOneWidget);
    await tester.tap(find.text('Copiar Pix'));
    await tester.pump();
    expect(copied(), 'PIX-B');
    await tester.tap(find.text('Ver boleto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir documento'));
    await tester.pumpAndSettle();
    expect(launcher.opened, 'https://example.test/b');
  });

  testWidgets('Dock: fatura escolhida que muda exige nova escolha',
      (tester) async {
    final copied = _useClipboard();
    final service = ChangingInvoiceService();
    final provider = FinanceiroProvider(service);
    await provider.fetchHistory();
    await _pumpHome(tester, 'layout_03', provider);
    expect(find.text('Copiar Pix'), findsOneWidget);
    service.changed = true;
    await provider.fetchHistory();
    await tester.pump();
    expect(find.textContaining('fatura selecionada mudou'), findsOneWidget);
    expect(find.text('Copiar Pix'), findsNothing);
    await tester.tap(find.text('Janeiro'));
    await tester.pump();
    await tester.tap(find.text('Copiar Pix'));
    await tester.pump();
    expect(copied(), 'PIX-NEW');
  });

  testWidgets('Dock: sete meses em aberto em tela estreita e texto ampliado',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final provider = FinanceiroProvider(SevenInvoiceService());
    await provider.fetchHistory();
    await _pumpHome(tester, 'layout_03', provider, scale: 1.5);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Julho'));
    await tester.pump();
    await tester.tap(find.text('Julho'));
    await tester.pump();
    expect(find.text('Fatura de julho'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

TestUrlLauncher _useLauncher() {
  final original = UrlLauncherPlatform.instance;
  final launcher = TestUrlLauncher();
  UrlLauncherPlatform.instance = launcher;
  addTearDown(() => UrlLauncherPlatform.instance = original);
  return launcher;
}

String? Function() _useClipboard() {
  String? copied;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      copied = (call.arguments as Map)['text'] as String?;
    }
    return null;
  });
  addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null));
  return () => copied;
}

Future<void> _pumpHome(
    WidgetTester tester, String layout, FinanceiroProvider provider,
    {double scale = 1}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      financeiroViewModelProvider.overrideWith((ref) => provider),
      configurationProvider.overrideWith((_) => DemoConfig(layout)),
      authNotifierProvider.overrideWith(DemoAuth.new),
      wifiManagementAvailableProvider.overrideWith((_) async => false),
      connectivityStatusProvider
          .overrideWith((_) => Stream.value(ConnectivityResult.wifi)),
    ],
    child: MaterialApp(
      theme: LayoutTokens.of(layout)
          .withPrimary(const Color(0xFF2456C9))
          .withBrightness(Brightness.light)
          .themeData(),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: Scaffold(
          body: CustomerHomePage(layoutType: layout, onNavigate: (_) {})),
    ),
  ));
  await tester.pump();
}
