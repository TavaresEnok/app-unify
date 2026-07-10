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
  final _secureStorage = const FlutterSecureStorage();

  // Keys
  static const _bioCpfKey = 'bio_cpf';
  static const _bioPassKey = 'bio_pass';

  Future<Usuario?> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final senha = await _secureStorage.read(key: 'userSenha');

    if (prefs.containsKey('userCpfCnpj') && senha != null) {
      return Usuario(
        cpfCnpj: prefs.getString('userCpfCnpj')!,
        senha: senha,
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
    debugPrint('DEBUG: Enviando login para $url');
    debugPrint('DEBUG: Body: ${jsonEncode(requestBody)}');

    final response = await http
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
        debugPrint('DEBUG: TIMEOUT na requisição!');
        throw Exception('Timeout: Servidor demorou para responder');
      },
    );

    debugPrint('DEBUG: Status code: ${response.statusCode}');
    debugPrint('DEBUG: Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('DEBUG: Login bem sucedido! Usuário: ${data['nome']}');

      if (data['customToken'] is String && data['customToken'].isNotEmpty) {
        await FirebaseAuth.instance.signInWithCustomToken(data['customToken']);
      }

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
      debugPrint('DEBUG: Falha no login - código ${response.statusCode}');
      throw Exception(
          'Falha no login: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> saveUserLocally(Usuario usuario, String providerId) async {
    final prefs = await SharedPreferences.getInstance();

    await _secureStorage.write(key: 'userSenha', value: usuario.senha);

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

    // Biometry persistence
    await saveCredentialsForBiometry(usuario.cpfCnpj, usuario.senha);
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
