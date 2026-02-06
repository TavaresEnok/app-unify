// Layout 06 Theme - Clean Dark
// Design elegante e moderno com foco em usabilidade

import 'package:flutter/material.dart';

class Layout06Theme {
  // Core Colors
  static const Color background = Color(0xFF0A0E21);
  static const Color backgroundSecondary = Color(0xFF0D1B2A);
  static const Color surface = Color(0xFF1A1F3C);
  static const Color cardBg = Color(0xFF0F1225);

  // Accent Colors
  static const Color primary = Color(0xFF00BCD4);
  static const Color primaryDark = Color(0xFF00838F);
  static const Color secondary = Color(0xFF00E676);
  static const Color tertiary = Color(0xFF7C4DFF);
  static const Color accent = Color(0xFFFFD700);

  // Status Colors
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFE53935);
  static const Color errorDark = Color(0xFFC62828);
  static const Color warning = Color(0xFFFFB74D);

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xCCFFFFFF); // 80%
  static const Color textMuted = Color(0x80FFFFFF); // 50%

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, backgroundSecondary],
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
            borderRadius: BorderRadius.circular(24),
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
  static BoxDecoration cardDecoration(
          {Color? borderColor, double radius = 24}) =>
      BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.06),
        ),
      );

  static BoxDecoration glassBtnDecoration() => BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      );

  static BoxDecoration connectionCardDecoration(
          bool isConnected, double pulseValue) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            (isConnected ? primary : error).withOpacity(0.12),
            (isConnected ? primary : error).withOpacity(0.04),
          ],
        ),
        border: Border.all(
          color: (isConnected ? primary : error)
              .withOpacity(0.15 + pulseValue * 0.1),
        ),
      );

  static BoxDecoration speedTestCardDecoration() => BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [surface, cardBg],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      );

  // Shadows
  static List<BoxShadow> primaryShadow({double blur = 12}) => [
        BoxShadow(
          color: primary.withOpacity(0.3),
          blurRadius: blur,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> glowShadow(Color color, {double blur = 15}) => [
        BoxShadow(
          color: color.withOpacity(0.4),
          blurRadius: blur,
        ),
      ];
}
