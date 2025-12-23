import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Layout12Palette {
  static const Color bg = Color(0xFF050910);
  static const Color surface = Color(0xFF0C1524);
  static const Color primary = Color(0xFF39D0FF);
  static const Color secondary = Color(0xFF9C6BFF);
  static const Color accent = Color(0xFFFF7A9E);
  static const Color textPrimary = Color(0xFFF5F7FF);
  static const Color textSecondary = Color(0xFF8EA2C6);
  static const Color success = Color(0xFF2AD48A);
  static const Color warning = Color(0xFFFFC857);
  static const Color error = Color(0xFFFF5C8A);
}

class Layout12Theme {
  static ThemeData getTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: Layout12Palette.primary,
      onPrimary: Colors.black,
      secondary: Layout12Palette.secondary,
      onSecondary: Colors.black,
      error: Layout12Palette.error,
      onError: Colors.white,
      surface: Layout12Palette.surface,
      onSurface: Layout12Palette.textPrimary,
      surfaceContainerLowest: Layout12Palette.bg,
      onSurfaceVariant: Layout12Palette.textSecondary,
    );

    final textTheme = GoogleFonts.spaceGroteskTextTheme().apply(
      bodyColor: Layout12Palette.textPrimary,
      displayColor: Layout12Palette.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: Layout12Palette.bg,
      primaryColor: Layout12Palette.primary,
      colorScheme: scheme,
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Layout12Palette.textPrimary,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: Layout12Palette.textPrimary,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: Layout12Palette.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: Layout12Palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Layout12Palette.primary.withValues(alpha: 0.2),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Layout12Palette.surface.withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Layout12Palette.primary.withValues(alpha: 0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Layout12Palette.primary.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Layout12Palette.primary, width: 2),
        ),
        labelStyle: TextStyle(color: Layout12Palette.textSecondary),
        hintStyle: TextStyle(color: Layout12Palette.textSecondary.withValues(alpha: 0.7)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Layout12Palette.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          elevation: 0,
        ),
      ),
      iconTheme: IconThemeData(color: Layout12Palette.textPrimary),
      dividerColor: Layout12Palette.textSecondary.withValues(alpha: 0.2),
    ).copyWith(
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Layout12Palette.surface.withValues(alpha: isDark ? 0.9 : 0.95),
        indicatorColor: Layout12Palette.primary.withValues(alpha: 0.2),
        iconTheme: MaterialStateProperty.all(
          const IconThemeData(size: 22),
        ),
        labelTextStyle: MaterialStateProperty.all(
          textTheme.labelMedium?.copyWith(color: Layout12Palette.textSecondary),
        ),
      ),
    );
  }
}
