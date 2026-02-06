import 'package:flutter/material.dart';

/// Layout 02 - NetLink Premium Theme
/// Design moderno com gradientes azul/cyan, cards com sombras e animações
class Layout02Theme {
  // ==================== PRIMARY COLORS ====================
  static const primary = Color(0xFF0066FF);
  static const primaryLight = Color(0xFF4D94FF);
  static const primaryDark = Color(0xFF0052CC);
  static const secondary = Color(0xFF00D9FF);
  static const accent = Color(0xFF7C3AED);

  // ==================== STATUS COLORS ====================
  static const green = Color(0xFF10B981);
  static const greenLight = Color(0xFFD1FAE5);
  static const orange = Color(0xFFF59E0B);
  static const orangeLight = Color(0xFFFEF3C7);
  static const red = Color(0xFFEF4444);
  static const redLight = Color(0xFFFEE2E2);
  static const purple = Color(0xFF8B5CF6);
  static const purpleLight = Color(0xFFEDE9FE);
  static const cyan = Color(0xFF06B6D4);
  static const cyanLight = Color(0xFFCFFAFE);

  // ==================== NEUTRAL COLORS ====================
  static const grey = Color(0xFF94A3B8);
  static const greyLight = Color(0xFFF8FAFC);
  static const greyMedium = Color(0xFFE2E8F0);
  static const textDark = Color(0xFF0F172A);
  static const textGrey = Color(0xFF64748B);
  static const cardShadow = Color(0x12000000);

  // ==================== BACKGROUND ====================
  static const background = Colors.white;
  static const scaffoldBackground = Color(0xFFF8FAFC);

  // ==================== GRADIENTS ====================
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const primaryDarkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFE8F4FF),
      Color(0xFFF0F8FF),
      Color(0xFFFAFCFF),
      Colors.white,
    ],
    stops: [0.0, 0.15, 0.3, 0.5],
  );

  // ==================== DECORATIONS ====================
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static BoxDecoration get primaryCardDecoration => BoxDecoration(
        gradient: primaryDarkGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      );

  static BoxDecoration get glassCardDecoration => BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      );

  // ==================== TEXT STYLES ====================
  static const headlineLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: textDark,
    letterSpacing: -0.5,
  );

  static const headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textDark,
    letterSpacing: -0.3,
  );

  static const titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textDark,
  );

  static const titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textDark,
  );

  static const bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textGrey,
  );

  static const bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textGrey,
  );

  static const labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textGrey,
  );

  // ==================== THEME DATA ====================
  static ThemeData get themeData => ThemeData(
        useMaterial3: true,
        primaryColor: primary,
        scaffoldBackgroundColor: scaffoldBackground,
        colorScheme: ColorScheme.light(
          primary: primary,
          secondary: secondary,
          surface: background,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: textDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: textDark),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: greyLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      );
}
