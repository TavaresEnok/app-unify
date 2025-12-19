import 'package:flutter/material.dart';
import '../../core/models/theme_config.dart';

/// Layout 09: Midnight Glass Theme
/// Dark theme with frosted glass effects and pastel glows
/// Sophisticated dark glassmorphism with colorful accents
class Layout09Theme {
  // Core Colors - DARK GLASS THEME
  static const Color background = Color(0xFF0C0C1E); // Deep indigo black
  static const Color surface = Color(0xFF16162A); // Dark indigo surface
  static const Color surfaceLight = Color(0xFF1E1E38); // Lighter surface
  static const Color _defaultPrimary = Color(0xFFEC4899); // Pink-500
  static const Color _defaultSecondary = Color(0xFF8B5CF6); // Violet-500

  // Glass accent colors
  static const Color glassPink = Color(0xFFF472B6);
  static const Color glassBlue = Color(0xFF60A5FA);
  static const Color glassPurple = Color(0xFFA78BFA);
  static const Color glassGreen = Color(0xFF34D399);
  static const Color glassCyan = Color(0xFF22D3EE);

  // Pastel colors for card backgrounds (darker for dark theme)
  static const Color pastelPink = Color(0xFF2D1A24);
  static const Color pastelBlue = Color(0xFF1A2230);
  static const Color pastelGreen = Color(0xFF1A2D24);
  static const Color pastelYellow = Color(0xFF2D2A1A);
  static const Color pastelPurple = Color(0xFF241A2D);
  static const Color pastelCyan = Color(0xFF1A2D2D);

  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textHint = Color(0xFF71717A);
  static const Color border = Color(0xFF27273F);
  static const Color error = Color(0xFFF43F5E);
  static const Color success = Color(0xFF10B981);

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

  // Gradients
  static LinearGradient primaryGradient(ThemeConfig? config) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary(config), secondary(config)],
      );

  // Frosted background with glow
  static LinearGradient frostedGradient(ThemeConfig? config) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary(config).withValues(alpha: 0.1),
          secondary(config).withValues(alpha: 0.05),
        ],
      );

  // Text Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.8,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
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

  // DARK Glassmorphism Decoration
  static BoxDecoration glassDecoration(ThemeConfig? config) => BoxDecoration(
        color: surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primary(config).withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      );

  // Bento card with glow effect
  static BoxDecoration bentoCardDecoration(
          Color? glowColor, ThemeConfig? config) =>
      BoxDecoration(
        color: surfaceLight.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (glowColor ?? primary(config)).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (glowColor ?? primary(config)).withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
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
      fontFamily: 'Inter',
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
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      useMaterial3: true,
    );
  }
}
