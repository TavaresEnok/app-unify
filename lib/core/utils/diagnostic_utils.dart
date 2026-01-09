import 'package:flutter/material.dart';
import '../models/diagnostico_state.dart' as real_state;

class DiagnosticUtils {
  /// Extrai o valor de uma linha específica de um resultado multi-linhas.
  /// Ex: "Força do Sinal: -50dBm" -> retorna "-50dBm"
  static String parseResultLine(String? resultText, String key) {
    if (resultText == null || resultText.isEmpty) return "---";
    try {
      final line = resultText
          .split('\n')
          .firstWhere((l) => l.startsWith(key), orElse: () => '');
      if (line.isEmpty) return "---";
      // Pega tudo após o primeiro ':' e faz trim
      final parts = line.split(':');
      if (parts.length < 2) return "---";
      return parts.sublist(1).join(':').trim();
    } catch (_) {
      return "---";
    }
  }

  /// Retorna uma cor baseada no status do teste.
  /// [defaultColor] é usado para status pendente ou desconhecido.
  static Color getStatusColor(
    real_state.TestStatus status, {
    required Color success,
    required Color running,
    required Color error,
    required Color pending,
  }) {
    switch (status) {
      case real_state.TestStatus.success:
        return success;
      case real_state.TestStatus.running:
        return running;
      case real_state.TestStatus.error:
        return error;
      default:
        return pending;
    }
  }
}
