import 'package:flutter/material.dart';
import 'diagnostic_theme.dart';
import 'holo_card.dart';

class StatCard extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return HoloCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      accent: color,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [color.withAlpha(80), color.withAlpha(15)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(color: color.withAlpha(150), fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style:
                const TextStyle(color: DiagnosticTheme.textDim, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
