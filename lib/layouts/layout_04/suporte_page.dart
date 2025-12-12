// LAYOUT 04 - AURORA - SUPORTE PAGE (FIXED)
// Design: Modern support page with glassmorphic cards

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../core/providers/configuration_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/provider_config.dart';
import 'aurora_theme.dart';

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
          body: Center(child: Text('Configuração não encontrada')));
    }

    final contacts = providerConfig.config.supportContacts;

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: ShaderMask(
            shaderCallback: (bounds) =>
                AuroraColors.primaryGradient.createShader(bounds),
            child: const Text('Suporte',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Hero Card
            GlassCard(
              glowColor: AuroraColors.neonCyan,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AuroraColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: AuroraColors.neonCyan.withOpacity(0.4),
                            blurRadius: 25,
                            spreadRadius: 5),
                      ],
                    ),
                    child: const Icon(Icons.headset_mic,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Como podemos ajudar?',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AuroraColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nossa equipe está disponível para ajudar',
                    style: TextStyle(color: AuroraColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Status Card
            GlassCard(
              glowColor: usuario.status.toLowerCase() == 'ativo'
                  ? AuroraColors.success
                  : AuroraColors.error,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: usuario.status.toLowerCase() == 'ativo'
                          ? AuroraColors.success
                          : AuroraColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Status: ${usuario.status}',
                    style: const TextStyle(
                        color: AuroraColors.textPrimary,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Contact Options
            if (contacts.isNotEmpty) ...[
              Text(
                'Canais de Atendimento',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AuroraColors.textPrimary),
              ),
              const SizedBox(height: 16),
              ...contacts.map((contact) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildContactOption(context, contact),
                  )),
            ],

            const SizedBox(height: 24),

            // Support Ticket
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.support_agent, color: AuroraColors.neonCyan),
                      const SizedBox(width: 12),
                      const Text(
                        'Precisa de Ajuda?',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AuroraColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Abra um chamado de suporte para que nossa equipe técnica possa analisar seu caso.',
                    style: TextStyle(color: AuroraColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: NeonButton(
                      text: 'Abrir Chamado',
                      icon: Icons.chat_bubble_outline,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text('Sistema de chamados em breve!'),
                            backgroundColor: AuroraColors.neonPurple,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption(BuildContext context, SupportContactItem contact) {
    IconData icon;
    Color color;
    VoidCallback onTap;

    switch (contact.type) {
      case 'phone':
        icon = Icons.phone;
        color = AuroraColors.neonCyan;
        onTap = () => launchUrl(Uri.parse('tel:${contact.value}'));
        break;
      case 'whatsapp':
        icon = Icons.chat;
        color = const Color(0xFF25D366);
        onTap = () => launchUrl(Uri.parse('https://wa.me/${contact.value}'),
            mode: LaunchMode.externalApplication);
        break;
      case 'email':
        icon = Icons.email;
        color = AuroraColors.neonPurple;
        onTap = () => launchUrl(Uri.parse('mailto:${contact.value}'));
        break;
      default:
        icon = Icons.public;
        color = AuroraColors.textMuted;
        onTap = () {};
    }

    return GlassCard(
      glowColor: color,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(contact.name,
                style: const TextStyle(
                    color: AuroraColors.textPrimary,
                    fontWeight: FontWeight.w600)),
          ),
          Icon(Icons.arrow_forward_ios,
              color: AuroraColors.textMuted, size: 16),
        ],
      ),
    );
  }
}
