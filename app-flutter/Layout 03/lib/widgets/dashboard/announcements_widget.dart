import 'package:flutter/material.dart';

/// Widget de avisos/anúncios
class AnnouncementsWidget extends StatelessWidget {
  final Map<String, dynamic> config;

  const AnnouncementsWidget({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final announcements = (config['announcements'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    if (announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.campaign,
                      color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Avisos Importantes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...announcements.map((announcement) {
              final title = announcement['title'] as String? ?? '';
              final message = announcement['message'] as String? ?? '';
              final priority = announcement['priority'] as String? ?? 'info';
              final date = announcement['date'] as String? ?? '';

              final priorityData = _getPriorityData(priority);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: priorityData['color'].withOpacity(0.05),
                  border: Border.all(
                    color: priorityData['color'].withOpacity(0.2),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          priorityData['icon'],
                          size: 16,
                          color: priorityData['color'],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: priorityData['color'],
                            ),
                          ),
                        ),
                        if (date.isNotEmpty)
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getPriorityData(String priority) {
    switch (priority) {
      case 'urgent':
        return {
          'color': Colors.red,
          'icon': Icons.error,
        };
      case 'warning':
        return {
          'color': Colors.orange,
          'icon': Icons.warning,
        };
      case 'info':
      default:
        return {
          'color': Colors.blue,
          'icon': Icons.info,
        };
    }
  }
}
