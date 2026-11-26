import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/models/provider_config.dart';
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
  loginHeadlineConfigTests();
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

  testWidgets(
      'CPF com dígito verificador errado avisa uma vez e depois deixa tentar',
      (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      authNotifierProvider.overrideWith(TestAuth.new),
      layoutTokensProvider.overrideWithValue(LayoutTokens.of('layout_04')),
    ], child: const MaterialApp(home: UnifiedLoginPage())));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '52998224724');
    await tester.tap(find.text('Entrar').last);
    await tester.pump();
    expect(find.textContaining('CPF inválido'), findsOneWidget);
    expect(find.textContaining('toque em Entrar de novo'), findsOneWidget);

    // Mesmo número de novo: segue para o provedor (aqui, sem configuração).
    await tester.tap(find.text('Entrar').last);
    await tester.pump();
    expect(find.textContaining('CPF inválido'), findsNothing);
    expect(find.text('Erro de configuração. Tente novamente.'), findsOneWidget);

    // CPF incompleto nunca passa.
    await tester.enterText(find.byType(TextField), '5299822');
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();
    await tester.tap(find.text('Entrar').last);
    await tester.pump();
    expect(find.text('CPF incompleto. Confira os 11 números.'), findsOneWidget);
  });
}

// Frase da faixa de entrada configurável pelo painel (login.headline etc.).
void loginHeadlineConfigTests() {
  ConfigSection section(Map<String, dynamic> json) =>
      ConfigSection.fromJson(json, '');

  test('sem configuração: frase ligada e textos vazios (app usa o padrão)', () {
    final c = section({});
    expect(c.loginShowHeadline, isTrue);
    expect(c.loginHeadline, '');
    expect(c.loginSubheadline, '');
  });

  test('frase do painel é lida, aparada e limitada', () {
    final c = section({
      'login': {
        'headline': '  Conectando você  ',
        'subheadline': 'x' * 300,
        'showHeadline': true,
      }
    });
    expect(c.loginHeadline, 'Conectando você');
    expect(c.loginSubheadline.length, 120);
  });

  test('provedor pode desligar a frase', () {
    expect(
        section({
          'login': {'showHeadline': false}
        }).loginShowHeadline,
        isFalse);
  });
}
