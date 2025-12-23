// ARQUIVO: lib/core/services/speed_test_history_service.dart
// DESCRIÇÃO: Serviço para salvar e recuperar histórico de testes de velocidade

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de resultado de speed test
class SpeedTestResult {
  final DateTime timestamp;
  final double downloadSpeed; // Mbps
  final double uploadSpeed; // Mbps
  final int ping; // ms
  final String? serverName;

  SpeedTestResult({
    required this.timestamp,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.ping,
    this.serverName,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'downloadSpeed': downloadSpeed,
        'uploadSpeed': uploadSpeed,
        'ping': ping,
        'serverName': serverName,
      };

  factory SpeedTestResult.fromJson(Map<String, dynamic> json) {
    return SpeedTestResult(
      timestamp: DateTime.parse(json['timestamp']),
      downloadSpeed: (json['downloadSpeed'] ?? 0).toDouble(),
      uploadSpeed: (json['uploadSpeed'] ?? 0).toDouble(),
      ping: json['ping'] ?? 0,
      serverName: json['serverName'],
    );
  }

  String get formattedDate {
    final d = timestamp;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

/// Serviço para gerenciar histórico de speed tests
class SpeedTestHistoryService with ChangeNotifier {
  static const String _historyKey = 'speed_test_history';
  static const int _maxHistoryItems = 20;

  List<SpeedTestResult> _history = [];
  bool _isLoading = true;

  List<SpeedTestResult> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;
  bool get hasHistory => _history.isNotEmpty;

  /// Último resultado
  SpeedTestResult? get lastResult =>
      _history.isNotEmpty ? _history.first : null;

  /// Média de download
  double get averageDownload {
    if (_history.isEmpty) return 0;
    return _history.map((e) => e.downloadSpeed).reduce((a, b) => a + b) /
        _history.length;
  }

  /// Média de upload
  double get averageUpload {
    if (_history.isEmpty) return 0;
    return _history.map((e) => e.uploadSpeed).reduce((a, b) => a + b) /
        _history.length;
  }

  /// Carrega histórico do storage
  Future<void> loadHistory() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];

      _history = historyJson
          .map((json) => SpeedTestResult.fromJson(jsonDecode(json)))
          .toList();

      // Ordena por data (mais recente primeiro)
      _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('Erro ao carregar histórico: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Salva um novo resultado
  Future<void> saveResult(SpeedTestResult result) async {
    try {
      _history.insert(0, result);

      // Limita o histórico
      if (_history.length > _maxHistoryItems) {
        _history = _history.sublist(0, _maxHistoryItems);
      }

      await _persistHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao salvar resultado: $e');
    }
  }

  /// Adiciona resultado a partir de valores brutos
  Future<void> addResult({
    required double downloadSpeed,
    required double uploadSpeed,
    required int ping,
    String? serverName,
  }) async {
    final result = SpeedTestResult(
      timestamp: DateTime.now(),
      downloadSpeed: downloadSpeed,
      uploadSpeed: uploadSpeed,
      ping: ping,
      serverName: serverName,
    );
    await saveResult(result);
  }

  /// Limpa todo o histórico
  Future<void> clearHistory() async {
    try {
      _history.clear();
      await _persistHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao limpar histórico: $e');
    }
  }

  /// Persiste no storage
  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _history.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_historyKey, historyJson);
  }
}
