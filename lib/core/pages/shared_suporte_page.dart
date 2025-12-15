// Layout 02 - Suporte Page
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/providers.dart';

import '../../core/models/provider_config.dart';

class SuportePage extends ConsumerWidget {
  const SuportePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configurationProvider);
    final authState = ref.read(authNotifierProvider);
    final providerConfig = config.providerConfig;
    final usuario = authState.value;

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
          _buildTicketCard(context, providerConfig),
          const SizedBox(height: 180), // Padding for BottomNav
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

  Widget _buildTicketCard(
      BuildContext context, ProviderConfig? providerConfig) {
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
              'Entre em contato diretamente com nosso suporte técnico via WhatsApp.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat), // Changed icon to chat
                label:
                    const Text('Abrir Chamado via WhatsApp'), // Updated label
                onPressed: () {
                  if (providerConfig == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erro de configuração.')),
                    );
                    return;
                  }

                  // Find WhatsApp contact
                  try {
                    final whatsapp = providerConfig.config.supportContacts
                        .firstWhere((c) => c.type == 'whatsapp');

                    if (whatsapp.value.isNotEmpty) {
                      launchUrl(
                        Uri.parse('https://wa.me/${whatsapp.value}'),
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      throw Exception('Número vazio');
                    }
                  } catch (_) {
                    // Fallback to first phone or show error
                    try {
                      final phone = providerConfig.config.supportContacts
                          .firstWhere((c) => c.type == 'phone');
                      launchUrl(Uri.parse('tel:${phone.value}'));
                    } catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Nenhum canal de suporte encontrado.')),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
