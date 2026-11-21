import 'dart:ui' show Color;

/// Um traço de ícone do layout aprovado, no formato do SVG original.
///
/// `d` usa a sintaxe de path do SVG. Nos ícones (24×24) o padrão é traço
/// arredondado sem preenchimento, como na classe `.ic` do protótipo; nas
/// ilustrações das ofertas (120×120) cada parte informa o que desenha.
class VibeIconPart {
  const VibeIconPart(
    this.d, {
    this.fill = false,
    this.stroke = true,
    this.strokeWidth,
    this.opacity,
    this.color,
    this.roundCap = true,
  });

  final String d;
  final bool fill;
  final bool stroke;
  final double? strokeWidth;
  final double? opacity;
  final Color? color;
  final bool roundCap;
}
