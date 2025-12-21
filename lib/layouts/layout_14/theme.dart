import 'package:flutter/material.dart';
import '../../core/models/theme_config.dart';

/// Layout 14: Cyberpunk Neon Theme
/// Ultra-dark theme with vibrant neon cyan/magenta accents
class Layout14Theme {
  // Core Colors
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF050508);
  static const Color surfaceLight = Color(0xFF15151F);
  static const Color _defaultPrimary = Color(0xFF00FFFF);
  static const Color _defaultSecondary = Color(0xFFFF00FF);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color border = Color(0xFF2A2A3E);
  static const Color error = Color(0xFFFF4444);
  static const Color success = Color(0xFF00FF00);

  static Color primary(ThemeConfig? config) =>
      config?.colors.primary ?? _defaultPrimary;

  static Color secondary(ThemeConfig? config) =>
      config?.colors.secondary ?? _defaultSecondary;

  static LinearGradient primaryGradient(ThemeConfig? config) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary(config), secondary(config)],
      );

  static LinearGradient neonGradient(ThemeConfig? config) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          primary(config),
          secondary(config),
        ],
      );

  static ThemeData getTheme(ThemeConfig? config) {
    final primaryColor = primary(config);
    final secondaryColor = secondary(config);
    final iconColor = config?.effects.iconColor ?? primaryColor;

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: background,
      fontFamily: 'JetBrains Mono',
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surface,
        error: error,
      ),
      iconTheme: IconThemeData(color: iconColor),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: iconColor),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      useMaterial3: true,
    );
  }
}
