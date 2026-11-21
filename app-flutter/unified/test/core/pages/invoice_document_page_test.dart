import 'dart:async';
import 'dart:convert';

import 'package:app_provedor_unified/core/pages/customer/invoice_document_page.dart';
import 'package:app_provedor_unified/core/providers/financeiro_provider.dart';
import 'package:app_provedor_unified/core/services/financeiro_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

class _Service extends FinanceiroService {
  _Service()
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
          'link': 'https://example.test/a',
          'linha_digitavel': 'LINHA-A'
        },
      ];
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('renders PDF locally with no subscriber authorization',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final provider = FinanceiroProvider(_Service());
      await provider.fetchHistory();
      final png = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/a0cAAAAASUVORK5CYII=');
      const channel = MethodChannel('br.com.ajust.app_provedor/invoice_pdf');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var rendered = false;
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'render');
        expect(call.arguments['bytes'], isA<Uint8List>());
        rendered = true;
        return {'image': png, 'pages': 1};
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final client = MockClient((request) async {
        expect(request.headers.containsKey('authorization'), isFalse);
        return http.Response.bytes(utf8.encode('%PDF-1.4\nfixture'), 200,
            headers: {'content-type': 'application/pdf'});
      });
      await tester.pumpWidget(ProviderScope(
        overrides: [
          financeiroViewModelProvider.overrideWith((ref) => provider)
        ],
        child: MaterialApp(
            home: Scaffold(
                body: InvoiceDocumentPage(
                    invoice: provider.invoices.first, client: client))),
      ));
      await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(rendered, isTrue);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Copiar linha'), findsOneWidget);
      expect(find.text('Abrir documento'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('HTML response gives browser fallback without rendering',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final provider = FinanceiroProvider(_Service());
      await provider.fetchHistory();
      final client = MockClient(
          (request) async => http.Response('<html>Login</html>', 200));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          financeiroViewModelProvider.overrideWith((ref) => provider)
        ],
        child: MaterialApp(
            home: Scaffold(
                body: InvoiceDocumentPage(
                    invoice: provider.invoices.first, client: client))),
      ));
      await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Visualização indisponível'), findsOneWidget);
      expect(find.text('Abrir documento'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets('does not start native rendering after leaving the page',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final provider = FinanceiroProvider(_Service());
      await provider.fetchHistory();
      final response = Completer<http.Response>();
      final client = MockClient((request) => response.future);
      var rendered = false;
      const channel = MethodChannel('br.com.ajust.app_provedor/invoice_pdf');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        rendered = true;
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          financeiroViewModelProvider.overrideWith((ref) => provider)
        ],
        child: MaterialApp(
            home: Scaffold(
                body: InvoiceDocumentPage(
                    invoice: provider.invoices.first, client: client))),
      ));
      await tester.pumpWidget(const SizedBox.shrink());
      response
          .complete(http.Response.bytes(utf8.encode('%PDF-1.4\nfixture'), 200));
      await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      expect(rendered, isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
