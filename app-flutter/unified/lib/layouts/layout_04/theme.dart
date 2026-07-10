import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Layout04Theme {
  // --- Colors ---
  static const Color background = Color(0xFF101010); // Deep matte black
  static const Color surface = Color(0xFF1C1C1E); // Dark grey surface
  static const Color surfaceHighlight =
      Color(0xFF2C2C2E); // Lighter grey for interactions
  static const Color secondarySurface = Color(0xFF252525); // Secondary surface

  static const Color primary = Color(0xFF5E5CE6); // Modern Violet/Indigo
  static const Color primaryVariant = Color(0xFF7D7AFF);

  static const Color accent = Color(0xFF0A84FF); // Bright Blue for stats/links
  static const Color success = Color(0xFF32D74B); // iOS Green
  static const Color warning = Color(0xFFFFD60A); // iOS Yellow
  static const Color error = Color(0xFFFF453A); // iOS Red

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93); // Light Grey
  static const Color textTertiary = Color(0xFF636366); // Darker Grey
  static const Color border = Color(0xFF3A3A3C); // Subtle border

  // --- Gradients (Subtle) ---
  // Using minimal gradients, mostly formatting utility
  static LinearGradient primaryGradient = const LinearGradient(
    colors: [primary, primaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Text Styles ---
  static TextStyle get heading1 => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700, // Bold
        color: textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get heading2 => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600, // SemiBold
        color: textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get heading3 => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textTertiary,
        letterSpacing: 0.5,
      );

  static TextStyle get buttonText => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  // --- Decoration Helpers ---

  // Standard Card Style
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Active / Highlighted Card
  static BoxDecoration activeCardDecoration = BoxDecoration(
    color: surfaceHighlight,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: primary.withValues(alpha: 0.3), width: 1),
  );

  // Simple Input Decoration
  static InputDecoration inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      filled: true,
      fillColor: surface,
      labelText: label,
      labelStyle: bodyMedium,
      prefixIcon:
          icon != null ? Icon(icon, color: textSecondary, size: 20) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: error, width: 1),
      ),
    );
  }

  // Primary Button Style
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    textStyle: buttonText,
  );

  // Secondary / Outline Button Style
  static ButtonStyle outlineButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: textPrimary,
    side: const BorderSide(color: border),
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    textStyle: buttonText.copyWith(fontSize: 14),
  );
}
