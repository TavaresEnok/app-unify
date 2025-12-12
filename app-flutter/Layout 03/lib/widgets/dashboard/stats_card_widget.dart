import 'package:flutter/material.dart';

/// Widget de card de estatística
class StatsCardWidget extends StatelessWidget {
  final Map<String, dynamic> config;

  const StatsCardWidget({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final icon = _getIcon(config['icon'] as String? ?? 'info');
    final label = config['label'] as String? ?? 'Estatística';
    final value = config['value'] as String? ?? '0';
    final colorHex = config['color'] as String? ?? '#6366F1';
    final color = _hexToColor(colorHex);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'network':
        return Icons.router;
      case 'speed':
        return Icons.speed;
      case 'data':
        return Icons.data_usage;
      case 'calendar':
        return Icons.calendar_today;
      case 'money':
        return Icons.attach_money;
      default:
        return Icons.info_outline;
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}
