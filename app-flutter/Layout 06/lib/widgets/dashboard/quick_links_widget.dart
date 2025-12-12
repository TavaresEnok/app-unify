import 'package:flutter/material.dart';

/// Widget de links rápidos
class QuickLinksWidget extends StatelessWidget {
  final Map<String, dynamic> config;

  const QuickLinksWidget({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final links =
        (config['links'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    if (links.isEmpty) {
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
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.link, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Links Rápidos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...links.map((link) {
              final title = link['title'] as String? ?? 'Link';
              final url = link['url'] as String? ?? '';
              final icon = _getIcon(link['icon'] as String? ?? 'link');

              return InkWell(
                onTap: () {
                  // TODO: Abrir URL externa
                  print('Abrindo: $url');
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'web':
        return Icons.language;
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'help':
        return Icons.help_outline;
      case 'info':
        return Icons.info_outline;
      default:
        return Icons.link;
    }
  }
}
