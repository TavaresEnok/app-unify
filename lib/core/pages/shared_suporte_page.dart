// Layout 02 - Suporte Page
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/providers.dart';

import '../../core/models/provider_config.dart';
import '../../layouts/layout_05/theme.dart';

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

    final layoutType = providerConfig.layoutType;
    final isLayout05 = layoutType == 'layout_05';

    final theme = Theme.of(context);
    final backgroundColor =
        isLayout05 ? Layout05Theme.background : theme.scaffoldBackgroundColor;
    final appBarColor =
        isLayout05 ? Layout05Theme.background : theme.primaryColor;
    final appBarTextColor = isLayout05 ? Layout05Theme.textDark : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Suporte', style: TextStyle(color: appBarTextColor)),
        backgroundColor: appBarColor,
        iconTheme: IconThemeData(color: appBarTextColor),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildConnectionStatusCard(context, usuario.status, isLayout05),
          const SizedBox(height: 24),
          _buildContactChannelsCard(context, providerConfig, isLayout05),
          const SizedBox(height: 24),
          _buildTicketCard(context, providerConfig, isLayout05),
          const SizedBox(height: 100), // Padding for BottomNav
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard(
      BuildContext context, String status, bool isLayout05) {
    final theme = Theme.of(context);
    final isOk = status.toLowerCase() == 'ativo';

    final decoration = isLayout05
        ? Layout05Theme.neumorphicDecoration
        : BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ],
          );

    return Container(
      decoration: decoration,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status da Conexão',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isLayout05 ? Layout05Theme.textDark : null,
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
                    color: isLayout05 ? Layout05Theme.textDark : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isOk
                  ? 'Sua conexão está funcionando normalmente. Se encontrar problemas, tente nosso diagnóstico.'
                  : 'Detectamos um problema com sua conexão. Verifique suas faturas ou entre em contato.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isLayout05 ? Layout05Theme.textGrey : null,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: isLayout05
                  ? ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Diagnóstico em breve!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Layout05Theme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Diagnóstico de Rede'),
                    )
                  : OutlinedButton.icon(
                      icon: const Icon(Icons.network_check, size: 20),
                      label: const Text('Diagnóstico de Rede'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Diagnóstico em breve!')),
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
      BuildContext context, ProviderConfig providerConfig, bool isLayout05) {
    final theme = Theme.of(context);
    final contacts = providerConfig.config.supportContacts;

    if (contacts.isEmpty) return const SizedBox.shrink();

    final decoration = isLayout05
        ? Layout05Theme.neumorphicDecoration
        : BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ],
          );

    return Container(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Canais de Atendimento',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isLayout05 ? Layout05Theme.textDark : null,
              ),
            ),
            const SizedBox(height: 16),
            ...contacts.map(
                (contact) => _buildContactTile(context, contact, isLayout05)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(
      BuildContext context, SupportContactItem contact, bool isLayout05) {
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

    final tileDecoration = isLayout05
        ? Layout05Theme.flatDecoration
        : BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: tileDecoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon,
                    color: isLayout05
                        ? Layout05Theme.primary
                        : theme.colorScheme.primary,
                    size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(contact.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isLayout05 ? Layout05Theme.textDark : null,
                      )),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: isLayout05
                        ? Layout05Theme.textGrey
                        : theme.colorScheme.onSurfaceVariant,
                    size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(
      BuildContext context, ProviderConfig? providerConfig, bool isLayout05) {
    final theme = Theme.of(context);

    final decoration = isLayout05
        ? Layout05Theme.neumorphicDecoration
        : BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ],
          );

    return Container(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Precisa de Ajuda?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isLayout05 ? Layout05Theme.textDark : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Entre em contato diretamente com nosso suporte técnico via WhatsApp.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isLayout05 ? Layout05Theme.textGrey : null,
              ),
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
                style: isLayout05
                    ? ElevatedButton.styleFrom(
                        backgroundColor: Layout05Theme.secondary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
