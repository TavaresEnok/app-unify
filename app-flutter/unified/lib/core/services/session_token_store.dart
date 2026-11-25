import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Armazena e decodifica o JWT self-hosted da sessão do assinante.
class SessionTokenStore {
  static const String _storageKey = 'session_jwt';

  static final SessionTokenStore instance = SessionTokenStore();

  final FlutterSecureStorage _storage;
  String? _token;
  Map<String, dynamic>? _claims;
  bool _loaded = false;

  SessionTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  String? get uid => _claims?['uid']?.toString() ?? _claims?['sub']?.toString();
  String? get providerId => _claims?['providerId']?.toString();
  String? get cpfCnpj => _claims?['cpfCnpj']?.toString();
  String? get email => _claims?['email']?.toString();
  bool get isAuthenticated => _token != null && !_isExpired(_claims);

  Future<void> saveToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      await clear();
      return;
    }
    final claims = decodeJwtClaims(trimmed);
    if (claims == null || _isExpired(claims)) {
      await clear();
      return;
    }
    _token = trimmed;
    _claims = claims;
    _loaded = true;
    await _safeWrite(trimmed);
  }

  Future<String?> getToken() async {
    if (_token != null) {
      if (!_isExpired(_claims)) return _token;
      await clear();
      return null;
    }
    if (_loaded) return null;

    _loaded = true;
    final stored = await _safeRead();
    if (stored == null || stored.trim().isEmpty) return null;

    final claims = decodeJwtClaims(stored);
    if (claims == null || _isExpired(claims)) {
      await clear();
      return null;
    }
    _token = stored.trim();
    _claims = claims;
    return _token;
  }

  Future<Map<String, dynamic>?> getClaims() async {
    final token = await getToken();
    if (token == null) return null;
    return _claims == null ? null : Map<String, dynamic>.from(_claims!);
  }

  Future<void> clear() async {
    _token = null;
    _claims = null;
    _loaded = true;
    await _safeDelete();
  }

  @visibleForTesting
  void setTokenForTest(String? token) {
    if (token == null || token.trim().isEmpty) {
      _token = null;
      _claims = null;
      _loaded = true;
      return;
    }
    final trimmed = token.trim();
    _token = trimmed;
    _claims = decodeJwtClaims(trimmed);
    _loaded = true;
  }

  static Map<String, dynamic>? decodeJwtClaims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final jsonStr = utf8.decode(base64Url.decode(normalized));
      final parsed = jsonDecode(jsonStr);
      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static bool _isExpired(Map<String, dynamic>? claims) {
    if (claims == null) return true;
    final exp = claims['exp'];
    if (exp is num) {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp <= nowSec;
    }
    return false;
  }

  Future<String?> _safeRead() async {
    try {
      return await _storage.read(key: _storageKey);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _safeWrite(String value) async {
    try {
      await _storage.write(key: _storageKey, value: value);
    } on MissingPluginException {
      // Ignored in unit tests
    } on PlatformException {
      // Ignored on unavailable secure storage backends
    } catch (_) {}
  }

  Future<void> _safeDelete() async {
    try {
      await _storage.delete(key: _storageKey);
    } on MissingPluginException {
      // Ignored in unit tests
    } on PlatformException {
      // Ignored on unavailable secure storage backends
    } catch (_) {}
  }
}
