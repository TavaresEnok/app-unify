import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final sgpParams = {
      "token": config.config.integrations.apiToken,
      "app": config.config.integrations.appName,
      "sgpBaseUrl": config.config.integrations.sgpBaseUrl
    };

    final requestBody = {
      'cpf': cpf,
      'sgpParams': sgpParams,
      'sgpBaseUrl': config.config.integrations.sgpBaseUrl,
    };

    final url = '$apiUrl/check-cpf';
    debugPrint('DEBUG: Enviando login para $url');

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
        throw Exception('Timeout: Servidor demorou para responder');
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

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
      throw Exception(
          'Falha no login: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> saveUserLocally(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();

    await _secureStorage.write(key: 'userSenha', value: usuario.senha);

    await prefs.setString('userCpfCnpj', usuario.cpfCnpj);
    await prefs.setString('userName', usuario.nome);
    await prefs.setString('userPlan', usuario.plano);
    await prefs.setString('userStatus', usuario.status);
    await prefs.setString('billValue', usuario.valorFatura);
    await prefs.setString('billDueDate', usuario.vencimentoFatura);

    if (usuario.contratoId != null) {
      await prefs.setInt('userContratoId', usuario.contratoId!);
    }

    // Biometry persistence
    await saveCredentialsForBiometry(usuario.cpfCnpj, usuario.senha);
    await _saveDeviceToken(usuario.cpfCnpj);
  }

  Future<void> logout(Usuario? currentUser) async {
    try {
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('clientes')
            .doc(currentUser.cpfCnpj)
            .update({
          'fcmToken': FieldValue.delete(),
        });
      }
    } catch (e) {
      debugPrint('ℹ️  Aviso: Falha ao limpar o token FCM durante o logout: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _secureStorage.delete(key: 'userSenha');
  }

  Future<void> _saveDeviceToken(String cpfCnpj) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('clientes')
            .doc(cpfCnpj)
            .set(
          {
            'fcmToken': token,
            'providerId':
                'vibe', // This might need to be dynamic? using 'vibe' as per legacy code
            'lastUpdated': FieldValue.serverTimestamp()
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar o token FCM: $e');
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
