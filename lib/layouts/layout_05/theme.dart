import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Layout05Theme {
  // --- Soft UI Colors ---
  static const Color background = Color(0xFFEFEEEE); // Light Platinum
  static const Color surface = Color(0xFFEFEEEE); // Same as BG for Neumorphism

  static const Color primary = Color(0xFF7280FF); // Soft Indigo/Blue
  static const Color secondary = Color(0xFF4FD1C5); // Soft Teal
  static const Color accent = Color(0xFFFF7B9C); // Soft Pink

  static const Color textDark = Color(0xFF3E4E68); // Dark Blue-Grey
  static const Color textGrey = Color(0xFF7D8CA3); // Soft Grey
  static const Color textWhite = Colors.white;

  static const Color error = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF51CF66);
  static const Color warning = Color(0xFFFFC078);

  // --- Neumorphic Decorations ---

  // 1. Convex (Standard "pop out" card/button)
  static BoxDecoration get neumorphicDecoration => BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white,
            offset: const Offset(-8, -8),
            blurRadius: 16,
          ),
          BoxShadow(
            color: const Color(0xFFA3B1C6).withValues(alpha: 0.4),
            offset: const Offset(8, 8),
            blurRadius: 16,
          ),
        ],
      );

  // 1b. Convex Circle (for Avatars/Icons)
  static BoxDecoration get neumorphicCircleDecoration => BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white,
            offset: const Offset(-8, -8),
            blurRadius: 16,
          ),
          BoxShadow(
            color: const Color(0xFFA3B1C6).withValues(alpha: 0.4),
            offset: const Offset(8, 8),
            blurRadius: 16,
          ),
        ],
      );

  // 2. Concave (Pressed state or Input)
  static BoxDecoration get neumorphicPressedDecoration => BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA3B1C6).withValues(alpha: 0.2),
            offset: const Offset(6, 6),
            blurRadius: 10,
            // inset: true // Requires customized implementation or specialized package,
            // but standard flutter BoxDecoration doesn't support 'inset'.
            // We simulate "pressed" by flipping shadows or darkening inner.
            // For valid Flutter code without extra packages:
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            offset: const Offset(-6, -6),
            blurRadius: 10,
            // inset: true
          ),
        ],
        // Note: Standard BoxDecoration does NOT support 'inset' shadows natively without custom painting
        // or packages like flutter_neumorphic.
        // We will simulate "Concave" using a slightly darker/flat look or standard shadows
        // inverted if we had a package.
        // For standard Flutter, we'll just use a flatter, darker style for inputs/pressed.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE6E6E6), // Slightly darker top-left
            Color(0xFFF7F7F7), // Lighter bottom-right
          ],
        ),
      );

  // 3. Flat / Simple for small elements
  static BoxDecoration get flatDecoration => BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white,
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: const Color(0xFFA3B1C6).withValues(alpha: 0.3),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
        ],
      );

  // Alias for compatibility with previous layout code
  static BoxDecoration get cardDecoration => neumorphicDecoration;
  static BoxDecoration get glassDecoration =>
      neumorphicDecoration; // Map glass to neumorphic
  static BoxDecoration get solidCardDecoration => flatDecoration;

  // --- Typography ---
  static TextStyle get heading1 => GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: textDark,
        height: 1.2,
      );

  static TextStyle get heading2 => GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textDark,
      );

  static TextStyle get bodyText => GoogleFonts.nunito(
        fontSize: 15,
        color: textGrey,
        height: 1.5,
      );

  static TextStyle get label => GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: textGrey,
        letterSpacing: 0.5,
      );

  // --- Constants ---
  static const double radiusM = 20.0;
  static const double radiusL = 30.0;
  static const double padding = 24.0;
}
