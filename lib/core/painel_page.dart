import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../layout_selector.dart';
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

    // TEMPORARY: Force layout_04 for testing - REMOVE THIS LINE AFTER TESTING!
    // final layoutType = 'layout_04';
    final layoutType = configProvider.providerConfig?.layoutType ?? 'layout_06';

    print('[DEBUG] layoutType from config = $layoutType');

    if (usuario == null) {
      // Não deveria acontecer, mas por segurança
      return const Scaffold(
        body: Center(child: Text('Erro: Usuário não autenticado')),
      );
    }

    // Layout 04 (Aurora) has its own complete navigation system (AuroraMainPage)
    // So we return it directly without the common wrapper
    if (layoutType == 'layout_04') {
      print('[DEBUG] ====== LAYOUT 04 AURORA DETECTED ======');
      print('[DEBUG] layoutType = $layoutType');
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
        onNavigate: (page) {}, // Aurora handles its own navigation
      );
    }

    print('[DEBUG] Using standard layout: $layoutType');

    return Scaffold(
      appBar: _buildAppBar(context, layoutType),
      drawer: _buildDrawer(context, usuario, authService, layoutType),
      body: _buildBody(layoutType, usuario),
    );
  }

  AppBar _buildAppBar(BuildContext context, String layoutType) {
    // Cores baseadas no layout
    final isDarkLayout = layoutType == 'layout_06';
    final isOnDashboard = _currentPage == 'dashboard';
    final pageName = _pageNames[_currentPage] ?? 'Dashboard';

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

  Drawer _buildDrawer(BuildContext context, Usuario usuario,
      AuthService authService, String layoutType) {
    final isDarkLayout = layoutType == 'layout_06';
    final primaryColor = Theme.of(context).primaryColor;

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
