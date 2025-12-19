import 'package:flutter/material.dart';
import '../../core/models/theme_config.dart';

/// Layout 10: Deep Purple Theme
/// Dark immersive theme with purple gradients and glowing accents
class Layout10Theme {
  // Default Colors (Deep Purple Palette)
  static const Color _defaultBackground = Color(0xFF0D0D1A); // Deep navy/purple
  static const Color _defaultSurface = Color(0xFF1A1A2E);
  static const Color _defaultSurfaceLight = Color(0xFF252547);
  static const Color _defaultPrimary = Color(0xFF8B5CF6); // Violet
  static const Color _defaultSecondary = Color(0xFF06B6D4); // Cyan
  static const Color defaultAccent = Color(0xFFF472B6); // Pink

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textHint = Color(0xFF6B7280);
  static const Color border = Color(0xFF374151);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);

  // Dynamic Color Getters
  static Color primary(ThemeConfig? config) {
    return config?.colors.primary ?? _defaultPrimary;
  }

  static Color secondary(ThemeConfig? config) {
    return config?.colors.secondary ?? _defaultSecondary;
  }

  static Color background(ThemeConfig? config) {
    return config?.colors.background ?? _defaultBackground;
  }

  static Color surface(ThemeConfig? config) {
    return config?.colors.surface ?? _defaultSurface;
  }

  // Gradients
  static LinearGradient primaryGradient(ThemeConfig? config) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary(config), secondary(config)],
      );

  static LinearGradient heroGradient(ThemeConfig? config) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primary(config).withValues(alpha: 0.8),
          primary(config).withValues(alpha: 0.4),
          background(config),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  static LinearGradient cardGradient(ThemeConfig? config) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          surface(config),
          _defaultSurfaceLight,
        ],
      );

  // Text Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -1,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: textSecondary,
  );

  // Gradient Border Card Decoration
  static BoxDecoration gradientBorderDecoration(ThemeConfig? config) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary(config).withValues(alpha: 0.5),
          secondary(config).withValues(alpha: 0.3),
        ],
      ),
    );
  }

  static BoxDecoration cardDecoration(ThemeConfig? config) => BoxDecoration(
        color: surface(config),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary(config).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration glowCardDecoration(ThemeConfig? config) => BoxDecoration(
        color: surface(config),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary(config).withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      );

  // ThemeData
  static ThemeData getTheme(ThemeConfig? config) {
    final primaryColor = primary(config);
    final secondaryColor = secondary(config);
    final bgColor = background(config);
    final surfaceColor = surface(config);
    final iconColor = config?.effects.iconColor ?? primaryColor;

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bgColor,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      iconTheme: IconThemeData(color: iconColor),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: iconColor),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      useMaterial3: true,
    );
  }
}
