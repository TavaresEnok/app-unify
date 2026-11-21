// ARQUIVO: lib/core/models/fatura.dart
// DESCRIÇÃO: Modelo de dados para uma única fatura com campos de pagamento.

class Fatura {
  final String numero;
  final double valor;
  final DateTime vencimento;
  final String status; // Ex: 'pago', 'pendente', 'vencido'
  final String? urlBoleto;
  final String? linhaDigitavel;
  final String? pixCopiaECola;
  final DateTime? dataPagamento;

  Fatura({
    required this.numero,
    required this.valor,
    required this.vencimento,
    required this.status,
    this.urlBoleto,
    this.linhaDigitavel,
    this.pixCopiaECola,
    this.dataPagamento,
  });

  /// Verifica se a fatura está paga
  bool get isPago => status.toLowerCase() == 'pago';

  /// Verifica se a fatura está vencida
  bool get isVencido {
    if (isPago) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(vencimento.year, vencimento.month, vencimento.day);
    return today.isAfter(dueDate);
  }

  /// Factory constructor para criar uma Fatura a partir de um JSON
  factory Fatura.fromJson(Map<String, dynamic> json) {
    final rawValue = json['valor'];
    var valueText = rawValue?.toString().trim() ?? '';
    if (valueText.contains(',')) {
      valueText = valueText.replaceAll('.', '').replaceAll(',', '.');
    }
    final value = double.tryParse(valueText);

    DateTime? parseDate(dynamic value) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) return null;
      if (text.contains('/')) {
        final parts = text.split('/');
        if (parts.length != 3) return null;
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day == null || month == null || year == null) return null;
        final date = DateTime(year, month, day);
        return date.year == year && date.month == month && date.day == day
            ? date
            : null;
      }
      return DateTime.tryParse(text);
    }

    final due = parseDate(json['vencimento'] ?? json['dataVencimento']);
    final rawStatus = json['status']?.toString().trim().toLowerCase();
    final paidFlag = json['pago'];
    final String status;
    if (rawStatus == 'pago' || rawStatus == 'paga' || rawStatus == 'paid') {
      status = 'pago';
    } else if (rawStatus == 'pendente' ||
        rawStatus == 'aberto' ||
        rawStatus == 'aberta' ||
        rawStatus == 'vencido' ||
        rawStatus == 'vencida' ||
        rawStatus == 'em aberto') {
      status = 'pendente';
    } else if ((rawStatus == null || rawStatus.isEmpty) && paidFlag is bool) {
      status = paidFlag ? 'pago' : 'pendente';
    } else {
      throw const FormatException('Situação da fatura indisponível.');
    }
    if (value == null || !value.isFinite || due == null) {
      throw const FormatException(
          'Valor ou vencimento da fatura indisponível.');
    }

    String? text(dynamic value) {
      final result = value?.toString().trim();
      return result == null || result.isEmpty ? null : result;
    }

    return Fatura(
      numero: (json['id'] ??
              json['numero'] ??
              json['nossoNumero'] ??
              json['numero_documento'] ??
              'N/A')
          .toString(),
      valor: value,
      vencimento: due,
      status: status,
      urlBoleto: text(json['url_boleto'] ?? json['urlBoleto'] ?? json['link']),
      linhaDigitavel: text(json['linha_digitavel'] ?? json['linhaDigitavel']),
      pixCopiaECola: text(json['pix_copia_cola'] ??
          json['pixCopiaECola'] ??
          json['linha_digitavel_pix'] ??
          json['codigoPix']),
      dataPagamento: parseDate(json['data_pagamento'] ?? json['dataPagamento']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numero': numero,
      'valor': valor,
      'vencimento': vencimento.toIso8601String(),
      'status': status,
      'urlBoleto': urlBoleto,
      'linhaDigitavel': linhaDigitavel,
      'pixCopiaECola': pixCopiaECola,
      'dataPagamento': dataPagamento?.toIso8601String(),
    };
  }
}
