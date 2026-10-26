import 'package:flutter/material.dart';
import '../theme/layout_tokens.dart';

/// Helper de cores por layout, mantido por compatibilidade.
///
/// A fonte da verdade agora é [LayoutTokens]; todos os métodos abaixo apenas
/// delegam a ela (mesmos valores de antes). Telas novas devem ler
/// `LayoutTokens.of(layoutType)` diretamente; este helper existe para não exigir
/// a migração de todos os call-sites de uma vez.
class SharedThemeHelper {
  static Color getBackgroundColor(String? layoutType) =>
      LayoutTokens.of(layoutType).background;

  static bool isDarkLayout(String? layoutType) =>
      LayoutTokens.of(layoutType).isDark;

  static bool isNeumorphic(String? layoutType) =>
      LayoutTokens.of(layoutType).isNeumorphic;

  static Color getPrimaryColor(String? layoutType) =>
      LayoutTokens.of(layoutType).primary;

  static Color getTextColor(String? layoutType) =>
      LayoutTokens.of(layoutType).textPrimary;

  static Color getTextGreyColor(String? layoutType) =>
      LayoutTokens.of(layoutType).textSecondary;

  static Color getSuccessColor(String? layoutType) =>
      LayoutTokens.of(layoutType).success;

  static Color getErrorColor(String? layoutType) =>
      LayoutTokens.of(layoutType).error;

  static Color getWarningColor(String? layoutType) =>
      LayoutTokens.of(layoutType).warning;

  static Color getCardColor(String? layoutType) =>
      LayoutTokens.of(layoutType).card;

  static Color getBorderColor(String? layoutType) =>
      LayoutTokens.of(layoutType).border;

  /// Decoração neumórfica (layout_03). Mantida com o valor fixo original.
  static BoxDecoration get neumorphicDecoration =>
      LayoutTokens.of('layout_03').neumorphicDecoration;
}
