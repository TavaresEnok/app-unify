// Comparison Widget
// Shows diff between current and previous test results

import 'package:flutter/material.dart';
import '../models/test_history.dart';

class ComparisonWidget extends StatelessWidget {
  final Map<String, dynamic> comparison;

  const ComparisonWidget({
    super.key,
    required this.comparison,
  });

  @override
  Widget build(BuildContext context) {
    final downloadDiff = comparison['downloadDiff'] as double;
    final uploadDiff = comparison['uploadDiff'] as double;
    final pingDiff = comparison['pingDiff'] as int;
    final previous = comparison['previous'] as TestHistoryEntry;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.compare_arrows,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Comparação com teste anterior',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            previous.formattedDate,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 14),
          _buildComparisonRow(
            'Download',
            downloadDiff,
            'Mbps',
            Icons.download_rounded,
          ),
          const SizedBox(height: 10),
          _buildComparisonRow(
            'Upload',
            uploadDiff,
            'Mbps',
            Icons.upload_rounded,
          ),
          const SizedBox(height: 10),
          _buildComparisonRow(
            'Ping',
            pingDiff.toDouble(),
            'ms',
            Icons.speed_rounded,
            reverse: true, // Lower is better
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    double diff,
    String unit,
    IconData icon, {
    bool reverse = false,
  }) {
    final isPositive = reverse ? diff < 0 : diff > 0;
    final color = isPositive
        ? const Color(0xFF10B981)
        : diff == 0
            ? Colors.white54
            : const Color(0xFFEF4444);

    final sign = diff > 0 ? '+' : '';
    final arrow = isPositive
        ? Icons.arrow_upward
        : diff == 0
            ? Icons.remove
            : Icons.arrow_downward;

    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
        Icon(arrow, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '$sign${diff.toStringAsFixed(1)} $unit',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
