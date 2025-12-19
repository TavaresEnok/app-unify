/// Design System Centralizado
/// Tokens de design reutilizáveis para consistência visual

import 'package:flutter/material.dart';

/// Cores do Sistema
class AppColors {
  // Cores Primárias
  static const Color primary = Color(0xFF6366F1); // Indigo moderno
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);

  // Cores Secundárias
  static const Color secondary = Color(0xFF10B981); // Emerald
  static const Color secondaryDark = Color(0xFF059669);
  static const Color secondaryLight = Color(0xFF34D399);

  // Cores de Feedback
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Cores Neutras
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color backgroundDark = Color(0xFF0F172A);

  // Cores de Texto
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Colors.white;

  // Cores de Borda
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  // Cores Especiais (Premium)
  static const Color neonCyan = Color(0xFF00F3FF);
  static const Color neonPink = Color(0xFFBC13FE);
  static const Color gold = Color(0xFFFFD700);
}

/// Tipografia do Sistema
class AppTypography {
  static const String fontFamily = 'Inter';

  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    letterSpacing: 1.0,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  // Button
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

/// Espaçamentos do Sistema
class AppSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Padding padrão
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);

  // Padding horizontal
  static const EdgeInsets paddingHorizontalMd =
      EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg =
      EdgeInsets.symmetric(horizontal: lg);

  // Padding de página
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(lg, md, lg, lg);
  static const EdgeInsets pageWithBottomNav =
      EdgeInsets.fromLTRB(lg, md, lg, 100);
}

/// Sombras do Sistema
class AppShadows {
  // Sombras sutis
  static const BoxShadow xs = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static const BoxShadow sm = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  static const BoxShadow md = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 16,
    offset: Offset(0, 8),
  );

  static const BoxShadow lg = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 24,
    offset: Offset(0, 12),
  );

  static const BoxShadow xl = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 32,
    offset: Offset(0, 16),
  );

  // Sombras coloridas (para efeitos premium)
  static BoxShadow colored(Color color, {double opacity = 0.3}) => BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: 20,
        offset: const Offset(0, 10),
      );

  // Sombra de glow (para efeitos neon)
  static BoxShadow glow(Color color,
          {double opacity = 0.4, double blur = 20}) =>
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: 2,
      );

  // Lista para cards
  static const List<BoxShadow> card = [sm];
  static const List<BoxShadow> cardElevated = [md];
  static const List<BoxShadow> cardFloating = [lg];
}

/// Raios de Borda do Sistema
class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;

  // BorderRadius prontos
  static const BorderRadius borderRadiusSm =
      BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderRadiusMd =
      BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderRadiusLg =
      BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderRadiusXl =
      BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderRadiusFull =
      BorderRadius.all(Radius.circular(full));
}

/// Durações de Animação
class AppDurations {
  static const Duration fast = Duration(milliseconds: 100);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration slower = Duration(milliseconds: 500);
  static const Duration page = Duration(milliseconds: 400);
}

/// Curvas de Animação
class AppCurves {
  static const Curve ease = Curves.easeInOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve bounce = Curves.elasticOut;
  static const Curve smooth = Curves.fastOutSlowIn;
}

/// Decorações Reutilizáveis
class AppDecorations {
  // Card padrão
  static BoxDecoration card({Color? color}) => BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: AppRadius.borderRadiusLg,
        boxShadow: AppShadows.card,
      );

  // Card elevado
  static BoxDecoration cardElevated({Color? color}) => BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: AppRadius.borderRadiusLg,
        boxShadow: AppShadows.cardElevated,
      );

  // Card com borda
  static BoxDecoration cardBordered({Color? borderColor}) => BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(color: borderColor ?? AppColors.border),
      );

  // Card glassmorphism
  static BoxDecoration glass({Color? color, double opacity = 0.1}) =>
      BoxDecoration(
        color: (color ?? Colors.white).withValues(alpha: opacity),
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      );

  // Badge/Chip
  static BoxDecoration badge(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.borderRadiusFull,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      );
}
