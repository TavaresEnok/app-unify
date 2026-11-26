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

  /// Dia do mês em que o contrato vence: "20/11/2026", "Vence em 6/11/2026",
  /// "2026-11-06", "Dia 9" ou "9" → 20 / 6 / 6 / 9 / 9. Nulo quando o texto
  /// não traz uma data.
  static int? dueDayOf(String value) {
    final match = RegExp(r'^\s*(?:dia\s*)?(\d{1,2})\s*$', caseSensitive: false)
            .firstMatch(value) ??
        RegExp(r'(?<!\d)(\d{1,2})/\d{1,2}(?:/\d{2,4})?(?!\d)')
            .firstMatch(value) ??
        RegExp(r'\d{4}-\d{2}-(\d{2})').firstMatch(value);
    final day = int.tryParse(match?.group(1) ?? '');
    return day == null || day < 1 || day > 31 ? null : day;
  }

  /// Primeira data com o dia [day] depois de [after] (dia 31 em mês curto
  /// vira o último dia do mês).
  static DateTime nextDue(int day, DateTime after) {
    for (var i = 0; i < 3; i++) {
      final first = DateTime(after.year, after.month + i);
      final last = DateTime(first.year, first.month + 1, 0).day;
      final date = DateTime(first.year, first.month, day > last ? last : day);
      if (date.isAfter(DateTime(after.year, after.month, after.day))) {
        return date;
      }
    }
    return DateTime(after.year, after.month + 1, day);
  }

  /// "Hoje, 08:00", "Ontem, 19:12" ou "12/11, 08:40".
  static String when(DateTime value, {DateTime? now}) {
    final local = value.toLocal(), today = now ?? DateTime.now();
    final days = DateTime(today.year, today.month, today.day)
        .difference(DateTime(local.year, local.month, local.day))
        .inDays;
    String two(int n) => n.toString().padLeft(2, '0');
    final time = '${two(local.hour)}:${two(local.minute)}';
    final day = days == 0
        ? 'Hoje'
        : days == 1
            ? 'Ontem'
            : '${two(local.day)}/${two(local.month)}'
                '${local.year == today.year ? '' : '/${local.year}'}';
    return '$day, $time';
  }

  static String decimal(num value, {int digits = 2}) =>
      NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: digits)
          .format(value);

  static const _minor = {'de', 'da', 'do', 'das', 'dos', 'e'};

  /// Texto vindo do sistema do provedor em forma legível: sublinhados viram
  /// espaços e, se tudo estiver em maiúsculas, só as iniciais ficam
  /// maiúsculas ("FIBRA_500MB_RESIDENCIAL" → "Fibra 500MB Residencial").
  /// Palavras com números (500MB, 5G) e textos já em caixa mista ficam
  /// como vieram.
  static String label(String? value) {
    final text = (value ?? '')
        .replaceAll('_', ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty || text != text.toUpperCase()) return text;
    final words = text.split(' ');
    return [
      for (var i = 0; i < words.length; i++)
        if (RegExp(r'\d').hasMatch(words[i]))
          words[i]
        else if (i > 0 && _minor.contains(words[i].toLowerCase()))
          words[i].toLowerCase()
        else
          words[i][0] + words[i].substring(1).toLowerCase(),
    ].join(' ');
  }

  /// Nome de pessoa em forma legível ("MARINA COSTA DE OLIVEIRA" → "Marina
  /// Costa de Oliveira"); nomes já em caixa mista ficam como vieram.
  static String personName(String? value) => label(value);
}
