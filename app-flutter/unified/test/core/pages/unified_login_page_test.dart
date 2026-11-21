import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/models/usuario.dart';
import 'package:app_provedor_unified/core/notifiers/auth_notifier.dart';
import 'package:app_provedor_unified/core/pages/unified_login_page.dart';
import 'package:app_provedor_unified/core/providers/providers.dart';
import 'package:app_provedor_unified/core/theme/layout_tokens.dart';

class TestAuth extends AuthNotifier {
  @override
  FutureOr<Usuario?> build() => null;
}

void main() {
  testWidgets('login has a single CPF/CNPJ field in dark mode', (tester) async {
    final tokens = LayoutTokens.of('layout_04');
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(TestAuth.new),
          layoutTokensProvider.overrideWithValue(tokens),
        ],
        child: MaterialApp(
            theme: ThemeData(
                inputDecorationTheme: const InputDecorationTheme(
                    filled: true, fillColor: Colors.white)),
            home: const UnifiedLoginPage())));
    await tester.pump();
    final fields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields, hasLength(1));
    expect(fields.first.decoration!.filled, isFalse);
    expect(find.text('Senha da central do assinante'), findsNothing);
    expect(find.byTooltip('Mostrar senha'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
