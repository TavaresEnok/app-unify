import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/theme_config.dart';

class DynamicThemeBuilder {
  /// Converte ThemeConfig para ThemeData do Flutter
  static ThemeData buildTheme(ThemeConfig config) {
    return ThemeData(
      useMaterial3: true,

      // Cores principais
      primaryColor: config.colors.primary,
      scaffoldBackgroundColor: config.colors.background,

      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: config.colors.primary,
        secondary: config.colors.secondary,
        surface: config.colors.surface,
        error: config.colors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: config.colors.textPrimary,
        onError: Colors.white,
      ),

      // Tipografia
      textTheme: GoogleFonts.getTextTheme(
        config.typography.fontFamily,
        TextTheme(
          displayLarge: TextStyle(
            fontSize: config.typography.fontSizes['h1']!,
            color: config.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          displayMedium: TextStyle(
            fontSize: config.typography.fontSizes['h2']!,
            color: config.colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          displaySmall: TextStyle(
            fontSize: config.typography.fontSizes['h3']!,
            color: config.colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            fontSize: config.typography.fontSizes['body']!,
            color: config.colors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: config.typography.fontSizes['body']!,
            color: config.colors.textSecondary,
          ),
          bodySmall: TextStyle(
            fontSize: config.typography.fontSizes['caption']!,
            color: config.colors.textHint,
          ),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: config.colors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(config.borderRadius.lg),
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: config.colors.surface,
        foregroundColor: config.colors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: config.colors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.borderRadius.md),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: config.spacing.lg,
            vertical: config.spacing.md,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: config.colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius.md),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.all(config.spacing.md),
      ),
    );
  }
}
