import 'package:flutter/material.dart';

import 'vibe_tokens.dart';

/// Estilo de texto com as medidas do CSS do layout aprovado.
///
/// [weight] é o peso do CSS (500, 650, 780…). Nas fontes variáveis o peso
/// vai exato pelo eixo `wght`, porque o Flutter não aplica [FontWeight] a
/// fonte variável. Na Inter (só pesos 400–700, como a fonte embutida da tela
/// Dock) vale a regra de escolha do navegador: acima de 500 sobe para o peso
/// disponível mais próximo. [height] é o `line-height` do CSS e
/// [letterSpacingEm] o `letter-spacing` em `em`.
TextStyle vibeText(
  VibeTokens t,
  double size,
  double weight, {
  Color? color,
  double height = 1.4,
  double letterSpacingEm = 0,
  bool tabular = true,
  FontStyle? fontStyle,
  TextDecoration? decoration,
}) {
  final variable = t.variableFamily;
  final staticWeight = variable != null
      ? weight
      : weight <= 500
          ? weight.clamp(400, 500)
          : weight <= 600
              ? 600
              : 700;
  return TextStyle(
    fontFamily: variable ?? t.fontFamily,
    fontSize: size,
    fontWeight: _nearest(staticWeight.toDouble()),
    fontVariations:
        variable == null ? null : [FontVariation('wght', weight.toDouble())],
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    color: color ?? t.ink,
    height: height,
    leadingDistribution: TextLeadingDistribution.even,
    // A tela Dock herda `letter-spacing:-.0175em` de 12 px (-0,21 px) em
    // todo texto sem espaçamento próprio.
    letterSpacing: letterSpacingEm != 0
        ? letterSpacingEm * size
        : t.dock != null
            ? -.21
            : 0,
    fontStyle: fontStyle,
    decoration: decoration,
  );
}

/// `font: 500 12px/1.5 'DM Mono'` (linha digitável e resumos copiáveis).
TextStyle vibeMono(Color color, {double size = 12}) => TextStyle(
      fontFamily: 'DMMono',
      fontSize: size,
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: color,
    );

FontWeight _nearest(double weight) {
  final index = ((weight / 100).round() - 1).clamp(0, 8);
  return FontWeight.values[index];
}
