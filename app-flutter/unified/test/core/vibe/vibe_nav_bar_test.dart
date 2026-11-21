import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/theme/layout_tokens.dart';
import 'package:app_provedor_unified/core/vibe/vibe_nav_bar.dart';

void main() {
  for (final layout in ['layout_02', 'layout_03', 'layout_04']) {
    testWidgets('$layout mantém as quatro abas utilizáveis com texto ampliado',
        (tester) async {
      tester.view.physicalSize = const Size(320, 650);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final scale in [1.0, 1.3, 2.0]) {
        var selected = -1;
        await tester.pumpWidget(MaterialApp(
          theme: LayoutTokens.of(layout).themeData(),
          home: MediaQuery(
            data: MediaQueryData(
                size: const Size(320, 650),
                textScaler: TextScaler.linear(scale)),
            child: Scaffold(
                bottomNavigationBar: VibeNavBar(
                    selectedIndex: 0, onSelected: (index) => selected = index)),
          ),
        ));
        final bar = tester.getRect(find.byType(VibeNavBar));
        for (final (index, label)
            in ['Início', 'Faturas', 'Conexão', 'Suporte'].indexed) {
          final text = find.text(label);
          expect(bar.contains(tester.getBottomLeft(text)), isTrue);
          await tester.tap(text);
          expect(selected, index);
        }
        expect(tester.takeException(), isNull);
      }
    });
  }
}
