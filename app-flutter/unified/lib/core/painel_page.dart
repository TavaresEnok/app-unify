import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../layout_selector.dart';
import 'providers/providers.dart';
import 'providers/connectivity_provider.dart';
import 'providers/financeiro_provider.dart';
import 'providers/customer_capabilities_provider.dart';
import 'navigation/customer_routes.dart';
import 'navigation/customer_shell_scope.dart';
import 'vibe/vibe_nav_bar.dart';
import 'vibe/vibe_page_parts.dart';
import 'vibe/vibe_text.dart';
import 'vibe/vibe_tokens.dart';
import 'services/incident_service.dart';
import 'services/push_notification_service.dart';
import 'widgets/content_state.dart';
import 'widgets/offline_banner.dart';
import 'pages/customer/customer_home_page.dart';
import 'pages/customer/homes/vibe_home_data.dart';
import 'pages/customer/subscriber_services_page.dart';
import 'pages/customer/promotions_page.dart';
import 'pages/invoice_detail_page.dart';
import 'pages/customer/connection_hub_page.dart';
import 'pages/customer/customer_support_page.dart';
import 'pages/customer/customer_account_page.dart';
import 'pages/shared_diagnostico_page.dart';
import 'pages/shared_ping_page.dart';
import 'pages/achievements_page.dart';
import 'pages/customer/diagnostic_history_page.dart';

/// Moldura única do app do assinante para os cinco layouts aprovados:
/// Início, Faturas, Conexão e Suporte na barra de navegação do layout, e as
/// demais páginas por cima, com o mesmo cabeçalho e a mesma barra.
class PainelPage extends ConsumerStatefulWidget {
  final String initialDestination;
  final bool refreshOnOpen;
  const PainelPage(
      {super.key,
      this.initialDestination = 'dashboard',
      this.refreshOnOpen = true});
  @override
  ConsumerState<PainelPage> createState() => _PainelPageState();
}

class _PainelPageState extends ConsumerState<PainelPage> {
  int _tab = 0;
  ProviderIncident? _activeIncident;
  String? _dismissedIncidentId;
  static const _tabs = ['dashboard', 'invoices', 'connection', 'support'];

  @override
  void initState() {
    super.initState();
    final destination = CustomerRoutes.normalize(widget.initialDestination);
    _tab = _tabs.contains(destination) ? _tabs.indexOf(destination) : 0;
    PushNotificationService().setOnNotificationTap(_handlePushRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.refreshOnOpen) _refresh();
      if (!_tabs.contains(destination) && mounted) _navigate(destination);
    });
  }

  @override
  void dispose() {
    PushNotificationService().setOnNotificationTap(null);
    super.dispose();
  }

  void _handlePushRoute(String? rawRoute) {
    if (!mounted) return;
    final normalized = CustomerRoutes.normalize(rawRoute ?? '');
    final target = normalized.isEmpty ? 'notifications' : normalized;
    _navigate(target);
  }

  Future<void> _refresh() async {
    final config = ref.read(configurationProvider).providerConfig;
    if (config == null) return;
    await ref.read(configurationProvider).loadConfig(config.id);
    if (!mounted) return;
    await ref.read(authNotifierProvider.notifier).refreshUserData(config);
    if (!mounted) return;
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user != null) {
      await ref.read(financeiroViewModelProvider).fetchHistory();
      if (!mounted) return;
      final notif = ref.read(notificationProvider);
      notif.configureApiUrl(config.apiUrl);
      await notif.syncRemoteNotifications(user, config.id);
    }
    final incident = await IncidentService.fetchActiveFromApi(config.apiUrl);
    if (mounted) {
      setState(() => _activeIncident = incident);
    }
  }

  void _showIncidentSheet(VibeTokens t, ProviderIncident incident) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheet) => Container(
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: t.ink.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      incident.severity == 'critical'
                          ? Icons.error_outline_rounded
                          : Icons.warning_amber_rounded,
                      color: incident.severity == 'critical' ? t.bad : t.wa,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        incident.title,
                        style: vibeText(t, 18, 800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  incident.message,
                  style: vibeText(t, 14, 500, color: t.mut, height: 1.45),
                ),
                if (incident.area != null || incident.estimatedResolution != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (incident.area != null)
                        Chip(
                          label: Text('Região: ${incident.area!}',
                              style: vibeText(t, 12, 600)),
                          backgroundColor: t.ink.withValues(alpha: .06),
                          side: BorderSide.none,
                        ),
                      if (incident.estimatedResolution != null)
                        Chip(
                          label: Text('Previsão: ${incident.estimatedResolution!}',
                              style: vibeText(t, 12, 600)),
                          backgroundColor: t.ink.withValues(alpha: .06),
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                VibePageButton(
                  label: 'Entendi',
                  onPressed: () => Navigator.of(sheet).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _tabForRoute(String route) => switch (route) {
        'dashboard' => 0,
        'invoices' || 'contract' || 'trust_unlock' || 'invoice' => 1,
        'connection' ||
        'network_diagnostic' ||
        'wifi' ||
        'speed_test' ||
        'ping' ||
        'trace_route' ||
        'my_ip' ||
        'internet_usage' ||
        'history' =>
          2,
        'support' || 'faq' => 3,
        _ => 0,
      };

  Future<void> _navigate(String route) async {
    route = CustomerRoutes.normalize(route);
    final config = ref.read(configurationProvider).providerConfig;
    if (config == null) return;
    if (!CustomerRoutes.enabled(config, route) ||
        (route == 'wifi' &&
            ref.read(wifiManagementAvailableProvider).valueOrNull != true)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Este recurso não está disponível para seu provedor.')));
      return;
    }
    if (route == 'trust_unlock') {
      await _push(route, const TrustUnlockPage());
      return;
    }
    if (_tabs.contains(route)) {
      final shellRoute = ModalRoute.of(context);
      if (shellRoute != null) {
        Navigator.of(context).popUntil((candidate) => candidate == shellRoute);
      }
      setState(() => _tab = _tabs.indexOf(route));
      return;
    }
    final layout = config.layoutType;
    void back() => Navigator.of(context).maybePop();
    // Páginas com cabeçalho próprio no desenho do layout ficam como estão;
    // as demais recebem o cabeçalho do layout acima do conteúdo.
    final (String title, String? subtitle, Widget child, bool own) =
        switch (route) {
      'promotions' => (
          'Ofertas',
          'Do seu provedor',
          const PromotionsPage(),
          true
        ),
      'services' => (
          'Todos os serviços',
          null,
          SubscriberServicesPage(onNavigate: _navigate),
          true
        ),
      'account' => (
          'Minha conta',
          null,
          CustomerAccountPage(onNavigate: _navigate),
          true
        ),
      'network_diagnostic' => (
          'Verificar conexão',
          null,
          LayoutSelector.getDiagnosticByStyle(
            layoutType: layout,
            diagnosticStyle: config.diagnosticStyle ?? 'default',
          ),
          true
        ),
      'wifi' => (
          'Minha rede Wi-Fi',
          null,
          LayoutSelector.getWifiPage(layoutType: layout),
          true
        ),
      'speed_test' => (
          'Teste de velocidade',
          null,
          const DiagnosticoPage(speedOnly: true),
          true
        ),
      'ping' => ('Teste de ping', null, const SharedPingPage(), true),
      'trace_route' => (
          'Tracert',
          'Rota da rede',
          LayoutSelector.getTraceRoutePage(layoutType: layout),
          true
        ),
      'my_ip' => (
          'Meu IP',
          'IP público e localização',
          LayoutSelector.getMeuIpPage(layoutType: layout),
          true
        ),
      'internet_usage' => (
          'Consumo',
          null,
          LayoutSelector.getConsumoPage(layoutType: layout),
          true
        ),
      'contract' => (
          'Meu contrato',
          'Somente consulta',
          LayoutSelector.getContratoPage(
              layoutType: layout, onNavigate: _navigate),
          true
        ),
      'notifications' => (
          'Notificações',
          null,
          LayoutSelector.getNotificationPage(layoutType: layout),
          true
        ),
      'faq' => (
          'Perguntas frequentes',
          config.name.isEmpty ? null : 'Respostas da ${config.name}',
          LayoutSelector.getFaqPage(layoutType: layout, onNavigate: _navigate),
          true
        ),
      'history' => (
          'Histórico de verificações',
          null,
          const DiagnosticHistoryPage(),
          true
        ),
      'achievements' => ('Conquistas', null, const AchievementsPage(), true),
      _ => (
          'Recurso indisponível',
          null,
          const ContentState(
              icon: Icons.info_outline,
              title: 'Este recurso não está disponível',
              message: 'Volte para continuar usando o aplicativo.'),
          false
        ),
    };
    final page = own
        ? child
        : Builder(
            builder: (context) => VibePageScaffold(
                title: title, subtitle: subtitle, onBack: back, body: child));
    await _push(route, page);
  }

  /// Abre uma página com a moldura do app. O contexto do shell fica acima do
  /// [CustomerShellScope] que ele mesmo cria, então empilha direto aqui.
  Future<void> _push(String route, Widget page) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => _frame(route, page)));

  /// Faixa de status: na cor da marca no Início dos layouts de topo
  /// colorido, na cor do fundo nas demais telas.
  SystemUiOverlayStyle _statusStyle(VibeTokens t, {required bool home}) {
    final color = home && t.homeStatusOnBrand ? t.ac : t.bg;
    final light = LayoutTokensContrast.isLight(color);
    final navLight =
        LayoutTokensContrast.isLight(t.dock != null ? t.bg : t.card);
    return SystemUiOverlayStyle(
      statusBarColor: color,
      statusBarIconBrightness: light ? Brightness.dark : Brightness.light,
      statusBarBrightness: light ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: t.dock != null ? t.bg : t.card,
      systemNavigationBarIconBrightness:
          navLight ? Brightness.dark : Brightness.light,
    );
  }

  /// Marca fixa da tela Dock acima do conteúdo (`.app-brand`).
  Widget _withMasthead(VibeTokens t, Widget body) {
    if (t.dock == null) return body;
    return ColoredBox(
      color: t.bg,
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          Consumer(builder: (context, ref, _) {
            final data = VibeHomeData.watch(ref, _navigate);
            return VibeDockMasthead(
              providerName: data.providerName,
              subtitle: [data.firstName, if (data.plan.isNotEmpty) data.plan]
                  .join(' · '),
              initials: data.initials,
              logoUrl: data.logoUrl,
              network: data.network,
              onNetwork: data.openDiagnostic,
              onBell: data.bellAction,
              onAccount: data.openAccount,
            );
          }),
          Expanded(child: body),
        ]),
      ),
    );
  }

  /// Moldura das páginas que abrem por cima das abas.
  Widget _frame(String route, Widget page) => Consumer(
        builder: (context, ref, _) {
          final tokens = ref.watch(layoutTokensProvider);
          final theme = tokens.themeData(base: Theme.of(context));
          final t = theme.extension<VibeTokens>()!;
          return Theme(
            data: theme,
            child: CustomerShellScope(
              frame: _frame,
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: _statusStyle(t, home: false),
                child: Scaffold(
                  backgroundColor: t.bg,
                  body: _withMasthead(
                      t,
                      ColoredBox(
                          color: t.bg,
                          child: SafeArea(bottom: false, child: page))),
                  bottomNavigationBar: VibeNavBar(
                    selectedIndex: _tabForRoute(route),
                    onSelected: (index) => _navigate(_tabs[index]),
                  ),
                ),
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    ref.watch(
        financeiroViewModelProvider); // Keep one invoice consultation across the four tabs.
    final config = ref.watch(configurationProvider).providerConfig;
    final tokens = ref.watch(layoutTokensProvider);
    // A consulta da rede alimenta o Início e a marca da tela Dock.
    ref.watch(connectivityStatusProvider);
    if (user == null || config == null) {
      return const ColoredBox(
          color: Colors.white,
          child: Center(
              child: SizedBox(
                  width: 96,
                  child: LinearProgressIndicator(
                      minHeight: 3,
                      color: Color(0xFF18202C),
                      backgroundColor: Color(0x1A18202C)))));
    }
    final theme = tokens.themeData(base: Theme.of(context));
    final t = theme.extension<VibeTokens>()!;
    final body = switch (_tab) {
      0 => CustomerHomePage(
          onNavigate: _navigate,
          onRefresh: () async {
            await _refresh();
            if (mounted) {
              await ref.read(financeiroViewModelProvider).fetchHistory();
            }
          }),
      1 => CustomerRoutes.enabled(config, 'invoices')
          ? LayoutSelector.getFinanceiroPage(layoutType: config.layoutType)
          : const ContentState(
              icon: Icons.receipt_long_outlined,
              title: 'Faturas indisponíveis no app',
              message: 'Consulte seu provedor.'),
      2 => ConnectionHubPage(onNavigate: _navigate),
      _ => CustomerSupportPage(onNavigate: _navigate),
    };
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _statusStyle(t, home: _tab == 0),
      child: Theme(
          data: theme,
          child: CustomerShellScope(
            frame: _frame,
            child: Builder(
                builder: (context) => PopScope(
                      canPop: _tab == 0,
                      onPopInvokedWithResult: (didPop, _) {
                        if (!didPop && _tab != 0) setState(() => _tab = 0);
                      },
                      child: Scaffold(
                        backgroundColor: t.bg,
                        body: Column(children: [
                          Expanded(child: _withMasthead(t, body)),
                          if (_activeIncident != null &&
                              _activeIncident!.id != _dismissedIncidentId)
                            _buildIncidentBanner(t, _activeIncident!),
                          const OfflineBanner(),
                        ]),
                        bottomNavigationBar: VibeNavBar(
                          selectedIndex: _tab,
                          onSelected: (index) => _navigate(_tabs[index]),
                        ),
                      ),
                    )),
          )),
    );
  }

  Widget _buildIncidentBanner(VibeTokens t, ProviderIncident incident) {
    final accent = incident.severity == 'critical' ? t.bad : t.wa;
    return Material(
      color: accent.withValues(alpha: .12),
      child: InkWell(
        onTap: () => _showIncidentSheet(t, incident),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: accent.withValues(alpha: .35)),
            ),
          ),
          child: Row(
            children: [
              Icon(
                incident.severity == 'critical'
                    ? Icons.error_outline_rounded
                    : Icons.warning_amber_rounded,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      incident.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: vibeText(t, 12.5, 700, color: t.ink),
                    ),
                    Text(
                      incident.area != null
                          ? '${incident.area} · Toque para detalhes'
                          : 'Toque para ver detalhes do aviso',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: vibeText(t, 11, 500, color: t.mut),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded, size: 18, color: t.mut),
                tooltip: 'Dispensar aviso',
                onPressed: () =>
                    setState(() => _dismissedIncidentId = incident.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Decide se os ícones da barra do sistema ficam escuros (fundo claro).
class LayoutTokensContrast {
  static bool isLight(Color color) =>
      ThemeData.estimateBrightnessForColor(color) == Brightness.light;
}
