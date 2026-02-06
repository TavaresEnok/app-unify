import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🎨 TRUE NEUMORPHISM - Layout 03 Theme
// ═══════════════════════════════════════════════════════════════════════════

class Layout03Theme {
  // THE BASE COLOR - Everything uses this EXACT color
  static const Color neuBase = Color(0xFFE0E5EC);
  static const Color background = neuBase;
  static const Color surface = neuBase;

  // THE SHADOWS - The heart of neumorphism
  static const Color neuShadowDark = Color(0xFFA3B1C6);
  static const Color neuShadowLight = Color(0xFFFFFFFF);

  // TEXT - Soft grays, never pure black
  static const Color textDark = Color(0xFF4A5568);
  static const Color textMedium = Color(0xFF718096);
  static const Color textLight = Color(0xFFA0AEC0);
  static const Color textGrey = textMedium;
  static const Color textWhite = Colors.white;

  // ACCENT - Only for small details (icons, chips)
  static const Color primary = Color(0xFF6B7FD7);
  static const Color accent = primary;
  static const Color secondary = Color(0xFF4FD1C5);
  static const Color success = Color(0xFF68D391);
  static const Color warning = Color(0xFFECC94B);
  static const Color error = Color(0xFFFC8181);

  // COLD COLORS for feature icons (desaturated, muted)
  static const Color iconBlue = Color(0xFF7B9DBF);
  static const Color iconTeal = Color(0xFF6BA8A0);
  static const Color iconSlate = Color(0xFF8B9DC3);
  static const Color iconSage = Color(0xFF8DAA9D);
  static const Color iconMauve = Color(0xFF9B8FA8);
  static const Color iconStorm = Color(0xFF7C8DA0);
  static const Color iconMist = Color(0xFF9CAFB7);
  static const Color iconDusk = Color(0xFF8A97AA);
  static const Color iconFog = Color(0xFF94A3B8);

  // ═══════════════════════════════════════════════════════════════════════════
  // CONVEX SHADOW - Element rises FROM the surface
  // ═══════════════════════════════════════════════════════════════════════════
  static List<BoxShadow> neuConvex({
    double distance = 8,
    double blur = 15,
    double spread = 1,
  }) {
    return [
      BoxShadow(
        color: neuShadowDark,
        offset: Offset(distance, distance),
        blurRadius: blur,
        spreadRadius: spread,
      ),
      BoxShadow(
        color: neuShadowLight,
        offset: Offset(-distance, -distance),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONCAVE SHADOW - Element sinks INTO the surface (inset simulation)
  // ═══════════════════════════════════════════════════════════════════════════
  static List<BoxShadow> neuConcave({
    double distance = 6,
    double blur = 12,
    double spread = 1,
  }) {
    return [
      BoxShadow(
        color: neuShadowDark.withOpacity(0.5),
        offset: Offset(distance, distance),
        blurRadius: blur,
        spreadRadius: -spread,
      ),
      BoxShadow(
        color: neuShadowLight.withOpacity(0.7),
        offset: Offset(-distance, -distance),
        blurRadius: blur,
        spreadRadius: -spread,
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FLAT SHADOW - Subtle, for smaller elements
  // ═══════════════════════════════════════════════════════════════════════════
  static List<BoxShadow> neuFlat({double distance = 4, double blur = 8}) {
    return [
      BoxShadow(
        color: neuShadowDark.withOpacity(0.6),
        offset: Offset(distance, distance),
        blurRadius: blur,
      ),
      BoxShadow(
        color: neuShadowLight,
        offset: Offset(-distance, -distance),
        blurRadius: blur,
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRESSED SHADOW - For active/pressed state
  // ═══════════════════════════════════════════════════════════════════════════
  static List<BoxShadow> neuPressed({double distance = 3, double blur = 6}) {
    return [
      BoxShadow(
        color: neuShadowDark.withOpacity(0.4),
        offset: Offset(distance, distance),
        blurRadius: blur,
        spreadRadius: -2,
      ),
      BoxShadow(
        color: neuShadowLight.withOpacity(0.6),
        offset: Offset(-distance, -distance),
        blurRadius: blur,
        spreadRadius: -2,
      ),
    ];
  }

  // --- Neumorphic Decorations (Backward compatibility) ---
  static BoxDecoration get neumorphicDecoration => BoxDecoration(
        color: neuBase,
        borderRadius: BorderRadius.circular(20),
        boxShadow: neuConvex(),
      );

  static BoxDecoration get neumorphicCircleDecoration => BoxDecoration(
        color: neuBase,
        shape: BoxShape.circle,
        boxShadow: neuConvex(),
      );

  static BoxDecoration get neumorphicPressedDecoration => BoxDecoration(
        color: neuBase,
        borderRadius: BorderRadius.circular(20),
        boxShadow: neuPressed(),
      );

  static BoxDecoration get flatDecoration => BoxDecoration(
        color: neuBase,
        borderRadius: BorderRadius.circular(16),
        boxShadow: neuFlat(),
      );

  // Aliases
  static BoxDecoration get cardDecoration => neumorphicDecoration;
  static BoxDecoration get glassDecoration => neumorphicDecoration;
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
        color: textMedium,
        height: 1.5,
      );

  static TextStyle get label => GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: textMedium,
        letterSpacing: 0.5,
      );

  // --- Constants ---
  static const double radiusM = 20.0;
  static const double radiusL = 30.0;
  static const double padding = 24.0;
}
