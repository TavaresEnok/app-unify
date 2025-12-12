import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/usuario.dart';

class AuthService with ChangeNotifier {
  Usuario? _usuario;
  bool _isLoading = true;

  final _secureStorage = const FlutterSecureStorage();

  // Chaves para persistência de biometria (não apagadas no logout comum)
  static const _bioCpfKey = 'bio_cpf';
  static const _bioPassKey = 'bio_pass';

  Usuario? get usuario => _usuario;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _usuario != null;

  AuthService() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final senha = await _secureStorage.read(key: 'userSenha');

    if (prefs.containsKey('userCpfCnpj') && senha != null) {
      _usuario = Usuario(
        cpfCnpj: prefs.getString('userCpfCnpj')!,
        senha: senha,
        nome: prefs.getString('userName')!,
        plano: prefs.getString('userPlan')!,
        status: prefs.getString('userStatus')!,
        valorFatura: prefs.getString('billValue')!,
        vencimentoFatura: prefs.getString('billDueDate')!,
      );
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Realiza o login verificando o CPF na API e então salvando os dados
  Future<void> performLogin(String cpfInput) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      // Tenta ler a URL da API do cache se disponível, senão usa default
      String apiUrl = 'http://45.176.56.70:3000/check-cpf';

      final providerId = 'vibe';
      final cachedConfig = prefs.getString('provider_config_$providerId');
      if (cachedConfig != null) {
        try {
          final Map<String, dynamic> data = json.decode(cachedConfig);
          // A estrutura do config pode variar, tenta pegar apiUrl da raiz ou de 'config'
          final configApiUrl = data['apiUrl'] ?? data['config']?['apiUrl'];
          if (configApiUrl != null && configApiUrl.toString().isNotEmpty) {
            // apiUrl = configApiUrl; // Mantendo IP fixo por segurança do teste, usuario confirmou IP
          }
        } catch (e) {
          print('Erro ao ler config cache: $e');
        }
      }

      final unformattedCpf = cpfInput.replaceAll(RegExp(r'[^0-9]'), '');

      print('AuthService: Verificando CPF $unformattedCpf em $apiUrl');

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'cpf': unformattedCpf}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['error'] != null) {
          throw Exception(data['error']);
        }

        final userData = data['data'] ?? data;

        final nome = userData['nome']?.toString() ?? 'Cliente';
        final plano = userData['plano']?.toString() ?? 'Plano Padrão';
        final status = userData['status']?.toString() ?? 'Ativo';
        final valorFatura = userData['valor_fatura']?.toString() ?? '0,00';
        final vencimento =
            userData['vencimento_fatura']?.toString() ?? '01/01/2024';
        final senha = userData['senha']?.toString() ?? '123456';

        await login(unformattedCpf, senha, nome, plano, status, valorFatura,
            vencimento);
      } else {
        throw Exception('Erro na verificação: Status ${response.statusCode}');
      }
    } catch (e) {
      print('AuthService: Erro no login: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String cpf, String s, String name, String plan,
      String status, String bill, String due) async {
    final prefs = await SharedPreferences.getInstance();
    final unformattedCpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    final firstName = name.split(' ').first;

    await _secureStorage.write(key: 'userSenha', value: s);

    await prefs.setString('userCpfCnpj', unformattedCpf);
    await prefs.setString('userName', firstName);
    await prefs.setString('userPlan', plan);
    await prefs.setString('userStatus', status);
    await prefs.setString('billValue', bill);
    await prefs.setString('billDueDate', due);

    await saveCredentialsForBiometry(unformattedCpf, s);

    _usuario = Usuario(
      cpfCnpj: unformattedCpf,
      senha: s,
      nome: firstName,
      plano: plan,
      status: status,
      valorFatura: bill,
      vencimentoFatura: due,
    );

    await _saveDeviceToken(unformattedCpf);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      if (_usuario != null) {
        await FirebaseFirestore.instance
            .collection('clientes')
            .doc(_usuario!.cpfCnpj)
            .update({
          'fcmToken': FieldValue.delete(),
        });
      }
    } catch (e) {
      print('ℹ️  Aviso: Falha ao limpar o token FCM durante o logout: $e');
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
    await _secureStorage.delete(key: 'userSenha');
    // OBS: Não chamamos deleteAll() para preservar as chaves _bioCpfKey e _bioPassKey

    _usuario = null;
    notifyListeners();
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
            'providerId': 'vibe',
            'lastUpdated': FieldValue.serverTimestamp()
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      print('❌ Erro ao salvar o token FCM: $e');
    }
  }

  // --- MÉTODOS PARA BIOMETRIA ---

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
