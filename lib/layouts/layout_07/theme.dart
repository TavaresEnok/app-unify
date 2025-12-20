import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema para o layout 07 (Pôr‑do‑Sol Tropical).
class Layout07Theme {
  // Cores principais
  static const Color headerStart = Color(0xFFFF6B6B); // coral quente
  static const Color headerMid = Color(0xFFFFB66C); // tom de pêssego
  static const Color headerEnd = Color(0xFF56CCF2); // azul‑turquesa
  static const Color background = Color(0xFFFFF7EE); // fundo claro cremoso
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color accent = Color(0xFF2D9CDB); // azul‑verde para destaques
  static const Color goldBadge = Color(0xFFFFE082); // badge dourado

  static ThemeData getTheme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      primaryColor: accent,
      scaffoldBackgroundColor: background,
      cardColor: cardBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accent,
        surface: cardBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      iconTheme: const IconThemeData(color: accent),
      cardTheme: CardThemeData(
        color: cardBackground,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 2,
          shadowColor: accent.withValues(alpha: 0.3),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accent),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBackground,
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static LinearGradient headerGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [headerStart, headerMid, headerEnd],
    );
  }
}
