import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Serviço de cache local para dados offline
class CacheService {
  static const String _configKey = 'provider_config';
  static const String _configIdKey = 'provider_config_id';
  static const String _timestampKey = 'cache_timestamp';
  static const String _userKey = 'user_data';

  /// Salva configuração do provedor no cache
  static Future<void> saveConfig(
      Map<String, dynamic> config, String providerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_configKey, jsonEncode(config));
      await prefs.setString(_configIdKey, providerId);
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Erro ao salvar config no cache: $e');
    }
  }

  /// Busca configuração do cache
  static Future<Map<String, dynamic>?> getConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);
      if (configJson == null) return null;
      return jsonDecode(configJson) as Map<String, dynamic>;
    } catch (e) {
      print('Erro ao buscar config do cache: $e');
      return null;
    }
  }

  /// Retorna ID do provedor cacheado
  static Future<String?> getCachedProviderId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_configIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Verifica se o cache ainda é válido
  static Future<bool> isCacheValid({int maxAgeHours = 24}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_timestampKey);
      if (timestamp == null) return false;

      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      final maxAge = Duration(hours: maxAgeHours).inMilliseconds;
      return cacheAge < maxAge;
    } catch (e) {
      return false;
    }
  }

  /// Salva dados do usuário
  static Future<void> saveUserData(Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user));
    } catch (e) {
      print('Erro ao salvar user no cache: $e');
    }
  }

  /// Busca dados do usuário
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson == null) return null;
      return jsonDecode(userJson) as Map<String, dynamic>;
    } catch (e) {
      print('Erro ao buscar user do cache: $e');
      return null;
    }
  }

  /// Limpa todo o cache
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Erro ao limpar cache: $e');
    }
  }

  /// Retorna idade do cache em horas
  static Future<int> getCacheAgeHours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_timestampKey);
      if (timestamp == null) return -1;

      final ageMs = DateTime.now().millisecondsSinceEpoch - timestamp;
      return (ageMs / (1000 * 60 * 60)).floor();
    } catch (e) {
      return -1;
    }
  }
}
