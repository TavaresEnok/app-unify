import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../layout_selector.dart';
import '../layouts/layout_05/theme.dart'; // Import Layout05 Theme
import 'providers/configuration_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'models/usuario.dart';

/// PainelPage - Widget principal de navegação após login
///
/// Gerencia:
/// - Drawer/Menu lateral
/// - Rotas entre páginas (faturas, suporte, consumo, etc.)
/// - Renderização do dashboard correto via LayoutSelector
class PainelPage extends StatefulWidget {
  const PainelPage({super.key});

  @override
  State<PainelPage> createState() => _PainelPageState();
}

class _PainelPageState extends State<PainelPage> {
  String _currentPage = 'dashboard'; // Página atual

  // Mapa de rotas para páginas
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

  // Mapa de ícones para cada página
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
    Navigator.of(context).pop(); // Fecha o drawer
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final configProvider = Provider.of<ConfigurationProvider>(context);
    final usuario = authService.usuario;

    final layoutType = configProvider.providerConfig?.layoutType ?? 'layout_06';

    if (usuario == null) {
      // Não deveria acontecer, mas por segurança
      return const Scaffold(
        body: Center(child: Text('Erro: Usuário não autenticado')),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(context, layoutType),
      drawer: _buildDrawer(context, usuario, authService, layoutType),
      body: _buildBody(layoutType, usuario),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String layoutType) {
    // Cores baseadas no layout
    final isDarkLayout = layoutType == 'layout_06';
    final isNeumorphic = layoutType == 'layout_05'; // Soft UI Check

    final isOnDashboard = _currentPage == 'dashboard';
    final pageName = _pageNames[_currentPage] ?? 'Dashboard';

    // Custom Neumorphic AppBar
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
            // Slight separation line/shadow simulation if desired, or leave empty for "Seamless"
          ),
        ),
      );
    }

    // Default Material AppBar (Layout 06, etc.)
    return AppBar(
      // Back button when not on dashboard
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
      // Breadcrumb title
      title: isOnDashboard
          ? Text(pageName)
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
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withOpacity(0.7),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withOpacity(0.5),
                  ),
                ),
                Text(
                  pageName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
      elevation: isDarkLayout ? 0 : 2,
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

  Widget _buildDrawer(BuildContext context, Usuario usuario,
      AuthService authService, String layoutType) {
    final isDarkLayout = layoutType == 'layout_06';
    final isNeumorphic = layoutType == 'layout_05'; // Soft UI Check
    final primaryColor = Theme.of(context).primaryColor;

    if (isNeumorphic) {
      return Drawer(
        backgroundColor: Layout05Theme.background,
        elevation: 0,
        // We use a container to apply border if needed or just let it be flat
        child: Column(
          children: [
            // User Header - Neumorphic
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              color: Layout05Theme.background,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: Layout05Theme.neumorphicDecoration
                        .copyWith(shape: BoxShape.circle),
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
            // Menu Items
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
                    if (shouldLogout == true) authService.logout();
                  }),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Default Drawer
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header do Drawer com informações do usuário
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
                // Avatar do usuário
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
                // Nome do usuário
                Text(
                  'Olá, ${usuario.nome}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                // Plano do usuário
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

          // Menu items
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

          // Dark Mode Toggle
          Consumer<DynamicThemeProvider>(
            builder: (context, themeProvider, _) {
              final isDark = themeProvider.themeMode == ThemeMode.dark;
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
                  themeProvider.setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              );
            },
          ),

          const Divider(),

          // Botão de logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Sair',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              // Confirmar logout
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
                await authService.logout();
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

    // "Pressed" state for selected item
    final decoration =
        isSelected ? Layout05Theme.neumorphicPressedDecoration : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: decoration, // If not selected, it's flat/transparent
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
    // Se for dashboard, usa LayoutSelector
    if (_currentPage == 'dashboard') {
      return LayoutSelector.getDashboard(
        layoutType: layoutType,
        customerName: usuario.nome,
        planName: usuario.plano,
        connectionStatus: usuario.status,
        billAmount: _parseBillAmount(usuario.valorFatura),
        billDueDate: _parseBillDate(usuario.vencimentoFatura),
        usedGb: 50.0, // TODO: Buscar dados reais do consumo
        totalGb: 100.0, // TODO: Buscar dados reais do plano
        downloadMbps: 100.0, // TODO: Buscar dados reais
        uploadMbps: 50.0, // TODO: Buscar dados reais
        onNavigate: (page) {
          setState(() {
            _currentPage = page;
          });
        },
      );
    }

    // Página de Faturas (Financeiro)
    if (_currentPage == 'invoices') {
      return LayoutSelector.getFinanceiroPage(layoutType: layoutType);
    }

    // Página de Suporte
    if (_currentPage == 'support') {
      return LayoutSelector.getSuportePage(layoutType: layoutType);
    }

    // Página de Diagnóstico de Rede
    if (_currentPage == 'network_diagnostic') {
      return LayoutSelector.getDiagnosticoPage(layoutType: layoutType);
    }

    // Página de Consumo de Internet
    if (_currentPage == 'internet_usage') {
      return LayoutSelector.getConsumoPage(layoutType: layoutType);
    }

    // Página de Meu IP
    if (_currentPage == 'my_ip') {
      return LayoutSelector.getMeuIpPage(layoutType: layoutType);
    }

    // Página de FAQ
    if (_currentPage == 'faq') {
      return LayoutSelector.getFaqPage(layoutType: layoutType);
    }

    // Página de Contrato
    if (_currentPage == 'contract') {
      return LayoutSelector.getContratoPage(layoutType: layoutType);
    }

    // Página de Wifi
    if (_currentPage == 'wifi') {
      return LayoutSelector.getWifiPage(layoutType: layoutType);
    }

    // Página de Velocidade (usa Diagnóstico que já tem speed test)
    if (_currentPage == 'speed_test') {
      return LayoutSelector.getDiagnosticoPage(layoutType: layoutType);
    }

    // Para outras páginas, mostrar placeholder por enquanto
    // TODO: Adicionar LayoutSelector para cada página conforme forem unificadas
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

  /// Converte string de valor para double (ex: "R$ 150,00" -> 150.0)
  double _parseBillAmount(String value) {
    try {
      // Remove tudo exceto números, vírgula e ponto
      final cleaned = value.replaceAll(RegExp(r'[^0-9,.]'), '');
      // Substitui vírgula por ponto para parse
      final normalized = cleaned.replaceAll(',', '.');
      return double.parse(normalized);
    } catch (_) {
      return 0.0;
    }
  }

  /// Converte string de data para DateTime (formato dd/mm/yyyy)
  DateTime _parseBillDate(String value) {
    try {
      final parts = value.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]), // ano
          int.parse(parts[1]), // mês
          int.parse(parts[0]), // dia
        );
      }
    } catch (_) {}
    return DateTime.now();
  }
}
