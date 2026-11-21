import 'package:intl/intl.dart';

/// Formatting at the presentation boundary; API numbers keep their precision.
abstract final class AppFormatters {
  static final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _date = DateFormat('dd/MM/yyyy', 'pt_BR');

  static String currency(Object? value) {
    num? amount;
    if (value is num) {
      amount = value;
    } else if (value is String) {
      var normalized = value.replaceAll(RegExp(r'[^0-9,.\-]'), '');
      if (normalized.contains(',')) {
        normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
      }
      amount = num.tryParse(normalized);
    }
    if (amount == null || !amount.isFinite) return 'Valor indisponível';
    return _money.format(amount);
  }

  static String date(DateTime value) => _date.format(value);
  static String decimal(num value, {int digits = 2}) =>
      NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: digits)
          .format(value);
}
