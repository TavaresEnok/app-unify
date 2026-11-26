import 'package:app_provedor_unified/core/theme/layout_tokens.dart';
import 'package:app_provedor_unified/core/vibe/vibe_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(bool redacted, double scale, {bool animations = true}) =>
    MaterialApp(
      theme: LayoutTokens.of('layout_02').themeData(),
      home: MediaQuery(
        data: MediaQueryData(
            size: const Size(320, 640),
            disableAnimations: !animations,
            textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: VibeSkeletonScope(
            child: Column(children: [
              VibeRedact(
                redacted: redacted,
                child: const Text('R\$ 199,90',
                    key: Key('value'), style: TextStyle(fontSize: 40)),
              ),
              const Text('abaixo', key: Key('below')),
            ]),
          ),
        ),
      ),
    );

void main() {
  for (final scale in [1.0, 1.3, 1.6]) {
    testWidgets('mesma geometria coberto e revelado (escala $scale)',
        (tester) async {
      await tester.pumpWidget(_host(true, scale));
      await tester.pump(const Duration(milliseconds: 200));
      final size = tester.getSize(find.byType(VibeRedact));
      final below = tester.getTopLeft(find.byKey(const Key('below')));

      await tester.pumpWidget(_host(false, scale));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(VibeRedact)), size);
      expect(tester.getTopLeft(find.byKey(const Key('below'))), below);
    });
  }

  testWidgets('valor coberto não é lido nem tocado', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(true, 1, animations: false));
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('199')), findsNothing);
    await tester.pumpWidget(_host(false, 1, animations: false));
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('199')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('brilho para depois de 8 s e não deixa timers pendentes',
      (tester) async {
    await tester.pumpWidget(_host(true, 1));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(seconds: 9));
    // Sem animação rodando: pumpAndSettle termina.
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });
}
