import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometryService {
  final LocalAuthentication auth = LocalAuthentication();
  static const String _biometryEnabledKey = 'biometry_enabled';

  /// Verifica se o dispositivo suporta biometria e se há biometria cadastrada
  Future<bool> isBiometryAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      
      if (!canAuthenticate) return false;

      final List<BiometricType> availableBiometrics =
          await auth.getAvailableBiometrics();

      return availableBiometrics.isNotEmpty;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Tenta autenticar o usuário
  Future<bool> authenticate() async {
    try {
      return await auth.authenticate(
        localizedReason: 'Autentique-se para acessar o App',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Verifica se a biometria está habilitada pelo usuário nas preferências
  Future<bool> isBiometryEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometryEnabledKey) ?? false;
  }

  /// Habilita ou desabilita a biometria nas preferências
  Future<void> setBiometryEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometryEnabledKey, enabled);
  }
}
