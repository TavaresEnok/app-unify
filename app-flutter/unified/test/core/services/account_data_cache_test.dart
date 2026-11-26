import 'package:app_provedor_unified/core/services/account_data_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chave não leva o documento em claro e muda por conta', () {
    final a = AccountDataCache.keyFor('invoices',
        providerId: 'vibe', document: '12345678900', contratoId: 1);
    final b = AccountDataCache.keyFor('invoices',
        providerId: 'vibe', document: '12345678900', contratoId: 2);
    expect(a.contains('12345678900'), isFalse);
    expect(a, isNot(b));
  });

  test('grava, lê do disco em uma nova instância e apaga ao sair', () async {
    final store = MemoryAccountCacheStore();
    final key = AccountDataCache.keyFor('invoices',
        providerId: 'vibe', document: '1', contratoId: 1);
    await AccountDataCache(store: store).write(key, [
      {'numero': 'X'}
    ]);

    final fresh = AccountDataCache(store: store);
    expect(fresh.peek(key), isNull);
    final entry = await fresh.read(key);
    expect(entry!.data, [
      {'numero': 'X'}
    ]);
    expect(fresh.peek(key), isNotNull);

    store.values['outra_chave'] = 'fica';
    await fresh.clear();
    expect(await fresh.read(key), isNull);
    expect(store.values.keys, ['outra_chave']);
  });

  test('dados velhos demais são descartados', () async {
    final store = MemoryAccountCacheStore();
    final cache =
        AccountDataCache(store: store, maxAge: const Duration(days: 7));
    await cache.write('acct_cache_v1.k', [1],
        savedAt: DateTime.now().subtract(const Duration(days: 8)));
    expect(
        await AccountDataCache(store: store).read('acct_cache_v1.k'), isNull);
    expect(store.values, isEmpty);
  });

  test('conteúdo corrompido vira "sem cache"', () async {
    final store = MemoryAccountCacheStore()..values['acct_cache_v1.k'] = '{x';
    expect(
        await AccountDataCache(store: store).read('acct_cache_v1.k'), isNull);
  });

  test('consulta iniciada antes de sair da conta não regrava os dados',
      () async {
    final store = MemoryAccountCacheStore();
    final cache = AccountDataCache(store: store);
    final key = AccountDataCache.keyFor('invoices',
        providerId: 'vibe', document: '1', contratoId: 1);
    final before = cache.generation;
    await cache.clear(); // logout enquanto a consulta andava
    await cache.write(key, [1], generation: before);
    expect(cache.peek(key), isNull);
    expect(store.values, isEmpty);

    // Depois de entrar de novo, uma consulta nova grava normalmente.
    await cache.write(key, [2], generation: cache.generation);
    expect(cache.peek(key)!.data, [2]);
  });
}
