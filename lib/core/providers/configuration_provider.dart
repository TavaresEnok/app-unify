import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/provider_config.dart';

class ConfigurationProvider with ChangeNotifier {
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
      // 2. Busca do servidor em segundo plano
      final doc = await FirebaseFirestore.instance
          .collection('provedores')
          .doc(providerId)
          .get(const GetOptions(source: Source.server));

      if (doc.exists && doc.data() != null) {
        final rawData = doc.data()!;
        final safeData = Map<String, dynamic>.from(rawData);

        _providerConfig = ProviderConfig.fromJson(safeData, providerId);

        // DEBUG: Print layoutType and colors being loaded
        debugPrint(
            "🎨 [DEBUG] layoutType from Firestore: ${_providerConfig?.layoutType}");
        debugPrint(
            "🎨 [DEBUG] Raw layoutType in JSON: ${safeData['layoutType']}");
        debugPrint("🎨 [DEBUG] themeColor: ${safeData['themeColor']}");
        debugPrint("🎨 [DEBUG] secondaryColor: ${safeData['secondaryColor']}");
        debugPrint(
            "🎨 [DEBUG] config.themeColor: ${_providerConfig?.config.themeColor}");
        debugPrint(
            "🎨 [DEBUG] config.secondaryColor: ${_providerConfig?.config.secondaryColor}");

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

  Future<void> _loadFromCache(String providerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('provider_config_$providerId');
      if (cachedString != null) {
        final Map<String, dynamic> data = json.decode(cachedString);
        _providerConfig = ProviderConfig.fromJson(data, providerId);
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
