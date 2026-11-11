import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/provider_config.dart';
import '../models/provider_config_normalizer.dart';
import '../services/provider_config_api.dart';

typedef ProviderDocumentLoader = Future<Map<String, dynamic>?> Function(
    String providerId);

class ConfigurationProvider with ChangeNotifier {
  ConfigurationProvider({
    ProviderConfigApi? api,
    String apiBaseUrl = ProviderConfigApi.compiledBaseUrl,
    ProviderDocumentLoader? firestoreLoader,
  })  : _api = api ?? ProviderConfigApi(),
        _apiBaseUrl = apiBaseUrl,
        _firestoreLoader = firestoreLoader ?? _loadFromFirestore;

  final ProviderConfigApi _api;
  final String _apiBaseUrl;
  final ProviderDocumentLoader _firestoreLoader;

  ProviderConfig? _providerConfig;
  bool _isLoading = true;
  String? _errorMessage;

  ProviderConfig? get providerConfig => _providerConfig;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Retorna uma string dinâmica da configuração ou o valor padrão
  String getString(String key, String defaultValue) {
    if (_providerConfig == null) return defaultValue;
    final val = _providerConfig!.config.strings[key];
    if (val is String && val.isNotEmpty) return val;
    return defaultValue;
  }

  /// Retorna uma lista de strings dinâmica ou o valor padrão
  List<String> getStringList(String key, List<String> defaultValue) {
    if (_providerConfig == null) return defaultValue;
    final val = _providerConfig!.config.strings[key];
    if (val is List) return List<String>.from(val);
    return defaultValue;
  }

  /// Método para carregar a configuração de forma assíncrona.
  Future<void> loadConfig(String providerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 1. Tenta carregar do cache local primeiro
    await _loadFromCache(providerId);

    try {
      // 2. Busca do servidor: primeiro a API (configuração sanitizada); o
      // Firestore direto fica como fallback para builds sem URL gravada e
      // enquanto as regras antigas ainda estiverem publicadas.
      var safeData = await _loadFromApi(providerId);
      safeData ??= await _firestoreLoader(providerId);

      if (safeData != null) {
        _providerConfig =
            ProviderConfigNormalizer.fromFirestore(safeData, providerId);

        // 3. Atualiza o cache
        await _saveToCache(providerId, safeData);
        debugPrint("✅ Configuração '$providerId' atualizada do servidor.");
      } else {
        if (_providerConfig == null) {
          _errorMessage = "Provedor com ID '$providerId' não encontrado.";
        }
        debugPrint("❌ ERRO: Provedor não encontrado no servidor.");
      }
    } catch (e) {
      if (_providerConfig == null) {
        _errorMessage = "Erro de conexão e sem cache local: $e";
      }
      debugPrint(
          "⚠️ Aviso: Usando versão em cache devido a erro de conexão: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tenta a URL gravada no build e, depois, a última `apiUrl` conhecida (do
  /// cache), para apps que ainda não foram reconstruídos com a URL.
  Future<Map<String, dynamic>?> _loadFromApi(String providerId) async {
    final candidates = <String>{
      if (_apiBaseUrl.trim().isNotEmpty) _apiBaseUrl.trim(),
      if (_providerConfig?.apiUrl.trim().isNotEmpty == true)
        _providerConfig!.apiUrl.trim(),
    };
    for (final base in candidates) {
      final data = await _api.fetch(base, providerId);
      if (data != null) return data;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _loadFromFirestore(
      String providerId) async {
    final doc = await FirebaseFirestore.instance
        .collection('provedores')
        .doc(providerId)
        .get(const GetOptions(source: Source.server));
    final data = doc.data();
    return doc.exists && data != null ? Map<String, dynamic>.from(data) : null;
  }

  Future<void> _loadFromCache(String providerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('provider_config_$providerId');
      if (cachedString != null) {
        final Map<String, dynamic> data = json.decode(cachedString);
        _providerConfig =
            ProviderConfigNormalizer.fromFirestore(data, providerId);
        _isLoading = false; // Já temos dados para mostrar!
        notifyListeners();
        debugPrint("📦 Configuração carregada do cache local.");
      }
    } catch (e) {
      debugPrint("Erro ao ler cache: $e");
    }
  }

  Future<void> _saveToCache(
      String providerId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final safeData = _sanitizeForJson(data);
      await prefs.setString(
          'provider_config_$providerId', json.encode(safeData));
    } catch (e) {
      debugPrint("Erro ao salvar cache: $e");
    }
  }

  /// Converte Firestore Timestamps e outros objetos não-serializáveis para tipos JSON
  dynamic _sanitizeForJson(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }

    if (value is DateTime) {
      return value.toIso8601String();
    }

    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _sanitizeForJson(v)));
    }

    if (value is List) {
      return value.map((v) => _sanitizeForJson(v)).toList();
    }

    // Valores primitivos (String, int, double, bool) passam direto
    return value;
  }
}
