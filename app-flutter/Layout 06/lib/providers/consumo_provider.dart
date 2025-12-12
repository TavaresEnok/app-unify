
// ARQUIVO: lib/providers/consumo_provider.dart (NOVO)
import 'package:flutter/material.dart';
import 'dart:async';

import '../services/consumo_service.dart';

// Enum para um controle de estado mais robusto e legível
enum ConsumoState { idle, loading, success, error }

class ConsumoProvider with ChangeNotifier {
  final ConsumoService _service;

  // Construtor que recebe o serviço como dependência
  ConsumoProvider(this._service);

  ConsumoState _state = ConsumoState.idle;
  ConsumoState get state => _state;

  Map<String, dynamic>? _consumptionData;
  Map<String, dynamic>? get consumptionData => _consumptionData;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Método público para iniciar a busca de dados
  Future<void> fetchConsumptionData() async {
    _state = ConsumoState.loading;
    _errorMessage = null;
    notifyListeners(); // Notifica a UI para mostrar o loading

    try {
      _consumptionData = await _service.fetchConsumptionData();
      _state = ConsumoState.success;
    } on TimeoutException {
      _errorMessage = 'O servidor demorou muito para responder. Verifique sua conexão e tente novamente.';
      _state = ConsumoState.error;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = ConsumoState.error;
    }

    notifyListeners(); // Notifica a UI sobre o resultado (sucesso ou erro)
  }
}
