import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Layout04Theme {
  // --- Aurora Colors ---
  static const Color backgroundBlack = Color(0xFF0F172A); // Deep Night Blue

  // Neon Accents
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonPurple = Color(0xFFBC13FE);
  static const Color neonPink = Color(0xFFFF0055);
  static const Color neonGreen = Color(0xFF0AFF60);

  // Text Colors
  static const Color textWhite = Colors.white;
  static const Color textWhite70 = Colors.white70;
  static const Color textWhite30 = Colors.white30;

  // --- Gradients ---
  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A), // Deep Blue
      Color(0xFF1E1B4B), // Indigo
      Color(0xFF312E81), // Deep Purple
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [neonCyan, neonPurple],
  );

  // --- Glassmorphism Decorations ---

  static BoxDecoration get glassDecoration => BoxDecoration(
        color: Colors.white.withOpacity(0.08), // Frosted glass tint
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.15), // Glass edge reflection
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration get glassCardActive => BoxDecoration(
        color: Colors.white.withOpacity(0.12), // Slightly easier to see
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: neonCyan.withOpacity(0.5), // Active glow border
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: neonCyan.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      );

  // --- Typography (Exo 2 for Sci-Fi feel or Outfit) ---
  static TextStyle get headingHero => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: textWhite,
        letterSpacing: -1.0,
      );

  static TextStyle get heading1 => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textWhite,
      );

  static TextStyle get heading2 => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textWhite,
      );

  static TextStyle get bodyText => GoogleFonts.outfit(
        fontSize: 16,
        color: textWhite70,
        height: 1.5,
      );

  static TextStyle get label => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textWhite70,
        letterSpacing: 0.5,
      );
}
