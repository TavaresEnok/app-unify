import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../../core/models/provider_config.dart';
import '../../core/providers/configuration_provider.dart';
import 'theme.dart';

class SuportePage extends StatelessWidget {
  const SuportePage({super.key});

  @override
  Widget build(BuildContext context) {
    final configProvider = context.read<ConfigurationProvider>();
    final config = configProvider.providerConfig?.config;

    return Scaffold(
      backgroundColor: Layout04Theme.background,
      appBar: AppBar(
        title: Text('Canal de Suporte', style: Layout04Theme.heading3),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: Layout04Theme.backgroundGradient,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 32),
              if (config != null) ...[
                // WhatsApp Integration (Find in contacts)
                if (config.supportContacts
                    .any((c) => c.type.toLowerCase() == 'whatsapp')) ...[
                  _SupportChannelCard(
                    title: 'WhatsApp',
                    subtitle: 'Atendimento via chat',
                    value: 'Iniciar conversa',
                    icon: Icons.chat_rounded,
                    color: Layout04Theme.success,
                    actionLabel: 'INICIAR AGORA',
                    onTap: () {
                      final contact = config.supportContacts.firstWhere(
                        (c) => c.type.toLowerCase() == 'whatsapp',
                        orElse: () => const SupportContactItem(
                            name: '', type: '', value: ''),
                      );
                      if (contact.value.isNotEmpty)
                        _openWhatsApp(contact.value);
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Support Contacts List
                ...config.supportContacts.map((contact) {
                  IconData icon;
                  Color color;
                  String actionLabel;
                  VoidCallback onTap;

                  switch (contact.type.toLowerCase()) {
                    case 'whatsapp':
                      icon = Icons.chat_rounded;
                      color = Layout04Theme.success;
                      actionLabel = 'INICIAR CONVERSA';
                      onTap = () => _openWhatsApp(contact.value);
                      break;
                    case 'phone':
                    case 'telefone':
                      icon = Icons.phone_rounded;
                      color = Layout04Theme.primaryCyan;
                      actionLabel = 'LIGAR AGORA';
                      onTap = () => _makeCall(contact.value);
                      break;
                    case 'email':
                      icon = Icons.email_rounded;
                      color = Layout04Theme.primaryPink;
                      actionLabel = 'COPIAR E-MAIL';
                      onTap = () {
                        Clipboard.setData(ClipboardData(text: contact.value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('E-mail copiado!'),
                            backgroundColor: Layout04Theme.success,
                          ),
                        );
                      };
                      break;
                    default:
                      icon = Icons.support_agent_rounded;
                      color = Layout04Theme.primaryPurple;
                      actionLabel = 'ENTRAR EM CONTATO';
                      onTap = () {};
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _SupportChannelCard(
                      title: contact.name,
                      subtitle: contact.type.toUpperCase(),
                      value: contact.value,
                      icon: icon,
                      color: color,
                      actionLabel: actionLabel,
                      onTap: onTap,
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: Layout04Theme.glassCard(borderRadius: 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: Layout04Theme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow:
                      Layout04Theme.neonGlow(Layout04Theme.primaryPurple),
                ),
                child: const Icon(
                  Icons.headset_mic_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Como podemos ajudar?',
                      style: Layout04Theme.heading2.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selecione um canal abaixo para falar com nosso time.',
                      style: Layout04Theme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = 'https://wa.me/55$cleanPhone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = 'tel:$cleanPhone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}

class _SupportChannelCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color color;
  final String actionLabel;
  final VoidCallback onTap;

  const _SupportChannelCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: Layout04Theme.glassCard(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: Layout04Theme.heading3),
                          const SizedBox(height: 2),
                          Text(subtitle, style: Layout04Theme.bodySmall),
                          const SizedBox(height: 4),
                          Text(value, style: Layout04Theme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: Layout04Theme.glassBorder,
              ),
              InkWell(
                onTap: onTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                  ),
                  child: Text(
                    actionLabel,
                    style: Layout04Theme.buttonText.copyWith(
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
