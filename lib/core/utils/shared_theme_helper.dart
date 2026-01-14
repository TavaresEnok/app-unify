import 'package:flutter/material.dart';

/// Helper centralizado para cores de tema por layout
/// Usado pelas shared pages para manter consistência visual
class SharedThemeHelper {
  /// Retorna a cor de fundo apropriada para o layout
  static Color getBackgroundColor(String? layoutType) {
    switch (layoutType) {
      case 'layout_02':
        return const Color(0xFFF7FAFC); // Light gray
      case 'layout_03':
        return const Color(0xFFE8EEF5); // Neumorphic light
      case 'layout_04':
        return const Color(0xFF0A0A0A); // Obsidian dark
      case 'layout_05':
        return const Color(0xFF050810); // Cyber neon dark
      case 'layout_06':
      default:
        return const Color(0xFF0A0E21); // Clean dark
    }
  }

  /// Verifica se o layout é escuro
  static bool isDarkLayout(String? layoutType) {
    return layoutType == 'layout_04' ||
        layoutType == 'layout_05' ||
        layoutType == 'layout_06';
  }

  /// Verifica se é layout neumórfico (Layout 03)
  static bool isNeumorphic(String? layoutType) => layoutType == 'layout_03';

  /// Cor primária por layout
  static Color getPrimaryColor(String? layoutType) {
    switch (layoutType) {
      case 'layout_02':
        return const Color(0xFF3182CE); // Blue
      case 'layout_03':
        return const Color(0xFF00D4FF); // Cyan
      case 'layout_04':
        return const Color(0xFF0891B2); // Teal
      case 'layout_05':
        return const Color(0xFF00E5FF); // Neon cyan
      case 'layout_06':
      default:
        return const Color(0xFF00BCD4); // Teal
    }
  }

  /// Cor de texto principal por layout
  static Color getTextColor(String? layoutType) {
    if (isDarkLayout(layoutType)) {
      return Colors.white;
    }
    switch (layoutType) {
      case 'layout_02':
        return const Color(0xFF1A202C);
      case 'layout_03':
        return const Color(0xFF2D3748);
      default:
        return const Color(0xFF1F2937);
    }
  }

  /// Cor de texto secundário/grey por layout
  static Color getTextGreyColor(String? layoutType) {
    if (isDarkLayout(layoutType)) {
      return Colors.white70;
    }
    return const Color(0xFF718096);
  }

  /// Cor de sucesso por layout
  static Color getSuccessColor(String? layoutType) {
    if (isDarkLayout(layoutType)) {
      return const Color(0xFF00E676);
    }
    return const Color(0xFF38A169);
  }

  /// Cor de erro por layout
  static Color getErrorColor(String? layoutType) {
    if (isDarkLayout(layoutType)) {
      return const Color(0xFFFF5252);
    }
    return const Color(0xFFE53E3E);
  }

  /// Cor de warning por layout
  static Color getWarningColor(String? layoutType) {
    if (isDarkLayout(layoutType)) {
      return const Color(0xFFFFD740);
    }
    return const Color(0xFFED8936);
  }

  /// Cor de card/surface por layout
  static Color getCardColor(String? layoutType) {
    switch (layoutType) {
      case 'layout_02':
        return Colors.white;
      case 'layout_03':
        return const Color(0xFFE8EEF5);
      case 'layout_04':
        return const Color(0xFF1C1C1E);
      case 'layout_05':
        return const Color(0xFF161B22);
      case 'layout_06':
      default:
        return const Color(0xFF0F1225);
    }
  }

  /// Decoração neumórfica para Layout 03
  static BoxDecoration get neumorphicDecoration => BoxDecoration(
        color: const Color(0xFFE8EEF5),
        borderRadius: BorderRadius.circular(16),
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

  /// Border color para cards
  static Color getBorderColor(String? layoutType) {
    if (isDarkLayout(layoutType)) {
      return Colors.white.withValues(alpha: 0.1);
    }
    return Colors.grey.withValues(alpha: 0.2);
  }
}
