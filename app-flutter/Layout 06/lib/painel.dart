import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui'; // Import necessário para o BackdropFilter

import 'shared/theme/app_colors.dart';
import 'page_mapper.dart';
import 'configuration_provider.dart';
import 'widgets/dynamic_module_loader.dart';
import 'widgets/skeleton_loading.dart';
import 'dashboard_page.dart';
import 'suporte.dart';
import 'services/auth_service.dart';
import 'models/usuario.dart';
import 'models/provider_config.dart';
import 'consumo_page.dart' deferred as consumo_page;
import 'widgets/dashboard/dynamic_dashboard.dart';

class MenuItem {
  final String id, name, type;
  final IconData icon;
  final String? url;
  const MenuItem(
      {required this.id,
      required this.name,
      required this.icon,
      required this.type,
      this.url});
}

class PainelPage extends StatefulWidget {
  const PainelPage({super.key});

  @override
  State<PainelPage> createState() => _PainelPageState();
}

class _PainelPageState extends State<PainelPage> {
  int _selectedIndex = 0;
  List<Widget>? _pages;
  List<MenuItem> _menuItems = [];
  final PageStorageBucket _pageStorage =
      PageStorageBucket(); // Bucket para manter estado das abas

  late ProviderConfig _providerConfig;
  late Usuario _user;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) return;
    _user = authService.usuario!;

    final configProvider = Provider.of<ConfigurationProvider>(context);
    if (configProvider.providerConfig == null) {
      if (_pages != null) setState(() => _pages = null);
      return;
    }

    _providerConfig = configProvider.providerConfig!;

    if (_menuItems.isEmpty) {
      _menuItems = _loadMenuConfig();
    }
    _pages ??= _buildPages();
  }

  void _navigateToPage(String pageId) {
    navigateToPageById(
      context: context,
      pageId: pageId,
      cpfCnpj: _user.cpfCnpj,
      senha: _user.senha,
      status: _user.status,
      clientName: _user.nome,
    );
  }

  List<MenuItem> _loadMenuConfig() {
    final List<MenuItem> enabledItems = [];
    final configProvider =
        Provider.of<ConfigurationProvider>(context, listen: false);

    for (var id in _providerConfig.menuConfig.order) {
      final itemData = _providerConfig.menuConfig.items[id];
      if (itemData != null && itemData.enabled) {
        String labelKey = id;
        if (id == 'dashboard') labelKey = 'home_tab_title';
        if (id == 'logout') labelKey = 'logout_label';

        String defaultLabel = itemData.name.isNotEmpty ? itemData.name : 'Menu';
        String finalLabel = configProvider.getString(labelKey, defaultLabel);

        enabledItems.add(MenuItem(
          id: id,
          name: finalLabel,
          type: itemData.type,
          url: itemData.url,
          icon: pageIcons[
                  itemData.type == 'external_link' ? 'external_link' : id] ??
              FontAwesomeIcons.question,
        ));
      }
    }
    return enabledItems;
  }

  double _parseBillAmount(String billValue) {
    if (billValue.toLowerCase().contains('pago')) return 0.0;
    final cleanValue =
        billValue.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
    return double.tryParse(cleanValue) ?? 0.0;
  }

  DateTime _parseDueDate(String dueDateStr) {
    try {
      return DateFormat('dd/MM/yyyy').parse(dueDateStr);
    } catch (e) {
      return DateTime.now();
    }
  }

  List<Widget> _buildPages() {
    final features = _providerConfig.features;

    // 🎨 MODO HÍBRIDO
    final useDynamicDashboard = features.useDynamicDashboard ?? false;
    final providerId = _providerConfig.id ?? 'default';

    Widget dashboardWidget;

    if (useDynamicDashboard) {
      dashboardWidget = DynamicDashboard(providerId: providerId);
    } else {
      dashboardWidget = ProviderDashboardPage(
        key: const PageStorageKey('dashboard'),
        customerName: _user.nome,
        planName: _user.plano,
        connectionStatus: _user.status,
        billAmount: _parseBillAmount(_user.valorFatura),
        billDueDate: _parseDueDate(_user.vencimentoFatura),
        onNavigate: _navigateToPage,
        usedGb: 87.5,
        totalGb: 300,
        downloadMbps: 480.3,
        uploadMbps: 245.8,
      );
    }

    return [
      dashboardWidget,
      if (features.consumption)
        DynamicModuleLoader(
          key: const PageStorageKey('consumo'),
          primaryColor: Theme.of(context).primaryColor,
          loadLibrary: consumo_page.loadLibrary(),
          builder: (context) => consumo_page.ConsumoPage(
              cpfCnpj: _user.cpfCnpj, senha: _user.senha),
        ),
      if (features.support)
        SuportePage(
          key: const PageStorageKey('suporte'),
          cpfCnpj: _user.cpfCnpj,
          senha: _user.senha,
          status: _user.status,
          clientName: _user.nome,
        ),
    ];
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  void _handleMenuNavigation(MenuItem item) async {
    // A navegação não deve chamar pop aqui, pois o drawer fecha sozinho ou é fixo
    if (item.type == 'external_link' && item.url != null) {
      final uri = Uri.parse(item.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      _navigateToPage(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pages == null) {
      return const SkeletonLoading();
    }

    // Definição dos itens de navegação
    // Definição dos itens de navegação
    final configProvider = Provider.of<ConfigurationProvider>(context);
    final List<BottomNavigationBarItem> navItems = [
      BottomNavigationBarItem(
          icon: const Icon(Icons.home_filled),
          label: configProvider.getString('home_tab_title', 'Início')),
      if (_providerConfig.features.consumption)
        BottomNavigationBarItem(
            icon: const Icon(Icons.data_usage_rounded),
            label:
                configProvider.getString('consumption_tab_title', 'Consumo')),
      if (_providerConfig.features.support)
        BottomNavigationBarItem(
            icon: const Icon(Icons.support_agent_rounded),
            label: configProvider.getString('support_tab_title', 'Suporte')),
    ];

    // LayoutBuilder para responsividade (Mobile vs Tablet/Desktop)
    return LayoutBuilder(
      builder: (context, constraints) {
        // Define se usaremos NavigationRail (lateral) baseado na largura
        final useRail = constraints.maxWidth >= 900;
        final theme = Theme.of(context);

        // O corpo principal com as páginas
        final stack = PageStorage(
          bucket: _pageStorage,
          child: IndexedStack(index: _selectedIndex, children: _pages!),
        );

        // Corpo com fundo gradiente e padding responsivo
        final scaffoldBody = Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surface,
                const Color(0xFF0F172A),
                const Color(0xFF132040)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  EdgeInsets.fromLTRB(useRail ? 24 : 0, 0, useRail ? 24 : 0, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (useRail)
                    _SideRail(
                      user: _user,
                      logoUrl: _providerConfig.config.logoUrl,
                      selectedIndex: _selectedIndex,
                      menuItems: _menuItems,
                      onPageSelected: _onItemTapped,
                      onMenuItemSelected: _handleMenuNavigation,
                    ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(useRail ? 32 : 0),
                      child: Container(
                        decoration: BoxDecoration(
                          // Fundo semitransparente para o conteúdo principal
                          color: theme.colorScheme.surface
                              .withOpacity(useRail ? 0.75 : 1),
                          borderRadius: BorderRadius.circular(useRail ? 32 : 0),
                          border: Border.all(
                              color:
                                  Colors.white.withOpacity(useRail ? 0.05 : 0)),
                        ),
                        child: stack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        return Scaffold(
          extendBody:
              true, // Permite que o corpo se estenda por trás da bottomBar
          backgroundColor:
              Colors.transparent, // O fundo é controlado pelo Container acima
          // Drawer só aparece se NÃO estiver usando o Rail lateral
          drawer: useRail
              ? null
              : _ModernDrawer(
                  logoUrl: _providerConfig.config.logoUrl,
                  menuItems: _menuItems,
                  onMenuItemSelected: (item) => _handleMenuNavigation(item),
                ),
          body: scaffoldBody,
          // BottomNavigationBar só aparece no mobile
          bottomNavigationBar: useRail || navItems.isEmpty
              ? null
              : _ModernBottomNavBar(
                  selectedIndex: _selectedIndex,
                  onItemTapped: _onItemTapped,
                  items: navItems,
                ),
        );
      },
    );
  }
}

// --- WIDGETS DE NAVEGAÇÃO ---

class _SideRail extends StatelessWidget {
  final Usuario user;
  final String logoUrl;
  final int selectedIndex;
  final List<MenuItem> menuItems;
  final ValueChanged<int> onPageSelected;
  final ValueChanged<MenuItem> onMenuItemSelected;

  const _SideRail({
    required this.user,
    required this.logoUrl,
    required this.selectedIndex,
    required this.menuItems,
    required this.onPageSelected,
    required this.onMenuItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 24, top: 24, bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          _DrawerHeader(
              logoUrl: logoUrl,
              clientName: user.nome,
              plano: user.plano,
              isRail: true),
          const SizedBox(height: 12),
          // Itens principais de navegação
          _DrawerItem(
            title: context
                .read<ConfigurationProvider>()
                .getString('home_tab_title', 'Início'),
            icon: Icons.home_filled,
            isSelected: selectedIndex == 0,
            onTap: () => onPageSelected(0),
          ),
          _DrawerItem(
            title: context
                .read<ConfigurationProvider>()
                .getString('consumption_tab_title', 'Meu Consumo'),
            icon: Icons.data_usage_rounded,
            isSelected: selectedIndex == 1,
            onTap: () => onPageSelected(1),
          ),
          _DrawerItem(
            title: context
                .read<ConfigurationProvider>()
                .getString('support_tab_title', 'Suporte Técnico'),
            icon: Icons.support_agent_rounded,
            isSelected: selectedIndex == 2,
            onTap: () => onPageSelected(2),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Divider(color: Colors.white10),
          ),
          // Menu dinâmico
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: menuItems
                  .map((item) => _DrawerItem(
                        title: item.name,
                        icon: item.icon,
                        onTap: () => onMenuItemSelected(item),
                      ))
                  .toList(),
            ),
          ),
          const _DrawerFooter(closeDrawer: false),
        ],
      ),
    );
  }
}

class _ModernDrawer extends StatelessWidget {
  final String logoUrl;
  final List<MenuItem> menuItems;
  final Function(MenuItem) onMenuItemSelected;

  const _ModernDrawer({
    required this.logoUrl,
    required this.menuItems,
    required this.onMenuItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().usuario!;
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(children: [
          _DrawerHeader(
              logoUrl: logoUrl, clientName: user.nome, plano: user.plano),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 12),
                  child: Text(
                      context
                          .read<ConfigurationProvider>()
                          .getString('other_tools_label', 'OUTRAS FERRAMENTAS'),
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                ),
                ...menuItems.map((item) => _DrawerItem(
                      title: item.name,
                      icon: item.icon,
                      onTap: () {
                        Navigator.pop(context); // Fecha o drawer no mobile
                        onMenuItemSelected(item);
                      },
                    )),
              ],
            ),
          ),
          const _DrawerFooter(closeDrawer: true),
        ]),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final String logoUrl, clientName, plano;
  final bool isRail;
  const _DrawerHeader(
      {required this.logoUrl,
      required this.clientName,
      required this.plano,
      this.isRail = false});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: isRail
          ? null
          : BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppColors.inputBorder, width: 1))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (logoUrl.isNotEmpty)
          Image.network(logoUrl,
              height: 30, errorBuilder: (c, e, s) => const SizedBox.shrink()),
        if (logoUrl.isNotEmpty) const SizedBox(height: 20),
        Text(clientName,
            style:
                textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
            '${context.read<ConfigurationProvider>().getString('plan_prefix', 'Plano')}: $plano',
            style:
                textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem(
      {required this.title,
      required this.icon,
      this.isSelected = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Material(
        color: isSelected
            ? colorScheme.primary.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Icon(icon,
                  size: 22,
                  color: isSelected
                      ? colorScheme.primary
                      : AppColors.textSecondary),
              const SizedBox(width: 16),
              Text(title,
                  style: textTheme.titleMedium?.copyWith(
                      color: isSelected
                          ? colorScheme.onSurface
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  final bool closeDrawer;
  const _DrawerFooter({this.closeDrawer = true});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: closeDrawer
          ? BoxDecoration(
              border: Border(
                  top: BorderSide(color: AppColors.inputBorder, width: 1)))
          : null,
      child: Column(children: [
        _DrawerItem(
            title: context
                .read<ConfigurationProvider>()
                .getString('logout_label', 'Sair do Aplicativo'),
            icon: Icons.logout,
            onTap: () {
              if (closeDrawer) Navigator.pop(context);
              context.read<AuthService>().logout();
            }),
        const SizedBox(height: 12),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            return Text(
                'Versão ${snapshot.data!.version}+${snapshot.data!.buildNumber}',
                style: textTheme.bodySmall?.copyWith(color: Colors.white38));
          },
        ),
      ]),
    );
  }
}

class _ModernBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final List<BottomNavigationBarItem> items;

  const _ModernBottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Implementação do Glassmorphism (Vidro Fosco)
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          16, 0, 16, 24), // Padding inferior maior para afastar da borda
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter:
              ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Efeito de desfoque
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937)
                  .withOpacity(0.85), // Fundo escuro semi-transparente
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                  color: Colors.white.withOpacity(0.1)), // Borda sutil
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors
                  .transparent, // Transparente para mostrar o container acima
              elevation: 0,
              selectedItemColor: theme.colorScheme.primary,
              unselectedItemColor: Colors.white54,
              showUnselectedLabels: false,
              showSelectedLabels: false,
              items: items,
              currentIndex: selectedIndex,
              onTap: onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}
