import 'package:flutter/material.dart';
import '../../core/models/provider_config.dart';
import 'package:provider/provider.dart';
import '../../core/providers/configuration_provider.dart';
import 'theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SuportePage extends StatelessWidget {
  const SuportePage({super.key});

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<ConfigurationProvider>();
    // Accessing config properly via helper getter if available, or direct property chain
    final supportContacts =
        configProvider.providerConfig?.config.supportContacts ?? [];

    return Scaffold(
      backgroundColor: Layout04Theme.background,
      appBar: AppBar(
        title: Text('Central de Ajuda', style: Layout04Theme.heading3),
        backgroundColor: Layout04Theme.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Como podemos ajudar você hoje?',
            style: Layout04Theme.heading2,
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione um canal de atendimento abaixo',
            style: Layout04Theme.bodyMedium,
          ),
          const SizedBox(height: 32),
          if (supportContacts.isEmpty)
            _SupportOption(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'WhatsApp',
              subtitle: 'Fale com nosso time',
              onTap: () {},
            )
          else
            ...supportContacts.map((contact) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _SupportOption(
                  icon: _getIconForType(contact.type),
                  title: contact.name,
                  subtitle: contact.value,
                  onTap: () => _launchContact(contact),
                ),
              );
            }),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'whatsapp':
        return Icons.chat;
      case 'phone':
        return Icons.phone_rounded;
      case 'email':
        return Icons.email_rounded;
      default:
        return Icons.support_agent_rounded;
    }
  }

  void _launchContact(SupportContactItem contact) async {
    // Basic launcher implementation
    final Uri uri;
    if (contact.type == 'phone') {
      uri = Uri.parse('tel:${contact.value}');
    } else if (contact.type == 'email') {
      uri = Uri.parse('mailto:${contact.value}');
    } else {
      // Assume web/whatsapp
      uri = Uri.parse(contact.value);
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }
}

class _SupportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: Layout04Theme.cardDecoration,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Layout04Theme.surfaceHighlight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Layout04Theme.primary, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Layout04Theme.heading3.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Layout04Theme.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Layout04Theme.textTertiary, size: 16),
          ],
        ),
      ),
    );
  }
}
