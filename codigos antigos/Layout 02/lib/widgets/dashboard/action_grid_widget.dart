import 'package:flutter/material.dart';

/// Widget de grid de ações rápidas
class ActionGridWidget extends StatelessWidget {
  final Map<String, dynamic> config;

  const ActionGridWidget({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final actions = (config['actions'] as List<dynamic>?)?.cast<String>() ??
        ['support', 'speed_test', 'invoices', 'notifications'];

    final columns = (config['columns'] as int?) ?? 2;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: actions.map((actionId) {
          final actionData = _getActionData(actionId);
          return _ActionCard(
            icon: actionData['icon'] as IconData,
            label: actionData['label'] as String,
            color: actionData['color'] as Color? ?? Colors.blue,
            onTap: () {
              // TODO: Navegar para ação correspondente
              print('Ação clicada: $actionId');
            },
          );
        }).toList(),
      ),
    );
  }

  Map<String, dynamic> _getActionData(String actionId) {
    switch (actionId) {
      case 'speed_test':
        return {
          'icon': Icons.speed,
          'label': 'Teste de Velocidade',
          'color': Colors.blue,
        };
      case 'support':
        return {
          'icon': Icons.support_agent,
          'label': 'Suporte',
          'color': Colors.orange,
        };
      case 'invoices':
        return {
          'icon': Icons.receipt_long,
          'label': 'Faturas',
          'color': Colors.green,
        };
      case 'notifications':
        return {
          'icon': Icons.notifications,
          'label': 'Notificações',
          'color': Colors.purple,
        };
      case 'internet_usage':
        return {
          'icon': Icons.bar_chart,
          'label': 'Consumo',
          'color': Colors.indigo,
        };
      case 'payment_promise':
        return {
          'icon': Icons.payment,
          'label': 'Promessa',
          'color': Colors.teal,
        };
      default:
        return {
          'icon': Icons.apps,
          'label': actionId,
          'color': Colors.grey,
        };
    }
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
