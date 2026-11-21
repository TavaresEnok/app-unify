import 'package:flutter/material.dart';

/// Recoverable empty/error content; technical exceptions stay out of the UI.
class ContentState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const ContentState(
      {super.key,
      required this.icon,
      required this.title,
      required this.message,
      this.actionLabel,
      this.onAction});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
        child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: colors.onSurfaceVariant),
          const SizedBox(height: 20),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: colors.onSurfaceVariant, fontSize: 16, height: 1.5)),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 24),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ]),
      ),
    ));
  }
}
