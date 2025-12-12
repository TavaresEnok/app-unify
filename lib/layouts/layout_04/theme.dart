import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Layout 04 - Cyber Wave Theme
/// Glassmorphism + Vibrant Gradients + Neon Accents
class Layout04Theme {
  // === COLORS ===

  // Background
  static const Color background = Color(0xFF0A0E27);
  static const Color backgroundLight = Color(0xFF12162E);

  // Primary Gradient Colors
  static const Color primaryCyan = Color(0xFF00D9FF);
  static const Color primaryPurple = Color(0xFF7B2FFF);
  static const Color primaryPink = Color(0xFFFF2E97);

  // Accent Colors
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color neonRed = Color(0xFFFF3366);
  static const Color neonYellow = Color(0xFFFFD600);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8D4);
  static const Color textTertiary = Color(0xFF6B7399);

  // Glass/Frosted Colors
  static const Color glassWhite = Color(0x1AFFFFFF); // 10% white
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white

  // Status Colors
  static const Color success = neonGreen;
  static const Color error = neonRed;
  static const Color warning = neonYellow;
  static const Color info = primaryCyan;

  // === GRADIENTS ===

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryCyan, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [primaryPurple, primaryPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [primaryCyan, primaryPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFF0A0E27),
      Color(0xFF12162E),
      Color(0xFF1A1F3A),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === TEXT STYLES ===

  static TextStyle get heading1 => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get heading2 => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get heading3 => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textTertiary,
      );

  static TextStyle get buttonText => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textTertiary,
      );

  // === DECORATIONS ===

  /// Glass Card Decoration with blur effect
  static BoxDecoration glassCard({
    double borderRadius = 20,
    Color? customColor,
  }) {
    return BoxDecoration(
      color: customColor ?? glassWhite,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: glassBorder,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  /// Neon Glow Button Decoration
  static BoxDecoration neonButton({
    Gradient? gradient,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      gradient: gradient ?? primaryGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: primaryCyan.withOpacity(0.5),
          blurRadius: 20,
          offset: const Offset(0, 5),
        ),
        BoxShadow(
          color: primaryPurple.withOpacity(0.3),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  /// Status Badge Decoration
  static BoxDecoration statusBadge(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: color.withOpacity(0.4),
        width: 1,
      ),
    );
  }

  /// Shimmer effect for loading states
  static BoxDecoration shimmerDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        glassWhite,
        Colors.white.withOpacity(0.3),
        glassWhite,
      ],
      stops: const [0.0, 0.5, 1.0],
    ),
  );

  // === SHAPES ===

  static RoundedRectangleBorder cardShape({double radius = 20}) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
  }

  // === SHADOWS ===

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> neonGlow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.5),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];
}
