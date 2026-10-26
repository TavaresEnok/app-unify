/// Serviço de Cache Inteligente
/// Cache com TTL (Time To Live) e suporte offline
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de entrada de cache com metadados
class CacheEntry<T> {
  final T data;
  final DateTime createdAt;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.createdAt,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;

  Map<String, dynamic> toJson(dynamic Function(T) dataToJson) => {
        'data': dataToJson(data),
        'createdAt': createdAt.toIso8601String(),
        'ttlMs': ttl.inMilliseconds,
      };

  factory CacheEntry.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) dataFromJson,
  ) {
    return CacheEntry(
      data: dataFromJson(json['data']),
      createdAt: DateTime.parse(json['createdAt']),
      ttl: Duration(milliseconds: json['ttlMs']),
    );
  }
}

/// Serviço de Cache Principal
class CacheService {
  static CacheService? _instance;
  SharedPreferences? _prefs;

  // Cache em memória para acesso rápido
  final Map<String, CacheEntry<dynamic>> _memoryCache = {};

  // Prefixo para evitar conflitos
  static const String _prefix = 'cache_';

  // TTL padrão: 5 minutos
  static const Duration defaultTTL = Duration(minutes: 5);

  // TTL para dados que mudam pouco
  static const Duration longTTL = Duration(hours: 1);

  // TTL para dados estáticos
  static const Duration staticTTL = Duration(days: 1);

  CacheService._();

  static CacheService get instance {
    _instance ??= CacheService._();
    return _instance!;
  }

  /// Inicializa o serviço de cache
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFromDisk();
  }

  /// Carrega cache do disco para memória
  Future<void> _loadFromDisk() async {
    if (_prefs == null) return;

    final keys = _prefs!.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      try {
        final jsonString = _prefs!.getString(key);
        if (jsonString != null) {
          final json = jsonDecode(jsonString);
          final entry = CacheEntry<dynamic>.fromJson(json, (d) => d);
          if (!entry.isExpired) {
            _memoryCache[key.replaceFirst(_prefix, '')] = entry;
          } else {
            // Remove entradas expiradas
            await _prefs!.remove(key);
          }
        }
      } catch (e) {
        // Ignora entradas corrompidas
        await _prefs!.remove(key);
      }
    }
  }

  /// Salva dados no cache
  Future<void> set<T>(
    String key,
    T data, {
    Duration? ttl,
    bool persistToDisk = true,
  }) async {
    final entry = CacheEntry<T>(
      data: data,
      createdAt: DateTime.now(),
      ttl: ttl ?? defaultTTL,
    );

    _memoryCache[key] = entry;

    if (persistToDisk && _prefs != null) {
      final jsonString = jsonEncode(entry.toJson((d) => d));
      await _prefs!.setString('$_prefix$key', jsonString);
    }
  }

  /// Recupera dados do cache
  T? get<T>(String key, {bool ignoreExpiry = false}) {
    final entry = _memoryCache[key];
    if (entry == null) return null;

    if (!ignoreExpiry && entry.isExpired) {
      _memoryCache.remove(key);
      _prefs?.remove('$_prefix$key');
      return null;
    }

    return entry.data as T?;
  }

  /// Recupera ou busca dados (cache-first strategy)
  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? ttl,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = get<T>(key);
      if (cached != null) return cached;
    }

    final data = await fetcher();
    await set<T>(key, data, ttl: ttl);
    return data;
  }

  /// Remove item do cache
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _prefs?.remove('$_prefix$key');
  }

  /// Limpa todo o cache
  Future<void> clear() async {
    _memoryCache.clear();
    if (_prefs != null) {
      final keys = _prefs!.getKeys().where((k) => k.startsWith(_prefix));
      for (final key in keys) {
        await _prefs!.remove(key);
      }
    }
  }

  /// Limpa apenas itens expirados
  Future<void> clearExpired() async {
    final expiredKeys = <String>[];

    _memoryCache.forEach((key, entry) {
      if (entry.isExpired) expiredKeys.add(key);
    });

    for (final key in expiredKeys) {
      await remove(key);
    }
  }

  /// Verifica se existe no cache (e não expirou)
  bool has(String key) {
    final entry = _memoryCache[key];
    return entry != null && !entry.isExpired;
  }

  /// Retorna estatísticas do cache
  Map<String, dynamic> get stats => {
        'itemCount': _memoryCache.length,
        'validItems': _memoryCache.values.where((e) => !e.isExpired).length,
        'expiredItems': _memoryCache.values.where((e) => e.isExpired).length,
      };
}

/// Chaves de cache pré-definidas
class CacheKeys {
  static const String userData = 'user_data';
  static const String invoices = 'invoices';
  static const String connectionStatus = 'connection_status';
  static const String speedTestHistory = 'speed_test_history';
  static const String providerConfig = 'provider_config';
  static const String notifications = 'notifications';
}

/// Extension para facilitar uso com Riverpod
extension CacheServiceExtension on CacheService {
  /// Cache de lista de faturas
  Future<List<Map<String, dynamic>>> getInvoices(
    Future<List<Map<String, dynamic>>> Function() fetcher, {
    bool forceRefresh = false,
  }) async {
    return getOrFetch(
      CacheKeys.invoices,
      fetcher,
      ttl: CacheService.longTTL,
      forceRefresh: forceRefresh,
    );
  }

  /// Cache de configuração do provedor
  Future<Map<String, dynamic>> getProviderConfig(
    Future<Map<String, dynamic>> Function() fetcher, {
    bool forceRefresh = false,
  }) async {
    return getOrFetch(
      CacheKeys.providerConfig,
      fetcher,
      ttl: CacheService.staticTTL,
      forceRefresh: forceRefresh,
    );
  }
}
