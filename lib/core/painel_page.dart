import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../layout_selector.dart';
import '../layouts/layout_05/theme.dart';
import '../layouts/layout_05/widgets/neumorphic_bottom_nav.dart';
import 'providers/providers.dart';
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
  };

  final Map<String, IconData> _pageIcons = {
    'dashboard': Icons.dashboard,
    'invoices': Icons.receipt_long,
    'support': Icons.support_agent,
    'internet_usage': Icons.data_usage,
    'speed_test': Icons.speed,
    'network_diagnostic': Icons.wifi_tethering,
    'contract': Icons.description,
    'my_ip': Icons.public,
    'faq': Icons.help_outline,
    'notifications': Icons.notifications,
  };

  void _navigateToPage(String pageId) {
    setState(() {
      _currentPage = pageId;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final configProvider = ref.watch(configurationProvider);
    final usuario = authState.value;

    final layoutType = configProvider.providerConfig?.layoutType ?? 'layout_06';
    // Layout 02 também deve ter bottom nav agora
    final hasBottomNav = layoutType == 'layout_05' || layoutType == 'layout_02';

    if (usuario == null) {
      return const Scaffold(
        body: Center(child: Text('Erro: Usuário não autenticado')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
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
          if (context.mounted)
            Navigator.pop(
                context); // Sai do app (PopScope allows exit if we let it, but here we manually pop the route)
          // Actually, for PopScope with canPop: false, we can't just return.
          // We need to use SystemChannels.platform.invokeMethod('SystemNavigator.pop') for pure exit, or let the router handle it.
          // Since this is the main page, popping it exits the app.
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: _buildAppBar(context, layoutType),
        drawer: _buildDrawer(context, usuario, ref, layoutType),
        body: Stack(
          children: [
            _buildBody(layoutType, usuario),
            if (hasBottomNav)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: NeumorphicBottomNav(
                  currentIndex: _getBottomNavIndex(),
                  onTap: _onBottomNavTap,
                  // Layout 02 pode querer um estilo diferente de nav, mas vamos reutilizar o Neumorphic por enquanto ou adaptar.
                  // O NeumorphicBottomNav é bem estilizado 'glass'.
                  // Para o Layout 02 (roxo), talvez fique bom, ou precise de ajustes de cor.
                  // O widget NeumorphicBottomNav usa cores fixas em 'Layout05Theme'.
                  // Vamos manter assim por enquanto para consistência da solicitação.
                ),
              ),
          ],
        ),
        extendBody: hasBottomNav,
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context, String layoutType) {
    // Layout 02 agora usa a AppBar padrão do PainelPage, não a header interna.
    // Layout 05 (Neumorphic) tem AppBar customizada
    final isDarkLayout = layoutType == 'layout_06';
    final isNeumorphic = layoutType == 'layout_05';
    // Layout 02 usa cores roxas
    final isLayout02 = layoutType == 'layout_02';

    final isOnDashboard = _currentPage == 'dashboard';
    final pageName = _pageNames[_currentPage] ?? 'Dashboard';

    if (isNeumorphic) {
      return AppBar(
        backgroundColor: Layout05Theme.background,
        elevation: 0,
        centerTitle: true,
        leading: isOnDashboard
            ? Builder(
                builder: (context) => IconButton(
                      icon: const Icon(Icons.menu_rounded,
                          color: Layout05Theme.textDark),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ))
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: Layout05Theme.textDark),
                onPressed: () => setState(() => _currentPage = 'dashboard'),
              ),
        title: Text(pageName,
            style:
                Layout05Theme.heading2.copyWith(color: Layout05Theme.textDark)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Layout05Theme.textDark),
            onPressed: () => setState(() => _currentPage = 'notifications'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.white,
            height: 1,
          ),
        ),
      );
    }

    // Layout 02 agora faz seu próprio header no Dashboard, então escondemos a AppBar principal
    if (isLayout02 && isOnDashboard) {
      return null;
    }

    // Default AppBar for Layout 06, etc. OR Layout 02 non-dashboard pages
    final primaryColor = Theme.of(context).primaryColor;
    final bgColor = isLayout02
        ? const Color(0xFF673AB7)
        : (isDarkLayout ? Colors.grey[900] : primaryColor);
    final contentColor = Colors.white;

    return AppBar(
      backgroundColor: bgColor,
      iconTheme: IconThemeData(color: contentColor),
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
          ? Text(pageName, style: TextStyle(color: contentColor))
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
                      color: contentColor.withOpacity(0.7),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: contentColor.withOpacity(0.5),
                  ),
                ),
                Text(
                  pageName,
                  style: TextStyle(
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
    final isDarkLayout = layoutType == 'layout_06';
    final isNeumorphic = layoutType == 'layout_05';
    final primaryColor = Theme.of(context).primaryColor;

    if (isNeumorphic) {
      return Drawer(
        backgroundColor: Layout05Theme.background,
        elevation: 0,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              color: Layout05Theme.background,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Layout05Theme.background,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white,
                          offset: const Offset(-8, -8),
                          blurRadius: 16,
                        ),
                        BoxShadow(
                          color: const Color(0xFFA3B1C6).withOpacity(0.4),
                          offset: const Offset(8, 8),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Layout05Theme.primary,
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
                                Layout05Theme.heading2.copyWith(fontSize: 16)),
                        Text(usuario.plano,
                            style:
                                Layout05Theme.bodyText.copyWith(fontSize: 12)),
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
                        backgroundColor: Layout05Theme.background,
                        title: Text('Sair', style: Layout05Theme.heading2),
                        content: Text('Deseja realmente sair?',
                            style: Layout05Theme.bodyText),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('Cancelar',
                                  style: TextStyle(
                                      color: Layout05Theme.textGrey))),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Sim, Sair',
                                  style:
                                      TextStyle(color: Layout05Theme.error))),
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

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: isDarkLayout
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withOpacity(0.8),
                        primaryColor,
                      ],
                    )
                  : null,
              color: isDarkLayout ? null : primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withOpacity(0.2),
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
                    color: Colors.white.withOpacity(0.8),
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
        ],
      ),
    );
  }

  Widget _buildNeumorphicMenuItem(String id, String label, IconData icon,
      {bool isLogout = false, VoidCallback? onTap}) {
    final isSelected = _currentPage == id;
    final color = isLogout
        ? Layout05Theme.error
        : (isSelected ? Layout05Theme.primary : Layout05Theme.textGrey);

    final decoration =
        isSelected ? Layout05Theme.neumorphicPressedDecoration : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: decoration,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: color),
        title: Text(label,
            style: TextStyle(
                color: isLogout ? Layout05Theme.error : Layout05Theme.textDark,
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
      selectedTileColor: primaryColor.withOpacity(0.1),
      onTap: () => _navigateToPage(pageId),
    );
  }

  Widget _buildBody(String layoutType, Usuario usuario) {
    if (_currentPage == 'dashboard') {
      return LayoutSelector.getDashboard(
        layoutType: layoutType,
        customerName: usuario.nome,
        planName: usuario.plano,
        connectionStatus: usuario.status,
        billAmount: _parseBillAmount(usuario.valorFatura),
        billDueDate: _parseBillDate(usuario.vencimentoFatura),
        usedGb: 50.0,
        totalGb: 100.0,
        downloadMbps: 100.0,
        uploadMbps: 50.0,
        onNavigate: (page) {
          setState(() {
            _currentPage = page;
          });
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
      return LayoutSelector.getDiagnosticoPage(layoutType: layoutType);
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
      return LayoutSelector.getDiagnosticoPage(layoutType: layoutType);
    }

    return _buildPlaceholderPage(layoutType);
  }

  Widget _buildPlaceholderPage(String layoutType) {
    final isDarkLayout = layoutType == 'layout_06';

    return Container(
      decoration: BoxDecoration(
        gradient: isDarkLayout
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[900]!,
                  Colors.grey[850]!,
                ],
              )
            : null,
        color: isDarkLayout ? null : Colors.grey[100],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _pageIcons[_currentPage] ?? Icons.construction,
              size: 80,
              color: isDarkLayout ? Colors.white54 : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              _pageNames[_currentPage] ?? _currentPage,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkLayout ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta página será implementada em breve',
              style: TextStyle(
                fontSize: 16,
                color: isDarkLayout ? Colors.white70 : Colors.grey[600],
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
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
}
