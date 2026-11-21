import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_provedor_unified/core/pages/onboarding_page.dart';
import 'package:app_provedor_unified/core/providers/providers.dart';
import 'package:app_provedor_unified/core/theme/layout_tokens.dart';
import 'package:app_provedor_unified/core/widgets/content_state.dart';
import '../../../tool/capture_preview.dart';

void main() {
  for (final id in [
    'layout_02',
    'layout_03',
    'layout_04',
    'layout_05',
    'layout_06'
  ]) {
    test('global theme consumes already loaded $id configuration', () {
      final container = ProviderContainer(overrides: [
        configurationProvider.overrideWith((_) => DemoConfig(id)),
      ]);
      addTearDown(container.dispose);
      final theme = container.read(themeProvider);
      final t = LayoutTokens.of(id);
      expect(theme.config.colors.background, t.background);
      expect(theme.config.colors.textPrimary, t.textPrimary);
      expect(theme.themeMode, ThemeMode.light);
      expect(
          LayoutTokens.contrast(theme.lightTheme.colorScheme.onPrimary,
              theme.lightTheme.colorScheme.primary),
          greaterThanOrEqualTo(4.5));
    });

    testWidgets('$id onboarding supports large text on a small screen',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var completed = false;
      await tester.pumpWidget(MaterialApp(
          theme: LayoutTokens.of(id).themeData(),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!),
          home: OnboardingPage(onComplete: () => completed = true)));
      for (var i = 0; i < 3; i++) {
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Avançar'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Começar'));
      await tester.pumpAndSettle();
      expect(completed, isTrue);
    });
  }
  testWidgets('recoverable state retries and supports large text',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(MaterialApp(
        theme: LayoutTokens.of('layout_02').themeData(),
        home: Scaffold(
            body: ContentState(
                icon: Icons.wifi_off,
                title: 'Não conseguimos consultar sua rede',
                message: 'Tente consultar novamente.',
                actionLabel: 'Tentar de novo',
                onAction: () => retries++))));
    await tester.tap(find.text('Tentar de novo'));
    expect(retries, 1);
    expect(tester.takeException(), isNull);
  });
}
