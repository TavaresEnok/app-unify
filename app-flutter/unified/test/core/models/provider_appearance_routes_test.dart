import 'package:app_provedor_unified/core/models/provider_config.dart';
import 'package:app_provedor_unified/core/models/provider_config_normalizer.dart';
import 'package:app_provedor_unified/core/navigation/customer_routes.dart';
import 'package:app_provedor_unified/core/providers/configuration_provider.dart';
import 'package:app_provedor_unified/core/providers/providers.dart';
import 'package:app_provedor_unified/core/widgets/customer_ui.dart';
import 'package:app_provedor_unified/core/theme/layout_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestConfiguration extends ConfigurationProvider {
  TestConfiguration(this.value);
  final ProviderConfig value;
  @override
  ProviderConfig get providerConfig => value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('active preset takes precedence over legacy theme in both modes',
      () async {
    for (final layout in [
      'layout_02',
      'layout_03',
      'layout_04',
      'layout_05',
      'layout_06'
    ]) {
      for (final entry in const {
        '#FC46AA': Color(0xFFFC46AA),
        '#2456C9': Color(0xFF2456C9),
        '#137650': Color(0xFF137650),
        '#123456': Color(0xFF123456),
      }.entries) {
        SharedPreferences.setMockInitialValues({});
        final config = ProviderConfigNormalizer.fromFirestore({
          'layoutType': layout,
          'themeColor': entry.key,
          'theme': {
            'colors': {'primary': '#998877'}
          },
        }, 'test');
        final container = ProviderContainer(overrides: [
          configurationProvider.overrideWith((_) => TestConfiguration(config)),
        ]);
        expect(container.read(layoutTokensProvider).primary, entry.value);
        await container.read(themeProvider).setThemeMode(ThemeMode.dark);
        expect(container.read(layoutTokensProvider).primary, entry.value);
        expect(container.read(layoutTokensProvider).isDark, isTrue);
        await container.read(themeProvider).setThemeMode(ThemeMode.light);
        expect(container.read(layoutTokensProvider).primary, entry.value);
        expect(container.read(layoutTokensProvider).isDark, isFalse);
        container.dispose();
      }
    }
  });

  test('legacy nested theme supplies a color when no active color exists', () {
    final config = ProviderConfigNormalizer.fromFirestore({
      'theme': {
        'colors': {'primary': '#137650'}
      },
    }, 'test');
    expect(config.config.themeColor, '#137650');
  });

  test('invoice and trust routes respect both feature and menu settings', () {
    for (final data in [
      {
        'features': {'invoices': false}
      },
      {
        'config': {
          'features': {'invoices': false}
        }
      },
      {
        'menuConfig': {
          'items': {
            'invoices': {'enabled': false}
          }
        }
      },
    ]) {
      final config = ProviderConfigNormalizer.fromFirestore(data, 'test');
      expect(CustomerRoutes.enabled(config, 'invoices'), isFalse);
      expect(CustomerRoutes.enabled(config, 'faturas'), isFalse);
      expect(CustomerRoutes.enabled(config, 'trust_unlock'), isFalse);
    }
    final defaultConfig = ProviderConfigNormalizer.fromFirestore({}, 'test');
    expect(defaultConfig.features.invoices, isTrue);
    expect(CustomerRoutes.enabled(defaultConfig, 'trust_unlock'), isTrue);
  });
  test('legacy menu identifiers disable the equivalent destinations', () {
    for (final entry in const {
      'financial': 'invoices',
      'payment_promise': 'trust_unlock',
      'diagnostics': 'network_diagnostic',
      'speedtest': 'speed_test',
      'speedTest': 'speed_test',
      'consumption': 'internet_usage',
    }.entries) {
      final config = ProviderConfigNormalizer.fromFirestore({
        'menuConfig': {
          'items': {
            entry.key: {'enabled': false}
          }
        },
      }, 'test');
      expect(CustomerRoutes.enabled(config, entry.value), isFalse,
          reason: entry.key);
    }
  });
  testWidgets('configured card color is rendered in its matching mode',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final config = ProviderConfigNormalizer.fromFirestore({
      'layoutType': 'layout_02',
      'backgroundColor': '#F0EAE2',
      'cardColor': '#EADDCF',
      'textColor': '#25190E',
    }, 'test');
    final container = ProviderContainer(overrides: [
      configurationProvider.overrideWith((_) => TestConfiguration(config)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: Consumer(
          builder: (context, ref, _) => MaterialApp(
                theme: ref.watch(layoutTokensProvider).themeData(),
                home: const Scaffold(body: CustomerCard(child: Text('Cartão'))),
              )),
    ));
    await tester.pumpAndSettle();
    final card = tester.widget<Container>(find
        .descendant(
          of: find.byType(CustomerCard),
          matching: find.byType(Container),
        )
        .first);
    expect((card.decoration! as BoxDecoration).color, const Color(0xFFEADDCF));
    expect(container.read(layoutTokensProvider).background,
        const Color(0xFFF0EAE2));
    await container.read(themeProvider).setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    final dark = container.read(layoutTokensProvider);
    expect(dark.background, isNot(const Color(0xFFF0EAE2)));
    expect(dark.card, isNot(const Color(0xFFEADDCF)));
    expect(LayoutTokens.contrast(dark.textPrimary, dark.card),
        greaterThanOrEqualTo(4.5));
  });
}
