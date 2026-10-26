part of '../diagnostic_06_page.dart';

class AppColors {
  static const bg = Color(0xFFFAFAFA);
  static const cardBg = Colors.white;
  static const primary = Color(0xFF475569); // Slate
  static const accent = Color(0xFF0EA5E9); // Sky blue
  static const accentLight = Color(0xFF7DD3FC);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFFA1A1AA);
  static const border = Color(0xFFE4E4E7);
}

enum DiagStep { ready, wifi, fiber, devices, speed, route, done }
