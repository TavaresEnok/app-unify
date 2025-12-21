import 'package:flutter/material.dart';
import '../../core/models/theme_config.dart';

/// Layout 01: Classic Theme
/// Professional dark theme with purple accents
class Layout01Theme {
  // Core Colors
  static const Color background = Color(0xFF1A202C);
  static const Color surface = Color(0xFF2D3748);
  static const Color surfaceLight = Color(0xFF4A5568);
  static const Color _defaultPrimary = Color(0xFF6B46C1);
  static const Color _defaultSecondary = Color(0xFF9F7AEA);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0AEC0);
  static const Color border = Color(0xFF4A5568);
  static const Color error = Color(0xFFFC8181);
  static const Color success = Color(0xFF68D391);

  static Color primary(ThemeConfig? config) =>
      config?.colors.primary ?? _defaultPrimary;

  static Color secondary(ThemeConfig? config) =>
      config?.colors.secondary ?? _defaultSecondary;

  static LinearGradient primaryGradient(ThemeConfig? config) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary(config), secondary(config)],
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
