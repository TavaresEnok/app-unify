import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Últimos dados que o assinante já viu (faturas, consumo), guardados no
/// armazenamento privado do app para a tela abrir com eles na hora e
/// atualizar por trás ("stale-while-revalidate").
///
/// - Chave por provedor + contrato + hash do documento (o CPF não vai em
///   claro para a chave).
/// - No Android, EncryptedSharedPreferences (igual à sessão).
/// - Vale por 7 dias; apagado inteiro ao sair da conta.
/// - Qualquer falha de leitura ou escrita vira "sem cache": nunca quebra a
///   tela.
class AccountDataCache {
  AccountDataCache({AccountCacheStore? store, Duration? maxAge})
      : _store = store ?? SecureAccountCacheStore(),
        maxAge = maxAge ?? const Duration(days: 7);

  static AccountDataCache instance = AccountDataCache();

  static const _prefix = 'acct_cache_v1.';

  final AccountCacheStore _store;
  final Duration maxAge;

  /// Espelho em memória: um provider recriado na mesma sessão (troca de
  /// aba, refresh de config) já nasce com os dados, sem esperar o disco.
  final Map<String, CachedEntry> _memory = {};

  /// Muda a cada [clear] (saída da conta). Uma consulta que começou antes
  /// da saída passa o valor que leu em [write] e não regrava os dados da
  /// conta que já saiu.
  int _generation = 0;
  int get generation => _generation;

  static String keyFor(String kind,
      {required String providerId,
      required String document,
      int? contratoId,
      String? extra}) {
    final digest = sha256
        .convert(utf8.encode('$providerId|${contratoId ?? ''}|$document'))
        .toString()
        .substring(0, 32);
    return '$_prefix$kind.$digest${extra == null ? '' : '.$extra'}';
  }

  /// Leitura síncrona do que já está em memória.
  CachedEntry? peek(String key) {
    final entry = _memory[key];
    if (entry == null) return null;
    if (_expired(entry)) {
      _memory.remove(key);
      return null;
    }
    return entry;
  }

  Future<CachedEntry?> read(String key) async {
    final hot = peek(key);
    if (hot != null) return hot;
    try {
      final raw = await _store.read(key);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final savedAt = DateTime.tryParse('${json['savedAt']}');
      if (savedAt == null) return null;
      final entry = CachedEntry(json['data'], savedAt);
      if (_expired(entry)) {
        await _store.delete(key);
        return null;
      }
      return _memory[key] = entry;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, Object? data,
      {DateTime? savedAt, int? generation}) async {
    final gen = generation ?? _generation;
    if (gen != _generation) return;
    final entry = CachedEntry(data, savedAt ?? DateTime.now());
    _memory[key] = entry;
    try {
      await _store.write(
          key,
          jsonEncode(
              {'savedAt': entry.savedAt.toIso8601String(), 'data': data}));
      // A conta saiu enquanto gravava: não deixa o dado para trás.
      if (gen != _generation) {
        _memory.remove(key);
        await _store.delete(key);
      }
    } catch (_) {
      // Sem disco, segue só em memória nesta sessão.
    }
  }

  /// Ao sair da conta: some tudo, da memória e do disco.
  Future<void> clear() async {
    _generation++;
    _memory.clear();
    try {
      await _store.deleteWhere((key) => key.startsWith(_prefix));
    } catch (_) {}
  }

  bool _expired(CachedEntry entry) =>
      DateTime.now().difference(entry.savedAt) > maxAge;
}

class CachedEntry {
  CachedEntry(this.data, this.savedAt);
  final Object? data;
  final DateTime savedAt;
}

abstract class AccountCacheStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteWhere(bool Function(String key) test);
}

class SecureAccountCacheStore implements AccountCacheStore {
  SecureAccountCacheStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteWhere(bool Function(String key) test) async {
    final all = await _storage.readAll();
    for (final key in all.keys.where(test)) {
      await _storage.delete(key: key);
    }
  }
}

/// Armazenamento em memória (testes e ambientes sem disco seguro).
class MemoryAccountCacheStore implements AccountCacheStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> deleteWhere(bool Function(String key) test) async =>
      values.removeWhere((key, _) => test(key));
}
