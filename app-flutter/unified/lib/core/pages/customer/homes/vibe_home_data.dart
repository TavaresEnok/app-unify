import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/fatura.dart';
import '../../../models/provider_config.dart';
import '../../../models/usuario.dart';
import '../../../navigation/customer_routes.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../providers/customer_capabilities_provider.dart';
import '../../../providers/financeiro_provider.dart';
import '../../../providers/providers.dart';
import '../../../vibe/vibe_home_parts.dart';
import '../../../vibe/vibe_invoice.dart';
import '../../../vibe/vibe_tokens.dart';
import '../../invoice_detail_page.dart';
import '../promotions_page.dart';
import '../../../utils/app_formatters.dart';

/// Dados do Início compartilhados pelos cinco layouts aprovados.
class VibeHomeData {
  VibeHomeData._({
    required this.config,
    required this.user,
    required this.billing,
    required this.network,
    required this.wifiAvailable,
    required this.unread,
    required this.onNavigate,
  });

  factory VibeHomeData.watch(WidgetRef ref, ValueChanged<String> onNavigate) {
    final connection = ref.watch(connectivityStatusProvider).valueOrNull;
    return VibeHomeData._(
      config: ref.watch(configurationProvider).providerConfig,
      user: ref.watch(authNotifierProvider).valueOrNull,
      billing: VibeBilling(ref.watch(financeiroViewModelProvider)),
      network: vibeNetworkOf(connection),
      wifiAvailable:
          ref.watch(wifiManagementAvailableProvider).valueOrNull == true,
      unread: ref.watch(notificationProvider).unreadCount,
      onNavigate: onNavigate,
    );
  }

  final ProviderConfig? config;
  final Usuario? user;
  final VibeBilling billing;
  final VibeNetwork network;
  final bool wifiAvailable;
  final int unread;
  final ValueChanged<String> onNavigate;

  bool can(String route) =>
      config == null || CustomerRoutes.enabled(config!, route);

  bool get suspended => user?.isSuspended == true;

  List<String> get _names => (user?.nome ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((n) => n.isNotEmpty)
      .toList();

  String get firstName {
    final n = _names;
    if (n.isEmpty) return 'cliente';
    final w = n.first.toLowerCase();
    return '${w[0].toUpperCase()}${w.substring(1)}';
  }

  /// Primeiro e último nome ("Marina Costa").
  String get shortName {
    final n = _names;
    if (n.isEmpty) return 'Cliente';
    String cap(String s) =>
        '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
    return n.length == 1 ? cap(n.first) : '${cap(n.first)} ${cap(n.last)}';
  }

  String get initials {
    final n = _names;
    if (n.isEmpty) return '?';
    final first = n.first.characters.first;
    final last = n.length > 1 ? n.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  String get plan => AppFormatters.label(user?.plano);

  /// Com a fatura paga, a próxima data pelo dia de vencimento do contrato
  /// (`NX` do protótipo). Sem o dia no cadastro, nada é presumido.
  DateTime? nextDue({DateTime? today}) {
    final main = billing.main;
    final day = AppFormatters.dueDayOf(user?.vencimentoFatura ?? '');
    if (main == null || !main.paid || day == null) return null;
    final now = today ?? DateTime.now();
    final paidDue = main.invoice.vencimento;
    return AppFormatters.nextDue(day, paidDue.isAfter(now) ? paidDue : now);
  }

  String get providerName => config?.name.trim() ?? '';
  String? get logoUrl => config?.config.logoUrl;

  String? get contractLabel =>
      user?.contratoId == null ? null : 'Contrato ${user!.contratoId}';

  void openNotifications() => onNavigate('notifications');
  void openAccount() => onNavigate('account');
  void openDiagnostic() => onNavigate('network_diagnostic');

  VoidCallback? get bellAction =>
      can('notifications') ? openNotifications : null;

  /// Atalhos por relevância (`QREL` do protótipo): o último vira
  /// "Ver todos". Destinos desligados pelo provedor dão lugar ao seguinte.
  List<VibeShortcut> shortcuts(int count) {
    const relevance = [
      ('invoices', 'Faturas', 'file'),
      ('support', 'Suporte', 'chat'),
      ('internet_usage', 'Consumo', 'g-chart'),
      ('speed_test', 'Velocidade', 'gauge'),
      ('my_ip', 'Meu IP', 'globe'),
      ('network_diagnostic', 'Diagnóstico', 'pulse'),
      ('trace_route', 'Tracert', 'g-route'),
    ];
    final items = [
      for (final (route, label, icon) in relevance)
        if (can(route)) VibeShortcut(label, icon, () => onNavigate(route)),
    ].take(count - 1).toList();
    items.add(VibeShortcut('Ver todos', 'grid', () => onNavigate('services')));
    return items;
  }

  /// Faixa de serviços (`serviceRail()` do protótipo): "Ver todos" primeiro
  /// e o catálogo em seguida.
  List<VibeShortcut> rail(BuildContext context) {
    final main = billing.main;
    final items = <VibeShortcut>[
      VibeShortcut('Ver todos', 'grid', () => onNavigate('services')),
    ];
    void route(String id, String label, String icon) {
      if (can(id)) items.add(VibeShortcut(label, icon, () => onNavigate(id)));
    }

    route('invoices', 'Faturas', 'file');
    route('support', 'Suporte', 'chat');
    route('internet_usage', 'Consumo', 'g-chart');
    route('speed_test', 'Velocidade', 'gauge');
    route('my_ip', 'Meu IP', 'globe');
    route('network_diagnostic', 'Diagnóstico', 'pulse');
    route('trace_route', 'Tracert', 'g-route');
    if (can('invoices') && main != null && !main.paid) {
      items.add(VibeShortcut('Pagar fatura', 'pix',
          () => openSubscriberInvoice(context, main.invoice)));
    }
    if (can('invoices') && main != null && main.hasBoleto) {
      items.add(VibeShortcut('PDF da fatura', 'down',
          () => VibeInvoiceActions.openBoleto(context, main.invoice)));
    }
    if (can('invoices') && suspended && billing.overdue) {
      items.add(VibeShortcut(
          'Liberar internet', 'unlock', () => onNavigate('trust_unlock')));
    }
    route('ping', 'Ping', 'pulse');
    route('history', 'Histórico', 'clock');
    route('faq', 'Dúvidas', 'g-help');
    route('contract', 'Contrato', 'doc');
    route('notifications', 'Notificações', 'bell');
    route('account', 'Minha conta', 'user');
    route('achievements', 'Conquistas', 'g-trophy');
    if (promotions.isNotEmpty) route('promotions', 'Ofertas', 'gift');
    if (wifiAvailable) {
      route('wifi', 'Meu ${VibeTokens.of(context).wifi}', 'wifi');
    }
    return items;
  }

  List<Promotion> get promotions =>
      config?.config.promotions.activePromotions ?? const <Promotion>[];

  /// Ofertas do provedor no formato dos cartões do Início. Somem quando há
  /// fatura vencida ou internet suspensa, como no protótipo.
  List<VibePromo> promos(BuildContext context) {
    if (suspended || billing.overdue) return const [];
    final list = <VibePromo>[
      for (final p in promotions)
        VibePromo(
          kicker: p.badge.isNotEmpty ? p.badge : 'Oferta para você',
          title: p.title,
          text: p.description,
          imageUrl: p.imageUrl,
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => PromotionDetailsPage(promotion: p))),
        ),
    ];
    if (list.isEmpty) {
      final images = config?.config.imageCarousel
              .whereType<String>()
              .where((u) => u.trim().isNotEmpty)
              .toList() ??
          const <String>[];
      for (final url in images) {
        list.add(VibePromo(
            title: 'Novidade do provedor',
            kicker: providerName,
            imageUrl: url,
            onTap: () {
              if (can('promotions')) onNavigate('promotions');
            }));
      }
    }
    return list.isEmpty ? highlights(context) : list;
  }

  /// Sem ofertas cadastradas, o espaço do carrossel mostra o que o app já
  /// faz pelo assinante, cada cartão abrindo a função. Nada de promessa
  /// comercial: isso é do provedor, pelo painel.
  List<VibePromo> highlights(BuildContext context) {
    // Pix fica de fora: o cartão da fatura logo acima já tem o botão.
    return [
      if (can('network_diagnostic'))
        VibePromo(
          highlight: true,
          kicker: 'Dica do app',
          title: 'Internet lenta?',
          text: 'Descubra onde está o problema.',
          cta: 'Verificar agora',
          art: 'wifi',
          onTap: openDiagnostic,
        ),
      if (can('speed_test'))
        VibePromo(
          highlight: true,
          kicker: 'Dica do app',
          title: 'Meça sua velocidade',
          text: 'Download e upload em segundos.',
          cta: 'Testar agora',
          art: 'turbo',
          onTap: () => onNavigate('speed_test'),
        ),
      if (can('internet_usage'))
        VibePromo(
          highlight: true,
          kicker: 'Dica do app',
          title: 'Seu consumo do mês',
          text: 'Quanto você usou, dia a dia.',
          cta: 'Ver consumo',
          icon: 'g-chart',
          onTap: () => onNavigate('internet_usage'),
        ),
    ];
  }

  void copyPix(BuildContext context, Fatura invoice) =>
      VibeInvoiceActions.copyPix(context, invoice);
}

VibeNetwork vibeNetworkOf(ConnectivityResult? result) => switch (result) {
      ConnectivityResult.wifi ||
      ConnectivityResult.ethernet =>
        VibeNetwork.wifi,
      ConnectivityResult.mobile => VibeNetwork.mobile,
      ConnectivityResult.none => VibeNetwork.offline,
      _ => VibeNetwork.unknown,
    };
