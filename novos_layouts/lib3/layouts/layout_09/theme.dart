import 'package:flutter/material.dart';
import '../../core/models/theme_config.dart';

class Layout09AuroraTheme {
  static ThemeData getTheme(ThemeConfig config, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final primary = config.colors.primary;
    final secondary = config.colors.secondary;

    final background = isDark
        ? _blend(config.colors.background, const Color(0xFF070A12), 0.65)
        : _blend(config.colors.background, const Color(0xFFF6F7FB), 0.75);

    final surface = isDark
        ? _blend(config.colors.surface, const Color(0xFF101425), 0.75)
        : _blend(config.colors.surface, const Color(0xFFFFFFFF), 0.85);

    final onSurface = isDark ? const Color(0xFFECEFF8) : const Color(0xFF101828);
    final onSurfaceVariant =
        isDark ? const Color(0xFFA7B0C3) : const Color(0xFF475467);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isDark ? Colors.black : Colors.white,
      secondary: secondary,
      onSecondary: isDark ? Colors.black : Colors.white,
      error: config.colors.error,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerLowest: background,
      onSurfaceVariant: onSurfaceVariant,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      dividerColor: onSurfaceVariant.withValues(alpha: isDark ? 0.22 : 0.18),
      iconTheme: IconThemeData(color: config.effects.iconColor ?? primary),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            bodyColor: onSurface,
            displayColor: onSurface,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: null,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface.withValues(alpha: isDark ? 0.65 : 0.85),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius.md),
          borderSide: BorderSide(
            color: onSurfaceVariant.withValues(alpha: isDark ? 0.22 : 0.18),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius.md),
          borderSide: BorderSide(
            color: onSurfaceVariant.withValues(alpha: isDark ? 0.18 : 0.14),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius.md),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.borderRadius.md),
          ),
        ),
      ),
    );

    return base;
  }

  static Color _blend(Color a, Color b, double t) {
    return Color.lerp(a, b, t) ?? a;
  }
}
