part of '../diagnostic_07_page.dart';

// ============ THEME CONFIG (WHITE MODE) ============
class AppTheme {
  // Bases
  static const bgLight = Color(0xFFF8FAFC); // Slate 50
  static const bgWhite = Colors.white;

  // Brand
  static const primary = Color(0xFF7C3AED); // Violet 600
  static const primarySafe = Color(0xFF6D28D9); // Violet 700
  static const accent = Color(0xFF0EA5E9); // Sky 500
  static const secondary = Color(0xFFF43F5E); // Rose 500

  // Status
  static const success = Color(0xFF059669); // Emerald 600
  static const warning = Color(0xFFD97706); // Amber 600
  static const error = Color(0xFFDC2626); // Red 600

  // Text
  static const textDark = Color(0xFF0F172A); // Slate 900
  static const textGrey = Color(0xFF64748B); // Slate 500
  static const textLight = Color(0xFF94A3B8); // Slate 400

  static final borderRadius = BorderRadius.circular(24);
}

enum DiagStep { ready, wifi, fiber, tracert, devices, speed, done }
