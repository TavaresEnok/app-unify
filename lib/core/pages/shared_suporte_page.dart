// Layout 02 - Suporte Page
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/configuration_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/provider_config.dart';

class SuportePage extends StatelessWidget {
  const SuportePage({super.key});

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<ConfigurationProvider>();
    final authService = context.read<AuthService>();
    final providerConfig = configProvider.providerConfig;
    final usuario = authService.usuario;

    if (providerConfig == null || usuario == null) {
      return const Scaffold(
        body: Center(child: Text('Configuração não encontrada')),
      );
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildConnectionStatusCard(context, usuario.status),
          const SizedBox(height: 24),
          _buildContactChannelsCard(context, providerConfig),
          const SizedBox(height: 24),
          _buildTicketCard(context),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard(BuildContext context, String status) {
    final theme = Theme.of(context);
    final isOk = status.toLowerCase() == 'ativo';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status da Conexão',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOk ? Colors.green : Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: (isOk ? Colors.green : Colors.red)
                            .withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  status,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isOk
                  ? 'Sua conexão está funcionando normalmente. Se encontrar problemas, tente nosso diagnóstico.'
                  : 'Detectamos um problema com sua conexão. Verifique suas faturas ou entre em contato.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.network_check, size: 20),
                label: const Text('Diagnóstico de Rede'),
                onPressed: () {
                  // TODO: Navegar para diagnóstico
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Diagnóstico em breve!')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactChannelsCard(
      BuildContext context, ProviderConfig providerConfig) {
    final theme = Theme.of(context);
    final contacts = providerConfig.config.supportContacts;

    if (contacts.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Canais de Atendimento',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...contacts.map((contact) => _buildContactTile(context, contact)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(BuildContext context, SupportContactItem contact) {
    final theme = Theme.of(context);
    IconData icon;
    VoidCallback onTap;

    switch (contact.type) {
      case 'phone':
        icon = Icons.phone;
        onTap = () => launchUrl(Uri.parse('tel:${contact.value}'));
        break;
      case 'whatsapp':
        icon = Icons.chat;
        onTap = () => launchUrl(
              Uri.parse('https://wa.me/${contact.value}'),
              mode: LaunchMode.externalApplication,
            );
        break;
      case 'email':
        icon = Icons.email;
        onTap = () => launchUrl(Uri.parse('mailto:${contact.value}'));
        break;
      default:
        icon = Icons.public;
        onTap = () {};
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(contact.name, style: theme.textTheme.bodyLarge),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: theme.colorScheme.onSurfaceVariant, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Precisa de Ajuda?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Abra um ticket de suporte para que nossa equipe técnica possa analisar seu caso.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.support_agent),
                label: const Text('Abrir Chamado'),
                onPressed: () {
                  // TODO: Navegar para página de abrir chamado
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chamados em breve!')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
