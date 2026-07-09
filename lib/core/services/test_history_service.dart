// Test History Service
// Persists and retrieves test history using SharedPreferences and Firebase

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/test_history.dart';

class TestHistoryService {
  static const String _key = 'test_history';
  static const int _maxEntries = 30;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save test result locally
  Future<void> saveTest(TestHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    // Add new entry at the beginning
    history.insert(0, entry);

    // Keep only last 30 entries locally
    if (history.length > _maxEntries) {
      history.removeRange(_maxEntries, history.length);
    }

    // Save to SharedPreferences
    final jsonList = history.map((e) => e.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  /// Save test result to Firestore for remote access
  /// [entry] - The test result to save
  /// [providerId] - The provider's Firebase document ID
  /// [clientInfo] - Map containing 'id', 'name', 'plan' from SGP
  Future<void> saveTestToCloud({
    required TestHistoryEntry entry,
    required String providerId,
    required Map<String, dynamic> clientInfo,
  }) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      final connectionType = await _getConnectionType();

      await _firestore
          .collection('provedores')
          .doc(providerId)
          .collection('diagnostic_results')
          .add({
            // Test data
            ...entry.toJson(),
            // Client info from SGP
            'clientId': clientInfo['id'] ?? '',
            'clientName': clientInfo['name'] ?? 'Desconhecido',
            'clientPlan': clientInfo['plan'] ?? '',
            // Connection info
            'connectionType': connectionType,
            // Device info
            'deviceInfo': deviceInfo,
            // Server timestamp for consistency
            'createdAt': FieldValue.serverTimestamp(),
          });

      print(
        '✅ Diagnostic result saved to cloud for client: ${clientInfo['name']}',
      );
    } catch (e) {
      print('❌ Error saving diagnostic to cloud: $e');
      // Don't throw - cloud save failure shouldn't break the app flow
    }
  }

  /// Get connection type (wifi, mobile, ethernet)
  Future<String> _getConnectionType() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      switch (connectivityResult) {
        case ConnectivityResult.wifi:
          return 'wifi';
        case ConnectivityResult.mobile:
          return 'mobile';
        case ConnectivityResult.ethernet:
          return 'ethernet';
        default:
          return 'unknown';
      }
    } catch (e) {
      return 'unknown';
    }
  }

  /// Get device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        return {
          'model': '${androidInfo.manufacturer} ${androidInfo.model}',
          'os': 'Android ${androidInfo.version.release}',
          'appVersion': packageInfo.version,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        return {
          'model': iosInfo.utsname.machine,
          'os': 'iOS ${iosInfo.systemVersion}',
          'appVersion': packageInfo.version,
        };
      }
      return {
        'model': 'Unknown',
        'os': Platform.operatingSystem,
        'appVersion': packageInfo.version,
      };
    } catch (e) {
      return {'model': 'Unknown', 'os': 'Unknown', 'appVersion': 'Unknown'};
    }
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
            (json) => TestHistoryEntry.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('Error saving test to history: $e');
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
    final bestScore = history
        .map((e) => e.healthScore)
        .reduce((a, b) => a > b ? a : b);
    final worstScore = history
        .map((e) => e.healthScore)
        .reduce((a, b) => a < b ? a : b);

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
