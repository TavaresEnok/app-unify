// Test History Model
// Stores diagnostic test results for historical analysis

import 'package:flutter/foundation.dart';

@immutable
class TestHistoryEntry {
  final String id;
  final DateTime timestamp;
  final double downloadSpeed;
  final double uploadSpeed;
  final int ping;
  final double jitter;
  final int packetLoss;
  final String testMode; // 'quick', 'gaming', 'streaming', 'complete'
  final int healthScore; // 0-100
  final Map<String, dynamic>? additionalData; // WiFi, ONU, etc

  const TestHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.ping,
    required this.jitter,
    required this.packetLoss,
    required this.testMode,
    required this.healthScore,
    this.additionalData,
  });

  // Create from DiagnosticoState
  factory TestHistoryEntry.fromDiagnosticoState({
    required String testMode,
    required int healthScore,
    required double downloadSpeed,
    required double uploadSpeed,
    required int ping,
    required double jitter,
    required int packetLoss,
    Map<String, dynamic>? additionalData,
  }) {
    return TestHistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      downloadSpeed: downloadSpeed,
      uploadSpeed: uploadSpeed,
      ping: ping,
      jitter: jitter,
      packetLoss: packetLoss,
      testMode: testMode,
      healthScore: healthScore,
      additionalData: additionalData,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'downloadSpeed': downloadSpeed,
      'uploadSpeed': uploadSpeed,
      'ping': ping,
      'jitter': jitter,
      'packetLoss': packetLoss,
      'testMode': testMode,
      'healthScore': healthScore,
      'additionalData': additionalData,
    };
  }

  factory TestHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TestHistoryEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      downloadSpeed: (json['downloadSpeed'] as num).toDouble(),
      uploadSpeed: (json['uploadSpeed'] as num).toDouble(),
      ping: json['ping'] as int,
      jitter: (json['jitter'] as num).toDouble(),
      packetLoss: json['packetLoss'] as int,
      testMode: json['testMode'] as String,
      healthScore: json['healthScore'] as int,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  // Helper getters
  String get speedSummary =>
      '${downloadSpeed.toStringAsFixed(1)}↓ / ${uploadSpeed.toStringAsFixed(1)}↑ Mbps';

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m atrás';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h atrás';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d atrás';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  String toString() =>
      'TestHistoryEntry(${formattedDate}, $speedSummary, Score: $healthScore)';
}
