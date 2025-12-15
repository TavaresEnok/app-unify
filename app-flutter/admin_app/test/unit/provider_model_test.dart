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
}
