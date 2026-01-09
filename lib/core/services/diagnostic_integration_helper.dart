// Diagnostic Integration Helper
// Centralizes integration logic for health score, test modes, and history

import '../models/diagnostico_state.dart';
import '../models/network_health_score.dart';
import '../models/test_history.dart';
import '../models/test_mode.dart';
import '../services/test_history_service.dart';

class DiagnosticIntegrationHelper {
  final TestHistoryService _historyService = TestHistoryService();

  // Save completed test to history
  Future<void> saveTestResult({
    required DiagnosticoState state,
    required TestMode testMode,
    double? contractedSpeed,
  }) async {
    // Calculate health score
    final healthScore = NetworkHealthScore.calculate(
      state,
      contractedSpeedMbps: contractedSpeed,
    );

    // Extract key metrics
    final downloadSpeed = state.customDownloadResultMbps;
    final uploadSpeed = state.customUploadResultMbps;

    final pingResult = state.testResultsDisplay['pingGoogle']?['result'];
    final ping =
        pingResult != null ? int.tryParse(pingResult.split(' ')[0]) ?? 0 : 0;

    final jitter = state.speedTestJitter ?? 0.0;
    final packetLoss = 0; // Would need to parse from ping result

    // Create history entry
    final entry = TestHistoryEntry.fromDiagnosticoState(
      testMode: testMode.displayName,
      healthScore: healthScore.totalScore,
      downloadSpeed: downloadSpeed,
      uploadSpeed: uploadSpeed,
      ping: ping,
      jitter: jitter,
      packetLoss: packetLoss,
      additionalData: {
        'wifiRssi': state.testResultsDisplay['wifiInfo']?['result'],
        'onuStatus': state.testResultsDisplay['onuSignal']?['result'],
        'deviceCount': state.testResultsDisplay['lanScan']?['result'],
      },
    );

    // Save to history
    await _historyService.saveTest(entry);
  }

  // Get comparison with last test
  Future<Map<String, dynamic>?> getComparison(DiagnosticoState current) async {
    final latest = await _historyService.getLatestTest();
    if (latest == null) return null;

    final downloadDiff =
        current.customDownloadResultMbps - latest.downloadSpeed;
    final uploadDiff = current.customUploadResultMbps - latest.uploadSpeed;

    final currentPing = int.tryParse(current.testResultsDisplay['pingGoogle']
                    ?['result']
                ?.split(' ')[0] ??
            '0') ??
        0;
    final pingDiff = currentPing - latest.ping;

    return {
      'downloadDiff': downloadDiff,
      'uploadDiff': uploadDiff,
      'pingDiff': pingDiff,
      'previous': latest,
      'downloadPercent': latest.downloadSpeed > 0
          ? (downloadDiff / latest.downloadSpeed * 100)
          : 0.0,
      'uploadPercent': latest.uploadSpeed > 0
          ? (uploadDiff / latest.uploadSpeed * 100)
          : 0.0,
    };
  }

  // Get suggested test mode based on time of day or usage pattern
  TestMode getSuggestedMode() {
    final hour = DateTime.now().hour;

    // Evening: likely streaming
    if (hour >= 18 && hour < 23) {
      return TestMode.streaming;
    }

    // Late night/early morning: gaming
    if (hour >= 23 || hour < 6) {
      return TestMode.gaming;
    }

    // Work hours: quick test
    if (hour >= 9 && hour < 18) {
      return TestMode.quick;
    }

    return TestMode.complete;
  }
}
