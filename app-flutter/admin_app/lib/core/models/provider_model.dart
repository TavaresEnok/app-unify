class ProviderModel {
  final String id;
  final String name;
  final String? logoUrl;
  final String? themeColor;
  final String? apiUrl;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? details;
  final Map<String, dynamic>? features;
  final Map<String, dynamic>? notifications;
  final Map<String, dynamic>? appConfig;

  ProviderModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.themeColor,
    this.apiUrl,
    this.active = true,
    this.createdAt,
    this.updatedAt,
    this.details,
    this.features,
    this.notifications,
    this.appConfig,
  });

  factory ProviderModel.fromMap(Map<String, dynamic> map, String id) {
    return ProviderModel(
      id: id,
      name: map['name'] ?? 'Sem nome',
      logoUrl: map['logoUrl'],
      themeColor: map['themeColor'],
      apiUrl: map['apiUrl'],
      active: map['active'] ?? true,
      createdAt: map['createdAt'] is String
          ? DateTime.tryParse(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] is String
          ? DateTime.tryParse(map['updatedAt'])
          : null,
      details: map['details'],
      features: map['features'],
      notifications: map['notifications'],
      appConfig: map['config'] ?? map['appConfig'], // Read from 'config' first
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'themeColor': themeColor,
      'apiUrl': apiUrl,
      'active': active,
      'details': details,
      'features': features,
      'notifications': notifications,
      'config': appConfig, // Save to 'config' to match Web Admin
    };
  }

  // Campos aceitos por POST /admin/providers (espelha personalizationSchema e
  // detailsSchema em api-service/src/services/providerConfig.ts). A API recusa
  // a requisição inteira se vier campo desconhecido; integração SGP, apiUrl e
  // identidade do app não passam por aqui.
  static const _personalizationKeys = {
    'layoutType', 'diagnosticStyle', 'themeColor', 'secondaryColor',
    'backgroundColor', 'cardColor', 'cardTextColor', 'textColor',
    'textSecondaryColor', 'iconColor', 'actionColor', 'invoiceColor',
    'quickActionsCardColor', 'quickActionsTextColor', 'otherCardsColor',
    'otherCardsTextColor', 'logoUrl', 'iconUrl', 'backgroundUrl', 'loginQuote',
    'termsOfUse', 'iconPack', 'typography', 'imageCarousel', 'menuConfig',
    'supportContacts', 'supportChannels', 'faq', 'tips', 'strings', 'features',
    'messages', 'social', 'socialNetworks', 'other', 'splash', 'login',
    'promotions', 'notifications', 'dashboardConfig', 'dashboard',
  };
  static const _detailKeys = {
    'name', 'email', 'phone', 'address', 'cnpj', 'contactName',
    'commercialName', 'website', 'city', 'state', 'systemType',
  };
  static const _featureKeys = {
    'consumption', 'support', 'invoices', 'contract', 'diagnostics',
    'speedTest', 'speedtest', 'notifications', 'tickets', 'tips', 'faq',
    'plans', 'profile', 'payment_promise', 'speed_test', 'terms_of_use',
    'custom_menu',
  };

  static Map<String, dynamic> _pick(
          Map<String, dynamic>? source, Set<String> keys) =>
      {
        for (final entry in (source ?? const {}).entries)
          if (keys.contains(entry.key) && entry.value != null)
            entry.key: entry.value,
      };

  /// Corpo de POST /admin/providers: com `id` (sem ele a API cria outro
  /// provedor) e só campos permitidos.
  Map<String, dynamic> toSaveMap() {
    final config = _pick(appConfig, _personalizationKeys)..remove('features');
    // layoutThemes antigos (layouts 07+) não passam no validador estrito; este
    // app não edita temas, e a gravação com merge preserva o valor atual.
    final strings = config['strings'];
    if (strings is Map) {
      config['strings'] = Map<String, dynamic>.from(strings)
        ..remove('layoutThemes');
    }
    final featureFlags = {
      for (final entry in (features ?? const {}).entries)
        if (_featureKeys.contains(entry.key) && entry.value is bool)
          entry.key: entry.value,
    };
    final detailsMap = {
      for (final entry in _pick(details, _detailKeys).entries)
        if (entry.value is String) entry.key: entry.value,
    };
    final notificationList = notifications?['list'];
    return {
      'id': id,
      'name': name,
      'active': active,
      if (logoUrl != null && logoUrl!.isNotEmpty) 'logoUrl': logoUrl,
      if (themeColor != null && themeColor!.isNotEmpty) 'themeColor': themeColor,
      if (featureFlags.isNotEmpty) 'features': featureFlags,
      if (detailsMap.isNotEmpty) 'details': detailsMap,
      if (notificationList is List) 'notifications': {'list': notificationList},
      if (config.isNotEmpty) 'config': config,
    };
  }

  ProviderModel copyWith({
    String? name,
    String? logoUrl,
    String? themeColor,
    String? apiUrl,
    bool? active,
    Map<String, dynamic>? details,
    Map<String, dynamic>? features,
    Map<String, dynamic>? notifications,
    Map<String, dynamic>? appConfig,
  }) {
    return ProviderModel(
      id: id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      themeColor: themeColor ?? this.themeColor,
      apiUrl: apiUrl ?? this.apiUrl,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: updatedAt,
      details: details ?? this.details,
      features: features ?? this.features,
      notifications: notifications ?? this.notifications,
      appConfig: appConfig ?? this.appConfig,
    );
  }
}
