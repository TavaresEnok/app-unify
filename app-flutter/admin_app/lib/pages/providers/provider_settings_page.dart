import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/provider_model.dart';
import '../../core/providers/providers.dart';
import 'tabs/banners_tab.dart';
import 'tabs/social_tab.dart';
import 'tabs/faq_tab.dart';
import 'tabs/notifications_tab.dart';
import 'tabs/app_config_tab.dart';
import 'tabs/terms_tab.dart';
import 'tabs/texts_tab.dart';
import 'tabs/backup_tab.dart';
import 'tabs/support_tab.dart';
import 'tabs/menus_tab.dart';
import 'tabs/tips_tab.dart';
import 'tabs/promotions_tab.dart';
import 'tabs/other_tab.dart';
import 'tabs/dashboard_builder_tab.dart';

class ProviderSettingsPage extends ConsumerStatefulWidget {
  final ProviderModel provider;

  const ProviderSettingsPage({super.key, required this.provider});

  @override
  ConsumerState<ProviderSettingsPage> createState() =>
      _ProviderSettingsPageState();
}

class _ProviderSettingsPageState extends ConsumerState<ProviderSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ProviderModel _localProvider;
  bool _isSaving = false;

  // Appearance
  late TextEditingController _themeColorController;
  late TextEditingController _secondaryColorController;
  late TextEditingController _backgroundColorController; // [NEW]
  late TextEditingController _iconColorController; // [NEW]
  late TextEditingController _cardColorController; // [NEW]
  late TextEditingController _textColorController; // [NEW]
  late TextEditingController _logoUrlController;
  late TextEditingController _appNameController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;

  // Features
  late bool _featureConsumption;
  late bool _featureSupport;
  late bool _featureInvoices;
  late bool _featureContract;
  late bool _hasAndroidApp;
  late bool _hasIosApp;

  // Integrations
  late TextEditingController _apiUrlController;
  late TextEditingController
  _textSecondaryColorController; // [FIX] Re-adding declaration
  late TextEditingController _apiTokenController;
  late TextEditingController _systemUrlController;
  late TextEditingController _systemTypeController;

  @override
  void initState() {
    super.initState();
    _localProvider = widget.provider;
    _tabController = TabController(length: 17, vsync: this);

    final appConfig = _localProvider.appConfig ?? {};

    // Init appearance & general
    _themeColorController = TextEditingController(
      text: _localProvider.themeColor ?? '#673AB7',
    );
    // [FIX] Read from appConfig first, then details fallback
    _secondaryColorController = TextEditingController(
      text:
          appConfig['secondaryColor'] ??
          _localProvider.details?['secondaryColor'] ??
          '#9575CD',
    );
    _backgroundColorController = TextEditingController(
      text: appConfig['backgroundColor'] ?? '#0F172A',
    );
    _iconColorController = TextEditingController(
      text: appConfig['iconColor'] ?? '#FFFFFF',
    );
    _cardColorController = TextEditingController(
      text: appConfig['cardColor'] ?? '#1E293B',
    );
    _textColorController = TextEditingController(
      text: appConfig['textColor'] ?? '#FFFFFF',
    );
    _textSecondaryColorController = TextEditingController(
      text: appConfig['textSecondaryColor'] ?? '#94A3B8',
    );

    _logoUrlController = TextEditingController(
      text: _localProvider.logoUrl ?? '',
    );
    _appNameController = TextEditingController(
      text: _localProvider.details?['appName'] ?? '',
    );
    _cityController = TextEditingController(
      text: _localProvider.details?['city'] ?? '',
    );
    _stateController = TextEditingController(
      text: _localProvider.details?['state'] ?? '',
    );

    // Init features
    final features = _localProvider.features ?? {};
    final details = _localProvider.details ?? {};
    _featureConsumption = features['consumption'] ?? true;
    _featureSupport = features['support'] ?? true;
    _featureInvoices = features['invoices'] ?? true;
    _featureContract = features['contract'] ?? true;
    _hasAndroidApp = details['hasAndroidApp'] ?? false;
    _hasIosApp = details['hasIosApp'] ?? false;

    // Init integrations
    _apiUrlController = TextEditingController(
      text: _localProvider.apiUrl ?? '',
    );
    _apiTokenController = TextEditingController(
      text: details['apiToken'] ?? '',
    );
    _systemUrlController = TextEditingController(
      text: details['systemUrl'] ?? '',
    );
    _systemTypeController = TextEditingController(
      text: details['systemType'] ?? '',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _themeColorController.dispose();
    _secondaryColorController.dispose();
    _backgroundColorController.dispose();
    _iconColorController.dispose();
    _cardColorController.dispose();
    _textColorController.dispose();
    _logoUrlController.dispose();
    _apiUrlController.dispose();
    _apiTokenController.dispose();
    super.dispose();
  }

  void _updateLocalProvider(Map<String, dynamic> changes) {
    setState(() {
      _localProvider = _localProvider.copyWith(
        themeColor: changes['themeColor'],
        logoUrl: changes['logoUrl'],
        apiUrl: changes['apiUrl'],
        features: changes['features'],
        details: changes['details'],
        notifications: changes['notifications'],
        appConfig: changes['appConfig'],
      );
    });
    // Auto-save on tab changes
    _saveSettings(isAutoSave: true);
  }

  Future<void> _saveSettings({bool isAutoSave = false}) async {
    setState(() => _isSaving = true);

    // Construct Updated Provider
    final updatedDetails = Map<String, dynamic>.from(
      _localProvider.details ?? {},
    );
    // [FIX] Do NOT save colors to details anymore, save to appConfig
    updatedDetails['appName'] = _appNameController.text.trim();
    updatedDetails['city'] = _cityController.text.trim();
    updatedDetails['state'] = _stateController.text.trim();
    updatedDetails['apiToken'] = _apiTokenController.text.trim();
    updatedDetails['systemUrl'] = _systemUrlController.text.trim();
    updatedDetails['systemType'] = _systemTypeController.text.trim();
    updatedDetails['hasAndroidApp'] = _hasAndroidApp;
    updatedDetails['hasIosApp'] = _hasIosApp;

    final updatedFeatures = Map<String, dynamic>.from(
      _localProvider.features ?? {},
    );
    updatedFeatures['consumption'] = _featureConsumption;
    updatedFeatures['support'] = _featureSupport;
    updatedFeatures['invoices'] = _featureInvoices;
    updatedFeatures['contract'] = _featureContract;

    // [NEW] Update appConfig (which corresponds to 'config' in Firestore)
    final updatedAppConfig = Map<String, dynamic>.from(
      _localProvider.appConfig ?? {},
    );
    updatedAppConfig['themeColor'] = _themeColorController.text.trim(); // Sync
    updatedAppConfig['secondaryColor'] = _secondaryColorController.text.trim();
    updatedAppConfig['backgroundColor'] = _backgroundColorController.text
        .trim();
    updatedAppConfig['iconColor'] = _iconColorController.text.trim();
    updatedAppConfig['cardColor'] = _cardColorController.text.trim();
    updatedAppConfig['textColor'] = _textColorController.text.trim();

    final updatedProvider = _localProvider.copyWith(
      themeColor: _themeColorController.text.trim(),
      logoUrl: _logoUrlController.text.trim(),
      apiUrl: _apiUrlController.text.trim(),
      features: updatedFeatures,
      details: updatedDetails,
      appConfig: updatedAppConfig,
    );

    try {
      await ref.read(providerRepositoryProvider).saveProvider(updatedProvider);

      // Update local state to match saved
      setState(() {
        _localProvider = updatedProvider;
      });

      if (mounted && !isAutoSave) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações salvas!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Config - ${_localProvider.name}'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF673AB7),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.palette), text: 'Aparência'),
            Tab(icon: Icon(Icons.smartphone), text: 'App Config'),
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.menu), text: 'Menus'),
            Tab(icon: Icon(Icons.description), text: 'Termos'),
            Tab(icon: Icon(Icons.text_fields), text: 'Textos'),
            Tab(icon: Icon(Icons.toggle_on), text: 'Features'),
            Tab(icon: Icon(Icons.link), text: 'Integrações'),
            Tab(icon: Icon(Icons.view_carousel), text: 'Banners'),
            Tab(icon: Icon(Icons.share), text: 'Social'),
            Tab(icon: Icon(Icons.help_outline), text: 'FAQ'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Dicas'),
            Tab(icon: Icon(Icons.local_offer), text: 'Promoções'),
            Tab(icon: Icon(Icons.support_agent), text: 'Suporte'),
            Tab(icon: Icon(Icons.notifications), text: 'Notificações'),
            Tab(icon: Icon(Icons.settings), text: 'Outras'),
            Tab(icon: Icon(Icons.backup), text: 'Backup'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppearanceTab(),
          AppConfigTab(provider: _localProvider, onSave: _updateLocalProvider),
          DashboardBuilderTab(
            provider: _localProvider,
            onSave: _updateLocalProvider,
          ),
          MenusTab(provider: _localProvider, onSave: _updateLocalProvider),
          TermsTab(provider: _localProvider, onSave: _updateLocalProvider),
          TextsTab(provider: _localProvider, onSave: _updateLocalProvider),
          _buildFeaturesTab(),
          _buildIntegrationsTab(),
          BannersTab(provider: _localProvider, onSave: _updateLocalProvider),
          SocialTab(provider: _localProvider, onSave: _updateLocalProvider),
          FaqTab(provider: _localProvider, onSave: _updateLocalProvider),
          TipsTab(provider: _localProvider, onSave: _updateLocalProvider),
          PromotionsTab(provider: _localProvider, onSave: _updateLocalProvider),
          SupportTab(provider: _localProvider, onSave: _updateLocalProvider),
          NotificationsTab(
            provider: _localProvider,
            onSave: _updateLocalProvider,
          ),
          OtherTab(provider: _localProvider, onSave: _updateLocalProvider),
          BackupTab(provider: _localProvider),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : () => _saveSettings(),
        backgroundColor: const Color(0xFF673AB7),
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save, color: Colors.white),
        label: Text(
          _isSaving ? 'Salvando...' : 'Salvar',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAppearanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cores do Tema',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildColorField('Cor Primária', _themeColorController),
          const SizedBox(height: 16),

          _buildColorField('Cor Secundária', _secondaryColorController),
          const SizedBox(height: 24),

          // [NEW] Additional Colors
          const Text(
            'Personalização',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildColorField('Cor de Fundo (Page)', _backgroundColorController),
          const SizedBox(height: 16),
          _buildColorField('Cor dos Ícones', _iconColorController),
          const SizedBox(height: 16),
          _buildColorField('Cor dos Cards (Surface)', _cardColorController),
          const SizedBox(height: 16),
          _buildColorField('Cor do Texto', _textColorController),
          const SizedBox(height: 16),
          _buildColorField(
            'Cor do Texto Secundário',
            _textSecondaryColorController,
          ),
          const SizedBox(height: 24),

          const Text(
            'Logo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _logoUrlController,
            decoration: InputDecoration(
              labelText: 'URL da Logo',
              hintText: 'https://...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.image),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Informações Gerais',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _appNameController,
            decoration: InputDecoration(
              labelText: 'Nome do Aplicativo',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'Cidade',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _stateController,
                  decoration: InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorField(String label, TextEditingController controller) {
    Color? previewColor;
    try {
      previewColor = Color(
        int.parse(controller.text.replaceFirst('#', '0xFF')),
      );
    } catch (e) {
      previewColor = null;
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              hintText: '#673AB7',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: previewColor ?? Colors.grey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Módulos do App',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildFeatureSwitch(
            'Consumo',
            'Visualização do consumo',
            Icons.speed,
            _featureConsumption,
            (v) => setState(() => _featureConsumption = v),
          ),

          _buildFeatureSwitch(
            'Suporte',
            'Tickets de suporte',
            Icons.support_agent,
            _featureSupport,
            (v) => setState(() => _featureSupport = v),
          ),

          _buildFeatureSwitch(
            'Faturas',
            'Visualização de faturas',
            Icons.receipt_long,
            _featureInvoices,
            (v) => setState(() => _featureInvoices = v),
          ),

          _buildFeatureSwitch(
            'Contratos',
            'Visualização de contratos',
            Icons.description,
            _featureContract,
            (v) => setState(() => _featureContract = v),
          ),

          const Divider(height: 32),
          const Text(
            'Plataformas Disponíveis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFeatureSwitch(
            'Android App',
            'Aplicativo Android habilitado',
            Icons.android,
            _hasAndroidApp,
            (v) => setState(() => _hasAndroidApp = v),
          ),
          _buildFeatureSwitch(
            'iOS App',
            'Aplicativo iPhone habilitado',
            Icons.apple,
            _hasIosApp,
            (v) => setState(() => _hasIosApp = v),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSwitch(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, color: const Color(0xFF673AB7)),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Text(subtitle),
        ),
        value: value,
        onChanged: onChanged,
        // ignore: deprecated_member_use
        activeColor: const Color(0xFF2563EB),
      ),
    );
  }

  Widget _buildIntegrationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'API SGP',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _apiUrlController,
            decoration: InputDecoration(
              labelText: 'URL da API',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _apiTokenController,
            decoration: InputDecoration(
              labelText: 'Token',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Sistema de Gestão',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _systemUrlController,
            decoration: InputDecoration(
              labelText: 'URL do Sistema (SGP)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _systemTypeController,
            decoration: InputDecoration(
              labelText: 'Tipo de Sistema',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
