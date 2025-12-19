import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/models/theme_config.dart';

/// Layout 10: Mesh Gradient & Glassmorphism Theme
/// Vibrant gradients, frosted glass effects, and premium feel.
class Layout10Theme {
  // Core Colors (Defaults)
  static const Color background = Color(0xFF0F172A); // Deep Slate
  static const Color surface = Color(0xFF1E293B);

  // Premium defaults
  static const Color _defaultPrimary = Color(0xFF8E44AD); // Violet
  static const Color _defaultSecondary = Color(0xFF1ABC9C); // Teal
  static const Color _defaultError = Color(0xFFFF453A);

  // Dynamic Color Getters
  static Color primary(ThemeConfig? config) =>
      config?.colors.primary ?? _defaultPrimary;
  static Color secondary(ThemeConfig? config) =>
      config?.colors.secondary ?? _defaultSecondary;
  static Color backgroundColor(ThemeConfig? config) =>
      config?.colors.background ?? background;

  // Glass Decoration
  static BoxDecoration glassDecoration({
    required Color color,
    double blur = 12,
    double opacity = 0.1,
    BorderRadius? borderRadius,
  }) =>
      BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.5,
        ),
      );

  // Widget de Vidro (Glassmorphism)
  static Widget glassCard({
    required Widget child,
    double blur = 20,
    double opacity = 0.1,
    Color? color,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: glassDecoration(
            color: color ?? Colors.white,
            opacity: opacity,
            borderRadius: borderRadius,
          ),
          child: child,
        ),
      ),
    );
  }

  // ThemeData
  static ThemeData getTheme(ThemeConfig? config) {
    final primaryColor = primary(config);
    final secondaryColor = secondary(config);
    final bgColor = backgroundColor(config);

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bgColor,
      fontFamily: 'Outfit',
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surface,
        error: _defaultError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      ),
      useMaterial3: true,
    );
  }
}
