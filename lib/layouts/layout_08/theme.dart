import 'package:flutter/material.dart';
import '../../core/models/theme_config.dart';

/// Layout 08: Eco-Minimal Theme
/// Light, clean theme with green/blue eco-friendly colors
class Layout08Theme {
  // Core Colors
  static const Color background = Color(0xFFF0F4F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFE8F0F8);
  static const Color _defaultPrimary = Color(0xFF4CAF50);
  static const Color _defaultSecondary = Color(0xFF2196F3);

  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF757575);
  static const Color border = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFF44336);
  static const Color success = Color(0xFF4CAF50);

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
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.light(
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
