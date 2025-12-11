import 'package:flutter/material.dart';

/// Cores padrão do aplicativo
/// Essas cores são usadas como fallback quando o provedor não define cores customizadas
class AppColors {
  // Cores principais
  static const Color primaryBlue = Color(0xFF1E6FF8);
  static const Color primaryDark = Color(0xFF0A1929);
  static const Color accent = Color(0xFF00D9FF);
  
  // Background
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color darkBackground = Color(0xFF0F172A);
  
  // Texto
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  
  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Aliases para compatibilidade com diferentes layouts
  static const Color primary = primaryBlue;
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFE2E8F0);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, Color(0xFF8B5CF6)],
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );
}
