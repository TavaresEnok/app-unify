import 'package:flutter/material.dart';
import 'diagnostic_theme.dart';

class DiagnosticDataRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const DiagnosticDataRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color = DiagnosticTheme.cyan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color.withAlpha(180), size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  color: DiagnosticTheme.textSecondary, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
