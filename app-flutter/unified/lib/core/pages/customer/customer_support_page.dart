import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../providers/customer_capabilities_provider.dart';
import '../../navigation/customer_routes.dart';
import '../../services/customer_contact_launcher.dart';
import '../../vibe/vibe_page_parts.dart';

/// Suporte (`PG.suporte` do layout aprovado): assuntos que resolvem sem
/// chamado, os canais do provedor e as perguntas frequentes.
class CustomerSupportPage extends ConsumerWidget {
  final ValueChanged<String> onNavigate;
  const CustomerSupportPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configurationProvider).providerConfig;
    final name = config?.name.trim() ?? '';
    if (config == null || !CustomerRoutes.enabled(config, 'support')) {
      return const VibePageScaffold(
        title: 'Suporte',
        children: [
          VibeCard(
            child: VibeEmpty(
              icon: 'chat',
              title: 'Atendimento indisponível no app',
              text:
                  'Consulte os canais de atendimento informados pelo seu provedor.',
            ),
          ),
        ],
      );
    }
    bool can(String route) => CustomerRoutes.enabled(config, route);
    final wifiAvailable =
        ref.watch(wifiManagementAvailableProvider).valueOrNull == true;
    final contacts = config.config.supportContacts
        .where((c) => c.value.trim().isNotEmpty)
        .toList();
    final topics = <Widget>[
      if (can('network_diagnostic')) ...[
        VibeRow(
            icon: 'gauge',
            title: 'Internet lenta',
            subtitle: 'Verifique a conexão primeiro',
            onTap: () => onNavigate('network_diagnostic')),
        VibeRow(
            icon: 'alert',
            title: 'Sem internet',
            subtitle: 'Descubra onde está o problema',
            onTap: () => onNavigate('network_diagnostic')),
      ],
      if (can('invoices'))
        VibeRow(
            icon: 'file',
            title: 'Dúvida sobre fatura',
            subtitle: 'Valores, Pix e boleto',
            onTap: () => onNavigate('invoices')),
      if (wifiAvailable && can('wifi'))
        VibeRow(
            icon: 'wifi',
            title: 'Alterar nome ou senha do Wi-Fi',
            subtitle: 'Na sua rede de casa',
            onTap: () => onNavigate('wifi')),
      if (can('invoices'))
        VibeRow(
            icon: 'unlock',
            title: 'Internet bloqueada',
            subtitle: 'Liberação por confiança',
            onTap: () => onNavigate('trust_unlock')),
    ];
    return VibePageScaffold(
      title: 'Suporte',
      subtitle: name.isEmpty ? null : 'Atendimento da $name',
      children: [
        if (topics.isNotEmpty) ...[
          const VibeGroupTitle('Sobre o que você precisa de ajuda?'),
          VibeCard(child: VibeRows(children: topics)),
        ],
        VibeGroupTitle(name.isEmpty ? 'Fale com o provedor' : 'Fale com $name'),
        if (contacts.isEmpty)
          const VibeCard(
            child: VibeEmpty(
              icon: 'chat',
              title: 'Canais ainda não informados',
              text:
                  'Seu provedor ainda não informou canais de atendimento neste aplicativo.',
            ),
          )
        else
          VibeCard(
            child: VibeRows(children: [
              for (final contact in contacts)
                VibeRow(
                  icon: switch (contact.type.toLowerCase()) {
                    'whatsapp' => 'wa',
                    'phone' => 'g-phone',
                    'email' => 'g-mail',
                    _ => 'globe',
                  },
                  title: contact.name.isNotEmpty
                      ? contact.name
                      : switch (contact.type.toLowerCase()) {
                          'whatsapp' => 'WhatsApp',
                          'phone' => 'Telefone',
                          'email' => 'E-mail',
                          _ => 'Site',
                        },
                  subtitle: contact.type.toLowerCase() == 'whatsapp'
                      ? 'Abre com a mensagem pronta'
                      : contact.value,
                  onTap: () => openCustomerContact(context, contact),
                ),
            ]),
          ),
        if (can('faq'))
          VibeCard(
            child: VibeRow(
                icon: 'g-help',
                title: 'Perguntas frequentes',
                subtitle: 'Respostas rápidas',
                onTap: () => onNavigate('faq')),
          ),
      ],
    );
  }
}
