import 'provider_config.dart';

class ProviderConfigNormalizer {
  static const supportedLayouts = {
    'layout_02',
    'layout_03',
    'layout_04',
    'layout_05',
    'layout_06',
  };

  static ProviderConfig fromFirestore(
    Map<String, dynamic>? raw,
    String providerId,
  ) {
    final root = _stringMap(raw);
    final legacy = _stringMap(root['config']);
    final normalized = <String, dynamic>{...legacy, ...root};
    normalized.remove('config');
    final layout = normalized['layoutType'];
    normalized['layoutType'] =
        layout is String && supportedLayouts.contains(layout)
            ? layout
            : 'layout_06';
    normalized['themeColor'] = _color(normalized['themeColor'], '#673AB7');
    normalized['secondaryColor'] =
        _color(normalized['secondaryColor'], '#9575CD');
    normalized['features'] = _stringMap(normalized['features']);
    normalized['menuConfig'] = _stringMap(normalized['menuConfig']);
    normalized['integrations'] = _stringMap(normalized['integrations']);
    normalized['strings'] = _stringMap(normalized['strings']);
    normalized['faq'] = _list(normalized['faq']);
    normalized['tips'] = _list(normalized['tips'] ?? normalized['dicas']);
    normalized['supportContacts'] = _list(normalized['supportContacts']);
    normalized['imageCarousel'] = _list(normalized['imageCarousel']);
    return ProviderConfig.fromJson(normalized, providerId);
  }

  static Map<String, dynamic> _stringMap(dynamic value) {
    if (value is! Map) return <String, dynamic>{};
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static List<dynamic> _list(dynamic value) =>
      value is List ? List<dynamic>.from(value) : <dynamic>[];

  static String _color(dynamic value, String fallback) {
    if (value is String &&
        RegExp(r'^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$').hasMatch(value)) {
      return value;
    }
    return fallback;
  }
}
