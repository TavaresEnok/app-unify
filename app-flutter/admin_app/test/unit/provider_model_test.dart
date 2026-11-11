import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/core/models/provider_model.dart';

// import 'package:cloud_firestore/cloud_firestore.dart';
// @GenerateNiceMocks([MockSpec<DocumentSnapshot>()])
// import 'provider_model_test.mocks.dart';

void main() {
  group('ProviderModel Tests', () {
    final testDate = DateTime(2025, 12, 12);
    final provider = ProviderModel(
      id: '123',
      name: 'Test Provider',
      logoUrl: 'http://example.com/logo.png',
      themeColor: '#FFFFFF',
      apiUrl: 'http://api.example.com',
      active: true,
      createdAt: testDate,
      details: {'address': 'Street 1'},
      features: {'feature1': true},
      notifications: {'push': true},
      appConfig: {'version': '1.0.0'},
    );

    test('toMap serializes correctly', () {
      final map = provider.toMap();

      expect(map['name'], 'Test Provider');
      expect(map['logoUrl'], 'http://example.com/logo.png');
      expect(map['themeColor'], '#FFFFFF');
      expect(map['apiUrl'], 'http://api.example.com');
      expect(map['active'], true);
      expect(map['details'], {'address': 'Street 1'});
      expect(map['features'], {'feature1': true});
      // createdAt is not in toMap based on previous read, let's verify
    });

    test('copyWith creates a new instance with updated fields', () {
      final updated = provider.copyWith(name: 'New Name', active: false);

      expect(updated.id, provider.id);
      expect(updated.name, 'New Name');
      expect(updated.active, false);
      expect(updated.apiUrl, provider.apiUrl);
      expect(updated.createdAt, provider.createdAt);
    });

    test('copyWith with nulls should not update fields', () {
      // copyWith implementation usually ignores nulls if argument is optional and defaults to null
      // looking at ProviderModel: name: name ?? this.name
      // so passing null doesn't clear provided, good.
      final same = provider.copyWith();
      expect(same.name, provider.name);
    });
  });

  test('toSaveMap envia id e só campos aceitos pela API', () {
    final provider = ProviderModel(
      id: 'vibe',
      name: 'Vibe Telecom',
      apiUrl: 'http://10.0.0.5:8034',
      themeColor: '#112233',
      details: {
        'city': 'Fortaleza',
        'systemType': 'SGP',
        'apiToken': 'synthetic-secret',
        'systemUrl': 'https://sgp.example',
        'appName': 'Vibe',
        'hasAndroidApp': true,
      },
      features: {'invoices': true, 'unlock': true, 'support': 'sim'},
      notifications: {'list': [], 'legacy': 1},
      appConfig: {
        'themeColor': '#112233',
        'apiUrl': 'http://10.0.0.5:8034',
        'details': {'apiToken': 'synthetic-secret'},
        'integrations': {'apiToken': 'synthetic-secret'},
        'updatedAt': '2026-11-11',
        'faq': [],
        'strings': {'hello_prefix': 'Oi', 'layoutThemes': '{}'},
      },
    );

    final body = provider.toSaveMap();

    expect(body['id'], 'vibe');
    expect(body['details'], {'city': 'Fortaleza', 'systemType': 'SGP'});
    expect(body['features'], {'invoices': true});
    expect(body['notifications'], {'list': []});
    expect(body['config'], {
      'themeColor': '#112233',
      'faq': [],
      'strings': {'hello_prefix': 'Oi'},
    });
    expect(body.containsKey('apiUrl'), isFalse);
    expect(body.toString(), isNot(contains('synthetic-secret')));
    expect(body.toString(), isNot(contains('sgp.example')));
  });
}
