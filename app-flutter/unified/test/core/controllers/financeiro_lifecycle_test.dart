import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/services/financeiro_service.dart';
import 'package:app_provedor_unified/core/providers/financeiro_provider.dart';

class DeferredInvoices extends FinanceiroService {
  DeferredInvoices()
      : super(
            apiUrl: 'https://example.invalid',
            cpfCnpjUnformatted: 'demo',
            providerId: 'demo');
  final result = Completer<List<dynamic>>();
  int requests = 0;
  @override
  Future<List<dynamic>> fetchInvoices() {
    requests++;
    return result.future;
  }
}

void main() {
  test(
      'navigation shares in-flight invoices and leaving the session does not notify a disposed provider',
      () async {
    final service = DeferredInvoices();
    final provider = FinanceiroProvider(service);
    final first = provider.fetchHistory();
    final second = provider.fetchHistory();
    expect(identical(first, second), true);
    expect(service.requests, 1);
    provider.dispose();
    service.result.complete([]);
    await first;
  });
}
