import 'package:flutter/material.dart';

/// Serviço para modo escuro automático baseado no horário
class AutoDarkModeService {
  /// Verifica se deve usar modo escuro baseado no horário
  /// Escuro: 18:00 - 06:00
  /// Claro: 06:00 - 18:00
  static bool shouldUseDarkMode() {
    final hour = DateTime.now().hour;
    // Modo escuro entre 18h e 6h
    return hour >= 18 || hour < 6;
  }

  /// Retorna o ThemeMode recomendado baseado no horário
  static ThemeMode getRecommendedThemeMode() {
    return shouldUseDarkMode() ? ThemeMode.dark : ThemeMode.light;
  }

  /// Retorna o ThemeMode baseado na preferência do usuário
  /// 'auto' = baseado no horário
  /// 'dark' = sempre escuro
  /// 'light' = sempre claro
  static ThemeMode getThemeModeFromPreference(String preference) {
    switch (preference) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'auto':
      default:
        return getRecommendedThemeMode();
    }
  }

  /// Descrição legível do modo atual
  static String getModeDescription(String preference) {
    switch (preference) {
      case 'dark':
        return 'Sempre escuro';
      case 'light':
        return 'Sempre claro';
      case 'auto':
      default:
        final isDark = shouldUseDarkMode();
        return 'Automático (${isDark ? "escuro" : "claro"} agora)';
    }
  }

  /// Ícone para o modo atual
  static IconData getModeIcon(String preference) {
    switch (preference) {
      case 'dark':
        return Icons.dark_mode_rounded;
      case 'light':
        return Icons.light_mode_rounded;
      case 'auto':
      default:
        return Icons.brightness_auto_rounded;
    }
  }

  /// Debug: mostra info do horário
  static void logDebugInfo() {
    final hour = DateTime.now().hour;
    final isDark = shouldUseDarkMode();
    // ignore: avoid_print
    print('[AutoDarkMode] Hora: $hour, Modo escuro: $isDark');
  }
}
