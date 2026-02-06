import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../layouts/layout_04/widgets/skeleton_dashboard_page.dart';
import 'services/diagnostico_service.dart';
import '../layout_selector.dart';
import '../layouts/layout_03/theme.dart';
import '../layouts/layout_03/widgets/neumorphic_bottom_nav.dart';
import 'providers/providers.dart';
import 'widgets/offline_banner.dart';
import 'models/usuario.dart';

/// PainelPage - Widget principal de navegação após login
class PainelPage extends ConsumerStatefulWidget {
  const PainelPage({super.key});

  @override
  ConsumerState<PainelPage> createState() => _PainelPageState();
}

class _PainelPageState extends ConsumerState<PainelPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentPage = 'dashboard';

  @override
  void initState() {
    super.initState();
    // Refresh data in background when Painel opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshData();
      if (mounted) {
        await _syncNotifications();
      }
    });
  }

  Future<void> _refreshData() async {
    final config = ref.read(configurationProvider).providerConfig;
    if (config != null) {
      // Refresh Configuration (for WhatsApp changes etc)
      await ref.read(configurationProvider).loadConfig(config.id);

      // Refresh User Data (for Balance 0.00 fix)
      if (ref.read(authNotifierProvider).value != null) {
        await ref.read(authNotifierProvider.notifier).refreshUserData(config);
      }
    }
  }

  Future<void> _syncNotifications() async {
    final usuario = ref.read(authNotifierProvider).value;
    final config = ref.read(configurationProvider).providerConfig;

    if (usuario != null && config != null) {
      await ref
          .read(notificationProvider)
          .syncRemoteNotifications(usuario, config.id);
    }
  }

  final Map<String, String> _pageNames = {
    'dashboard': 'Dashboard',
    'invoices': 'Faturas',
    'support': 'Suporte',
    'internet_usage': 'Consumo',
    'speed_test': 'Teste de Velocidade',
    'network_diagnostic': 'Diagnóstico',
    'contract': 'Contrato',
    'my_ip': 'Meu IP',
    'faq': 'FAQ',
    'notifications': 'Notificações',
    'trace_route': 'Rota (Tracert)',
    'wifi': 'Meu Wi-Fi',
    // Aliases for compatibility
    'home': 'Dashboard',
    'diagnostico': 'Diagnóstico',
    'suporte': 'Suporte',
    'notificacoes': 'Notificações',
    'financeiro': 'Financeiro',
    'perfil': 'Perfil',
    'logout': 'Sair',
  };

  final Map<String, IconData> _pageIcons = {
    'dashboard': Icons.dashboard,
    'invoices': Icons.receipt_long,
    'support': Icons.support_agent,
    'internet_usage': Icons.data_usage,
    'speed_test': Icons.speed,
    'network_diagnostic': Icons.wifi_tethering,
    'trace_route': Icons.alt_route_rounded,
    'contract': Icons.description,
    'my_ip': Icons.public,
    'faq': Icons.help_outline,
    'notifications': Icons.notifications,
    'wifi': Icons.wifi,
    // Aliases for compatibility
    'home': Icons.home,
    'diagnostico': Icons.wifi_tethering,
    'suporte': Icons.support_agent,
    'notificacoes': Icons.notifications,
    'financeiro': Icons.attach_money,
    'perfil': Icons.person,
    'logout': Icons.exit_to_app,
  };

  void _navigateToPage(String pageId) {
    setState(() {
      _currentPage = pageId;
    });
    // BI (Analytics)
    ref.read(analyticsServiceProvider).logScreenView(pageId);

    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final configProvider = ref.watch(configurationProvider);
    final usuario = authState.value;

    final layoutType = configProvider.providerConfig?.layoutType ?? 'layout_02';
    // Layouts with custom bottom navigation - Layout 02, 05, 06 handle their own in dashboard_page
    // Layout 05 now has its own _buildBottomNav inside dashboard_page.dart
    final hasBottomNav =
        false; // Nenhum layout usa mais o NeumorphicBottomNav externo

    if (authState.isLoading) {
      return const SkeletonDashboardPage();
    }

    if (usuario == null) {
      return const Scaffold(
        body: Center(child: Text('Erro: Usuário não autenticado')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_currentPage != 'dashboard') {
          setState(() => _currentPage = 'dashboard');
          return;
        }

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sair do App'),
            content: const Text('Deseja realmente sair?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sair'),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          if (context.mounted) {
            Navigator.pop(
                context); // Sai do app (PopScope allows exit if we let it, but here we manually pop the route)
          }
          // Actually, for PopScope with canPop: false, we can't just return.
          // We need to use SystemChannels.platform.invokeMethod('SystemNavigator.pop') for pure exit, or let the router handle it.
          // Since this is the main page, popping it exits the app.
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: null, // Respect theme's scaffoldBackgroundColor
        appBar: _buildAppBar(context, layoutType),
        drawer: _buildDrawer(context, usuario, ref, layoutType),
        body: Stack(
          children: [
            _buildBody(layoutType, usuario, context),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: OfflineBanner(),
            ),
            if (hasBottomNav)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: NeumorphicBottomNav(
                  currentIndex: _getBottomNavIndex(),
                  onTap: _onBottomNavTap,
                ),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context, String layoutType) {
    // Layout 02 agora usa a AppBar padrão do PainelPage, não a header interna.
    // Layout 05 agora tem seu próprio header interno no dashboard, não precisa mais de AppBar externa
    // Layout 02 usa cores roxas
    final isLayout02 = layoutType == 'layout_02';

    final isOnDashboard = _currentPage == 'dashboard';
    final pageName = _pageNames[_currentPage] ?? 'Dashboard';

    // Layout 02 agora faz seu próprio header no Dashboard, então escondemos a AppBar principal
    // Layout 03, 04, 05, 06 também têm seus próprios headers
    if ((isLayout02 ||
            layoutType == 'layout_03' ||
            layoutType == 'layout_04' ||
            layoutType == 'layout_05' ||
            layoutType == 'layout_06') &&
        isOnDashboard) {
      return null;
    }

    // Default AppBar for Layout 04, Layout 06, etc. OR Layout 02 non-dashboard pages
    // Use themeConfig colors for Layout 02 to respect web admin settings
    final themeConfig = ref.watch(themeProvider).config;
    final primaryColor = themeConfig.colors.primary;
    final bool isDarkLayout =
        layoutType == 'layout_04' || layoutType == 'layout_06';
    Color bgColor;
    if (isLayout02) {
      bgColor = primaryColor; // Use dynamic primary color from themeConfig
    } else if (isDarkLayout) {
      bgColor = const Color(0xFF0A0A0A); // Pure black for Layout 04/06
    } else {
      bgColor = primaryColor;
    }
    const contentColor = Colors.white;

    return AppBar(
      backgroundColor: bgColor,
      iconTheme: const IconThemeData(color: contentColor),
      leading: isOnDashboard
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Voltar para Dashboard',
              onPressed: () {
                setState(() {
                  _currentPage = 'dashboard';
                });
              },
            ),
      title: isOnDashboard
          ? Text(pageName, style: const TextStyle(color: contentColor))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _currentPage = 'dashboard';
                    });
                  },
                  child: Text(
                    'Início',
                    style: TextStyle(
                      fontSize: 14,
                      color: contentColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: contentColor.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  pageName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: contentColor,
                  ),
                ),
              ],
            ),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            setState(() {
              _currentPage = 'notifications';
            });
          },
        ),
      ],
    );
  }

  int _getBottomNavIndex() {
    switch (_currentPage) {
      case 'dashboard':
        return 0;
      case 'wifi':
        return 1;
      case 'invoices':
        return 2;
      case 'support':
        return 3;
      default:
        return 0;
    }
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        _navigateToPage('dashboard');
        break;
      case 1:
        _navigateToPage('wifi');
        break;
      case 2:
        _navigateToPage('invoices');
        break;
      case 3:
        _navigateToPage('support');
        break;
      case 4:
        _scaffoldKey.currentState?.openDrawer();
        break;
    }
  }

  Widget _buildDrawer(
      BuildContext context, Usuario usuario, WidgetRef ref, String layoutType) {
    final isNeumorphic = layoutType == 'layout_05';
    final primaryColor = Theme.of(context).primaryColor;

    if (isNeumorphic) {
      return Drawer(
        backgroundColor: Layout03Theme.background,
        elevation: 0,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              color: Layout03Theme.background,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Layout03Theme.background,
                      shape: BoxShape.circle,
                      boxShadow: [
                        const BoxShadow(
                          color: Colors.white,
                          offset: Offset(-8, -8),
                          blurRadius: 16,
                        ),
                        BoxShadow(
                          color: const Color(0xFFA3B1C6).withValues(alpha: 0.4),
                          offset: const Offset(8, 8),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Layout03Theme.primary,
                      child: Text(
                        usuario.nome.isNotEmpty
                            ? usuario.nome[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(usuario.nome,
                            style:
                                Layout03Theme.heading2.copyWith(fontSize: 16)),
                        Text(usuario.plano,
                            style:
                                Layout03Theme.bodyText.copyWith(fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const Divider(color: Colors.white, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildNeumorphicMenuItem(
                      'dashboard', 'Início', Icons.grid_view_rounded),
                  _buildNeumorphicMenuItem(
                      'invoices', 'Faturas', Icons.receipt_long_rounded),
                  _buildNeumorphicMenuItem(
                      'wifi', 'Meu Wi-Fi', Icons.wifi_rounded),
                  _buildNeumorphicMenuItem(
                      'network_diagnostic', 'Diagnóstico', Icons.speed_rounded),
                  _buildNeumorphicMenuItem(
                      'trace_route', 'Rota (Tracert)', Icons.alt_route_rounded),
                  _buildNeumorphicMenuItem(
                      'support', 'Suporte', Icons.headset_mic_rounded),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white),
                  const SizedBox(height: 24),
                  _buildNeumorphicMenuItem(
                      'logout', 'Sair', Icons.logout_rounded, isLogout: true,
                      onTap: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Layout03Theme.background,
                        title: Text('Sair', style: Layout03Theme.heading2),
                        content: Text('Deseja realmente sair?',
                            style: Layout03Theme.bodyText),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar',
                                  style: TextStyle(
                                      color: Layout03Theme.textGrey))),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Sim, Sair',
                                  style:
                                      TextStyle(color: Layout03Theme.error))),
                        ],
                      ),
                    );
                    if (shouldLogout == true) {
                      ref.read(authNotifierProvider.notifier).logout();
                    }
                  }),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Layout 06: Dark Fintech Drawer
    final isDarkLayout = layoutType == 'layout_06';
    if (isDarkLayout) {
      final colorScheme = Theme.of(context).colorScheme;
      final primaryColor = Theme.of(context).primaryColor;
      final secondaryColor = colorScheme.secondary;
      final surfaceColor = Theme.of(context).cardColor;
      final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
      final textColor =
          Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

      return Drawer(
        backgroundColor: backgroundColor,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, secondaryColor],
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      usuario.nome.isNotEmpty
                          ? usuario.nome[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(usuario.nome,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text(usuario.plano,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8))),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDarkMenuItem('dashboard', 'Início', Icons.home_rounded),
                  _buildDarkMenuItem(
                      'invoices', 'Faturas', Icons.receipt_long_rounded),
                  _buildDarkMenuItem('wifi', 'Meu Wi-Fi', Icons.wifi_rounded),
                  _buildDarkMenuItem(
                      'speed_test', 'Velocidade', Icons.speed_rounded),
                  _buildDarkMenuItem('network_diagnostic', 'Diagnóstico',
                      Icons.analytics_rounded),
                  _buildDarkMenuItem(
                      'trace_route', 'Traceroute', Icons.route_rounded),
                  _buildDarkMenuItem(
                      'support', 'Suporte', Icons.headset_mic_rounded),
                  _buildDarkMenuItem(
                      'internet_usage', 'Consumo', Icons.data_usage_rounded),
                  _buildDarkMenuItem('my_ip', 'Meu IP', Icons.public_rounded),
                  _buildDarkMenuItem(
                      'contract', 'Contrato', Icons.description_rounded),
                  _buildDarkMenuItem('faq', 'FAQ', Icons.help_outline_rounded),
                  const SizedBox(height: 24),
                  Divider(color: textColor.withValues(alpha: 0.2)),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.star_rate_rounded,
                        color: Color(0xFFFFD700)),
                    title: const Text('Avalie este App',
                        style: TextStyle(color: Color(0xFFFFD700))),
                    onTap: () {
                      ref.read(reviewServiceProvider).openStoreListing();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded,
                        color: Color(0xFFFF453A)),
                    title: const Text('Sair',
                        style: TextStyle(color: Color(0xFFFF453A))),
                    onTap: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: surfaceColor,
                          title:
                              Text('Sair', style: TextStyle(color: textColor)),
                          content: Text('Deseja realmente sair?',
                              style: TextStyle(
                                  color: textColor.withValues(alpha: 0.7))),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text('Cancelar',
                                    style: TextStyle(
                                        color:
                                            textColor.withValues(alpha: 0.5)))),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Sim, Sair',
                                    style:
                                        TextStyle(color: Color(0xFFFF453A)))),
                          ],
                        ),
                      );
                      if (shouldLogout == true) {
                        ref.read(authNotifierProvider.notifier).logout();
                      }
                    },
                  ),
                  SizedBox(height: 50 + MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    usuario.nome.isNotEmpty
                        ? usuario.nome[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Olá, ${usuario.nome}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  usuario.plano,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildMenuItem('dashboard', context),
          _buildMenuItem('invoices', context),
          _buildMenuItem('support', context),
          _buildMenuItem('internet_usage', context),
          _buildMenuItem('speed_test', context),
          _buildMenuItem('network_diagnostic', context),
          _buildMenuItem('trace_route', context),
          _buildMenuItem('contract', context),
          _buildMenuItem('my_ip', context),
          _buildMenuItem('faq', context),
          const Divider(),
          Consumer(
            builder: (context, ref, _) {
              final themeNotifer = ref.watch(themeProvider);
              final isDark = themeNotifer.themeMode == ThemeMode.dark;
              return SwitchListTile(
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: isDark ? Colors.amber : Colors.blueGrey,
                ),
                title: const Text('Modo Escuro'),
                subtitle: Text(
                  isDark ? 'Ativado' : 'Desativado',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                value: isDark,
                onChanged: (value) {
                  themeNotifer.setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Sair',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sair'),
                  content: const Text('Deseja realmente sair do aplicativo?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await ref.read(authNotifierProvider.notifier).logout();
              }
            },
          ),
          const SizedBox(height: 50), // Add padding for Android navigation bar
        ],
      ),
    );
  }

  Widget _buildNeumorphicMenuItem(String id, String label, IconData icon,
      {bool isLogout = false, VoidCallback? onTap}) {
    final isSelected = _currentPage == id;
    final color = isLogout
        ? Layout03Theme.error
        : (isSelected ? Layout03Theme.primary : Layout03Theme.textGrey);

    final decoration =
        isSelected ? Layout03Theme.neumorphicPressedDecoration : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: decoration,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: color),
        title: Text(label,
            style: TextStyle(
                color: isLogout ? Layout03Theme.error : Layout03Theme.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        onTap: onTap ?? () => _navigateToPage(id),
      ),
    );
  }

  ListTile _buildMenuItem(String pageId, BuildContext context) {
    final isSelected = _currentPage == pageId;
    final primaryColor = Theme.of(context).primaryColor;

    return ListTile(
      leading: Icon(
        _pageIcons[pageId] ?? Icons.circle,
        color: isSelected ? primaryColor : Colors.grey[600],
      ),
      title: Text(
        _pageNames[pageId] ?? pageId,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? primaryColor : null,
        ),
      ),
      selected: isSelected,
      selectedTileColor: primaryColor.withValues(alpha: 0.1),
      onTap: () => _navigateToPage(pageId),
    );
  }

  Widget _buildBody(String layoutType, Usuario usuario, BuildContext context) {
    // Handle route aliases and special routes - redirect to actual routes
    // This must be done first before any page checks
    switch (_currentPage) {
      case 'home':
        _currentPage = 'dashboard';
        break;
      case 'diagnostico':
        _currentPage = 'network_diagnostic';
        break;
      case 'suporte':
        _currentPage = 'support';
        break;
      case 'notificacoes':
        _currentPage = 'notifications';
        break;
      case 'financeiro':
        _currentPage = 'invoices';
        break;
      case 'planos':
        // Planos não tem página específica - redirecionar para suporte
        _currentPage = 'support';
        break;
      case 'perfil':
        // Perfil/Profile não está implementado - redirect to dashboard for now
        _currentPage = 'dashboard';
        break;
      case 'logout':
        // Handle logout
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(authNotifierProvider.notifier).logout();
        });
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
    }

    if (_currentPage == 'dashboard') {
      return LayoutSelector.getDashboard(
        layoutType: layoutType,
        customerName: usuario.nome,
        planName: usuario.plano,
        connectionStatus: usuario.status,
        billAmount: _parseBillAmount(usuario.valorFatura),
        billDueDate: _parseBillDate(usuario.vencimentoFatura),
        // Extract speed from plan name (e.g. "500 Mega" -> 500)
        usedGb: 0.0, // API doesn't provide this - will be hidden in dashboard
        totalGb: 0.0, // API doesn't provide this
        downloadMbps: _extractSpeedFromPlan(usuario.plano),
        uploadMbps: _extractSpeedFromPlan(usuario.plano) *
            0.5, // Estimate upload as half of download
        onNavigate: (page) {
          setState(() {
            _currentPage = page;
          });
        },
        onRefresh: () async {
          final config = ref.read(configurationProvider).providerConfig;
          if (config != null) {
            await ref
                .read(authNotifierProvider.notifier)
                .refreshUserData(config);
          }
        },
      );
    }

    if (_currentPage == 'invoices') {
      return LayoutSelector.getFinanceiroPage(layoutType: layoutType);
    }

    if (_currentPage == 'support') {
      return LayoutSelector.getSuportePage(layoutType: layoutType);
    }

    if (_currentPage == 'network_diagnostic') {
      final diagnosticStyle =
          ref.read(configurationProvider).providerConfig?.diagnosticStyle ??
              'default';
      return LayoutSelector.getDiagnosticByStyle(
        layoutType: layoutType,
        diagnosticStyle: diagnosticStyle,
      );
    }

    if (_currentPage == 'internet_usage') {
      return LayoutSelector.getConsumoPage(layoutType: layoutType);
    }

    if (_currentPage == 'my_ip') {
      return LayoutSelector.getMeuIpPage(layoutType: layoutType);
    }

    if (_currentPage == 'faq') {
      return LayoutSelector.getFaqPage(layoutType: layoutType);
    }

    if (_currentPage == 'contract') {
      return LayoutSelector.getContratoPage(layoutType: layoutType);
    }

    if (_currentPage == 'wifi') {
      return LayoutSelector.getWifiPage(layoutType: layoutType);
    }

    if (_currentPage == 'speed_test') {
      final configProvider = ref.read(configurationProvider);
      return LayoutSelector.getSpeedTestPage(
        layoutType: layoutType,
        diagnosticoService: DiagnosticoService(
          providerConfig: configProvider.providerConfig!,
          context: context,
        ),
        onBack: () => setState(() => _currentPage = 'dashboard'),
      );
    }

    if (_currentPage == 'trace_route') {
      return LayoutSelector.getTraceRoutePage(layoutType: layoutType);
    }

    if (_currentPage == 'notifications') {
      return LayoutSelector.getNotificationPage(layoutType: layoutType);
    }

    return _buildPlaceholderPage(layoutType);
  }

  Widget _buildPlaceholderPage(String layoutType) {
    final isLayout05 = layoutType == 'layout_05';
    final backgroundColor =
        isLayout05 ? Layout03Theme.background : Colors.grey[100];

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: isLayout05 ? const EdgeInsets.all(24) : null,
              decoration: isLayout05
                  ? BoxDecoration(
                      color: Layout03Theme.background,
                      shape: BoxShape.circle,
                      boxShadow: [
                        const BoxShadow(
                          color: Colors.white,
                          offset: Offset(-6, -6),
                          blurRadius: 12,
                        ),
                        BoxShadow(
                          color: const Color(0xFFA3B1C6).withValues(alpha: 0.4),
                          offset: const Offset(6, 6),
                          blurRadius: 12,
                        ),
                      ],
                    )
                  : null,
              child: Icon(
                _pageIcons[_currentPage] ?? Icons.construction,
                size: 80,
                color: isLayout05 ? Layout03Theme.textGrey : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _pageNames[_currentPage] ?? _currentPage,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isLayout05 ? Layout03Theme.textDark : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta página será implementada em breve',
              style: TextStyle(
                fontSize: 16,
                color: isLayout05 ? Layout03Theme.textGrey : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _currentPage = 'dashboard';
                });
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar ao Dashboard'),
              style: isLayout05
                  ? ElevatedButton.styleFrom(
                      backgroundColor: Layout03Theme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    )
                  : ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _parseBillAmount(String value) {
    try {
      final cleaned = value.replaceAll(RegExp(r'[^0-9,.]'), '');
      final normalized = cleaned.replaceAll(',', '.');
      return double.parse(normalized);
    } catch (_) {
      return 0.0;
    }
  }

  DateTime _parseBillDate(String value) {
    try {
      final parts = value.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
    return DateTime.now();
  }

  /// Extracts speed (Mbps) from plan name, e.g. "500 Mega" -> 500.0
  double _extractSpeedFromPlan(String planName) {
    try {
      final regex = RegExp(r'(\d+)');
      final match = regex.firstMatch(planName);
      if (match != null) {
        return double.parse(match.group(1)!);
      }
    } catch (_) {}
    return 100.0; // Default fallback
  }

  Widget _buildDarkMenuItem(String pageId, String label, IconData icon) {
    final isSelected = _currentPage == pageId;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? primaryColor : textColor.withValues(alpha: 0.6),
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? primaryColor : textColor,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          _navigateToPage(pageId);
        },
      ),
    );
  }
}
