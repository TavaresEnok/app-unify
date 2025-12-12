import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'shared/theme/app_colors.dart';
import 'configuration_provider.dart';
import 'widgets/skeleton_loading.dart';
import 'widgets/dynamic_module_loader.dart';
import 'dashboard_page.dart';
import 'financeiro_page.dart';
import 'consumo_page.dart' deferred as consumo_page;
import 'abrir_chamado_page.dart';
import 'diagnostico_page.dart';
import 'services/auth_service.dart';
import 'models/usuario.dart';
import 'models/provider_config.dart';
import 'widgets/dashboard/dynamic_dashboard.dart';
import 'utils.dart' show hexToColor;

class PainelPage extends StatefulWidget {
  final String? cpfCnpj;
  final String? senha;
  final String? content; // userName
  final String? plano;
  final String? status;
  final String? valorFatura;
  final String? vencimentoFatura;
  final Map<String, dynamic>? providerConfig;

  const PainelPage({
    super.key,
    this.cpfCnpj,
    this.senha,
    this.content,
    this.plano,
    this.status,
    this.valorFatura,
    this.vencimentoFatura,
    this.providerConfig,
  });

  @override
  State<PainelPage> createState() => _PainelPageState();
}

class _PainelPageState extends State<PainelPage> {
  int _selectedIndex = 0;
  List<Widget>? _pages;
  final PageStorageBucket _pageStorage = PageStorageBucket();

  String get _cpfCnpj => widget.cpfCnpj ?? _userFromProvider?.cpfCnpj ?? '';
  String get _senha => widget.senha ?? _userFromProvider?.senha ?? '';
  String get _nome => widget.content ?? _userFromProvider?.nome ?? 'Usuário';
  String get _plano => widget.plano ?? _userFromProvider?.plano ?? 'Plano';
  String get _status => widget.status ?? _userFromProvider?.status ?? 'Ativo';
  String get _valorFatura =>
      widget.valorFatura ?? _userFromProvider?.valorFatura ?? '0,00';
  String get _vencimentoFatura =>
      widget.vencimentoFatura ??
      _userFromProvider?.vencimentoFatura ??
      DateFormat('dd/MM/yyyy').format(DateTime.now());

  Usuario? _userFromProvider;
  dynamic _resolvedConfig;

  String _getString(String key, String defaultValue) {
    if (_resolvedConfig == null) return defaultValue;
    try {
      if (_resolvedConfig is ProviderConfig) {
        return _resolvedConfig.config.strings[key] ?? defaultValue;
      } else if (_resolvedConfig is Map) {
        // Fallback for Map if needed, but usually ProviderConfig is used for strings
        return defaultValue;
      }
    } catch (_) {}
    return defaultValue;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 1. Resolver Usuário
    if (widget.cpfCnpj == null) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        if (authService.isAuthenticated) {
          _userFromProvider = authService.usuario;
        }
      } catch (_) {}
    }

    // 2. Resolver Configuração
    if (_resolvedConfig == null) {
      if (widget.providerConfig != null) {
        try {
          print("🔍 Tentando fromJson com widget.providerConfig");
          _resolvedConfig =
              ProviderConfig.fromJson(widget.providerConfig!, 'vibe');
          print("✅ _resolvedConfig criado via fromJson");
        } catch (e) {
          print("❌ Erro ao converter providerConfig map: $e");
          // Deixar _resolvedConfig null para tentar Provider
        }
      }

      if (_resolvedConfig == null) {
        try {
          print("🔍 Tentando pegar do ConfigurationProvider");
          final configProvider =
              Provider.of<ConfigurationProvider>(context, listen: false);
          _resolvedConfig = configProvider.providerConfig;
          print("✅ _resolvedConfig do ConfigurationProvider");
          print("   Tipo: ${_resolvedConfig?.runtimeType}");
        } catch (e) {
          print("❌ Erro ao pegar config do provider: $e");
        }
      }
    }

    // Validação crítica
    if (_resolvedConfig == null) {
      print("❌ CRÍTICO: _resolvedConfig é NULL!");
      // Mostrar erro ao usuário ou carregar default
      return;
    }

    if (_pages == null && _resolvedConfig != null) {
      _pages = _buildPages();
    }
  }

  void _navigateToPage(String pageId) {
    if (pageId == 'invoices') setState(() => _selectedIndex = 1);
    if (pageId == 'internet_usage') setState(() => _selectedIndex = 2);
    if (pageId == 'network_diagnostic') setState(() => _selectedIndex = 3);
    if (pageId == 'support') setState(() => _selectedIndex = 4);
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
    // Extrair features de forma segura
    FeaturesSection features;
    if (_resolvedConfig is ProviderConfig) {
      features = (_resolvedConfig as ProviderConfig).features;
    } else {
      // Fallback seguro se for Map ou outro
      features = const FeaturesSection(
          consumption: true, support: true, useDynamicDashboard: false);
    }

    // Dashboard
    final useDynamicDashboard = features.useDynamicDashboard ?? false;
    final providerId = _resolvedConfig is ProviderConfig
        ? (_resolvedConfig as ProviderConfig).id
        : 'vibe';

    Widget dashboardWidget;

    if (useDynamicDashboard) {
      dashboardWidget = DynamicDashboard(providerId: providerId);
    } else {
      dashboardWidget = ProviderDashboardPage(
        customerName: _nome.split(' ').first,
        planName: _plano,
        connectionStatus: _status,
        billAmount: _parseBillAmount(_valorFatura),
        billDueDate: _parseDueDate(_vencimentoFatura),
        onNavigate: _navigateToPage,
        usedGb: 0.0,
        totalGb: 100,
        downloadMbps: 0.0,
        uploadMbps: 0.0,
      );
    }

    final List<Widget> pages = [
      dashboardWidget,
    ];

    // ========================================
    // EXTRAÇÃO ROBUSTA DE sgpParams (CORRIGIDO)
    // ========================================

    Map<String, dynamic> sgpParams = {};
    String sgpBaseUrl = 'https://vibetelecom.sgp.net.br';
    String? apiToken;
    String? appName;

    print("🔍 Iniciando extração de sgpParams...");
    print("🔍 _resolvedConfig tipo: ${_resolvedConfig.runtimeType}");

    try {
      // CAMINHO 1: ProviderConfig tipado
      if (_resolvedConfig is ProviderConfig) {
        print("✅ Detectado como ProviderConfig");

        final config = _resolvedConfig as ProviderConfig;
        final integrations = config.config.integrations;

        apiToken = integrations.apiToken;
        appName = integrations.appName;
        sgpBaseUrl = integrations.sgpBaseUrl;

        print(
            "   → apiToken: ${apiToken.substring(0, min(10, apiToken.length))}...");
        print("   → appName: $appName");
        print("   → sgpBaseUrl: $sgpBaseUrl");
      }
      // CAMINHO 2: Map dinâmico
      else if (_resolvedConfig is Map<String, dynamic>) {
        print("⚠️ Detectado como Map - usando extração alternativa");

        final configMap = _resolvedConfig as Map<String, dynamic>;

        // Tentativa 2.1: config.integrations
        if (configMap.containsKey('config')) {
          final configSection = configMap['config'];

          if (configSection is Map &&
              configSection.containsKey('integrations')) {
            final integrations = configSection['integrations'];

            if (integrations is Map) {
              apiToken = integrations['apiToken']?.toString();
              appName = integrations['appName']?.toString();
              sgpBaseUrl = integrations['sgpBaseUrl']?.toString() ?? sgpBaseUrl;

              print("   → Extraído de config.integrations");
              print(
                  "   → apiToken: ${apiToken?.substring(0, min(10, apiToken?.length ?? 0))}...");
              print("   → appName: $appName");
            }
          }
        }

        // Tentativa 2.2: details (fallback)
        if ((apiToken == null || apiToken.isEmpty) &&
            configMap.containsKey('details')) {
          final details = configMap['details'];

          if (details is Map) {
            apiToken = details['apiToken']?.toString();
            appName = details['appName']?.toString();
            sgpBaseUrl = details['sgpBaseUrl']?.toString() ??
                details['url']?.toString() ??
                sgpBaseUrl;

            print("   → Extraído de details (fallback)");
            print(
                "   → apiToken: ${apiToken?.substring(0, min(10, apiToken?.length ?? 0))}...");
            print("   → appName: $appName");
          }
        }
      } else {
        print(
            "❌ Tipo de _resolvedConfig não suportado: ${_resolvedConfig.runtimeType}");
      }

      // VALIDAÇÃO FINAL
      if (apiToken == null || apiToken.isEmpty) {
        print("❌ apiToken está vazio ou null!");
      }

      if (appName == null || appName.isEmpty) {
        print("❌ appName está vazio ou null!");
      }

      // CRIAR sgpParams VALIDADO
      // CORREÇÃO: Usar chaves 'token' e 'app' conforme esperado pelo FinanceiroService
      sgpParams = {
        'token': apiToken ?? '',
        'app': appName ?? '',
        'sgpBaseUrl': sgpBaseUrl,
      };

      print("✅ sgpParams criado com sucesso!");
      print("   Final: ${sgpParams.keys.join(', ')}");
    } catch (e, stackTrace) {
      print("❌ ERRO CRÍTICO na extração de sgpParams:");
      print("   Erro: $e");
      print(
          "   Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}");

      // Fallback seguro
      sgpParams = {
        'token': '',
        'app': '',
        'sgpBaseUrl': sgpBaseUrl,
      };
    }

    // Financeiro
    pages.add(FinanceiroPage(
      cpfCnpj: _cpfCnpj,
      senha: _senha,
      sgpParams: sgpParams,
    ));

    // Consumo
    if (features.consumption) {
      pages.add(DynamicModuleLoader(
        primaryColor: _resolvedConfig is ProviderConfig
            ? hexToColor((_resolvedConfig as ProviderConfig).config.themeColor)
            : AppColors.primary,
        loadLibrary: consumo_page.loadLibrary(),
        builder: (context) =>
            consumo_page.ConsumoPage(cpfCnpj: _cpfCnpj, senha: _senha),
      ));
    } else {
      pages.add(const Center(child: Text('Consumo não disponível')));
    }

    // Diagnóstico
    pages.add(const DiagnosticoPage());

    // Suporte
    pages.add(AbrirChamadoPage(
      cpfCnpj: _cpfCnpj,
      providerConfig: _resolvedConfig,
    ));

    return pages;
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    if (_pages == null) {
      if (_resolvedConfig != null) _pages = _buildPages();

      if (_pages == null) {
        return const SkeletonLoading();
      }
    }

    final List<BottomNavigationBarItem> navItems = [
      BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: _getString('home_tab_title', 'Início')),
      BottomNavigationBarItem(
          icon: const Icon(Icons.receipt_long_outlined),
          activeIcon: const Icon(Icons.receipt_long),
          label: _getString('financial_tab_title', 'Financeiro')),
      BottomNavigationBarItem(
          icon: const Icon(Icons.data_usage_outlined),
          activeIcon: const Icon(Icons.data_usage),
          label: _getString('consumption_tab_title', 'Consumo')),
      BottomNavigationBarItem(
          icon: const Icon(Icons.network_check_outlined),
          activeIcon: const Icon(Icons.network_check),
          label: 'Diagnóstico'),
      BottomNavigationBarItem(
          icon: const Icon(Icons.support_agent_outlined),
          activeIcon: const Icon(Icons.support_agent),
          label: _getString('support_tab_title', 'Suporte')),
    ];

    final primaryColor = _resolvedConfig is ProviderConfig
        ? hexToColor((_resolvedConfig as ProviderConfig).config.themeColor)
        : AppColors.primary;

    return Theme(
      data: Theme.of(context).copyWith(primaryColor: primaryColor),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: PageStorage(
            bucket: _pageStorage,
            child: IndexedStack(index: _selectedIndex, children: _pages!),
          ),
        ),
        bottomNavigationBar: _ModernBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
          items: navItems,
          selectedItemColor: primaryColor,
        ),
      ),
    );
  }
}

class _ModernBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final List<BottomNavigationBarItem> items;
  final Color selectedItemColor;

  const _ModernBottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.items,
    required this.selectedItemColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: selectedItemColor,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showUnselectedLabels: true,
        items: items,
        currentIndex: selectedIndex,
        onTap: onItemTapped,
      ),
    );
  }
}
