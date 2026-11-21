import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/utils/app_formatters.dart';

void main() {
  test('money preserves cents and handles API and localized representations',
      () {
    for (final value in [99.9, '99.90', '99,90', 'R\$ 99,90']) {
      expect(
          AppFormatters.currency(value).replaceAll('\u00a0', ' '), 'R\$ 99,90');
    }
    expect(AppFormatters.currency('1.234,56').replaceAll('\u00a0', ' '),
        'R\$ 1.234,56');
  });
  test('missing or invalid amounts are not shown as zero', () {
    for (final value in [
      null,
      '',
      'indisponível',
      double.nan,
      double.infinity
    ]) {
      expect(AppFormatters.currency(value), 'Valor indisponível');
    }
  });
  test('data volumes use a Brazilian decimal separator', () {
    expect(AppFormatters.decimal(125.4), '125,40');
  });
}
