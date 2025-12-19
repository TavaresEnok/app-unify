import 'package:flutter/material.dart';
import '../../core/models/theme_config.dart';

/// Layout 09: Organic / Biomorphic Theme
/// Fluid shapes, soft colors, and rounded corners (blobs).
class Layout09Theme {
  // Core Colors (Defaults)
  static const Color background = Color(0xFFF0F4F8);
  static const Color surface = Color(0xFFFFFFFF);

  // Natural Defaults
  static const Color _defaultPrimary = Color(0xFF1A5276); // Ocean Blue
  static const Color _defaultSecondary = Color(0xFF1D8348); // forest Green
  static const Color _defaultError = Color(0xFFE74C3C);

  // Dynamic Color Getters
  static Color primary(ThemeConfig? config) =>
      config?.colors.primary ?? _defaultPrimary;
  static Color secondary(ThemeConfig? config) =>
      config?.colors.secondary ?? _defaultSecondary;
  static Color surfaceColor(ThemeConfig? config) =>
      config?.colors.surface ?? surface;
  static Color backgroundColor(ThemeConfig? config) =>
      config?.colors.background ?? background;

  // Organic Decoration (Large Radii)
  static BoxDecoration organicDecoration({
    required Color color,
    BorderRadius? borderRadius,
    bool showShadow = true,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(32),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
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
      fontFamily: 'Outfit', // A soft, modern font
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surface,
        error: _defaultError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFF2C3E50),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Color(0xFF2C3E50),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryColor.withValues(alpha: 0.4),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: primaryColor),
        hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.6)),
      ),
      useMaterial3: true,
    );
  }
}
