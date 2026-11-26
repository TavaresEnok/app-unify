import '../services/api_response.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/usuario.dart';
import '../models/provider_config.dart';
import '../services/session_token_store.dart';
import '../services/subscriber_achievements.dart';

class AuthRepository {
  // Opções endurecidas: no Android usa EncryptedSharedPreferences (em vez do
  // backend legado) e no iOS restringe o acesso ao item a este dispositivo e
  // somente após o primeiro desbloqueio.
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  final http.Client _client;

  AuthRepository({http.Client? client}) : _client = client ?? http.Client();

  // Keys
  static const _bioCpfKey = 'bio_cpf';
  static const _bioPassKey = 'bio_pass';

  Future<Usuario?> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    // A sessão persiste via JWT self-hosted; usamos a presença do CPF como
    // marcador de auto-login. A senha não é mais armazenada (M11).
    // Token vencido ou ilegível não desloga: o CPF guardado basta para o app
    // renovar a sessão sozinho (AuthNotifier.renewSession). Só uma sessão de
    // outro tipo (ex.: admin) não vale aqui.
    final claims = await SessionTokenStore.instance.getClaims();
    if (claims != null && claims['role'] != 'subscriber') return null;
    if (prefs.containsKey('userCpfCnpj') && prefs.containsKey('userName')) {
      return Usuario(
        cpfCnpj: prefs.getString('userCpfCnpj')!,
        senha: '',
        nome: prefs.getString('userName')!,
        plano: prefs.getString('userPlan')!,
        status: prefs.getString('userStatus')!,
        contractStatus: prefs.getString('userContractStatus'),
        valorFatura: prefs.getString('billValue')!,
        vencimentoFatura: prefs.getString('billDueDate')!,
        contratoId: prefs.getInt('userContratoId'),
        email: prefs.getString('userEmail'),
      );
    }
    return null;
  }

  Future<Usuario> performLoginApi(String cpf, ProviderConfig config) async {
    final apiUrl = config.apiUrl;
    final requestBody = {
      'cpf': cpf,
      'providerId': config.id,
    };

    final url = '$apiUrl/check-cpf';
    if (kDebugMode) debugPrint('[Auth] Iniciando autenticacao.');

    final response = await _client
        .post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(requestBody),
    )
        .timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        if (kDebugMode) debugPrint('[Auth] Timeout na requisicao.');
        throw Exception('Timeout: Servidor demorou para responder');
      },
    );

    if (kDebugMode) debugPrint('[Auth] Status: ${response.statusCode}.');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Resposta inválida do servidor. Tente novamente.');
      }
      final data = decoded;
      if (kDebugMode) debugPrint('[Auth] Login concluido.');

      final sessionToken =
          (data['accessToken'] ?? data['customToken'])?.toString();
      if (sessionToken == null || sessionToken.isEmpty) {
        throw const LoginRejectedException(
          'Acesso indisponível para este contrato. Verifique o status com o provedor.',
        );
      }
      await SessionTokenStore.instance.saveToken(sessionToken);

      // Return User object directly from API data
      // Note: We still need to call 'saveUserLocally' effectively,
      // but the repository separation suggests 'performLoginApi' just gets data,
      // and 'saveUserLocally' persists it. However, to keep it simple and aligned
      // with previous logic, we can have a method that does both or separates them.
      // Let's create a User object here.

      return Usuario(
        cpfCnpj: cpf.replaceAll(RegExp(r'[^0-9]'), ''),
        senha: '',
        nome: data['nome']?.toString() ?? '',
        plano: data['plano']?.toString() ?? '',
        status: data['status']?.toString() ?? '',
        contractStatus: data['contractStatus']?.toString(),
        valorFatura: data['valorFatura']?.toString() ?? '',
        vencimentoFatura: data['vencimentoFatura']?.toString() ?? '',
        email: data['email']?.toString(),
        contratoId: data['contratoId'] is int
            ? data['contratoId']
            : int.tryParse(data['contratoId']?.toString() ?? ''),
      );
    } else {
      if (kDebugMode) {
        debugPrint('[Auth] Falha no login: ${response.statusCode}.');
      }
      final message = _loginErrorMessage(response);
      // CPF não encontrado / recusado pelo provedor: resposta definitiva.
      // Limite, timeout e falha do servidor podem passar sozinhos.
      final status = response.statusCode;
      if (status >= 400 && status < 500 && status != 408 && status != 429) {
        throw LoginRejectedException(message);
      }
      throw Exception(message);
    }
  }

  Future<Usuario> refreshUser(Usuario previous, ProviderConfig config) async {
    final token = await SessionTokenStore.instance.getToken();
    if (token == null) throw Exception('Entre novamente para continuar.');
    final response = await _client
        .post(
          Uri.parse('${config.apiUrl}/getClientData'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
          body: jsonEncode(
              {'cpfCnpj': previous.cpfCnpj, 'contratoId': previous.contratoId}),
        )
        .timeout(const Duration(seconds: 30));
    final body =
        decodeApiResponse(response, fallback: _loginErrorMessage(response));
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException(response.statusCode,
          'Resposta inesperada do servidor. Tente novamente.');
    }
    return Usuario(
      cpfCnpj: previous.cpfCnpj,
      senha: '',
      nome: data['userName']?.toString() ?? previous.nome,
      plano: data['userPlan']?.toString() ?? previous.plano,
      status: data['userStatus']?.toString() ?? previous.status,
      contractStatus:
          data['contractStatus']?.toString() ?? previous.contractStatus,
      valorFatura: data['billValue']?.toString() ?? previous.valorFatura,
      vencimentoFatura:
          data['billDueDate']?.toString() ?? previous.vencimentoFatura,
      contratoId: previous.contratoId,
      email: data['email']?.toString() ?? previous.email,
    );
  }

  String _loginErrorMessage(http.Response response) {
    if (response.statusCode == 404) {
      return 'CPF/CNPJ não encontrado. Confira os dados informados.';
    }
    if (response.statusCode == 429) {
      return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
    }
    if (response.statusCode >= 500) {
      return 'Serviço temporariamente indisponível. Tente novamente em instantes.';
    }

    try {
      final decoded = jsonDecode(response.body);
      final message = decoded is Map<String, dynamic>
          ? decoded['error'] is Map<String, dynamic>
              ? decoded['error']['message']
              : decoded['message']
          : null;
      if (message is String && message.isNotEmpty) return message;
    } catch (_) {}

    return 'Não foi possível entrar. Confira os dados e tente novamente.';
  }

  Future<void> saveUserLocally(
    Usuario usuario,
    String providerId, {
    String? apiUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await SubscriberAchievements.record(
          providerId, usuario.cpfCnpj, AchievementEvent.firstAccess);
    } catch (_) {
      // A persistência das conquistas não impede o acesso à conta.
    }

    // NÃO persistimos a senha central do SGP (M11): o login é mantido pela
    // sessão do Firebase, e a senha não é usada em nenhum fluxo. Guardá-la em
    // repouso seria pura superfície de ataque.

    await prefs.setString('userCpfCnpj', usuario.cpfCnpj);
    await prefs.setString('userName', usuario.nome);
    await prefs.setString('userPlan', usuario.plano);
    await prefs.setString('userStatus', usuario.status);
    if (usuario.contractStatus != null) {
      await prefs.setString('userContractStatus', usuario.contractStatus!);
    } else {
      await prefs.remove('userContractStatus');
    }
    if (usuario.email != null) {
      await prefs.setString('userEmail', usuario.email!);
    } else {
      await prefs.remove('userEmail');
    }
    await prefs.setString('billValue', usuario.valorFatura);
    await prefs.setString('billDueDate', usuario.vencimentoFatura);

    // Save providerId for persistence
    await prefs.setString('providerId', providerId);

    if (usuario.contratoId != null) {
      await prefs.setInt('userContratoId', usuario.contratoId!);
    } else {
      await prefs.remove('userContratoId');
    }

    await _saveDeviceToken(usuario, providerId, apiUrl: apiUrl);
  }

  Future<void> logout(Usuario? currentUser, {String? apiUrl}) async {
    try {
      if (currentUser != null) {
        final idToken = await SessionTokenStore.instance.getToken();
        String? fcmToken;
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
        } catch (_) {}
        if (apiUrl != null &&
            apiUrl.isNotEmpty &&
            idToken != null &&
            idToken.isNotEmpty) {
          final base = apiUrl.replaceAll(RegExp(r'/+$'), '');
          await _client
              .delete(
                Uri.parse('$base/subscriber/device-token'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $idToken',
                },
                body: jsonEncode({
                  if (fcmToken != null && fcmToken.isNotEmpty)
                    'fcmToken': fcmToken,
                }),
              )
              .timeout(const Duration(seconds: 6));
        }
      }
    } catch (e) {
      debugPrint('ℹ️  Aviso: Falha ao limpar o token FCM durante o logout: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    // Preserva flags que não são da sessão do usuário
    for (final key in prefs.getKeys()) {
      if (key != 'onboarding_completed' &&
          key != 'theme_preference' &&
          key != 'theme_mode' &&
          !key.startsWith(SubscriberAchievements.prefix)) {
        await prefs.remove(key);
      }
    }

    // Limpa credenciais do secure storage (senha antiga + JWT). O CPF
    // lembrado fica, para entrar de novo com a digital ([rememberedCpf]).
    await _secureStorage.delete(key: 'userSenha');
    await _secureStorage.delete(key: _bioPassKey);
    await SessionTokenStore.instance.clear();
  }

  Future<void> _saveDeviceToken(
    Usuario usuario,
    String providerId, {
    String? apiUrl,
  }) async {
    try {
      String? token;
      try {
        token = await FirebaseMessaging.instance.getToken();
      } catch (_) {}

      if (token != null &&
          token.isNotEmpty &&
          apiUrl != null &&
          apiUrl.isNotEmpty) {
        try {
          final idToken = await SessionTokenStore.instance.getToken();
          if (idToken != null && idToken.isNotEmpty) {
            final base = apiUrl.replaceAll(RegExp(r'/+$'), '');
            await _client
                .post(
                  Uri.parse('$base/subscriber/device-token'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $idToken',
                  },
                  body: jsonEncode({
                    'fcmToken': token,
                    if (usuario.contratoId != null)
                      'contratoId': usuario.contratoId.toString(),
                    'plano': usuario.plano,
                    'contractStatus': usuario.contractStatus ?? '',
                    'connectionStatus': usuario.status,
                  }),
                )
                .timeout(const Duration(seconds: 10));
          }
        } catch (e) {
          debugPrint('ℹ️  Aviso: Falha ao registrar token FCM na API: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar dados do cliente: $e');
    }
  }

  // --- BIOMETRIA ---

  /// CPF/CNPJ do último login neste aparelho, para entrar com a digital.
  Future<String?> rememberedCpf() async {
    try {
      final cpf = await _secureStorage.read(key: _bioCpfKey);
      return cpf != null && RegExp(r'^\d{11}(\d{3})?$').hasMatch(cpf)
          ? cpf
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> rememberCpf(String cpf) async {
    final digits = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    try {
      await _secureStorage.write(key: _bioCpfKey, value: digits);
    } catch (_) {}
  }

  Future<void> forgetCpf() async {
    try {
      await _secureStorage.delete(key: _bioCpfKey);
    } catch (_) {}
  }

  Future<void> saveCredentialsForBiometry(String cpf, String password) async {
    await _secureStorage.write(key: _bioCpfKey, value: cpf);
    await _secureStorage.write(key: _bioPassKey, value: password);
  }

  Future<Map<String, String>?> getCredentialsForBiometry() async {
    final cpf = await _secureStorage.read(key: _bioCpfKey);
    final pass = await _secureStorage.read(key: _bioPassKey);
    if (cpf != null && pass != null) {
      return {'cpf': cpf, 'password': pass};
    }
    return null;
  }

  Future<void> clearBiometryCredentials() async {
    await _secureStorage.delete(key: _bioCpfKey);
    await _secureStorage.delete(key: _bioPassKey);
  }
}

/// O provedor recusou o CPF/CNPJ (não encontrado, contrato encerrado):
/// renovar a sessão não adianta, o assinante precisa entrar de novo.
class LoginRejectedException implements Exception {
  const LoginRejectedException(this.message);
  final String message;
  @override
  String toString() => message;
}
