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

    test('uses safe defaults for malformed documents', () {
      final config = ProviderConfigNormalizer.fromFirestore({
        'layoutType': 'unknown',
        'themeColor': null,
        'faq': 'invalid',
      }, 'provider-1');
      expect(config.layoutType, 'layout_06');
      expect(config.config.themeColor, '#673AB7');
      expect(config.config.faq, isEmpty);
    });
  });
}
