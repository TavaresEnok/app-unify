import 'package:flutter/material.dart';

/// Fonte ÚNICA de design por `layoutType`.
///
/// Antes, a aparência era decidida por dezenas de comparações `layoutType ==
/// 'layout_0X'` espalhadas pelo código e por 11 métodos estáticos separados em
/// [SharedThemeHelper]. Aqui o `layoutType` é resolvido UMA vez em um objeto
/// imutável — as telas leem um token, não reinterpretam a string do layout.
///
/// Os valores espelham exatamente os que estavam no `SharedThemeHelper`, para
/// que consolidar não mude o visual. `SharedThemeHelper` passou a delegar a esta
/// classe (compatibilidade), então a migração das telas pode ser incremental.
@immutable
class LayoutTokens {
  final String layoutType;

  final Color background;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;
  final Color card;
  final Color border;
  final Color success;
  final Color error;
  final Color warning;

  final bool isDark;
  final bool isNeumorphic;

  /// Raio padrão de cantos (cards, campos, botões).
  final double radius;

  const LayoutTokens({
    required this.layoutType,
    required this.background,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.card,
    required this.border,
    required this.success,
    required this.error,
    required this.warning,
    required this.isDark,
    required this.isNeumorphic,
    this.radius = 16,
  });

  /// Sombra neumórfica (só faz sentido no layout_03).
  BoxDecoration get neumorphicDecoration => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
        ],
      );

  /// Decoração de card apropriada ao layout (neumórfico, escuro ou claro).
  BoxDecoration get cardDecoration {
    if (isNeumorphic) return neumorphicDecoration;
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
    );
  }

  static bool _isDark(String? layoutType) =>
      layoutType == 'layout_04' ||
      layoutType == 'layout_05' ||
      layoutType == 'layout_06';

  /// Resolve os tokens para um `layoutType` (default: layout_06).
  factory LayoutTokens.of(String? layoutType) {
    final isDark = _isDark(layoutType);
    final isNeu = layoutType == 'layout_03';

    Color background;
    Color primary;
    Color card;
    switch (layoutType) {
      case 'layout_02':
        background = const Color(0xFFF7FAFC);
        primary = const Color(0xFF3182CE);
        card = Colors.white;
        break;
      case 'layout_03':
        background = const Color(0xFFE8EEF5);
        primary = const Color(0xFF00D4FF);
        card = const Color(0xFFE8EEF5);
        break;
      case 'layout_04':
        background = const Color(0xFF0A0A0A);
        primary = const Color(0xFF0891B2);
        card = const Color(0xFF1C1C1E);
        break;
      case 'layout_05':
        background = const Color(0xFF050810);
        primary = const Color(0xFF00E5FF);
        card = const Color(0xFF161B22);
        break;
      case 'layout_06':
      default:
        background = const Color(0xFF0A0E21);
        primary = const Color(0xFF00BCD4);
        card = const Color(0xFF0F1225);
        break;
    }

    Color textPrimary;
    if (isDark) {
      textPrimary = Colors.white;
    } else if (layoutType == 'layout_02') {
      textPrimary = const Color(0xFF1A202C);
    } else if (layoutType == 'layout_03') {
      textPrimary = const Color(0xFF2D3748);
    } else {
      textPrimary = const Color(0xFF1F2937);
    }

    return LayoutTokens(
      layoutType: layoutType ?? 'layout_06',
      background: background,
      primary: primary,
      textPrimary: textPrimary,
      textSecondary: isDark ? Colors.white70 : const Color(0xFF718096),
      card: card,
      border: isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.grey.withValues(alpha: 0.2),
      success: isDark ? const Color(0xFF00E676) : const Color(0xFF38A169),
      error: isDark ? const Color(0xFFFF5252) : const Color(0xFFE53E3E),
      warning: isDark ? const Color(0xFFFFD740) : const Color(0xFFED8936),
      isDark: isDark,
      isNeumorphic: isNeu,
    );
  }
}
