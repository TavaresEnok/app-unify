import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Layout05Theme {
  // --- Colors (Deep Navy & Neon Accents) ---
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color secondary = Color(0xFF10B981); // Emerald 500
  static const Color accent = Color(0xFFF43F5E); // Rose 500

  static const Color textWhite = Color(0xFFF8FAFC);
  static const Color textGrey = Color(0xFF94A3B8);

  // --- Missing Properties for Compatibility ---
  static const Color textDark = Color(0xFF1E293B); // Slate 800
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500

  // --- Gradients ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1AFFFFFF), // White 10%
      Color(0x05FFFFFF), // White 2%
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Glassmorphism ---
  static BoxDecoration glassDecoration = BoxDecoration(
    gradient: glassGradient,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withOpacity(0.1)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 16,
        spreadRadius: 0,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration solidCardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withOpacity(0.05)),
  );

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surface, // Changed to surface for dark theme consistency
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // --- Typography (Inter) ---
  static TextStyle get heading1 => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textWhite,
        height: 1.2,
      );

  static TextStyle get heading2 => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textWhite,
      );

  static TextStyle get bodyText => GoogleFonts.inter(
        fontSize: 14,
        color: textGrey,
        height: 1.5,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textGrey,
        letterSpacing: 0.5,
      );

  // --- Constants ---
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double padding = 20.0;
}
