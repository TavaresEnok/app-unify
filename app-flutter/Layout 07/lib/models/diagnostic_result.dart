import 'diagnostic_category.dart';
import 'onu_signal_data.dart';
import 'local_test_results.dart';

// Resultado completo do diagnóstico
class DiagnosticResult {
  final String problem; // "Sinal óptico degradado"
  final DiagnosticCategory category;
  final double confidence; // 0.0 a 1.0
  final String solution; // "Recomendamos abrir chamado técnico"
  final String? estimatedTime; // "15-20 minutos"
  final LocalTestResults localTests;
  final OnuSignalData? onuData; // Pode ser null se SGP falhar
  final DateTime timestamp;

  DiagnosticResult({
    required this.problem,
    required this.category,
    required this.confidence,
    required this.solution,
    this.estimatedTime,
    required this.localTests,
    this.onuData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isHealthy => category == DiagnosticCategory.ALL_GOOD;
  bool get needsTechnician =>
      category == DiagnosticCategory.FIBER_ISSUE ||
      category == DiagnosticCategory.OLT_OVERLOAD;

  String get confidencePercentage => '${(confidence * 100).toInt()}%';

  factory DiagnosticResult.fromJson(Map<String, dynamic> json) {
    return DiagnosticResult(
      problem: json['problem'] as String,
      category: DiagnosticCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => DiagnosticCategory.UNKNOWN,
      ),
      confidence: (json['confidence'] as num).toDouble(),
      solution: json['solution'] as String,
      estimatedTime: json['estimatedTime'] as String?,
      localTests:
          LocalTestResults.fromJson(json['localTests'] as Map<String, dynamic>),
      onuData: json['onuData'] != null
          ? OnuSignalData.fromJson(json['onuData'] as Map<String, dynamic>)
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'problem': problem,
        'category': category.toString(),
        'confidence': confidence,
        'solution': solution,
        'estimatedTime': estimatedTime,
        'localTests': localTests.toJson(),
        'onuData': onuData?.toJson(),
        'timestamp': timestamp.toIso8601String(),
      };
}
