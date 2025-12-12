import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'shared/theme/app_colors.dart';
import 'shared/widgets/app_button.dart';
import 'shared/widgets/dashboard_card.dart';
import 'configuration_provider.dart';
import 'page_mapper.dart';
import 'abrir_chamado_page.dart';
import 'models/provider_config.dart';

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

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildConnectionStatusCard(context, providerConfig),
        const SizedBox(height: 24),
        _buildContactChannelsCard(context, providerConfig),
        const SizedBox(height: 24),
        _buildTicketCard(context),
      ],
    );
  }

  Widget _buildConnectionStatusCard(
      BuildContext context, ProviderConfig providerConfig) {
    final textTheme = Theme.of(context).textTheme;
    final bool isOk = status.toLowerCase() == 'ativo';

    return DashboardCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              context
                  .read<ConfigurationProvider>()
                  .getString('status_label', 'Status da Conexão'),
              style: textTheme.headlineMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOk ? AppColors.success : AppColors.error,
                    boxShadow: [
                      BoxShadow(
                          color: (isOk ? AppColors.success : AppColors.error)
                              .withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2),
                    ]),
              ),
              const SizedBox(width: 12),
              Text(status,
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isOk
                ? context.read<ConfigurationProvider>().getString(
                    'status_ok_message',
                    'Sua conexão está funcionando normalmente. Se ainda assim encontrar problemas, tente nosso diagnóstico.')
                : context.read<ConfigurationProvider>().getString(
                    'status_error_message',
                    'Detectamos um problema com sua conexão. Verifique suas faturas ou entre em contato conosco.'),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.network_check, size: 20),
              label: Text(context
                  .read<ConfigurationProvider>()
                  .getString('network_diagnostic', 'Diagnóstico de Rede')),
              onPressed: () => navigateToPageById(
                context: context,
                pageId: 'network_diagnostic',
                cpfCnpj: cpfCnpj,
                senha: senha,
                status: status,
                clientName: clientName,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactChannelsCard(
      BuildContext context, ProviderConfig providerConfig) {
    final textTheme = Theme.of(context).textTheme;
    final contacts = providerConfig.config.supportContacts;

    if (contacts.isEmpty) return const SizedBox.shrink();

    return DashboardCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              context
                  .read<ConfigurationProvider>()
                  .getString('channels_title', 'Canais de Atendimento'),
              style: textTheme.headlineMedium),
          const SizedBox(height: 16),
          ...contacts
              .map((contact) => _buildContactTile(context, contact))
              .expand((widget) => [widget, const SizedBox(height: 8)]),
        ],
      ),
    );
  }

  Widget _buildContactTile(BuildContext context, SupportContactItem contact) {
    final textTheme = Theme.of(context).textTheme;
    IconData icon;
    VoidCallback onTap;

    switch (contact.type) {
      case 'phone':
        icon = FontAwesomeIcons.phone;
        onTap = () => launchUrl(Uri.parse('tel:${contact.value}'));
        break;
      case 'whatsapp':
        icon = FontAwesomeIcons.whatsapp;
        onTap = () => launchUrl(Uri.parse('https://wa.me/${contact.value}'),
            mode: LaunchMode.externalApplication);
        break;
      case 'email':
        icon = FontAwesomeIcons.envelope;
        onTap = () => launchUrl(Uri.parse('mailto:${contact.value}'));
        break;
      default:
        icon = FontAwesomeIcons.globe;
        onTap = () {};
    }

    return Material(
      color: AppColors.inputFill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 16),
              Expanded(child: Text(contact.name, style: textTheme.bodyLarge)),
              Icon(Icons.arrow_forward_ios,
                  color: AppColors.textHint, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DashboardCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              context.read<ConfigurationProvider>().getString(
                  'complex_problem_title', 'Precisa de Ajuda Detalhada?'),
              style: textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(
            context.read<ConfigurationProvider>().getString(
                'complex_problem_message',
                'Abra um ticket de suporte para que nossa equipe técnica possa analisar seu caso com mais detalhes. Anexe prints se necessário.'),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              icon: Icons.support_agent,
              label: context
                  .read<ConfigurationProvider>()
                  .getString('open_ticket_title', 'Abrir um Chamado'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AbrirChamadoPage(cpfCnpj: cpfCnpj)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
