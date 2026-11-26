import 'package:flutter/material.dart';

import 'vibe_icon_data.dart';
import 'vibe_icon_part.dart';
import 'vibe_tokens.dart';

/// Ícone de traço do layout aprovado (`<svg class="ic">` no protótipo).
///
/// [strokeWidth] está na unidade do desenho (viewBox 24), como o
/// `stroke-width` do CSS: escala junto com o tamanho do ícone.
class VibeIcon extends StatelessWidget {
  const VibeIcon(
    this.name, {
    super.key,
    this.size = 20,
    this.color,
    this.strokeWidth = 1.8,
    this.semanticLabel,
  });

  final String name;
  final double size;
  final Color? color;
  final double strokeWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final parts = vibeIconData[name] ?? const <VibeIconPart>[];
    // Estilo dos ícones do provedor (fino, padrão ou forte).
    final weight = Theme.of(context).extension<VibeTokens>()?.iconWeight ?? 1;
    final paint = CustomPaint(
      size: Size.square(size),
      painter: _VibePartsPainter(
        parts: parts,
        color: color ?? IconTheme.of(context).color ?? const Color(0xFF000000),
        viewBox: 24,
        strokeWidth: strokeWidth * weight,
      ),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: paint)
        : Semantics(label: semanticLabel, child: paint);
  }
}

/// Ilustração dos cartões de oferta (`PRI` no protótipo, viewBox 120).
class VibeArt extends StatelessWidget {
  const VibeArt(this.name, {super.key, this.size = 124, required this.color});

  final String name;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(size),
          painter: _VibePartsPainter(
            parts: vibeArtData[name] ?? const <VibeIconPart>[],
            color: color,
            viewBox: 120,
            strokeWidth: 1,
          ),
        ),
      );
}

class _VibePartsPainter extends CustomPainter {
  _VibePartsPainter({
    required this.parts,
    required this.color,
    required this.viewBox,
    required this.strokeWidth,
  });

  final List<VibeIconPart> parts;
  final Color color;
  final double viewBox;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / viewBox;
    canvas.save();
    canvas.scale(scale);
    for (final part in parts) {
      final path = VibePathParser.parse(part.d);
      final base = part.color ?? color;
      final tone = part.opacity == null
          ? base
          : base.withValues(alpha: base.a * part.opacity!);
      if (part.fill) {
        canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.fill
              ..isAntiAlias = true
              ..color = tone);
      }
      if (part.stroke) {
        canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..isAntiAlias = true
              ..strokeWidth = part.strokeWidth ?? strokeWidth
              ..strokeCap = part.roundCap ? StrokeCap.round : StrokeCap.butt
              ..strokeJoin = StrokeJoin.round
              ..color = tone);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_VibePartsPainter old) =>
      old.parts != parts ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.viewBox != viewBox;
}

/// Leitor da sintaxe de path do SVG (M L H V C S Q T A Z, absolutos e
/// relativos). Os caminhos são lidos uma vez e reaproveitados.
class VibePathParser {
  VibePathParser._(this._d);

  static final Map<String, Path> _cache = {};

  static Path parse(String d) =>
      _cache.putIfAbsent(d, () => VibePathParser._(d)._run());

  final String _d;
  int _i = 0;

  static bool _isCommand(int c) => 'MmLlHhVvCcSsQqTtAaZz'.codeUnits.contains(c);

  void _skip() {
    while (_i < _d.length) {
      final c = _d.codeUnitAt(_i);
      if (c == 32 || c == 44 || c == 9 || c == 10 || c == 13) {
        _i++;
      } else {
        break;
      }
    }
  }

  double _number() {
    _skip();
    final start = _i;
    if (_i < _d.length && (_d[_i] == '-' || _d[_i] == '+')) _i++;
    var dot = false, exp = false;
    while (_i < _d.length) {
      final ch = _d[_i];
      final c = ch.codeUnitAt(0);
      if (c >= 48 && c <= 57) {
        _i++;
      } else if (ch == '.' && !dot && !exp) {
        dot = true;
        _i++;
      } else if ((ch == 'e' || ch == 'E') && !exp) {
        exp = true;
        _i++;
        if (_i < _d.length && (_d[_i] == '-' || _d[_i] == '+')) _i++;
      } else {
        break;
      }
    }
    return double.parse(_d.substring(start, _i));
  }

  bool _flag() {
    _skip();
    final value = _d[_i] == '1';
    _i++;
    return value;
  }

  Path _run() {
    final path = Path();
    var command = '';
    double x = 0, y = 0, startX = 0, startY = 0;
    double? cubicX, cubicY, quadX, quadY;
    while (true) {
      _skip();
      if (_i >= _d.length) break;
      final c = _d.codeUnitAt(_i);
      if (_isCommand(c)) {
        command = _d[_i];
        _i++;
      } else if (command == 'M') {
        command = 'L';
      } else if (command == 'm') {
        command = 'l';
      } else if (command.isEmpty || command == 'Z' || command == 'z') {
        break;
      }
      final rel = command.toLowerCase() == command;
      final ox = rel ? x : 0.0, oy = rel ? y : 0.0;
      double? nextCubicX, nextCubicY, nextQuadX, nextQuadY;
      switch (command.toUpperCase()) {
        case 'M':
          x = ox + _number();
          y = oy + _number();
          path.moveTo(x, y);
          startX = x;
          startY = y;
        case 'L':
          x = ox + _number();
          y = oy + _number();
          path.lineTo(x, y);
        case 'H':
          x = ox + _number();
          path.lineTo(x, y);
        case 'V':
          y = oy + _number();
          path.lineTo(x, y);
        case 'C':
          final x1 = ox + _number(), y1 = oy + _number();
          final x2 = ox + _number(), y2 = oy + _number();
          x = ox + _number();
          y = oy + _number();
          path.cubicTo(x1, y1, x2, y2, x, y);
          nextCubicX = x2;
          nextCubicY = y2;
        case 'S':
          final x1 = cubicX == null ? x : 2 * x - cubicX;
          final y1 = cubicY == null ? y : 2 * y - cubicY;
          final x2 = ox + _number(), y2 = oy + _number();
          x = ox + _number();
          y = oy + _number();
          path.cubicTo(x1, y1, x2, y2, x, y);
          nextCubicX = x2;
          nextCubicY = y2;
        case 'Q':
          final x1 = ox + _number(), y1 = oy + _number();
          x = ox + _number();
          y = oy + _number();
          path.quadraticBezierTo(x1, y1, x, y);
          nextQuadX = x1;
          nextQuadY = y1;
        case 'T':
          final x1 = quadX == null ? x : 2 * x - quadX;
          final y1 = quadY == null ? y : 2 * y - quadY;
          x = ox + _number();
          y = oy + _number();
          path.quadraticBezierTo(x1, y1, x, y);
          nextQuadX = x1;
          nextQuadY = y1;
        case 'A':
          final rx = _number().abs(), ry = _number().abs();
          final rotation = _number();
          final large = _flag(), sweep = _flag();
          x = ox + _number();
          y = oy + _number();
          if (rx == 0 || ry == 0) {
            path.lineTo(x, y);
          } else {
            path.arcToPoint(Offset(x, y),
                radius: Radius.elliptical(rx, ry),
                rotation: rotation,
                largeArc: large,
                clockwise: sweep);
          }
        case 'Z':
          path.close();
          x = startX;
          y = startY;
      }
      cubicX = nextCubicX;
      cubicY = nextCubicY;
      quadX = nextQuadX;
      quadY = nextQuadY;
    }
    return path;
  }
}
