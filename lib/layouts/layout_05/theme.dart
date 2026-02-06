// Layout 05 Theme - Cyber Neon Dark
// Design futurista com elementos neon e animações

import 'package:flutter/material.dart';

class Layout05Theme {
  // Core Colors
  static const Color background = Color(0xFF050810);
  static const Color surface = Color(0xFF0D1117);
  static const Color cardBg = Color(0xFF161B22);

  // Accent Colors
  static const Color primary = Color(0xFF00E5FF);
  static const Color primaryDark = Color(0xFF00B8D4);
  static const Color secondary = Color(0xFF7C4DFF);
  static const Color accent = Color(0xFFFFD700);

  // Status Colors
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFB74D);

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xB3FFFFFF); // 70%
  static const Color textMuted = Color(0x80FFFFFF); // 50%
  static const Color textDim = Color(0x66FFFFFF); // 40%

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
  );

  // ThemeData
  static ThemeData get themeData => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        primaryColor: primary,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: surface,
          error: error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: textPrimary,
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textPrimary),
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      );

  // Decorations
  static BoxDecoration glassDecoration({double opacity = 0.08}) =>
      BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      );

  static BoxDecoration cardDecoration({Color? borderColor}) => BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.05),
        ),
      );

  static BoxDecoration heroCardDecoration(double pulseValue) => BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withOpacity(0.15),
            primaryDark.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: primary.withOpacity(0.2 + pulseValue * 0.1),
        ),
      );

  // Shadows
  static List<BoxShadow> neonShadow(Color color, {double blur = 15}) => [
        BoxShadow(
          color: color.withOpacity(0.4),
          blurRadius: blur,
          spreadRadius: 1,
        ),
      ];

  static List<BoxShadow> glowShadow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.5),
          blurRadius: 20,
        ),
      ];
}
