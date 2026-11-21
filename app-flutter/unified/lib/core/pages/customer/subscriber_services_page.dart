import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/fatura.dart';
import '../../navigation/customer_routes.dart';
import '../../providers/customer_capabilities_provider.dart';
import '../../providers/financeiro_provider.dart';
import '../../providers/providers.dart';
import '../../services/customer_contact_launcher.dart';
import '../../utils/app_formatters.dart';
import '../../vibe/vibe_icon.dart';
import '../../vibe/vibe_page_parts.dart';
import '../../vibe/vibe_text.dart';
import '../../vibe/vibe_tokens.dart';
import '../invoice_detail_page.dart';

/// Serviços principais na ordem de relevância do layout aprovado (`QREL`):
/// rota, nome e ícone.
const subscriberShortcuts = <(String, String, String)>[
  ('invoices', 'Faturas', 'file'),
  ('support', 'Suporte', 'chat'),
  ('internet_usage', 'Consumo', 'g-chart'),
  ('speed_test', 'Velocidade', 'gauge'),
  ('my_ip', 'Meu IP', 'globe'),
  ('network_diagnostic', 'Diagnóstico', 'pulse'),
  ('trace_route', 'Tracert', 'g-route'),
];

/// Todos os serviços (`PG.servicos`): grade de três colunas, do mais usado
/// ao menos usado.
class SubscriberServicesPage extends ConsumerWidget {
  const SubscriberServicesPage({super.key, required this.onNavigate});

  final ValueChanged<String> onNavigate;

  Future<void> _chooseInvoice(
      BuildContext context, List<Fatura> invoices) async {
    if (invoices.isEmpty) return;
    final selected = invoices.length == 1
        ? invoices.first
        : await showModalBottomSheet<Fatura>(
            context: context,
            showDragHandle: true,
            builder: (sheet) {
              final t = VibeTokens.of(sheet);
              return SafeArea(
                child: ListView(shrinkWrap: true, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child:
                        Text('Escolha a fatura', style: vibeText(t, 17, 800)),
                  ),
                  for (final invoice in invoices)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: VibeRow(
                        icon: 'file',
                        title: AppFormatters.currency(invoice.valor),
                        subtitle:
                            'Vencimento ${AppFormatters.date(invoice.vencimento)}',
                        onTap: () => Navigator.pop(sheet, invoice),
                      ),
                    ),
                ]),
              );
            },
          );
    if (selected != null && context.mounted) {
      await openSubscriberInvoice(context, selected);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configurationProvider).providerConfig;
    if (config == null) return const SizedBox.shrink();
    bool enabled(String id) => CustomerRoutes.enabled(config, id);
    final invoices = ref.watch(financeiroViewModelProvider);
    final documents = invoices.invoices
        .where((f) => f.urlBoleto?.trim().isNotEmpty == true)
        .toList();
    final whatsapp = config.config.supportContacts
        .where((item) =>
            item.type.toLowerCase() == 'whatsapp' &&
            item.value.trim().isNotEmpty)
        .firstOrNull;
    final hasWifi = enabled('wifi') &&
        ref.watch(wifiManagementAvailableProvider).valueOrNull == true;
    final services = <(String, String, VoidCallback)>[];
    void route(String id, String title, String icon) {
      if (enabled(id)) services.add((title, icon, () => onNavigate(id)));
    }

    for (final (id, title, icon) in subscriberShortcuts) {
      route(id, title, icon);
    }
    if (enabled('invoices')) {
      if (invoices.pendingInvoices.isNotEmpty) {
        services.add((
          'Pagar fatura',
          'pix',
          () => _chooseInvoice(context, invoices.pendingInvoices)
        ));
      }
      if (documents.isNotEmpty) {
        services.add((
          'PDF da fatura',
          'down',
          () => _chooseInvoice(context, documents)
        ));
      }
      if (invoices.pendingInvoices.any((f) => f.isVencido)) {
        route('trust_unlock', 'Liberar internet', 'unlock');
      }
    }
    route('ping', 'Ping', 'pulse');
    route('history', 'Histórico', 'clock');
    if (enabled('support') && whatsapp != null) {
      services.add(
          ('WhatsApp', 'wa', () => openCustomerContact(context, whatsapp)));
    }
    route('faq', 'Dúvidas', 'g-help');
    route('contract', 'Contrato', 'doc');
    route('notifications', 'Notificações', 'bell');
    route('account', 'Minha conta', 'user');
    route('achievements', 'Conquistas', 'g-trophy');
    if (config.config.promotions.activePromotions.isNotEmpty) {
      route('promotions', 'Ofertas', 'gift');
    }
    if (hasWifi) route('wifi', 'Meu Wi-Fi', 'wifi');

    return VibePageScaffold(
      title: 'Todos os serviços',
      subtitle: 'Do mais usado ao menos usado',
      onBack: Navigator.of(context).canPop()
          ? () => Navigator.of(context).maybePop()
          : null,
      children: [_ServiceGrid(services: services)],
    );
  }
}

/// Grade de serviços (`.g-grid`): blocos com ícone em caixa e nome.
class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({required this.services});

  final List<(String, String, VoidCallback)> services;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(builder: (context, constraints) {
      final columns = (constraints.maxWidth / (96 * scale)).floor().clamp(1, 3);
      final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
      return Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (title, icon, action) in services)
          SizedBox(
            width: width,
            child: Semantics(
              button: true,
              label: title,
              excludeSemantics: true,
              child: Material(
                color: t.card,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(math.max(10, t.rad - 4)),
                    side: BorderSide(color: t.line)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: action,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    child: Column(children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: t.ac.withValues(alpha: t.dark ? .22 : .15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: VibeIcon(icon,
                            size: 20,
                            color: t.dark
                                ? vibeMix(t.ac, Colors.white, .40)
                                : t.at),
                      ),
                      const SizedBox(height: 8),
                      Text(title,
                          textAlign: TextAlign.center,
                          style: vibeText(t, 12.5, 650, height: 1.2)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
      ]);
    });
  }
}
