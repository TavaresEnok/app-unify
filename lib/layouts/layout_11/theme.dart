import 'package:flutter/material.dart';
import '../../core/models/theme_config.dart';

/// Layout 11: Aurora Glass Theme
/// Dark glassmorphism theme with aurora purple/blue gradients
class Layout11Theme {
  // Core Colors
  static const Color background = Color(0xFF121220);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF252540);
  static const Color _defaultPrimary = Color(0xFF7B3FF2);
  static const Color _defaultSecondary = Color(0xFF3F7BF2);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA7B0C3);
  static const Color border = Color(0xFF3A3A5E);
  static const Color error = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF22C55E);

  static Color primary(ThemeConfig? config) =>
      config?.colors.primary ?? _defaultPrimary;

  static Color secondary(ThemeConfig? config) =>
      config?.colors.secondary ?? _defaultSecondary;

  static LinearGradient primaryGradient(ThemeConfig? config) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary(config), secondary(config)],
      );

  static LinearGradient auroraGradient(ThemeConfig? config) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary(config),
          secondary(config),
          const Color(0xFF06B6D4),
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
