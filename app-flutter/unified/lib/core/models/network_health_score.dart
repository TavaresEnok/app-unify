// Network Health Score Model
// Calculates overall network quality score (0-100)

import 'package:flutter/material.dart';
import '../models/diagnostico_state.dart';

class NetworkHealthScore {
  final int totalScore; // 0-100
  final int speedScore; // 0-100
  final int latencyScore; // 0-100
  final int stabilityScore; // 0-100
  final int wifiScore; // 0-100

  const NetworkHealthScore({
    required this.totalScore,
    required this.speedScore,
    required this.latencyScore,
    required this.stabilityScore,
    required this.wifiScore,
  });

  // Calculate from DiagnosticoState
  factory NetworkHealthScore.calculate(
    DiagnosticoState state, {
    double? contractedSpeedMbps, // Speed contratada do plano
  }) {
    final speedScore = _calculateSpeedScore(
      state.customDownloadResultMbps,
      contractedSpeedMbps ?? 100, // Default 100 Mbps se não informado
    );

    final latencyScore = _calculateLatencyScore(
      state.testResultsDisplay['pingGoogle']?['result'] != null
          ? int.tryParse(
                state.testResultsDisplay['pingGoogle']!['result']!
                    .split(' ')[0],
              ) ??
              0
          : 0,
    );

    final stabilityScore = _calculateStabilityScore(
      state.testResultsDisplay['pingGoogle']?['result']?.contains('loss') ==
              true
          ? int.tryParse(
                state.testResultsDisplay['pingGoogle']!['result']!
                    .split('loss: ')[1]
                    .split('%')[0],
              ) ??
              0
          : 0,
    );

    final wifiScore = _calculateWifiScore(
      state.testResultsDisplay['wifiInfo']?['result']?.contains('dBm') == true
          ? int.tryParse(
                state.testResultsDisplay['wifiInfo']!['result']!
                    .split('RSSI: ')[1]
                    .split(' ')[0],
              ) ??
              -70
          : -70,
    );

    // Weighted average: Speed 30%, Latency 25%, Stability 25%, WiFi 20%
    final totalScore = (speedScore * 0.30 +
            latencyScore * 0.25 +
            stabilityScore * 0.25 +
            wifiScore * 0.20)
        .round();

    return NetworkHealthScore(
      totalScore: totalScore.clamp(0, 100),
      speedScore: speedScore,
      latencyScore: latencyScore,
      stabilityScore: stabilityScore,
      wifiScore: wifiScore,
    );
  }

  // Speed score: compare actual vs contracted
  static int _calculateSpeedScore(double actualMbps, double contractedMbps) {
    if (actualMbps <= 0) return 0;
    final percentage = (actualMbps / contractedMbps * 100).round();
    if (percentage >= 90) return 100;
    if (percentage >= 70) return 85;
    if (percentage >= 50) return 65;
    if (percentage >= 30) return 40;
    return 20;
  }

  // Latency score: <20ms excellent, >50ms poor
  static int _calculateLatencyScore(int pingMs) {
    if (pingMs <= 0) return 50; // No data
    if (pingMs < 20) return 100;
    if (pingMs < 30) return 90;
    if (pingMs < 50) return 75;
    if (pingMs < 80) return 55;
    if (pingMs < 120) return 35;
    return 20;
  }

  // Stability score: packet loss percentage
  static int _calculateStabilityScore(int packetLossPercent) {
    if (packetLossPercent == 0) return 100;
    if (packetLossPercent < 2) return 90;
    if (packetLossPercent < 5) return 70;
    if (packetLossPercent < 10) return 50;
    if (packetLossPercent < 20) return 30;
    return 10;
  }

  // WiFi score: RSSI quality
  static int _calculateWifiScore(int rssi) {
    if (rssi >= -50) return 100; // Excellent
    if (rssi >= -60) return 85; // Good
    if (rssi >= -70) return 65; // Fair
    if (rssi >= -80) return 40; // Poor
    return 20; // Very poor
  }

  // Visual helpers
  String get grade {
    if (totalScore >= 90) return 'A';
    if (totalScore >= 80) return 'B';
    if (totalScore >= 70) return 'C';
    if (totalScore >= 60) return 'D';
    return 'F';
  }

  Color get color {
    if (totalScore >= 80) return const Color(0xFF10B981); // Green
    if (totalScore >= 60) return const Color(0xFFF59E0B); // Yellow
    return const Color(0xFFEF4444); // Red
  }

  String get message {
    if (totalScore >= 90) return 'Excelente! Sua internet está ótima';
    if (totalScore >= 80) return 'Muito bom! Conexão de qualidade';
    if (totalScore >= 70) return 'Bom. Funciona bem para a maioria das tarefas';
    if (totalScore >= 60) return 'Regular. Pode ter lentidão ocasional';
    if (totalScore >= 40) return 'Ruim. Conexão instável ou lenta';
    return 'Crítico! Problemas graves detectados';
  }

  int get stars {
    if (totalScore >= 90) return 5;
    if (totalScore >= 75) return 4;
    if (totalScore >= 60) return 3;
    if (totalScore >= 40) return 2;
    return 1;
  }
}
