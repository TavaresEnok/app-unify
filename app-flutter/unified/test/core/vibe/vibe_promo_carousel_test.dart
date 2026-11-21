import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/vibe/vibe_home_parts.dart';

void main() {
  testWidgets('ofertas funcionam em tela estreita com texto ampliado',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final opened = <String>[];
    final promos = [
      VibePromo(
          kicker: 'Oferta especial',
          title: 'Oferta de internet para sua casa',
          text: 'Condições disponíveis com seu provedor',
          onTap: () => opened.add('1')),
      VibePromo(title: 'Outra oferta', onTap: () => opened.add('2')),
    ];
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
          data: const MediaQueryData(
              size: Size(320, 800), textScaler: TextScaler.linear(2)),
          child: Scaffold(
              body: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: VibePromoCarousel(promos: promos)))),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('1 de 2'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Próximo'));
    await tester.pumpAndSettle();
    expect(find.text('2 de 2'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('^Outra oferta')));
    expect(opened, ['2']);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });
}
