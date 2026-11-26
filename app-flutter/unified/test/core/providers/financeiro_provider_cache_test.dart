import 'dart:async';

import 'package:app_provedor_unified/core/providers/financeiro_provider.dart';
import 'package:app_provedor_unified/core/services/account_data_cache.dart';
import 'package:app_provedor_unified/core/services/api_response.dart';
import 'package:app_provedor_unified/core/services/financeiro_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _Service extends FinanceiroService {
  _Service()
      : super(
            apiUrl: 'https://example.invalid/get-invoices',
            cpfCnpjUnformatted: '00000000000',
            providerId: 'demo',
            contratoId: 1);
  final calls = <Completer<List<dynamic>>>[];
  @override
  Future<List<dynamic>> fetchInvoices() {
    final c = Completer<List<dynamic>>();
    calls.add(c);
    return c.future;
  }
}

List<dynamic> invoices(double valor) => [
      {
        'numero': 'INV-1',
        'valor': valor,
        'vencimento': '2030-01-10',
        'status': 'aberto',
        'pixCopiaECola': '000201',
      }
    ];

void main() {
  test('abre com as faturas guardadas e atualiza por trás', () async {
    final service = _Service();
    final cache = AccountDataCache(store: MemoryAccountCacheStore());
    await cache.write(service.cacheKey, invoices(99.9),
        savedAt: DateTime.now().subtract(const Duration(hours: 1)));
    final provider = FinanceiroProvider(service, cache: cache);

    final done = provider.fetchHistory();
    // Memória: disponível antes da resposta do provedor.
    expect(provider.hasResult, isTrue);
    expect(provider.invoices.single.valor, 99.9);
    expect(provider.refreshing, isTrue);
    expect(provider.isStale, isTrue);

    await Future<void>.delayed(Duration.zero);
    service.calls.single.complete(invoices(120));
    await done;
    expect(provider.state, FinanceiroState.success);
    expect(provider.invoices.single.valor, 120);
    expect(provider.isStale, isFalse);
    expect((await cache.read(service.cacheKey))!.data, invoices(120));
  });

  test('atualização que falha não apaga as faturas da tela', () async {
    final service = _Service();
    final provider = FinanceiroProvider(service,
        cache: AccountDataCache(store: MemoryAccountCacheStore()));

    final first = provider.fetchHistory();
    expect(provider.hasResult, isFalse); // primeira vez: esqueleto
    await Future<void>.delayed(Duration.zero);
    service.calls.single.complete(invoices(120));
    await first;

    final second = provider.fetchHistory();
    await Future<void>.delayed(Duration.zero);
    service.calls.last.completeError(ApiException(502, 'fora do ar'));
    await second;
    expect(provider.state, FinanceiroState.error);
    expect(provider.invoices.single.valor, 120);
    expect(provider.isStale, isTrue);
    expect(provider.lastError, isNotNull);
  });

  test('sem dados e com erro: nada para mostrar', () async {
    final service = _Service();
    final provider = FinanceiroProvider(service,
        cache: AccountDataCache(store: MemoryAccountCacheStore()));
    final done = provider.fetchHistory();
    await Future<void>.delayed(Duration.zero);
    service.calls.single.completeError(ApiException(502, 'x'));
    await done;
    expect(provider.hasResult, isFalse);
    expect(provider.lastError, isNull);
    expect(provider.state, FinanceiroState.error);
  });

  test('falhas passageiras ganham uma segunda tentativa', () {
    expect(FinanceiroService.isTransientFailure(TimeoutException('t')), isTrue);
    expect(FinanceiroService.isTransientFailure(ApiException(502, 'x')), isTrue);
    expect(
        FinanceiroService.isTransientFailure(ApiException(403, 'x')), isFalse);
    expect(FinanceiroService.isTransientFailure(Exception('CPF inválido')),
        isFalse);
  });
}
