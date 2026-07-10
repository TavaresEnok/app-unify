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
  });

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

    // CORREÇÃO: Removido replace automático de IP.
    // O usuário deve configurar o IP correto no Firebase.
    // if (finalApiUrl != null && finalApiUrl.contains('45.176.56.70')) {
    //   finalApiUrl = finalApiUrl.replaceAll('45.176.56.70', '168.194.13.18');
    // }

    // IMPORTANTE: A URL da API deve ser configurada no Web Admin (Firebase)
    // Campo: apiUrl no documento do provedor
    // Exemplo: http://seu-servidor:3000
    //
    // O fallback abaixo é apenas para desenvolvimento/emergência.
    // Se você mudar de servidor, basta atualizar o campo apiUrl no Firebase
    // e todos os apps receberão a nova URL automaticamente!
    String effectiveApiUrl;
    if (finalApiUrl != null && finalApiUrl.isNotEmpty) {
      effectiveApiUrl = finalApiUrl.trim();
    } else {
      // FALLBACK DE EMERGÊNCIA - Configure apiUrl no Firebase!
      effectiveApiUrl = 'http://168.194.13.18:8034';
    }

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

    return ProviderConfig(
      id: providerId,
      name: providerName,
      apiUrl: effectiveApiUrl,
      layoutType: layoutType,
      diagnosticStyle: diagnosticStyle,
      config: ConfigSection.fromJson(combinedConfig, fallbackSgpUrl),
      features: FeaturesSection.fromJson(
        json['features'] as Map<String, dynamic>? ?? {},
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
    };
  }
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
  final String loginQuote;
  final SgpIntegration integrations;
  final List<FaqItem> faq;
  final List<TipItem> tips;
  final List<SupportContactItem> supportContacts;
  final List<dynamic> imageCarousel;
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
    required this.loginQuote,
    required this.integrations,
    required this.faq,
    required this.tips,
    required this.supportContacts,
    required this.imageCarousel,
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
      themeColor: json['themeColor'] as String? ?? '#1E6FF8',
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
      'loginQuote': loginQuote,
      'integrations': integrations.toJson(),
      'faq': faq.map((e) => e.toJson()).toList(),
      'tips': tips.map((e) => e.toJson()).toList(),
      'supportContacts': supportContacts.map((e) => e.toJson()).toList(),
      'imageCarousel': imageCarousel,
      'other': other?.toJson(),
      'strings': strings,
    };
  }
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
  final bool consumption;
  final bool support;
  final bool? useDynamicDashboard;

  const FeaturesSection({
    required this.consumption,
    required this.support,
    this.useDynamicDashboard,
  });

  factory FeaturesSection.fromJson(Map<String, dynamic> json) {
    return FeaturesSection(
      consumption: json['consumption'] as bool? ?? true,
      support: json['support'] as bool? ?? true,
      useDynamicDashboard: json['useDynamicDashboard'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
  final String apiToken;
  final String appName;
  final String sgpBaseUrl;

  const SgpIntegration({
    required this.apiToken,
    required this.appName,
    required this.sgpBaseUrl,
  });

  factory SgpIntegration.fromJson(
    Map<String, dynamic> json, [
    String fallbackUrl = '',
  ]) {
    final rawUrl = json['sgpBaseUrl'] as String?;
    final finalUrl =
        (rawUrl != null && rawUrl.isNotEmpty) ? rawUrl : fallbackUrl;

    return SgpIntegration(
      apiToken: (json['apiToken'] as String? ?? '').isNotEmpty
          ? json['apiToken']
          : '4b6aae35-219a-4580-8c5c-dfb4efdbfae3', // Hardcoded fallback
      appName: (json['appName'] as String? ?? '').isNotEmpty
          ? json['appName']
          : 'APP-PROVEDOR', // Hardcoded fallback
      sgpBaseUrl: finalUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {'apiToken': apiToken, 'appName': appName, 'sgpBaseUrl': sgpBaseUrl};
  }
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
