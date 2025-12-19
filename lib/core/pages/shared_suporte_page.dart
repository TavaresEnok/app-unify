// Layout 02 - Suporte Page
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/providers.dart';

import '../../core/models/provider_config.dart';
import '../../layouts/layout_05/theme.dart';
import '../../layout_selector.dart';

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
    final isDarkLayout = layoutType == 'layout_06';

    final theme = Theme.of(context);
    Color backgroundColor;
    Color appBarColor;
    Color appBarTextColor;
    if (isDarkLayout) {
      backgroundColor = const Color(0xFF0A0A0A);
      appBarColor = const Color(0xFF0A0A0A);
      appBarTextColor = Colors.white;
    } else if (isLayout05) {
      backgroundColor = Layout05Theme.background;
      appBarColor = Layout05Theme.background;
      appBarTextColor = Layout05Theme.textDark;
    } else {
      backgroundColor = theme.scaffoldBackgroundColor;
      appBarColor = theme.primaryColor;
      appBarTextColor = Colors.white;
    }

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
          _buildConnectionStatusCard(context, usuario.status, isLayout05,
              isDarkLayout: isDarkLayout),
          const SizedBox(height: 24),
          // Removido "Canais de Atendimento" por solicitação - Redundante com o botão de WhatsApp abaixo
          // _buildContactChannelsCard(...),
          // const SizedBox(height: 24),
          _buildTicketCard(context, providerConfig, isLayout05,
              isDarkLayout: isDarkLayout),
          const SizedBox(height: 100), // Padding for BottomNav
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard(
      BuildContext context, String status, bool isLayout05,
      {bool isDarkLayout = false}) {
    final theme = Theme.of(context);
    final isOk = status.toLowerCase() == 'ativo';

    BoxDecoration decoration;
    if (isDarkLayout) {
      decoration = BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
      );
    } else if (isLayout05) {
      decoration = Layout05Theme.neumorphicDecoration;
    } else {
      decoration = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      );
    }

    // final textColor = isDarkLayout ? Colors.white : Colors.black87;
    // final subtitleColor =
    //    isDarkLayout ? const Color(0xFF8E8E93) : Colors.grey[600];

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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LayoutSelector.getDiagnosticoPage(
                              layoutType: isLayout05
                                  ? 'layout_05'
                                  : (isDarkLayout ? 'layout_06' : 'layout_02'),
                            ),
                          ),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LayoutSelector.getDiagnosticoPage(
                              layoutType: isLayout05
                                  ? 'layout_05'
                                  : (isDarkLayout ? 'layout_06' : 'layout_02'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(
      BuildContext context, ProviderConfig? providerConfig, bool isLayout05,
      {bool isDarkLayout = false}) {
    final theme = Theme.of(context);

    BoxDecoration decoration;
    if (isDarkLayout) {
      decoration = BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
      );
    } else if (isLayout05) {
      decoration = Layout05Theme.neumorphicDecoration;
    } else {
      decoration = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      );
    }

    // final textColor = isDarkLayout ? Colors.white : null;
    // final subtitleColor = isDarkLayout ? const Color(0xFF8E8E93) : null;

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

                  // 1. Tenta achar contato TIPO whatsapp
                  var uniqueContact = providerConfig.config.supportContacts
                      .where((c) =>
                          c.type.toLowerCase() == 'whatsapp' &&
                          c.value.isNotEmpty)
                      .firstOrNull;

                  // 2. Se não achar, tenta achar contato com NOME whatsapp
                  uniqueContact ??= providerConfig.config.supportContacts
                      .where((c) =>
                          c.name.toLowerCase().contains('whatsapp') &&
                          c.value.isNotEmpty)
                      .firstOrNull;

                  if (uniqueContact != null) {
                    final number =
                        uniqueContact.value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (number.isNotEmpty) {
                      launchUrl(
                        Uri.parse('https://wa.me/$number'),
                        mode: LaunchMode.externalApplication,
                      );
                      return;
                    }
                  }

                  // 3. Fallback: Se não achar nada de WhatsApp, tenta o primeiro telefone
                  final firstPhone = providerConfig.config.supportContacts
                      .where((c) =>
                          c.type.toLowerCase() == 'phone' && c.value.isNotEmpty)
                      .firstOrNull;

                  if (firstPhone != null) {
                    final number =
                        firstPhone.value.replaceAll(RegExp(r'[^0-9]'), '');
                    launchUrl(Uri.parse('tel:$number'));
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Nenhum canal de suporte encontrado.')),
                  );
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
