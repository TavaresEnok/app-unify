import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/models/provider_config.dart';

void main() {
  test('promotions honor enabled, active status and inclusive date range', () {
    final config = PromotionsConfig.fromJson(const {
      'enabled': true,
      'items': [
        {
          'id': 'active',
          'title': 'Oferta',
          'status': 'active',
          'startDate': '2026-11-19',
          'endDate': '2026-11-19'
        },
        {'id': 'future', 'title': 'Futura', 'startDate': '2026-11-20'},
        {'id': 'draft', 'title': 'Rascunho', 'status': 'draft'},
        {'id': 'off', 'title': 'Inativa', 'active': false},
      ],
    });
    final today = DateTime(2026, 11, 19, 23, 59);
    expect(
        config.items
            .where((item) => item.isActiveAt(today))
            .map((item) => item.id),
        ['active']);
    expect(
        PromotionsConfig.fromJson(
                {'enabled': false, 'items': config.toJson()['items']})
            .activePromotions,
        isEmpty);
  });
}
