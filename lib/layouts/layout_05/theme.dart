import 'package:flutter/material.dart';

class Layout05Theme {
  // Cores Principais (Estilo Clean/Corporativo Moderno)
  static const Color primary = Color(0xFF4F46E5); // Indigo vibrante
  static const Color secondary =
      Color(0xFF10B981); // Verde esmeralda (Ações positivas)
  static const Color background =
      Color(0xFFF8FAFC); // Cinza muito claro (Slate 50)
  static const Color surface = Colors.white;

  // Textos
  static const Color textDark = Color(0xFF1E293B); // Slate 800
  static const Color textGrey = Color(0xFF64748B); // Slate 500

  // Status
  static const Color error = Color(0xFFEF4444); // Vermelho suave
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);

  // Sombras e Bordas
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF64748B).withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF64748B).withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static BorderRadius get radiusXL => BorderRadius.circular(24);
  static BorderRadius get radiusL => BorderRadius.circular(16);
  static BorderRadius get radiusM => BorderRadius.circular(12);

  // Decorações Prontas
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surface,
        borderRadius: radiusL,
        boxShadow: cardShadow,
      );

  // Tipografia Personalizada
  static TextStyle get heading1 => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: textDark,
        letterSpacing: -0.5,
        fontFamily: 'Inter', // Assumindo fonte padrão ou sistema
      );

  static TextStyle get heading2 => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textDark,
        letterSpacing: -0.5,
      );

  static TextStyle get bodyText => const TextStyle(
        fontSize: 16,
        color: textGrey,
        height: 1.5,
      );
}
