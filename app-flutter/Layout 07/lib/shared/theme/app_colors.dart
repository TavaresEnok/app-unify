import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- Brand & Primary Actions ---
  static const Color primary = Color(0xFF1E6FF8); // Electric Blue
  static const Color primaryDark = Color(0xFF1557C0); // Darker shade
  static const Color primaryLight = Color(0xFFE0EAFF); // Light blue background
  
  static const Color accent = Color(0xFFFFB400); // Amber/Gold
  
  // --- Backgrounds & Surfaces ---
  static const Color background = Color(0xFFFFFFFF); // Pure White
  static const Color surface = Color(0xFFF9FAFB); // Cool Grey 50
  static const Color surfaceHighlight = Color(0xFFF3F4F6); // Grey 100
  
  // --- Text Hierarchy ---
  static const Color textPrimary = Color(0xFF111827); // Rich Black
  static const Color textSecondary = Color(0xFF6B7280); // Cool Grey 500
  static const Color textTertiary = Color(0xFF9CA3AF); // Cool Grey 400
  static const Color textOnPrimary = Colors.white;
  
  // Aliases for backward compatibility
  static const Color text = textPrimary; // Added alias for 'text'
  static const Color textHint = textTertiary;
  static const Color textLight = Colors.white;

  // --- Status Indicators ---
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color error = Color(0xFFEF4444); // Red
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF3B82F6); // Blue

  // --- Borders & Dividers ---
  static const Color border = Color(0xFFE5E7EB); // Grey 200
  static const Color divider = Color(0xFFF3F4F6); // Grey 100
  
  // --- Specific UI Elements ---
  static const Color inputFill = surface;
  static const Color inputBorder = border;
  static const Color overlay = Color(0x66000000); // Black 40% opacity
  static const Color dropdownBackground = background;
}
