import 'package:flutter/material.dart';
import '../../core/models/theme_config.dart';

/// Layout 06: Cyberpunk / Neon Theme
/// Dark theme with vibrant neon cyan and pink accents
class Layout06Theme {
  // Core Colors
  static const Color background = Color(0xFF050A14);
  static const Color surface = Color(0xFF131B2C);
  static const Color surfaceLight = Color(0xFF1A2338);
  static const Color _defaultPrimary = Color(0xFF00F3FF);
  static const Color _defaultSecondary = Color(0xFFBC13FE);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8892A6);
  static const Color border = Color(0xFF2A3548);
  static const Color error = Color(0xFFFF4757);
  static const Color success = Color(0xFF00E676);

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
      fontFamily: 'Inter',
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
