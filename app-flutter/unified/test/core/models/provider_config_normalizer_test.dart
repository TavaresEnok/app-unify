import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/models/provider_config_normalizer.dart';

void main() {
  group('ProviderConfigNormalizer', () {
    test('supports current and legacy provider documents', () {
      final config = ProviderConfigNormalizer.fromFirestore({
        'layoutType': 'layout_04',
        'themeColor': '#111111',
        'config': {'layoutType': 'layout_02', 'themeColor': '#222222'},
      }, 'provider-1');
      expect(config.layoutType, 'layout_04');
      expect(config.config.themeColor, '#111111');
    });

    test('preserves logo framing and bounds invalid numeric settings', () {
      final config = ProviderConfigNormalizer.fromFirestore({
        'logoUrl': 'https://example.test/logo.png',
        'logoFraming': {
          'shape': 'wide',
          'fit': 'cover',
          'zoom': 6,
          'x': -7,
          'y': 35
        },
      }, 'provider-1')
          .config;
      expect(config.logoUrl, 'https://example.test/logo.png');
      expect(config.logoFraming.toJson(),
          {'shape': 'wide', 'fit': 'cover', 'zoom': 3, 'x': 0, 'y': 35});
    });

    test('uses safe defaults for malformed documents', () {
      final config = ProviderConfigNormalizer.fromFirestore({
        'layoutType': 'unknown',
        'themeColor': null,
        'faq': 'invalid',
      }, 'provider-1');
      expect(config.layoutType, 'layout_06');
      expect(config.config.themeColor, '#2456C9');
      expect(config.config.faq, isEmpty);
    });
  });
}
