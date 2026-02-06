import 'package:flutter/material.dart';
import 'package:diagnostic_core/models/diagnostic_models.dart';

class AuditResultCard extends StatelessWidget {
  final DiagnosticResult? result;
  final VoidCallback? onRetry;

  const AuditResultCard({
    Key? key,
    this.result,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (result == null) return const SizedBox.shrink();

    // Compatibilidade segura para versões diferentes do enum
    final isGood = result!.category == DiagnosticCategory.HEALTHY;

    // Cores baseadas no resultado
    final backgroundColor =
        isGood ? Colors.green.shade50 : Colors.orange.shade50;
    final titleColor = isGood ? Colors.green.shade900 : Colors.orange.shade900;
    final subtitleColor =
        isGood ? Colors.green.shade700 : Colors.orange.shade700;
    final iconString = _getCategoryIcon(result!.category);

    return Card(
      elevation: 4,
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  iconString,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result!.problem,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      Text(
                        result!.category.name.replaceAll('_', ' '),
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confiança: ${(result!.confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                if (result!.estimatedTime != "N/A" &&
                    result!.estimatedTime.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Text(
                        result!.estimatedTime,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              result!.solution,
              style: const TextStyle(
                  fontSize: 15, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryIcon(DiagnosticCategory category) {
    switch (category) {
      case DiagnosticCategory.FIBER_ISSUE:
        return '🚧';
      case DiagnosticCategory.FIBER_DEGRADATION:
        return '⚠️';
      case DiagnosticCategory.WIFI_ISSUE:
        return '📶';
      case DiagnosticCategory.SPEED_ISSUE:
        return '🐌';
      case DiagnosticCategory.DEVICE_ISSUE:
        return '📱';
      case DiagnosticCategory.REGIONAL_ISSUE:
        return '🏙️';
      case DiagnosticCategory.BILLING_BLOCK:
        return '💰';
      case DiagnosticCategory.MAINTENANCE:
        return '🔧';
      case DiagnosticCategory.OLT_OVERLOAD:
        return '🔥';
      case DiagnosticCategory.HEALTHY:
        return '✅';
      case DiagnosticCategory.UNKNOWN:
        return '❓';
      default:
        return 'ℹ️';
    }
  }
}
