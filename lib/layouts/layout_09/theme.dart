import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema Aurora para Layout 09
/// Cores dinâmicas com suporte a dark/light mode
class Layout09Theme {
  // Cores principais
  static const Color primary = Color(0xFF6366F1); // Indigo vibrante
  static const Color secondary = Color(0xFF8B5CF6); // Violeta
  static const Color accent = Color(0xFF06B6D4); // Ciano

  // Cores de fundo
  static const Color backgroundLight = Color(0xFFF6F7FB);
  static const Color backgroundDark = Color(0xFF070A12);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF101425);

  // Cores de texto
  static const Color textPrimaryLight = Color(0xFF101828);
  static const Color textPrimaryDark = Color(0xFFECEFF8);
  static const Color textSecondaryLight = Color(0xFF475467);
  static const Color textSecondaryDark = Color(0xFFA7B0C3);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const double borderRadius = 16.0;

  static ThemeData getTheme({Brightness brightness = Brightness.light}) {
    final isDark = brightness == Brightness.dark;

    final background = isDark ? backgroundDark : backgroundLight;
    final surface = isDark ? surfaceDark : surfaceLight;
    final onSurface = isDark ? textPrimaryDark : textPrimaryLight;
    final onSurfaceVariant = isDark ? textSecondaryDark : textSecondaryLight;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isDark ? Colors.black : Colors.white,
      secondary: secondary,
      onSecondary: isDark ? Colors.black : Colors.white,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerLowest: background,
      onSurfaceVariant: onSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      dividerColor: onSurfaceVariant.withValues(alpha: isDark ? 0.22 : 0.18),
      iconTheme: const IconThemeData(color: primary),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface.withValues(alpha: isDark ? 0.65 : 0.85),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: onSurfaceVariant.withValues(alpha: isDark ? 0.22 : 0.18),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: onSurfaceVariant.withValues(alpha: isDark ? 0.18 : 0.14),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static Color blend(Color a, Color b, double t) {
    return Color.lerp(a, b, t) ?? a;
  }

  static LinearGradient auroraGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, secondary, accent],
    );
  }
}
