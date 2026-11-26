import 'package:flutter/foundation.dart';

// --- MODELOS PRINCIPAIS ---

@immutable
class ProviderConfig {
  final String id;
  final String name;
  final String apiUrl;
  final String
      layoutType; // NOVO: Tipo de layout (layout_02, layout_03, layout_06, layout_07)
  final String?
      diagnosticStyle; // Estilo de página de diagnóstico (diagnostic_02, diagnostic_03, etc.)
  final ConfigSection config;
  final FeaturesSection features;
  final MenuConfig menuConfig;
  final Map<String, dynamic>? theme;

  /// Política de privacidade (a do provedor ou a página gerada pelo
  /// servidor). Vazio: o app não mostra o link.
  final String privacyPolicyUrl;

  /// Como pedir a exclusão dos dados (LGPD).
  final String dataDeletionUrl;

  /// Versão mínima e mais recente do app (atualização obrigatória/sugerida).
  final AppVersionPolicy? appVersion;

  const ProviderConfig({
    required this.id,
    required this.name,
    required this.apiUrl,
    this.layoutType = 'layout_06', // Padrão: Layout 06 (Premium Dark)
    this.diagnosticStyle, // null = usa padrão baseado no layout
    required this.config,
    required this.features,
    required this.menuConfig,
    this.theme,
    this.privacyPolicyUrl = '',
    this.dataDeletionUrl = '',
    this.appVersion,
  });

  /// Só links https completos viram botão no app.
  static String _httpsUrl(Object? value) {
    if (value is! String) return '';
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return '';
    return value.trim();
  }

  /// Valida o esquema da apiUrl (A8). Rejeita esquemas não-http(s) (evita
  /// file:/javascript: vindos de config). Em release, bloqueia HTTP em claro
  /// para hosts não-loopback quando ENFORCE_HTTPS=true — assim, após habilitar o
  /// TLS no proxy reverso, token/CPF/senha nunca trafegam em texto puro.
  static String _validateApiUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw FormatException('apiUrl inválida (esquema não suportado): $url');
    }
    final host = uri.host;
    final isLoopback =
        host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2';
    if (uri.scheme == 'http' && !isLoopback) {
      const enforceHttps = bool.fromEnvironment(
        'ENFORCE_HTTPS',
        defaultValue: false,
      );
      if (enforceHttps) {
        return uri.replace(scheme: 'https').toString();
      }
      if (kReleaseMode) {
        debugPrint(
          '[SECURITY] apiUrl usa HTTP em claro em release: $host. '
          'Habilite TLS e ENFORCE_HTTPS.',
        );
      }
    }
    return url;
  }

  factory ProviderConfig.fromJson(
    Map<String, dynamic> json,
    String providerId,
  ) {
    final legacyConfig = json['config'] as Map<String, dynamic>? ?? {};

    // Combina configurações da raiz com as antigas
    final Map<String, dynamic> combinedConfig = {...legacyConfig, ...json};

    // Garante que 'integrations' seja preservado e passado corretamente
    if (!combinedConfig.containsKey('integrations') ||
        combinedConfig['integrations'] == null) {
      if (legacyConfig.containsKey('integrations')) {
        combinedConfig['integrations'] = legacyConfig['integrations'];
      }
    }

    // Limpeza para evitar recursão infinita no ConfigSection
    combinedConfig.remove('id');
    combinedConfig.remove('config');

    String? rootApiUrl = json['apiUrl'] as String?;
    String? configApiUrl = legacyConfig['apiUrl'] as String?;
    String? finalApiUrl =
        rootApiUrl?.isNotEmpty == true ? rootApiUrl : configApiUrl;

    // apiUrl: quando a configuração vem da API pública, é a URL que respondeu
    // (ConfigurationProvider a preenche); no fallback do Firestore, é o campo
    // apiUrl legado do documento do provedor.
    // Sem apiUrl na configuração, usa a URL gravada no build pelo apk-builder
    // (PUBLIC_API_URL). O endereço do emulador é só para desenvolvimento.
    const compiledApiUrl = String.fromEnvironment('PUBLIC_API_URL');
    String effectiveApiUrl;
    if (finalApiUrl != null && finalApiUrl.isNotEmpty) {
      effectiveApiUrl = finalApiUrl.trim();
    } else if (compiledApiUrl.isNotEmpty) {
      effectiveApiUrl = compiledApiUrl;
    } else {
      effectiveApiUrl = const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:8034',
      );
    }
    effectiveApiUrl = _validateApiUrl(effectiveApiUrl);

    final integrationsMap = (json['integrations'] ??
            legacyConfig['integrations']) as Map<String, dynamic>? ??
        {};
    var providerName = json['name'] as String? ??
        integrationsMap['appName'] as String? ??
        'Provedor';

    // FIX: Prevent legacy/template name "NetConnect" from appearing
    if (providerName.toLowerCase().replaceAll(' ', '') == 'netconnect') {
      providerName = 'Seu Provedor';
    }

    // [NEW] Extrai systemUrl de details para fallback
    final detailsMap = json['details'] as Map<String, dynamic>? ?? {};
    final fallbackSgpUrl = detailsMap['systemUrl'] as String? ?? '';

    // NOVO: Extrai layoutType do JSON ou usa padrão 'layout_06'
    final layoutType = json['layoutType'] as String? ?? 'layout_06';

    // NOVO: Extrai diagnosticStyle do JSON (null = usar padrão do layout)
    final diagnosticStyle = json['diagnosticStyle'] as String?;

    final otherMap = combinedConfig['other'];
    final privacyPolicyUrl = _httpsUrl(json['privacyPolicyUrl']).isNotEmpty
        ? _httpsUrl(json['privacyPolicyUrl'])
        : otherMap is Map
            ? _httpsUrl(otherMap['privacyPolicyUrl'])
            : '';

    return ProviderConfig(
      privacyPolicyUrl: privacyPolicyUrl,
      dataDeletionUrl: _httpsUrl(json['dataDeletionUrl']),
      appVersion: AppVersionPolicy.fromJson(json['appVersion']),
      id: providerId,
      name: providerName,
      apiUrl: effectiveApiUrl,
      layoutType: layoutType,
      diagnosticStyle: diagnosticStyle,
      config: ConfigSection.fromJson(combinedConfig, fallbackSgpUrl),
      features: FeaturesSection.fromJson(
        combinedConfig['features'] as Map<String, dynamic>? ?? {},
      ),
      menuConfig: MenuConfig.fromJson(
        json['menuConfig'] as Map<String, dynamic>? ?? {},
      ),
      theme: json['theme'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'apiUrl': apiUrl,
      'layoutType': layoutType,
      'diagnosticStyle': diagnosticStyle,
      'config': config.toJson(),
      'features': features.toJson(),
      'menuConfig': menuConfig.toJson(),
      'theme': theme,
      'privacyPolicyUrl': privacyPolicyUrl,
      'dataDeletionUrl': dataDeletionUrl,
      if (appVersion != null) 'appVersion': appVersion!.toJson(),
    };
  }
}

/// Política de versão do app vinda da configuração pública.
@immutable
class AppVersionPolicy {
  final String minVersion;
  final String latestVersion;
  final String storeUrl;
  final String title;
  final String message;
  final String buttonText;

  const AppVersionPolicy({
    this.minVersion = '',
    this.latestVersion = '',
    this.storeUrl = '',
    this.title = '',
    this.message = '',
    this.buttonText = '',
  });

  static AppVersionPolicy? fromJson(Object? raw) {
    if (raw is! Map) return null;
    String text(Object? v) => v is String ? v.trim() : '';
    final storeUrls = raw['storeUrls'];
    final candidates = [
      text(raw['storeUrl']),
      if (storeUrls is Map) text(storeUrls['android']),
    ];
    final store = candidates.firstWhere(
        (u) => Uri.tryParse(u)?.scheme == 'https',
        orElse: () => '');
    final msg = raw['updateMessage'];
    final pt = msg is Map && msg['pt_BR'] is Map ? msg['pt_BR'] as Map : null;
    final policy = AppVersionPolicy(
      // forceUpdate=false desliga o bloqueio mesmo com minVersion salva.
      minVersion: raw['forceUpdate'] == false ? '' : text(raw['minVersion']),
      latestVersion: text(raw['latestVersion']),
      storeUrl: store,
      title: text(pt?['title']),
      message: text(pt?['message']),
      buttonText: text(pt?['buttonText']),
    );
    if (policy.minVersion.isEmpty && policy.latestVersion.isEmpty) return null;
    return policy;
  }

  Map<String, dynamic> toJson() => {
        if (minVersion.isNotEmpty) 'minVersion': minVersion,
        if (latestVersion.isNotEmpty) 'latestVersion': latestVersion,
        if (storeUrl.isNotEmpty) 'storeUrl': storeUrl,
      };

  /// Compara versões "1.0.42" número a número (sufixos como "+3" ou
  /// "-beta" são ignorados). Negativo: [a] é mais antiga.
  static int compare(String a, String b) {
    List<int> parts(String v) => v
        .split(RegExp(r'[+\-\s]'))
        .first
        .split('.')
        .map((p) => int.tryParse(RegExp(r'\d+').stringMatch(p) ?? '') ?? 0)
        .toList();
    final x = parts(a), y = parts(b);
    for (var i = 0; i < (x.length > y.length ? x.length : y.length); i++) {
      final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
      if (d != 0) return d.sign;
    }
    return 0;
  }

  /// Versão instalada abaixo da mínima: o app bloqueia até atualizar.
  bool requiresUpdate(String installed) =>
      minVersion.isNotEmpty &&
      installed.trim().isNotEmpty &&
      compare(installed, minVersion) < 0;

  /// Há versão mais nova (aviso que pode ser fechado).
  bool suggestsUpdate(String installed) =>
      latestVersion.isNotEmpty &&
      installed.trim().isNotEmpty &&
      compare(installed, latestVersion) < 0;
}

// --- SEÇÕES DE CONFIGURAÇÃO ---

@immutable
class ConfigSection {
  final String themeColor;
  final String? secondaryColor;
  final String? textColor;
  final String? invoiceColor;
  final String? cardColor;
  final String? cardTextColor;
  final String? actionColor;
  final String? backgroundColor;
  final String? iconColor; // [NEW] Icon color
  final String? textSecondaryColor; // [NEW] Secondary Text Color
  final String? quickActionsCardColor; // [NEW] Quick Actions Card Color
  final String? quickActionsTextColor; // [NEW] Quick Actions Text Color
  final String? otherCardsColor; // [NEW] Other Cards Color
  final String? otherCardsTextColor; // [NEW] Other Cards Text Color
  final String logoUrl;
  final LogoFraming logoFraming;
  final String loginQuote;
  final SgpIntegration integrations;
  final List<FaqItem> faq;
  final List<TipItem> tips;
  final List<SupportContactItem> supportContacts;
  final List<dynamic> imageCarousel;
  final PromotionsConfig promotions;
  final OtherSettings? other;
  final Map<String, dynamic> strings;

  const ConfigSection({
    required this.themeColor,
    this.secondaryColor,
    this.textColor,
    this.invoiceColor,
    this.cardColor,
    this.cardTextColor,
    this.actionColor,
    this.backgroundColor,
    this.iconColor,
    this.textSecondaryColor, // [NEW]
    this.quickActionsCardColor, // [NEW]
    this.quickActionsTextColor, // [NEW]
    this.otherCardsColor, // [NEW]
    this.otherCardsTextColor, // [NEW]
    required this.logoUrl,
    this.logoFraming = const LogoFraming(),
    required this.loginQuote,
    required this.integrations,
    required this.faq,
    required this.tips,
    required this.supportContacts,
    required this.imageCarousel,
    this.promotions = const PromotionsConfig(),
    this.other,
    this.strings = const {},
  });

  factory ConfigSection.fromJson(
    Map<String, dynamic> json, [
    String fallbackSgpUrl = '',
  ]) {
    final faqList = json['faq'] as List<dynamic>? ?? [];
    final tipsList = (json['tips'] ?? json['dicas']) as List<dynamic>? ?? [];
    final contactsList = json['supportContacts'] as List<dynamic>? ?? [];
    final carouselList = json['imageCarousel'] as List<dynamic>? ?? [];
    final stringsMap = json['strings'] as Map<String, dynamic>? ?? {};

    return ConfigSection(
      themeColor: json['themeColor'] as String? ?? '#2456C9',
      secondaryColor: json['secondaryColor'] as String?,
      textColor: json['textColor'] as String?,
      invoiceColor: json['invoiceColor'] as String?,
      cardColor: json['cardColor'] as String?,
      cardTextColor: json['cardTextColor'] as String?,
      actionColor: json['actionColor'] as String?,
      backgroundColor: json['backgroundColor'] as String?,
      iconColor: json['iconColor'] as String?, // [NEW]
      textSecondaryColor: json['textSecondaryColor'] as String?, // [NEW]
      quickActionsCardColor: json['quickActionsCardColor'] as String?, // [NEW]
      quickActionsTextColor: json['quickActionsTextColor'] as String?, // [NEW]
      otherCardsColor: json['otherCardsColor'] as String?, // [NEW]
      otherCardsTextColor: json['otherCardsTextColor'] as String?, // [NEW]
      logoUrl: json['logoUrl'] as String? ?? '',
      logoFraming: LogoFraming.fromJson(json['logoFraming']),
      loginQuote: json['loginQuote'] as String? ?? 'Acesse sua conta.',
      integrations: SgpIntegration.fromJson(
        json['integrations'] as Map<String, dynamic>? ?? {},
        fallbackSgpUrl,
      ),
      faq: faqList
          .map((item) => FaqItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      tips: tipsList
          .map((item) => TipItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      supportContacts: contactsList
          .map(
            (item) => SupportContactItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      imageCarousel: carouselList,
      promotions: PromotionsConfig.fromJson(json['promotions']),
      other: json['other'] != null
          ? OtherSettings.fromJson(json['other'] as Map<String, dynamic>)
          : null,
      strings: stringsMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeColor': themeColor,
      'secondaryColor': secondaryColor,
      'textColor': textColor,
      'invoiceColor': invoiceColor,
      'cardColor': cardColor,
      'cardTextColor': cardTextColor,
      'actionColor': actionColor,
      'backgroundColor': backgroundColor,
      'iconColor': iconColor, // [NEW]
      'textSecondaryColor': textSecondaryColor, // [NEW]
      'quickActionsCardColor': quickActionsCardColor, // [NEW]
      'quickActionsTextColor': quickActionsTextColor, // [NEW]
      'otherCardsColor': otherCardsColor, // [NEW]
      'otherCardsTextColor': otherCardsTextColor, // [NEW]
      'logoUrl': logoUrl,
      'logoFraming': logoFraming.toJson(),
      'loginQuote': loginQuote,
      'integrations': integrations.toJson(),
      'faq': faq.map((e) => e.toJson()).toList(),
      'tips': tips.map((e) => e.toJson()).toList(),
      'supportContacts': supportContacts.map((e) => e.toJson()).toList(),
      'imageCarousel': imageCarousel,
      'promotions': promotions.toJson(),
      'other': other?.toJson(),
      'strings': strings,
    };
  }
}

@immutable
class LogoFraming {
  final String shape;
  final String fit;
  final double zoom;
  final double x;
  final double y;

  const LogoFraming({
    this.shape = 'circle',
    this.fit = 'contain',
    this.zoom = 1,
    this.x = 50,
    this.y = 50,
  });

  factory LogoFraming.fromJson(Object? value) {
    final map = value is Map ? value : const {};
    double number(String key, double fallback, double min, double max) {
      final entry = map[key];
      return entry is num && entry.isFinite
          ? entry.clamp(min, max).toDouble()
          : fallback;
    }

    return LogoFraming(
      shape: switch (map['shape']) {
        'rounded' => 'rounded',
        'wide' => 'wide',
        _ => 'circle',
      },
      fit: map['fit'] == 'cover' ? 'cover' : 'contain',
      zoom: number('zoom', 1, 1, 3),
      x: number('x', 50, 0, 100),
      y: number('y', 50, 0, 100),
    );
  }

  Map<String, dynamic> toJson() => {
        'shape': shape,
        'fit': fit,
        'zoom': zoom,
        'x': x,
        'y': y,
      };
}

@immutable
class Promotion {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String link;
  final String badge;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool active;
  final bool showCountdown;

  const Promotion({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.link,
    required this.badge,
    this.startDate,
    this.endDate,
    this.active = true,
    this.showCountdown = false,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    DateTime? date(dynamic value) =>
        value is String ? DateTime.tryParse(value) : null;
    return Promotion(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
      badge: json['badge']?.toString() ?? '',
      startDate: date(json['startDate']),
      endDate: date(json['endDate']),
      active: json['active'] != false &&
          !const {'draft', 'expired'}.contains(json['status']),
      showCountdown: json['showCountdown'] == true,
    );
  }

  bool isActiveAt(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final start = startDate == null
        ? null
        : DateTime(startDate!.year, startDate!.month, startDate!.day);
    final end = endDate == null
        ? null
        : DateTime(endDate!.year, endDate!.month, endDate!.day);
    return active &&
        title.trim().isNotEmpty &&
        (start == null || !today.isBefore(start)) &&
        (end == null || !today.isAfter(end));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'link': link,
        'badge': badge,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'active': active,
        'showCountdown': showCountdown,
      };
}

@immutable
class PromotionsConfig {
  final bool enabled;
  final List<Promotion> items;
  const PromotionsConfig({this.enabled = false, this.items = const []});

  factory PromotionsConfig.fromJson(dynamic value) {
    if (value is! Map) return const PromotionsConfig();
    final items = value['items'];
    return PromotionsConfig(
      enabled: value['enabled'] == true,
      items: items is List
          ? items
              .whereType<Map>()
              .map(
                (item) => Promotion.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
          : const [],
    );
  }

  List<Promotion> get activePromotions => enabled
      ? items.where((item) => item.isActiveAt(DateTime.now())).toList()
      : const [];

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'items': items.map((item) => item.toJson()).toList(),
      };
}

@immutable
class OtherSettings {
  final bool useBackgroundImage;
  final String? speedTestUrl;
  final bool showTvService;
  final bool showPhoneService;

  const OtherSettings({
    this.useBackgroundImage = false,
    this.speedTestUrl,
    this.showTvService = true,
    this.showPhoneService = true,
  });

  factory OtherSettings.fromJson(Map<String, dynamic> json) {
    return OtherSettings(
      useBackgroundImage: json['useBackgroundImage'] as bool? ?? false,
      speedTestUrl: json['speedTestUrl'] as String?,
      showTvService: json['showTvService'] as bool? ?? true,
      showPhoneService: json['showPhoneService'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'useBackgroundImage': useBackgroundImage,
      'speedTestUrl': speedTestUrl,
      'showTvService': showTvService,
      'showPhoneService': showPhoneService,
    };
  }
}

@immutable
class FeaturesSection {
  final bool invoices;
  final bool consumption;
  final bool support;
  final bool? useDynamicDashboard;

  const FeaturesSection({
    this.invoices = true,
    required this.consumption,
    required this.support,
    this.useDynamicDashboard,
  });

  factory FeaturesSection.fromJson(Map<String, dynamic> json) {
    return FeaturesSection(
      invoices: json['invoices'] as bool? ?? true,
      consumption: json['consumption'] as bool? ?? true,
      support: json['support'] as bool? ?? true,
      useDynamicDashboard: json['useDynamicDashboard'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoices': invoices,
      'consumption': consumption,
      'support': support,
      'useDynamicDashboard': useDynamicDashboard,
    };
  }
}

@immutable
class MenuConfig {
  final List<String> order;
  final Map<String, MenuItemDetails> items;

  const MenuConfig({required this.order, required this.items});

  factory MenuConfig.fromJson(Map<String, dynamic> json) {
    final itemsMap = json['items'] as Map<String, dynamic>? ?? {};
    return MenuConfig(
      order: List<String>.from(json['order'] as List<dynamic>? ?? []),
      items: itemsMap.map(
        (key, value) => MapEntry(
          key,
          MenuItemDetails.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'items': items.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}

@immutable
class SgpIntegration {
  const SgpIntegration();

  factory SgpIntegration.fromJson(Map<String, dynamic> _, [String __ = '']) {
    return const SgpIntegration();
  }

  Map<String, dynamic> toJson() => const {};
}

@immutable
class FaqItem {
  final String question;
  final String answer;

  const FaqItem({required this.question, required this.answer});

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'question': question, 'answer': answer};
  }
}

@immutable
class TipItem {
  final String title;
  final String description;

  const TipItem({required this.title, required this.description});

  factory TipItem.fromJson(Map<String, dynamic> json) {
    return TipItem(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'description': description};
  }
}

@immutable
class SupportContactItem {
  final String name;
  final String type;
  final String value;

  const SupportContactItem({
    required this.name,
    required this.type,
    required this.value,
  });

  factory SupportContactItem.fromJson(Map<String, dynamic> json) {
    return SupportContactItem(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'phone',
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'type': type, 'value': value};
  }
}

@immutable
class MenuItemDetails {
  final bool enabled;
  final String name;
  final String type;
  final String? url;
  final String? color;

  const MenuItemDetails({
    required this.enabled,
    required this.name,
    required this.type,
    this.url,
    this.color,
  });

  factory MenuItemDetails.fromJson(Map<String, dynamic> json) {
    return MenuItemDetails(
      enabled: json['enabled'] as bool? ?? false,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'internal',
      url: json['url'] as String?,
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'name': name,
      'type': type,
      'url': url,
      'color': color,
    };
  }
}
