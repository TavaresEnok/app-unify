// Test History Service
// Persists and retrieves test history using SharedPreferences

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/test_history.dart';

class TestHistoryService {
  static const String _key = 'test_history';
  static const int _maxEntries = 30;

  // Save test result
  Future<void> saveTest(TestHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    // Add new entry at the beginning
    history.insert(0, entry);

    // Keep only last 30 entries
    if (history.length > _maxEntries) {
      history.removeRange(_maxEntries, history.length);
    }

    // Save to SharedPreferences
    final jsonList = history.map((e) => e.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  // Get all history
  Future<List<TestHistoryEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map(
              (json) => TestHistoryEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading test history: $e');
      return [];
    }
  }

  // Get history for specific time period
  Future<List<TestHistoryEntry>> getHistoryForPeriod(Duration period) async {
    final history = await getHistory();
    final cutoff = DateTime.now().subtract(period);
    return history.where((entry) => entry.timestamp.isAfter(cutoff)).toList();
  }

  // Statistics
  Future<Map<String, dynamic>> getStats() async {
    final history = await getHistory();
    if (history.isEmpty) {
      return {
        'avgDownload': 0.0,
        'avgUpload': 0.0,
        'avgPing': 0,
        'avgScore': 0,
        'totalTests': 0,
        'bestScore': 0,
        'worstScore': 0,
      };
    }

    final avgDownload =
        history.map((e) => e.downloadSpeed).reduce((a, b) => a + b) /
            history.length;
    final avgUpload =
        history.map((e) => e.uploadSpeed).reduce((a, b) => a + b) /
            history.length;
    final avgPing =
        history.map((e) => e.ping).reduce((a, b) => a + b) ~/ history.length;
    final avgScore =
        history.map((e) => e.healthScore).reduce((a, b) => a + b) ~/
            history.length;
    final bestScore =
        history.map((e) => e.healthScore).reduce((a, b) => a > b ? a : b);
    final worstScore =
        history.map((e) => e.healthScore).reduce((a, b) => a < b ? a : b);

    return {
      'avgDownload': avgDownload,
      'avgUpload': avgUpload,
      'avgPing': avgPing,
      'avgScore': avgScore,
      'totalTests': history.length,
      'bestScore': bestScore,
      'worstScore': worstScore,
      'last7Days': (await getHistoryForPeriod(const Duration(days: 7))).length,
    };
  }

  // Clear all history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // Get latest test
  Future<TestHistoryEntry?> getLatestTest() async {
    final history = await getHistory();
    return history.isEmpty ? null : history.first;
  }
}
