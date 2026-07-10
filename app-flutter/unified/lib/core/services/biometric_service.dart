import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _cpfKey = 'biometric_cpf';
  static const String _passwordKey = 'biometric_pass';
  static const String _enabledKey = 'biometric_enabled';

  /// Verifica se o dispositivo tem suporte a biometria
  Future<bool> get isAvailable async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Verifica se o usuário já ativou a biometria no app anteriormente
  Future<bool> get isEnabled async {
    String? enabled = await _storage.read(key: _enabledKey);
    return enabled == 'true';
  }

  /// Salva as credenciais para uso futuro
  Future<void> saveCredentials(String cpf, String password) async {
    await _storage.write(key: _cpfKey, value: cpf);
    await _storage.write(key: _passwordKey, value: password);
    await _storage.write(key: _enabledKey, value: 'true');
  }

  /// Remove as credenciais (Logout ou desativar)
  Future<void> clearCredentials() async {
    await _storage.delete(key: _cpfKey);
    await _storage.delete(key: _passwordKey);
    await _storage.write(key: _enabledKey, value: 'false');
  }

  /// Autentica o usuário e retorna as credenciais salvas (se sucesso)
  Future<Map<String, String>?> authenticate() async {
    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Autentique-se para acessar sua conta',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Permite PIN se biometria falhar
        ),
      );
    } on PlatformException catch (e) {
      debugPrint("Erro na biometria: $e");
      return null;
    }

    if (authenticated) {
      String? cpf = await _storage.read(key: _cpfKey);
      String? password = await _storage.read(key: _passwordKey);

      if (cpf != null && password != null) {
        return {'cpf': cpf, 'password': password};
      }
    }
    return null;
  }
}
