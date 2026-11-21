import 'package:flutter/material.dart';
import '../../widgets/customer_ui.dart';

/// Related navigation destinations displayed together as a single card.
class CustomerGroupedActions extends StatelessWidget {
  final List<Widget> children;
  const CustomerGroupedActions({super.key, required this.children});

  @override
  Widget build(BuildContext context) => CustomerCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 64, endIndent: 16),
              children[i],
            ],
          ],
        ),
      );
}

class CustomerGroupedAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const CustomerGroupedAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colors.primary, size: 21),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
