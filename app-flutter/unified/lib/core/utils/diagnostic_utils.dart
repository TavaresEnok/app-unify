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

  /// Extrai um bloco de texto multi-linha após uma chave específica.
  /// Ex: "Servidores DNS:\n8.8.8.8\n8.8.4.4" -> retorna "8.8.8.8\n8.8.4.4"
  /// Útil para valores que ocupam múltiplas linhas.
  static String parseResultBlock(String? resultText, String key) {
    if (resultText == null || resultText.isEmpty) return "---";
    try {
      final lines = resultText.split('\n');
      final keyIndex = lines.indexWhere((l) => l.startsWith(key));
      if (keyIndex == -1) return "---";

      // Pega o conteúdo da linha da chave (se houver algo após ':')
      final keyLine = lines[keyIndex];
      final keyParts = keyLine.split(':');
      final firstLineValue =
          keyParts.length > 1 ? keyParts.sublist(1).join(':').trim() : '';

      // Se a primeira linha já tem conteúdo e não é vazia, retorna apenas ela
      if (firstLineValue.isNotEmpty && firstLineValue != 'N/A') {
        return firstLineValue;
      }

      // Caso contrário, pega as linhas seguintes até encontrar uma linha vazia ou outra chave
      final blockLines = <String>[];
      for (int i = keyIndex + 1; i < lines.length; i++) {
        final line = lines[i].trim();
        // Para se encontrar linha vazia ou linha que parece ser outra chave (contém ':')
        if (line.isEmpty) break;
        if (line.contains(':') && !line.startsWith(' ')) break; // Nova chave
        blockLines.add(line);
      }

      if (blockLines.isEmpty) return "---";
      return blockLines.join('\n');
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
