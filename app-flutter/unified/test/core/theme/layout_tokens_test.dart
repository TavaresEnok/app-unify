import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/theme/layout_tokens.dart';

void main() {
  group('LayoutTokens.of', () {
    test('classifica claros e escuros corretamente', () {
      expect(LayoutTokens.of('layout_02').isDark, isFalse);
      expect(LayoutTokens.of('layout_03').isDark, isFalse);
      expect(LayoutTokens.of('layout_04').isDark, isTrue);
      expect(LayoutTokens.of('layout_05').isDark, isTrue);
      expect(LayoutTokens.of('layout_06').isDark, isTrue);
    });

    test('só o layout_03 é neumórfico', () {
      expect(LayoutTokens.of('layout_03').isNeumorphic, isTrue);
      for (final l in ['layout_02', 'layout_04', 'layout_05', 'layout_06']) {
        expect(LayoutTokens.of(l).isNeumorphic, isFalse, reason: l);
      }
    });

    test('layout desconhecido/null cai no default (layout_06)', () {
      final fallback = LayoutTokens.of(null);
      final six = LayoutTokens.of('layout_06');
      expect(fallback.layoutType, 'layout_06');
      expect(fallback.background, six.background);
      expect(fallback.primary, six.primary);
    });

    test('texto principal é branco nos layouts escuros', () {
      expect(LayoutTokens.of('layout_04').textPrimary, Colors.white);
      expect(LayoutTokens.of('layout_02').textPrimary, isNot(Colors.white));
    });

    test('mantém os valores originais do SharedThemeHelper (sem mudar o visual)', () {
      // Ancora alguns valores conhecidos para travar regressão de cor.
      expect(LayoutTokens.of('layout_02').primary, const Color(0xFF3182CE));
      expect(LayoutTokens.of('layout_02').background, const Color(0xFFF7FAFC));
      expect(LayoutTokens.of('layout_04').primary, const Color(0xFF0891B2));
      expect(LayoutTokens.of('layout_05').background, const Color(0xFF050810));
      expect(LayoutTokens.of('layout_06').primary, const Color(0xFF00BCD4));
    });

    test('cardDecoration escolhe estilo por layout', () {
      // Neumórfico tem duas sombras (clara + escura).
      final neu = LayoutTokens.of('layout_03').cardDecoration;
      expect(neu.boxShadow, isNotNull);
      expect(neu.boxShadow!.length, 2);
      // Escuro sem sombra; claro com uma sombra sutil.
      expect(LayoutTokens.of('layout_04').cardDecoration.boxShadow, isNull);
      expect(LayoutTokens.of('layout_02').cardDecoration.boxShadow!.length, 1);
    });
  });
}
