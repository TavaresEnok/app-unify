// LAYOUT 04 - AURORA - SUPORTE PAGE

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/configuration_provider.dart';
import 'aurora_theme.dart';

class SuportePage extends StatelessWidget {
  const SuportePage({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigurationProvider>().providerConfig;
    final contacts = config?.config.supportContacts ?? [];

    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          pinned: true,
          expandedHeight: 100,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'Suporte',
                    style: TextStyle(
                      color: AuroraColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Quick Help Card
              AuroraCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const AuroraIconBox(
                        icon: Icons.support_agent_rounded,
                        color: AuroraColors.primary),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Precisa de ajuda?',
                            style: TextStyle(
                              color: AuroraColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Nossa equipe está pronta para atender você',
                            style: TextStyle(
                                color: AuroraColors.textSecondary,
                                fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Channels Title
              const Text(
                'Canais de Atendimento',
                style: TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Contact Channels
              if (contacts.isNotEmpty)
                ...contacts.map((contact) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ContactCard(
                        title: contact.name,
                        subtitle: contact.value,
                        icon: _getIconFromType(contact.type),
                        color: _getColorFromType(contact.type),
                        onTap: () =>
                            _launchContact(contact.type, contact.value),
                      ),
                    ))
              else ...[
                _ContactCard(
                  title: 'WhatsApp',
                  subtitle: 'Atendimento rápido',
                  icon: Icons.chat_rounded,
                  color: AuroraColors.success,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _ContactCard(
                  title: 'Telefone',
                  subtitle: 'Ligue para nós',
                  icon: Icons.phone_rounded,
                  color: AuroraColors.primary,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _ContactCard(
                  title: 'Email',
                  subtitle: 'Envie uma mensagem',
                  icon: Icons.email_rounded,
                  color: AuroraColors.secondary,
                  onTap: () {},
                ),
              ],

              const SizedBox(height: 24),

              // Self-service
              const Text(
                'Autoatendimento',
                style: TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.help_outline_rounded,
                      label: 'FAQ',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.router_rounded,
                      label: 'Diagnóstico',
                      onTap: () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  IconData _getIconFromType(String type) {
    switch (type.toLowerCase()) {
      case 'whatsapp':
        return Icons.chat_rounded;
      case 'telefone':
      case 'phone':
        return Icons.phone_rounded;
      case 'email':
        return Icons.email_rounded;
      default:
        return Icons.support_rounded;
    }
  }

  Color _getColorFromType(String type) {
    switch (type.toLowerCase()) {
      case 'whatsapp':
        return AuroraColors.success;
      case 'telefone':
      case 'phone':
        return AuroraColors.primary;
      case 'email':
        return AuroraColors.secondary;
      default:
        return AuroraColors.warning;
    }
  }

  void _launchContact(String type, String value) async {
    String url;
    switch (type.toLowerCase()) {
      case 'whatsapp':
        url = 'https://wa.me/$value';
        break;
      case 'telefone':
      case 'phone':
        url = 'tel:$value';
        break;
      case 'email':
        url = 'mailto:$value';
        break;
      default:
        return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ContactCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ContactCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AuroraCard(
      onTap: onTap,
      child: Row(
        children: [
          AuroraIconBox(icon: icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AuroraColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: AuroraColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AuroraColors.textMuted),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AuroraCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          AuroraIconBox(icon: icon, color: AuroraColors.primary, size: 48),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: AuroraColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
