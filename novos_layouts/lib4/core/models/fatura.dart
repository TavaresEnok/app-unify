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
    final valorString =
        (json['valor'] ?? '0.0').toString().replaceAll(',', '.');

    DateTime? parseDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) return null;
      try {
        // Tenta formatos diferentes: yyyy-MM-dd e dd/MM/yyyy
        if (dateString.contains('-')) {
          return DateTime.parse(dateString);
        } else if (dateString.contains('/')) {
          final parts = dateString.split('/');
          return DateTime(
              int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (e) {
        return null;
      }
      return null;
    }

    return Fatura(
      numero:
          json['id']?.toString() ?? json['nossoNumero']?.toString() ?? 'N/A',
      valor: double.tryParse(valorString) ?? 0.0,
      vencimento: parseDate(json['vencimento'] ?? json['dataVencimento']) ??
          DateTime.now(),
      status: json['status'] != null
          ? json['status'].toString()
          : ((json['pago'] as bool? ?? false) ? 'pago' : 'pendente'),
      urlBoleto: json['link'] as String?,
      linhaDigitavel: json['linha_digitavel'] as String?,
      pixCopiaECola: json['pix_copia_cola'] as String?,
      dataPagamento: parseDate(json['dataPagamento']),
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
