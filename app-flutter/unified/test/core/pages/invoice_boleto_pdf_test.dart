import 'dart:convert';

import 'package:app_provedor_unified/core/models/fatura.dart';
import 'package:app_provedor_unified/core/pages/customer/invoice_document_page.dart';
import 'package:app_provedor_unified/core/pages/invoice_detail_page.dart';
import 'package:app_provedor_unified/core/providers/financeiro_provider.dart';
import 'package:app_provedor_unified/core/services/financeiro_service.dart';
import 'package:app_provedor_unified/core/services/session_token_store.dart';
import 'package:app_provedor_unified/core/vibe/vibe_invoice.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

String _jwt() {
  String part(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final exp =
      DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch ~/
          1000;
  return '${part({'alg': 'none'})}.${part({'sub': 'u', 'exp': exp})}.sig';
}

const _json = {'content-type': 'application/json; charset=utf-8'};
final _pdf = Uint8List.fromList(utf8.encode('%PDF-1.4\nboleto'));

/// Fatura IXC em aberto sem link, linha nem PIX (carteira Sicredi).
class _Service extends FinanceiroService {
  _Service()
      : super(
            apiUrl: 'https://api.example.test/get-invoices',
            cpfCnpjUnformatted: '12345678909',
            providerId: 'p',
            contratoId: 100);
  @override
  Future<List<dynamic>> fetchInvoices() async => [
        {
          'id': '564859',
          'valor': 99.9,
          'vencimento': '2099-01-15',
          'status': 'pendente',
        },
      ];
}

Future<FinanceiroProvider> _provider() async {
  final provider = FinanceiroProvider(_Service());
  await provider.fetchHistory();
  return provider;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Widget _host(FinanceiroProvider provider, Widget child) => ProviderScope(
      overrides: [financeiroViewModelProvider.overrideWith((ref) => provider)],
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  setUp(() => SessionTokenStore.instance.setTokenForTest(_jwt()));
  tearDown(() => SessionTokenStore.instance.setTokenForTest(null));

  test('downloadBoletoPdf pede o PDF com a sessão e trata indisponível',
      () async {
    final service = _Service();
    late http.Request seen;
    final bytes = await service.downloadBoletoPdf('564859',
        client: MockClient((request) async {
      seen = request;
      return http.Response.bytes(_pdf, 200,
          headers: {'content-type': 'application/pdf'});
    }));
    expect(bytes, _pdf);
    expect(seen.method, 'GET');
    expect(seen.url.toString(),
        'https://api.example.test/subscriber/invoices/564859/boleto?contratoId=100');
    expect(seen.headers['Authorization'], startsWith('Bearer '));

    await expectLater(
        service.downloadBoletoPdf('564859',
            client: MockClient((_) async => http.Response(
                jsonEncode({
                  'error': {
                    'code': 'boleto-unavailable',
                    'message': 'Boleto não disponível para esta fatura.'
                  }
                }),
                404,
                headers: _json))),
        throwsA(isA<BoletoUnavailableException>().having((e) => e.message,
            'message', 'Boleto não disponível para esta fatura.')));
    await expectLater(
        service.downloadBoletoPdf('564859',
            client: MockClient(
                (_) async => http.Response('<html>oops</html>', 200))),
        throwsA(predicate(
            (e) => e.toString() == FinanceiroService.boletoFailedMessage)));
  });

  testWidgets(
      'fatura sem link mostra "Abrir boleto (PDF)" e não o beco sem saída',
      (tester) async {
    final provider = await _provider();
    final invoice = provider.invoices.first;
    expect(VibeInvoiceView(invoice).canIssuePdf, isTrue);
    await tester
        .pumpWidget(_host(provider, InvoiceDetailPage(invoice: invoice)));
    await tester.pump();
    expect(find.text('Abrir boleto (PDF)'), findsOneWidget);
    expect(
        find.text(
            'Boleto disponível na central do assinante ou com o suporte.'),
        findsNothing);
    final paid = Fatura(
        numero: '1',
        valor: 10,
        vencimento: DateTime(2026, 1, 1),
        status: 'pago');
    expect(VibeInvoiceView(paid).canIssuePdf, isFalse);
  });

  testWidgets('baixa o PDF pela API, mostra e abre/salva o arquivo',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final provider = await _provider();
      final png = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/a0cAAAAASUVORK5CYII=');
      const channel = MethodChannel('br.com.ajust.app_provedor/invoice_pdf');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
          channel, (call) async => {'image': png, 'pages': 1});
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final shared = <String, Uint8List>{};
      final client = MockClient((request) async {
        expect(request.url.path, '/subscriber/invoices/564859/boleto');
        expect(request.headers['Authorization'], startsWith('Bearer '));
        return http.Response.bytes(_pdf, 200);
      });
      await tester.pumpWidget(_host(
          provider,
          InvoiceDocumentPage(
              invoice: provider.invoices.first,
              client: client,
              saveAndShare: (bytes, name) async => shared[name] = bytes)));
      expect(find.bySemanticsLabel(RegExp('Gerando o boleto')), findsWidgets);
      await _settle(tester);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Abrir documento'), findsNothing);
      await tester.tap(find.text('Abrir ou salvar PDF'));
      await tester.pump();
      await tester.pump();
      expect(shared.keys, ['boleto-564859.pdf']);
      expect(shared.values.single, _pdf);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('falha passageira mostra a mensagem e permite tentar de novo',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final provider = await _provider();
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return calls == 1
            ? http.Response('{"error":{"code":"boleto-failed"}}', 502)
            : http.Response(
                '{"error":{"code":"boleto-overdue","message":"O boleto desta fatura vencida não pode ser emitido pelo app. Use o PIX ou fale com o suporte."}}',
                404,
                headers: _json);
      });
      await tester.pumpWidget(_host(
          provider,
          InvoiceDocumentPage(
              invoice: provider.invoices.first, client: client)));
      await _settle(tester);
      expect(find.text(FinanceiroService.boletoFailedMessage), findsOneWidget);
      await tester.tap(find.text('Tentar de novo'));
      await _settle(tester);
      expect(calls, 2);
      expect(
          find.text(
              'O boleto desta fatura vencida não pode ser emitido pelo app. Use o PIX ou fale com o suporte.'),
          findsOneWidget);
      expect(find.text('Abrir ou salvar PDF'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
