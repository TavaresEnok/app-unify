import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/models/usuario.dart';
import 'package:app_provedor_unified/core/notifiers/auth_notifier.dart';
import 'package:app_provedor_unified/core/pages/shared_ping_page.dart';
import 'package:app_provedor_unified/core/providers/providers.dart';

class NoSession extends AuthNotifier {
  @override
  FutureOr<Usuario?> build() => null;
}

void main() {
  testWidgets(
      'destinos rápidos preenchem o campo e a tela cabe com texto ampliado',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [authNotifierProvider.overrideWith(NoSession.new)],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: const Scaffold(body: SharedPingPage()),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cloudflare'));
    await tester.tap(find.text('Cloudflare'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '1.1.1.1');
    expect(tester.takeException(), isNull);
  });
}
