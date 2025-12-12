import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

  Future<void> login(String cpf, String s, String name, String plan, String status, String bill, String due) async {
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

    // Salva automaticamente para uso futuro com biometria
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
        await FirebaseFirestore.instance.collection('clientes').doc(_usuario!.cpfCnpj).update({
          'fcmToken': FieldValue.delete(),
        });
      }
    } catch (e) {
      print('ℹ️  Aviso: Falha ao limpar o token FCM durante o logout: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    
    // Limpa dados da sessão atual, mas MANTÉM as credenciais de biometria no secureStorage
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
        await FirebaseFirestore.instance.collection('clientes').doc(cpfCnpj).set(
          {'fcmToken': token, 'providerId': 'vibe', 'lastUpdated': FieldValue.serverTimestamp()},
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
