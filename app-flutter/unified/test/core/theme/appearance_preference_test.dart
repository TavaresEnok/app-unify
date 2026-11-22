import 'package:app_provedor_unified/core/models/theme_config.dart';
import 'package:app_provedor_unified/core/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a escolha de aparência persiste e não muda ao atualizar o provedor',
      () async {
    SharedPreferences.setMockInitialValues({});
    final theme = DynamicThemeProvider();
    await theme.setThemeMode(ThemeMode.dark);
    theme.updateFromConfig(ThemeConfig.defaultTheme, layoutType: 'layout_02');
    expect(theme.themeMode, ThemeMode.dark);
    expect(theme.darkTheme.brightness, Brightness.dark);
    expect(theme.lightTheme.brightness, Brightness.light);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), ThemeMode.dark.toString());
    theme.dispose();

    final restored = DynamicThemeProvider();
    await Future<void>.delayed(Duration.zero);
    expect(restored.themeMode, ThemeMode.dark);
    restored.dispose();
  });

  test('o modo automático segue o celular e volta salvo', () async {
    SharedPreferences.setMockInitialValues({});
    final binding = TestWidgetsFlutterBinding.instance;
    final theme = DynamicThemeProvider();
    expect(theme.themeMode, ThemeMode.light);
    expect(theme.brightness, Brightness.light);

    await theme.setThemeMode(ThemeMode.system);
    var notified = 0;
    theme.addListener(() => notified++);
    binding.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    expect(theme.brightness, Brightness.dark);
    expect(notified, greaterThan(0));
    binding.platformDispatcher.clearPlatformBrightnessTestValue();
    expect(theme.brightness, Brightness.light);
    theme.dispose();

    final restored = DynamicThemeProvider();
    await Future<void>.delayed(Duration.zero);
    expect(restored.themeMode, ThemeMode.system);
    restored.dispose();
  });
}
