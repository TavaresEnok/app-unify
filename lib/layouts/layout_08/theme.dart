import 'package:flutter/material.dart';
import '../../core/models/theme_config.dart';

/// Layout 08: Aurora Dark Theme
/// Premium dark theme with aurora borealis inspired gradients
/// Completely different from Layout 06 - uses deep navy with aurora accents
class Layout08Theme {
  // Core Colors - DARK AURORA THEME
  static const Color background = Color(0xFF0F172A); // Deep navy slate
  static const Color surface = Color(0xFF1E293B); // Slate-800
  static const Color surfaceLight = Color(0xFF334155); // Slate-700
  static const Color _defaultPrimary = Color(0xFF22D3EE); // Cyan-400 (Aurora)
  static const Color _defaultSecondary =
      Color(0xFFA78BFA); // Purple-400 (Aurora)

  // Aurora accent colors
  static const Color aurora1 = Color(0xFF06B6D4); // Cyan
  static const Color aurora2 = Color(0xFF8B5CF6); // Purple
  static const Color aurora3 = Color(0xFF10B981); // Emerald

  static const Color textPrimary = Color(0xFFF1F5F9); // Slate-100
  static const Color textSecondary = Color(0xFF94A3B8); // Slate-400
  static const Color textHint = Color(0xFF64748B); // Slate-500
  static const Color border = Color(0xFF334155); // Slate-700
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);

  // Dynamic Color Getters
  static Color primary(ThemeConfig? config) {
    return config?.colors.primary ?? _defaultPrimary;
  }

  static Color secondary(ThemeConfig? config) {
    return config?.colors.secondary ?? _defaultSecondary;
  }

  static Color backgroundDynamic(ThemeConfig? config) {
    return config?.colors.background ?? background;
  }

  static Color surfaceDynamic(ThemeConfig? config) {
    return config?.colors.surface ?? surface;
  }

  // Aurora Gradient - Multi-color flowing effect
  static LinearGradient auroraGradient(ThemeConfig? config) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary(config),
          aurora2,
          secondary(config),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  // Vertical aurora for backgrounds
  static LinearGradient auroraBackgroundGradient(ThemeConfig? config) =>
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primary(config).withValues(alpha: 0.15),
          background,
          background,
        ],
        stops: const [0.0, 0.4, 1.0],
      );

  // Text Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -1.0,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: textSecondary,
    height: 1.6,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: textSecondary,
    letterSpacing: 0.5,
  );

  // Glass Card with Aurora glow
  static BoxDecoration glassCardDecoration(ThemeConfig? config) =>
      BoxDecoration(
        color: surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primary(config).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primary(config).withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      );

  // Premium card with aurora border
  static BoxDecoration premiumCardDecoration(ThemeConfig? config) =>
      BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surface,
            surfaceLight.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primary(config).withValues(alpha: 0.15),
            blurRadius: 40,
            spreadRadius: -10,
            offset: const Offset(0, 20),
          ),
        ],
      );

  // ThemeData - DARK
  static ThemeData getTheme(ThemeConfig? config) {
    final primaryColor = primary(config);
    final secondaryColor = secondary(config);
    final bgColor = backgroundDynamic(config);
    final surfaceColor = surfaceDynamic(config);
    final iconColor = config?.effects.iconColor ?? primaryColor;

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bgColor,
      fontFamily: 'Outfit',
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: error,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
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
          fontWeight: FontWeight.w700,
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
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      useMaterial3: true,
    );
  }
}
