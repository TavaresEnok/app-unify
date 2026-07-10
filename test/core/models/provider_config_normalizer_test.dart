import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/models/provider_config_normalizer.dart';

void main() {
  group('ProviderConfigNormalizer', () {
    test('creates a complete config from an empty document', () {
      final config = ProviderConfigNormalizer.fromFirestore({}, 'provider-1');
      expect(config.id, 'provider-1');
      expect(config.layoutType, 'layout_06');
      expect(config.config.themeColor, '#673AB7');
      expect(config.features.consumption, isTrue);
      expect(config.features.support, isTrue);
    });

    test('prefers current root fields over legacy config fields', () {
      final config = ProviderConfigNormalizer.fromFirestore({
        'themeColor': '#111111',
        'layoutType': 'layout_04',
        'config': {'themeColor': '#222222', 'layoutType': 'layout_02'},
      }, 'provider-1');
      expect(config.layoutType, 'layout_04');
      expect(config.config.themeColor, '#111111');
    });

    test('falls back for malformed values without throwing', () {
      final config = ProviderConfigNormalizer.fromFirestore({
        'layoutType': 'unknown',
        'themeColor': 'invalid',
        'faq': 'invalid',
      }, 'provider-1');
      expect(config.layoutType, 'layout_06');
      expect(config.config.themeColor, '#673AB7');
      expect(config.config.faq, isEmpty);
    });
  });
}
