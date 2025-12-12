import 'package:flutter/material.dart';
import 'app_button.dart';

class AppError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppError({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 64),
            const SizedBox(height: 16),
            Text('Ocorreu um Erro', style: textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: textTheme.bodyMedium, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              AppButton(label: 'TENTAR NOVAMENTE', onPressed: onRetry!),
            ],
          ],
        ),
      ),
    );
  }
}
