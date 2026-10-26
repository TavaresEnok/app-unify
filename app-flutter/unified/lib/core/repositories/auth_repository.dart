import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/usuario.dart';
import '../models/provider_config.dart';

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

    // A sessão persiste via Firebase Auth; usamos a presença do CPF como marcador
    // de auto-login. A senha não é mais armazenada (M11).
    if (prefs.containsKey('userCpfCnpj')) {
      return Usuario(
        cpfCnpj: prefs.getString('userCpfCnpj')!,
        senha: '',
        nome: prefs.getString('userName')!,
        plano: prefs.getString('userPlan')!,
        status: prefs.getString('userStatus')!,
        valorFatura: prefs.getString('billValue')!,
        vencimentoFatura: prefs.getString('billDueDate')!,
        contratoId: prefs.getInt('userContratoId'),
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

      final customToken = data['customToken'];
      if (customToken is! String || customToken.isEmpty) {
        throw Exception(
          'Acesso indisponível para este contrato. Verifique o status com o provedor.',
        );
      }
      await FirebaseAuth.instance.signInWithCustomToken(customToken);

      // Return User object directly from API data
      // Note: We still need to call 'saveUserLocally' effectively,
      // but the repository separation suggests 'performLoginApi' just gets data,
      // and 'saveUserLocally' persists it. However, to keep it simple and aligned
      // with previous logic, we can have a method that does both or separates them.
      // Let's create a User object here.

      return Usuario(
        cpfCnpj: cpf.replaceAll(RegExp(r'[^0-9]'), ''),
        senha: data['senha']?.toString() ?? '',
        nome: (data['nome']?.toString() ?? 'Cliente').split(' ').first,
        plano: data['plano']?.toString() ?? 'Plano Básico',
        status: data['status']?.toString() ?? 'Ativo',
        valorFatura: data['valorFatura']?.toString() ?? '0,00',
        vencimentoFatura: data['vencimentoFatura']?.toString() ?? '',
        contratoId: data['contratoId'] is int
            ? data['contratoId']
            : int.tryParse(data['contratoId']?.toString() ?? ''),
      );
    } else {
      if (kDebugMode) {
        debugPrint('[Auth] Falha no login: ${response.statusCode}.');
      }
      throw Exception(_loginErrorMessage(response));
    }
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

  Future<void> saveUserLocally(Usuario usuario, String providerId) async {
    final prefs = await SharedPreferences.getInstance();

    // NÃO persistimos a senha central do SGP (M11): o login é mantido pela
    // sessão do Firebase, e a senha não é usada em nenhum fluxo. Guardá-la em
    // repouso seria pura superfície de ataque.

    await prefs.setString('userCpfCnpj', usuario.cpfCnpj);
    await prefs.setString('userName', usuario.nome);
    await prefs.setString('userPlan', usuario.plano);
    await prefs.setString('userStatus', usuario.status);
    await prefs.setString('billValue', usuario.valorFatura);
    await prefs.setString('billDueDate', usuario.vencimentoFatura);

    // Save providerId for persistence
    await prefs.setString('providerId', providerId);

    if (usuario.contratoId != null) {
      await prefs.setInt('userContratoId', usuario.contratoId!);
    }

    await _saveDeviceToken(usuario.cpfCnpj, providerId);
  }

  Future<void> logout(Usuario? currentUser) async {
    try {
      if (currentUser != null) {
        final authUid = FirebaseAuth.instance.currentUser?.uid;
        if (authUid != null) {
          await FirebaseFirestore.instance
              .collection('clientes')
              .doc(authUid)
              .update({'fcmToken': FieldValue.delete()});
        }
      }
    } catch (e) {
      debugPrint('ℹ️  Aviso: Falha ao limpar o token FCM durante o logout: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    // Preserva flags que não são da sessão do usuário
    final onboardingDone = prefs.getBool('onboarding_completed');
    final themeChoice = prefs.getString('theme_preference');
    await prefs.clear();
    if (onboardingDone != null) {
      await prefs.setBool('onboarding_completed', onboardingDone);
    }
    if (themeChoice != null) {
      await prefs.setString('theme_preference', themeChoice);
    }

    // Limpa credenciais do secure storage (senha + biometria)
    await _secureStorage.delete(key: 'userSenha');
    await clearBiometryCredentials();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _saveDeviceToken(String cpfCnpj, String providerId) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      final authUid = FirebaseAuth.instance.currentUser?.uid;

      // Load user data from storage to sync to Firestore
      final usuario = await loadUserFromStorage();

      if (token != null && usuario != null && authUid != null) {
        // Sync full profile for segmented notifications
        await FirebaseFirestore.instance
            .collection('clientes')
            .doc(authUid)
            .set(
          {
            'fcmToken': token,
            'authUid': authUid,
            'cpfCnpj': cpfCnpj,
            'providerId': providerId,
            'nome': usuario.nome,
            'plano': usuario.plano,
            'status': usuario.status,
            'lastUpdated': FieldValue.serverTimestamp()
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar dados do cliente no Firestore: $e');
    }
  }

  // --- BIOMETRIA ---

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
