import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/theme/layout_tokens.dart';

void main() {
  for (final id in [
    'layout_02',
    'layout_03',
    'layout_04',
    'layout_05',
    'layout_06'
  ]) {
    test('$id text is readable on its surfaces and primary action', () {
      final t = LayoutTokens.of(id);
      for (final bg in [t.background, t.card]) {
        expect(LayoutTokens.contrast(t.textPrimary, bg),
            greaterThanOrEqualTo(4.5));
        expect(LayoutTokens.contrast(t.textSecondary, bg),
            greaterThanOrEqualTo(4.5));
      }
      expect(LayoutTokens.contrast(t.onPrimary, t.primary),
          greaterThanOrEqualTo(4.5));
      // O tema segue o layout aprovado: superfícies e marca vêm dos tokens
      // do protótipo, que também precisam ser legíveis.
      final theme = t.themeData();
      final v = t.vibe;
      expect(theme.scaffoldBackgroundColor, v.bg);
      expect(theme.colorScheme.onSurface, v.ink);
      expect(theme.primaryColor, v.ac);
      expect(LayoutTokens.contrast(v.ink, v.card), greaterThanOrEqualTo(4.5));
      expect(LayoutTokens.contrast(v.mut, v.card), greaterThanOrEqualTo(4.5));
      expect(LayoutTokens.contrast(v.on, v.ac), greaterThanOrEqualTo(4.5));
    });
  }
  test('fallback palette keeps dark surfaces and readable text together', () {
    final fallback = LayoutTokens.of(null);
    expect(fallback.isDark, isTrue);
    expect(fallback.textPrimary, Colors.white);
    expect(LayoutTokens.of('unknown').layoutType, 'layout_06');
  });
  test('arbitrary opaque brand colors keep a readable action label', () {
    for (var red = 0; red <= 255; red += 17) {
      for (var green = 0; green <= 255; green += 17) {
        for (var blue = 0; blue <= 255; blue += 17) {
          final color = Color.fromARGB(255, red, green, blue);
          expect(
              LayoutTokens.contrast(LayoutTokens.foregroundFor(color), color),
              greaterThanOrEqualTo(4.5));
        }
      }
    }
  });
}
