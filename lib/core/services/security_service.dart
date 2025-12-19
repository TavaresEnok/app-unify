// Serviço de Segurança
// Secure Storage e proteção de dados sensíveis

import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Serviço de Armazenamento Seguro
class SecureStorageService {
  static SecureStorageService? _instance;
  late final FlutterSecureStorage _storage;

  // Opções de segurança para Android
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  // Opções de segurança para iOS
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  SecureStorageService._() {
    _storage = const FlutterSecureStorage(
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  static SecureStorageService get instance {
    _instance ??= SecureStorageService._();
    return _instance!;
  }

  /// Salva dado de forma segura
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Lê dado seguro
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Deleta dado seguro
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Verifica se existe
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  /// Limpa todos os dados seguros
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Salva objeto JSON de forma segura
  Future<void> writeJson(String key, Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    await write(key, jsonString);
  }

  /// Lê objeto JSON seguro
  Future<Map<String, dynamic>?> readJson(String key) async {
    final jsonString = await read(key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}

/// Chaves de armazenamento seguro
class SecureKeys {
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userCredentials = 'user_credentials';
  static const String biometricEnabled = 'biometric_enabled';
  static const String pinCode = 'pin_code';
  static const String encryptionKey = 'encryption_key';
}

/// Utilitários de Criptografia (sem dependências externas)
class CryptoUtils {
  /// Codifica para Base64
  static String encodeBase64(String input) {
    return base64Encode(utf8.encode(input));
  }

  /// Decodifica de Base64
  static String decodeBase64(String input) {
    return utf8.decode(base64Decode(input));
  }

  /// Gera salt aleatório
  static String generateSalt({int length = 32}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Gera token aleatório
  static String generateToken({int length = 64}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Ofusca string para exibição (ex: cartão de crédito)
  static String mask(String input, {int visibleStart = 4, int visibleEnd = 4}) {
    if (input.length <= visibleStart + visibleEnd) return input;
    final start = input.substring(0, visibleStart);
    final end = input.substring(input.length - visibleEnd);
    final masked = '*' * (input.length - visibleStart - visibleEnd);
    return '$start$masked$end';
  }

  /// Ofusca email
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return email;
    return '${name.substring(0, 2)}***@$domain';
  }

  /// Valida força da senha
  static PasswordStrength checkPasswordStrength(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?:{}|]'))) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }
}

/// Força da senha
enum PasswordStrength {
  weak,
  medium,
  strong;

  String get label {
    switch (this) {
      case PasswordStrength.weak:
        return 'Fraca';
      case PasswordStrength.medium:
        return 'Média';
      case PasswordStrength.strong:
        return 'Forte';
    }
  }

  double get value {
    switch (this) {
      case PasswordStrength.weak:
        return 0.33;
      case PasswordStrength.medium:
        return 0.66;
      case PasswordStrength.strong:
        return 1.0;
    }
  }
}

/// Validadores de Segurança
class SecurityValidators {
  /// Valida CPF
  static bool isValidCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}\$').hasMatch(cpf)) return false;

    // Validação dos dígitos verificadores
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int firstDigit = (sum * 10) % 11;
    if (firstDigit == 10) firstDigit = 0;
    if (firstDigit != int.parse(cpf[9])) return false;

    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    int secondDigit = (sum * 10) % 11;
    if (secondDigit == 10) secondDigit = 0;
    return secondDigit == int.parse(cpf[10]);
  }

  /// Valida email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}\$');
    return emailRegex.hasMatch(email);
  }

  /// Valida telefone brasileiro
  static bool isValidPhone(String phone) {
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return phone.length == 10 || phone.length == 11;
  }

  /// Sanitiza input (remove caracteres perigosos)
  static String sanitizeInput(String input) {
    // Remove HTML tags e caracteres perigosos
    String sanitized = input;
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
    sanitized = sanitized.replaceAll('<', '');
    sanitized = sanitized.replaceAll('>', '');
    return sanitized;
  }
}

/// Serviço de Autenticação Segura
class AuthSecurityService {
  final SecureStorageService _storage = SecureStorageService.instance;

  /// Salva tokens de autenticação
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(SecureKeys.authToken, accessToken);
    if (refreshToken != null) {
      await _storage.write(SecureKeys.refreshToken, refreshToken);
    }
  }

  /// Recupera token de acesso
  Future<String?> getAccessToken() async {
    return await _storage.read(SecureKeys.authToken);
  }

  /// Recupera refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(SecureKeys.refreshToken);
  }

  /// Limpa tokens (logout)
  Future<void> clearTokens() async {
    await _storage.delete(SecureKeys.authToken);
    await _storage.delete(SecureKeys.refreshToken);
  }

  /// Verifica se está autenticado
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
