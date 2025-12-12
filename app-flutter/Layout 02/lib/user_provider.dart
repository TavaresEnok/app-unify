import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _cpfCnpj;
  String? _senha;
  String? _name;
  String? _plan;
  String? _status;
  String? _billValue;
  String? _billDueDate;

  // Getters
  String get cpfCnpj => _cpfCnpj ?? '';
  String get senha => _senha ?? '';
  String get name => _name ?? '';
  String get plan => _plan ?? '';
  String get status => _status ?? '';
  String get billValue => _billValue ?? '';
  String get billDueDate => _billDueDate ?? '';

  bool get isLoggedIn => _cpfCnpj != null && _name != null;

  // Setter unificado
  void setUserData({
    required String cpfCnpj,
    required String senha,
    required String name,
    required String plan,
    required String status,
    required String billValue,
    required String billDueDate,
  }) {
    _cpfCnpj = cpfCnpj;
    _senha = senha;
    _name = name;
    _plan = plan;
    _status = status;
    _billValue = billValue;
    _billDueDate = billDueDate;
    notifyListeners();
  }

  void clearUserData() {
    _cpfCnpj = null;
    _senha = null;
    _name = null;
    _plan = null;
    _status = null;
    _billValue = null;
    _billDueDate = null;
    notifyListeners();
  }
}
