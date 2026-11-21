import 'package:app_provedor_unified/core/models/fatura.dart';
import 'package:app_provedor_unified/core/pages/customer/homes/vibe_home_blocks.dart';
import 'package:app_provedor_unified/core/vibe/vibe_home_parts.dart';
import 'package:app_provedor_unified/core/vibe/vibe_invoice.dart';
import 'package:app_provedor_unified/core/vibe/vibe_page_parts.dart';
import 'package:app_provedor_unified/core/vibe/vibe_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  testWidgets('nome integral do Pix e rede em tela estreita com fonte ampliada',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final view = VibeInvoiceView(Fatura(
        numero: '1',
        valor: 100,
        vencimento: DateTime(2027, 9, 20),
        status: 'pendente',
        pixCopiaECola: 'pix-1',
        urlBoleto: 'https://example.com/1'));
    final tokens =
        VibeTokens.resolve(layout: 'layout_03', brand: const Color(0xff2456c9));
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: [tokens]),
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(320, 800), textScaler: TextScaler.linear(1.3)),
            child: Scaffold(
                body: Column(children: [
              VibeDockMasthead(
                  providerName: 'Provedor',
                  subtitle: 'Cliente',
                  initials: 'CL',
                  network: VibeNetwork.wifi,
                  onNetwork: () {},
                  onAccount: () {}),
              Padding(
                  padding: const EdgeInsets.all(20),
                  child: VibeNextInvoiceCard(view: view)),
              VibeConnectionPill(network: VibeNetwork.wifi, onTap: () {}),
            ])))));
    final pix = find.text('Copiar Pix de setembro');
    expect(pix, findsOneWidget);
    expect(
        tester.renderObject<RenderParagraph>(pix).didExceedMaxLines, isFalse);
    expect(find.text('Wi‑Fi'), findsOneWidget);
    expect(tester.renderObject<RenderParagraph>(find.text('Wi‑Fi')).didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });
}
