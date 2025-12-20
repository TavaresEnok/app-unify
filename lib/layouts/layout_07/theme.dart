import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema para o layout 07 (Pôr‑do‑Sol Tropical).
class Layout07Theme {
  // Cores principais
  static const Color headerStart = Color(0xFFFF6B6B); // coral quente
  static const Color headerMid = Color(0xFFFFB66C); // tom de pêssego
  static const Color headerEnd = Color(0xFF56CCF2); // azul‑turquesa
  static const Color background = Color(0xFFFFF7EE); // fundo claro
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color accent = Color(0xFF2D9CDB); // azul‑verde para destaques

  /// Cria um [ThemeData] completo com base nas cores do layout.
  static ThemeData getTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: accent,
      scaffoldBackgroundColor: background,
      cardColor: cardBackground,
      // Usa a fonte Poppins via GoogleFonts
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: ColorScheme.light(
        primary: accent,
        secondary: accent,
        background: background,
        surface: cardBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      useMaterial3: true,
    );
  }

  /// Gradiente usado no cabeçalho superior.
  static LinearGradient headerGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [headerStart, headerMid, headerEnd],
    );
  }
}
