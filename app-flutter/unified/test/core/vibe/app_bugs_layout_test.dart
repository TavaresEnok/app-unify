import 'dart:async';

import 'package:app_provedor_unified/core/models/provider_config.dart';
import 'package:app_provedor_unified/core/models/usuario.dart';
import 'package:app_provedor_unified/core/notifiers/auth_notifier.dart';
import 'package:app_provedor_unified/core/providers/configuration_provider.dart';
import 'package:app_provedor_unified/core/providers/providers.dart';
import 'package:app_provedor_unified/core/vibe/vibe_home_parts.dart';
import 'package:app_provedor_unified/core/vibe/vibe_nav_bar.dart';
import 'package:app_provedor_unified/core/vibe/vibe_page_parts.dart';
import 'package:app_provedor_unified/core/vibe/vibe_tokens.dart';
import 'package:app_provedor_unified/core/widgets/app_update.dart';
import 'package:app_provedor_unified/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Config extends ConfigurationProvider {
  _Config(Map<String, dynamic> json)
      : data = ProviderConfig.fromJson(
            {'name': 'Provedor', 'apiUrl': 'https://x.test/api', ...json}, 'x');
  final ProviderConfig data;
  @override
  ProviderConfig get providerConfig => data;
  @override
  bool get isLoading => false;
  @override
  Future<void> loadConfig(String id, {bool preferCache = false}) async {}
}

class _LoggedOut extends AuthNotifier {
  @override
  FutureOr<Usuario?> build() => null;
}

Widget _wrap(Widget child, {String layout = 'layout_02', double scale = 1}) {
  final tokens =
      VibeTokens.resolve(layout: layout, brand: const Color(0xff2456c9));
  return MaterialApp(
    theme: ThemeData(extensions: [tokens]),
    home: MediaQuery(
      data: MediaQueryData(
          size: const Size(320, 800), textScaler: TextScaler.linear(scale)),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  setUp(() =>
      SharedPreferences.setMockInitialValues({'onboarding_completed': true}));

  testWidgets('Dock: nome longo do provedor fica em uma linha', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(
        VibeDockMasthead(
            providerName: 'UP Connect Telecomunicações',
            subtitle: 'Maria · Fibra 600MB Residencial Plus WIFI6',
            initials: 'MO',
            network: VibeNetwork.wifi,
            onNetwork: () {},
            onAccount: () {}),
        layout: 'layout_03',
        scale: 1.3));
    expect(tester.takeException(), isNull);
    final height = tester.getSize(find.byType(VibeDockMasthead)).height;
    expect(height, lessThan(90), reason: 'antes: ~215 px');
  });

  testWidgets('barra de navegação e valor não quebram a 200%', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(
        Column(children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 100),
            child: VibeAmount(1234.56, size: 40, color: Colors.black),
          ),
          const Spacer(),
          VibeNavBar(selectedIndex: 0, onSelected: (_) {}),
        ]),
        scale: 2));
    expect(tester.takeException(), isNull);
    for (final label in ['Faturas', 'Conexão', 'Suporte']) {
      final p = tester.renderObject<RenderParagraph>(find.text(label));
      expect(p.didExceedMaxLines, isFalse, reason: label);
    }
    final amount = tester.renderObject<RenderParagraph>(find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('1.234')));
    expect(amount.didExceedMaxLines, isFalse);
    expect(amount.text.toPlainText(), contains(',56'));
  });

  testWidgets('versão abaixo da mínima mostra só "Atualize o app"',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        configurationProvider.overrideWith((_) => _Config({
              'appVersion': {
                'minVersion': '1.0.50',
                'latestVersion': '1.0.60',
                'storeUrl': 'https://play.google.com/store/apps/details?id=x'
              }
            })),
        authNotifierProvider.overrideWith(_LoggedOut.new),
        installedAppProvider
            .overrideWith((_) async => (version: '1.0.42', package: 'x')),
      ],
      child: const MaterialApp(home: AuthGate()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Atualize o app'), findsOneWidget);
    expect(find.text('Atualizar agora'), findsOneWidget);
  });

  testWidgets('versão atual não bloqueia; abaixo da mais recente só avisa',
      (tester) async {
    final container = ProviderContainer(overrides: [
      configurationProvider.overrideWith((_) => _Config({
            'appVersion': {'minVersion': '1.0.40', 'latestVersion': '1.0.60'}
          })),
      installedAppProvider
          .overrideWith((_) async => (version: '1.0.42', package: 'x')),
    ]);
    addTearDown(container.dispose);
    await container.read(installedAppProvider.future);
    expect(container.read(appUpdateNeedProvider), AppUpdateNeed.suggested);
  });
}
