import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'shared/theme/app_colors.dart';
import 'configuration_provider.dart';
import 'page_mapper.dart';
import 'abrir_chamado_page.dart';
import 'models/provider_config.dart';
import 'utils.dart'; // Importado para hexToColor

class SuportePage extends StatelessWidget {
  final String cpfCnpj;
  final String senha;
  final String status;
  final String clientName;

  const SuportePage({
    super.key,
    required this.cpfCnpj,
    required this.senha,
    required this.status,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context) {
    final providerConfig =
        context.watch<ConfigurationProvider>().providerConfig!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context
            .read<ConfigurationProvider>()
            .getString('support_title', 'Central de Ajuda')),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _buildConnectionStatusCard(context),
          const SizedBox(height: 24),
          Text(
              context
                  .read<ConfigurationProvider>()
                  .getString('channels_title', 'Fale com a gente'),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildContactChannelsCard(context, providerConfig),
          const SizedBox(height: 24),
          _buildTicketCard(
              context, providerConfig), // Passando config para pegar a cor
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard(BuildContext context) {
    final theme = Theme.of(context);
    final bool isOk =
        status.toLowerCase() == 'ativo' || status.toLowerCase() == 'conectado';
    final color = isOk ? AppColors.success : AppColors.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(isOk ? Icons.check_circle : Icons.error,
                      color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        context
                            .read<ConfigurationProvider>()
                            .getString('status_label', 'Status da Rede'),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold)),
                    Text(
                        isOk
                            ? context
                                .read<ConfigurationProvider>()
                                .getString('status_ok_title', 'Conexão Estável')
                            : context.read<ConfigurationProvider>().getString(
                                'status_error_title', 'Instabilidade'),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isOk
                  ? context.read<ConfigurationProvider>().getString(
                      'status_ok_message',
                      'Sua conexão está operando normalmente. Se notar lentidão, faça um diagnóstico rápido.')
                  : context.read<ConfigurationProvider>().getString(
                      'status_error_message',
                      'Detectamos possíveis problemas. Verifique seus cabos ou inicie um diagnóstico.'),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.speed_rounded),
                label: Text(context
                    .read<ConfigurationProvider>()
                    .getString('network_diagnostic', 'Testar Conexão')),
                onPressed: () => PageMapper.navigateTo(context, 'diagnostico'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactChannelsCard(
      BuildContext context, ProviderConfig providerConfig) {
    final contacts = providerConfig.config.supportContacts;

    if (contacts.isEmpty) return const SizedBox.shrink();

    return Column(
      children: contacts
          .map((contact) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildContactTile(context, contact),
              ))
          .toList(),
    );
  }

  Widget _buildContactTile(BuildContext context, SupportContactItem contact) {
    final theme = Theme.of(context);
    IconData icon;
    Color iconColor;
    VoidCallback onTap;

    switch (contact.type) {
      case 'phone':
        icon = FontAwesomeIcons.phone;
        iconColor = Colors.blue;
        onTap = () => launchUrl(Uri.parse('tel:${contact.value}'));
        break;
      case 'whatsapp':
        icon = FontAwesomeIcons.whatsapp;
        iconColor = Colors.green;
        onTap = () => launchUrl(Uri.parse('https://wa.me/${contact.value}'),
            mode: LaunchMode.externalApplication);
        break;
      case 'email':
        icon = FontAwesomeIcons.envelope;
        iconColor = Colors.orange;
        onTap = () => launchUrl(Uri.parse('mailto:${contact.value}'));
        break;
      default:
        icon = FontAwesomeIcons.globe;
        iconColor = Colors.grey;
        onTap = () {};
    }

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(contact.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600))),
              Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, ProviderConfig providerConfig) {
    // Lendo a cor de ação
    final actionColor = providerConfig.config.actionColor != null
        ? hexToColor(providerConfig.config.actionColor!)
        : AppColors.primaryBlue;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:
            actionColor.withOpacity(0.05), // Usando a cor de ação com opacidade
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: actionColor.withOpacity(0.2)), // Borda com a cor de ação
      ),
      child: Column(
        children: [
          Icon(Icons.support_agent_rounded,
              size: 40, color: actionColor), // Ícone com a cor de ação
          const SizedBox(height: 12),
          Text(
              context
                  .read<ConfigurationProvider>()
                  .getString('complex_problem_title', 'Problema complexo?'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            context.read<ConfigurationProvider>().getString(
                'complex_problem_message',
                'Se os canais acima não resolveram, abra um chamado técnico detalhado.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor, // Botão com a cor de ação
                foregroundColor: Colors.white, // Texto branco
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AbrirChamadoPage(cpfCnpj: cpfCnpj)),
                );
              },
              child: Text(context
                  .read<ConfigurationProvider>()
                  .getString('open_ticket_title', 'Abrir Chamado')),
            ),
          ),
        ],
      ),
    );
  }
}
