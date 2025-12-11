// ARQUIVO: lib/core/widgets/empty_state.dart
// DESCRIÇÃO: Widget para estados vazios com ilustração e mensagem

import 'package:flutter/material.dart';

/// Widget para exibir estado vazio com ilustração
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone com efeito
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (iconColor ?? theme.primaryColor).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: iconColor ?? theme.primaryColor.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 24),

            // Título
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            // Mensagem opcional
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Botão de ação opcional
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado vazio para lista de faturas
class NoInvoicesState extends StatelessWidget {
  final VoidCallback? onRefresh;

  const NoInvoicesState({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'Nenhuma fatura encontrada',
      message: 'Você está em dia! Não há faturas pendentes.',
      iconColor: Colors.green,
      actionLabel: onRefresh != null ? 'Atualizar' : null,
      onAction: onRefresh,
    );
  }
}

/// Estado vazio para diagnóstico sem dados
class NoDiagnosticDataState extends StatelessWidget {
  final VoidCallback? onStart;

  const NoDiagnosticDataState({super.key, this.onStart});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.network_check,
      title: 'Iniciar Diagnóstico',
      message: 'Clique no botão abaixo para verificar sua conexão.',
      actionLabel: onStart != null ? 'Iniciar' : null,
      onAction: onStart,
    );
  }
}

/// Estado de erro genérico
class ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Ops! Algo deu errado',
      message: message ?? 'Não foi possível carregar os dados.',
      iconColor: Colors.red,
      actionLabel: onRetry != null ? 'Tentar novamente' : null,
      onAction: onRetry,
    );
  }
}

/// Estado de sem conexão
class NoConnectionState extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoConnectionState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.wifi_off,
      title: 'Sem conexão',
      message: 'Verifique sua conexão com a internet e tente novamente.',
      iconColor: Colors.orange,
      actionLabel: onRetry != null ? 'Tentar novamente' : null,
      onAction: onRetry,
    );
  }
}
