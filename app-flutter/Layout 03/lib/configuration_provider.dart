import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:layout01/models/provider_config.dart';

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

        // 3. Atualiza o cache
        await _saveToCache(providerId, safeData);
        print("✅ Configuração '$providerId' atualizada do servidor.");
      } else {
        if (_providerConfig == null) {
          _errorMessage = "Provedor com ID '$providerId' não encontrado.";
        }
        print("❌ ERRO: Provedor não encontrado no servidor.");
      }
    } catch (e) {
      if (_providerConfig == null) {
        _errorMessage = "Erro de conexão e sem cache local: $e";
      }
      print("⚠️ Aviso: Usando versão em cache devido a erro de conexão: $e");
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
        print("📦 Configuração carregada do cache local.");
      }
    } catch (e) {
      print("Erro ao ler cache: $e");
    }
  }

  Future<void> _saveToCache(
      String providerId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('provider_config_$providerId', json.encode(data));
    } catch (e) {
      print("Erro ao salvar cache: $e");
    }
  }
}
