import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'page_mapper.dart';
import 'configuration_provider.dart';
import 'widgets/dynamic_module_loader.dart';
import 'widgets/skeleton_loading.dart';
import 'dashboard_page.dart';
import 'suporte.dart';
import 'services/auth_service.dart';
import 'models/usuario.dart';
import 'models/provider_config.dart';
// import 'consumo_page.dart' deferred as consumo_page;
import 'widgets/dashboard/dynamic_dashboard.dart';
import 'utils.dart';
import 'shared/theme/app_colors.dart';
import 'screens/diagnostico_page.dart';

class MenuItem {
  final String id, name, type;
  final IconData icon;
  final String? url;
  final Color? color;
  const MenuItem(
      {required this.id,
      required this.name,
      required this.icon,
      required this.type,
      this.url,
      this.color});
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
  final PageStorageBucket _pageStorage = PageStorageBucket();

  late ProviderConfig _providerConfig;
  late Usuario _user;

  // Definindo os mapas de nomes e ícones padrão
  final Map<String, String> pageNames = {
    'dashboard': 'Início',
    'financeiro': 'Financeiro',
    'consumo': 'Consumo',
    'suporte': 'Suporte',
    'logout': 'Sair',
    'invoices': 'Faturas',
    'contract': 'Contrato',
    'my_ip': 'Meu IP',
    'speed_test': 'Velocidade',
    'internet_usage': 'Consumo',
    'useful_tips': 'Dicas',
    'faq': 'Ajuda',
    'abrir_chamado': 'Novo Chamado',
    'diagnostico': 'Diagnóstico',
    'promessa_pagamento': 'Promessa',
    'dicas': 'Dicas',
    'meu_ip': 'Meu IP',
    'status_servicos': 'Status',
    'velocidade': 'Velocidade',
  };

  final Map<String, IconData> pageIcons = {
    'dashboard': Icons.dashboard_rounded,
    'financeiro': Icons.attach_money_rounded,
    'consumo': Icons.data_usage_rounded,
    'suporte': Icons.support_agent_rounded,
    'logout': Icons.logout_rounded,
    'invoices': Icons.receipt_long_rounded,
    'contract': Icons.description_rounded,
    'my_ip': Icons.public_rounded,
    'speed_test': Icons.speed_rounded,
    'internet_usage': Icons.data_usage_rounded,
    'useful_tips': Icons.lightbulb_rounded,
    'faq': Icons.help_rounded,
    'external_link': Icons.open_in_new_rounded,
    'abrir_chamado': Icons.add_comment_rounded,
    'diagnostico': Icons.build_rounded,
    'promessa_pagamento': Icons.handshake_rounded,
    'dicas': Icons.lightbulb_outline_rounded,
    'status_servicos': Icons.network_check_rounded,
    'velocidade': Icons.speed_rounded,
  };

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
    _pages = _buildPages();
  }

  void _navigateToPage(String pageId) {
    if (pageId == 'logout') {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.logout();
      return;
    }
    PageMapper.navigateTo(context, pageId);
  }

  List<MenuItem> _loadMenuConfig() {
    final List<MenuItem> enabledItems = [];
    final configProvider =
        Provider.of<ConfigurationProvider>(context, listen: false);

    for (var id in _providerConfig.menuConfig.order) {
      final itemData = _providerConfig.menuConfig.items[id];
      if (itemData != null && itemData.enabled) {
        // Mapeamento de IDs para chaves de string
        String labelKey = id;
        if (id == 'dashboard') labelKey = 'home_tab_title';
        if (id == 'logout') labelKey = 'logout_label';
        if (id == 'diagnostico') labelKey = 'diagnostics_button';
        if (id == 'invoices') labelKey = 'view_invoices_label';
        if (id == 'contract') {
          labelKey = 'select_contract_message'; // Aproximação
        }

        String defaultLabel = itemData.name.isNotEmpty
            ? itemData.name
            : (pageNames[id] ?? 'Menu');

        // Tenta pegar do config, se não usa o default
        String finalLabel = configProvider.getString(labelKey, defaultLabel);

        enabledItems.add(MenuItem(
          id: id,
          name: finalLabel,
          type: itemData.type,
          url: itemData.url,
          icon: pageIcons[
                  itemData.type == 'external_link' ? 'external_link' : id] ??
              FontAwesomeIcons.question,
          color: itemData.color != null ? hexToColor(itemData.color!) : null,
        ));
      }
    }
    return enabledItems;
  }

  Color _getDefaultColorForId(String id) {
    switch (id) {
      case 'invoices':
        return const Color(0xFF1E6FF8);
      case 'support':
        return const Color(0xFF10B981);
      case 'contract':
        return const Color(0xFF8B5CF6);
      case 'my_ip':
        return const Color(0xFFF97316);
      case 'speed_test':
        return const Color(0xFFEAB308);
      case 'internet_usage':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF673AB7);
    }
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
    final config = _providerConfig.config;
    final dashboardMenuItems = _menuItems
        .map((item) => {
              'id': item.id,
              'label': item.name,
              'icon': item.icon,
              'type': item.type,
              'url': item.url,
            })
        .toList();
    final billValue = _parseBillAmount(_user.valorFatura);
    final dueDate = _parseDueDate(_user.vencimentoFatura);
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
        billAmount: billValue,
        billDueDate: dueDate,
        onNavigate: _navigateToPage,
        usedGb: 0,
        totalGb: 0,
        downloadMbps: 0,
        uploadMbps: 0,
        menuItems: dashboardMenuItems,
      );
    }
    return [
      dashboardWidget,
      // if (features.consumption)
      //   DynamicModuleLoader(
      //     key: const PageStorageKey('consumo'),
      //     primaryColor: AppColors.primaryBlue,
      //     loadLibrary: consumo_page.loadLibrary(),
      //     builder: (context) => consumo_page.ConsumoPage(
      //         cpfCnpj: _user.cpfCnpj, senha: _user.senha),
      //   ),
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

  @override
  Widget build(BuildContext context) {
    if (_pages == null) {
      return const SkeletonLoading();
    }

    final configProvider = Provider.of<ConfigurationProvider>(context);
    final config = _providerConfig.config;

    final barBgColor =
        config.cardColor != null ? hexToColor(config.cardColor!) : Colors.white;

    final bool isBgLight =
        ThemeData.estimateBrightnessForColor(barBgColor) == Brightness.light;

    final barIconColor = config.cardTextColor != null
        ? hexToColor(config.cardTextColor!)
        : (isBgLight ? const Color(0xFF94A3B8) : Colors.white.withOpacity(0.7));

    final activeItemColor = config.actionColor != null
        ? hexToColor(config.actionColor!)
        : (isBgLight ? const Color(0xFF1E6FF8) : Colors.white);

    final List<IconData> navIcons = [
      Icons.home_rounded,
      // if (_providerConfig.features.consumption) Icons.data_usage_rounded,
      if (_providerConfig.features.support) Icons.support_agent_rounded,
    ];
    final List<String> navLabels = [
      configProvider.getString('home_tab_title', 'Início'),
      // if (_providerConfig.features.consumption)
      //   configProvider.getString('consumption_tab_title', 'Consumo'),
      if (_providerConfig.features.support)
        configProvider.getString('support_tab_title', 'Suporte'),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu,
                color: Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _AppDrawer(
        user: _user,
        onNavigate: _navigateToPage,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: PageStorage(
        bucket: _pageStorage,
        child: IndexedStack(index: _selectedIndex, children: _pages!),
      ),
      bottomNavigationBar: navIcons.isEmpty
          ? null
          : _GlassBottomBar(
              selectedIndex: _selectedIndex,
              icons: navIcons,
              labels: navLabels,
              onTap: _onItemTapped,
              backgroundColor: barBgColor,
              itemsColor: activeItemColor,
              inactiveColor: barIconColor,
            ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final Usuario user;
  final Function(String) onNavigate;

  const _AppDrawer({required this.user, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(user.nome,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            accountEmail: Text(user.cpfCnpj, style: GoogleFonts.inter()),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Text(
                user.nome.isNotEmpty ? user.nome[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 24.0),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Início'),
            onTap: () => onNavigate('dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('Diagnóstico'),
            onTap: () => onNavigate('diagnostico'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () => onNavigate('logout'),
          ),
        ],
      ),
    );
  }
}

class _GlassBottomBar extends StatelessWidget {
  final int selectedIndex;
  final List<IconData> icons;
  final List<String> labels;
  final Function(int) onTap;
  final Color backgroundColor;
  final Color itemsColor;
  final Color inactiveColor;

  const _GlassBottomBar({
    required this.selectedIndex,
    required this.icons,
    required this.labels,
    required this.onTap,
    required this.backgroundColor,
    required this.itemsColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        height: 74,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(icons.length, (index) {
            final isSelected = selectedIndex == index;
            final color = isSelected ? itemsColor : inactiveColor;

            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? itemsColor.withOpacity(0.1)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icons[index],
                        color: color,
                        size: 26,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 2),
                      Text(
                        labels[index],
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
