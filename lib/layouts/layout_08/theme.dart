import 'package:flutter/material.dart';
import '../../core/models/theme_config.dart';

/// Layout 08: Neubrutalism Theme
/// Bold, high contrast, thick borders, and hard shadows.
class Layout08Theme {
  // Core Colors (Defaults)
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Vibrant Neubrutalist Defaults
  static const Color _defaultPrimary = Color(0xFFF4D03F); // Yellow
  static const Color _defaultSecondary = Color(0xFFFF007F); // Pink
  static const Color _defaultError = Color(0xFFFF4B4B); // Red

  static const double borderWidth = 3.0;
  static const double shadowOffset = 4.0;

  // Dynamic Color Getters
  static Color primary(ThemeConfig? config) =>
      config?.colors.primary ?? _defaultPrimary;
  static Color secondary(ThemeConfig? config) =>
      config?.colors.secondary ?? _defaultSecondary;
  static Color surfaceColor(ThemeConfig? config) =>
      config?.colors.surface ?? surface;
  static Color backgroundColor(ThemeConfig? config) =>
      config?.colors.background ?? background;

  // Box Decorations
  static BoxDecoration neubrutalismDecoration({
    required Color color,
    double bWidth = borderWidth,
    double sOffset = shadowOffset,
    BorderRadius? borderRadius,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.zero,
        border: Border.all(color: black, width: bWidth),
        boxShadow: [
          BoxShadow(
            color: black,
            blurRadius: 0,
            offset: Offset(sOffset, sOffset),
          ),
        ],
      );

  // ThemeData
  static ThemeData getTheme(ThemeConfig? config) {
    final primaryColor = primary(config);
    final secondaryColor = secondary(config);
    final bgColor = backgroundColor(config);

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bgColor,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surface,
        error: _defaultError,
        onPrimary: black,
        onSecondary: Colors.white,
        onSurface: black,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: black,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        iconTheme: const IconThemeData(color: black),
        shape: const Border(
          bottom: BorderSide(color: black, width: borderWidth),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: black, width: borderWidth),
          borderRadius: BorderRadius.circular(0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: black,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: black, width: borderWidth),
            borderRadius: BorderRadius.circular(0),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: black, width: borderWidth),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: black, width: borderWidth),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: black, width: borderWidth + 1),
        ),
        labelStyle: const TextStyle(color: black, fontWeight: FontWeight.bold),
        hintStyle: TextStyle(color: black.withValues(alpha: 0.5)),
      ),
      useMaterial3: true,
    );
  }
}
