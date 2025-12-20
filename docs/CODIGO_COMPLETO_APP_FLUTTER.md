# 📱 App Flutter Unificado - Código Completo

> **Gerado em:** 2025-12-19 20:39:10  
> **Total de arquivos:** 87  
> **Localização:** `/app-flutter/unified/lib/`

---

## 📂 Índice

1. [Core - Estrutura Central](#core---estrutura-central)
   - Models
   - Providers
   - Services
   - Widgets
   - Pages
2. [Layouts - Temas Visuais](#layouts---temas-visuais)
   - Layout 01 - Clássico (Roxo)
   - Layout 02 - Minimalista
   - Layout 03 - Neo Digital (Neumorphic)
   - Layout 04 - Premium Dark
   - Layout 05 - Organic
   - Layout 06 - Cyberpunk Neon

---

# 🔧 CORE - ESTRUTURA CENTRAL

> Arquivos compartilhados entre todos os layouts. Contém a lógica de negócio,
> gerenciamento de estado, serviços e widgets reutilizáveis.


## 📦 Core / Models
> Classes de dados e modelos de estado


---

### `lib/core/models/diagnostico_state.dart`
> Modelo de dados

```dart
import 'package:fl_chart/fl_chart.dart';

enum TestStatus { pending, running, success, error }

class DiagnosticoState {
  final bool isTesting;
  final String geralStatusMessage;
  final Map<String, Map<String, dynamic>> testResultsDisplay;
  final double? speedTestPingLatency;

  // Dados para o gráfico e resultados de velocidade
  final double customDownloadResultMbps;
  final double customUploadResultMbps;
  final double fastDownloadResultMbps;
  final double fastUploadResultMbps;
  final List<FlSpot> downloadHistory;
  final List<FlSpot> uploadHistory;
  final List<FlSpot> fastDownloadHistory;
  final List<FlSpot> fastUploadHistory;

  DiagnosticoState({
    required this.isTesting,
    required this.geralStatusMessage,
    required this.testResultsDisplay,
    this.speedTestPingLatency,
    this.customDownloadResultMbps = 0,
    this.customUploadResultMbps = 0,
    this.fastDownloadResultMbps = 0,
    this.fastUploadResultMbps = 0,
    this.downloadHistory = const [],
    this.uploadHistory = const [],
    this.fastDownloadHistory = const [],
    this.fastUploadHistory = const [],
  });

  factory DiagnosticoState.initial() {
    return DiagnosticoState(
      isTesting: false,
      geralStatusMessage: "Pronto para iniciar o diagnóstico completo.",
      testResultsDisplay: {
        'deviceInfo': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Informações do Dispositivo'
        },
        'batteryInfo': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Bateria e Energia'
        },
        'wifiInfo': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Informações de WiFi e DNS'
        },
        'lanScan': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Dispositivos na Rede (LAN)'
        },
        'publicIp': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'IP Público'
        },
        'pingGateway': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Ping para o Roteador'
        },
        'pingGoogle': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Ping para Google DNS'
        },
        'pingCloudflare': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Ping para Cloudflare DNS'
        },
        'speedTestCustom': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Teste de Velocidade (Servidor do Provedor)'
        },
        'speedTestFast': {
          'status': TestStatus.pending,
          'result': null,
          'label': 'Teste de Velocidade (Referência Fast.com)'
        },
      },
    );
  }

  DiagnosticoState copyWith({
    bool? isTesting,
    String? geralStatusMessage,
    Map<String, Map<String, dynamic>>? testResultsDisplay,
    double? speedTestPingLatency,
    double? customDownloadResultMbps,
    double? customUploadResultMbps,
    double? fastDownloadResultMbps,
    double? fastUploadResultMbps,
    List<FlSpot>? downloadHistory,
    List<FlSpot>? uploadHistory,
    List<FlSpot>? fastDownloadHistory,
    List<FlSpot>? fastUploadHistory,
  }) {
    return DiagnosticoState(
      isTesting: isTesting ?? this.isTesting,
      geralStatusMessage: geralStatusMessage ?? this.geralStatusMessage,
      testResultsDisplay: testResultsDisplay ?? this.testResultsDisplay,
      speedTestPingLatency: speedTestPingLatency ?? this.speedTestPingLatency,
      customDownloadResultMbps:
          customDownloadResultMbps ?? this.customDownloadResultMbps,
      customUploadResultMbps:
          customUploadResultMbps ?? this.customUploadResultMbps,
      fastDownloadResultMbps:
          fastDownloadResultMbps ?? this.fastDownloadResultMbps,
      fastUploadResultMbps: fastUploadResultMbps ?? this.fastUploadResultMbps,
      downloadHistory: downloadHistory ?? this.downloadHistory,
      uploadHistory: uploadHistory ?? this.uploadHistory,
      fastDownloadHistory: fastDownloadHistory ?? this.fastDownloadHistory,
      fastUploadHistory: fastUploadHistory ?? this.fastUploadHistory,
    );
  }
}
```

---

### `lib/core/models/fatura.dart`
> Modelo de dados

```dart
// ARQUIVO: lib/core/models/fatura.dart
// DESCRIÇÃO: Modelo de dados para uma única fatura com campos de pagamento.

class Fatura {
  final String numero;
  final double valor;
  final DateTime vencimento;
  final String status; // Ex: 'pago', 'pendente', 'vencido'
  final String? urlBoleto;
  final String? linhaDigitavel;
  final String? pixCopiaECola;
  final DateTime? dataPagamento;

  Fatura({
    required this.numero,
    required this.valor,
    required this.vencimento,
    required this.status,
    this.urlBoleto,
    this.linhaDigitavel,
    this.pixCopiaECola,
    this.dataPagamento,
  });

  /// Verifica se a fatura está paga
  bool get isPago => status.toLowerCase() == 'pago';

  /// Verifica se a fatura está vencida
  bool get isVencido {
    if (isPago) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(vencimento.year, vencimento.month, vencimento.day);
    return today.isAfter(dueDate);
  }

  /// Factory constructor para criar uma Fatura a partir de um JSON
  factory Fatura.fromJson(Map<String, dynamic> json) {
    final valorString =
        (json['valor'] ?? '0.0').toString().replaceAll(',', '.');

    DateTime? parseDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) return null;
      try {
        // Tenta formatos diferentes: yyyy-MM-dd e dd/MM/yyyy
        if (dateString.contains('-')) {
          return DateTime.parse(dateString);
        } else if (dateString.contains('/')) {
          final parts = dateString.split('/');
          return DateTime(
              int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (e) {
        return null;
      }
      return null;
    }

    return Fatura(
      numero:
          json['id']?.toString() ?? json['nossoNumero']?.toString() ?? 'N/A',
      valor: double.tryParse(valorString) ?? 0.0,
      vencimento: parseDate(json['vencimento'] ?? json['dataVencimento']) ??
          DateTime.now(),
      status: json['status'] != null
          ? json['status'].toString()
          : ((json['pago'] as bool? ?? false) ? 'pago' : 'pendente'),
      urlBoleto: json['link'] as String?,
      linhaDigitavel: json['linha_digitavel'] as String?,
      pixCopiaECola: json['pix_copia_cola'] as String?,
      dataPagamento: parseDate(json['dataPagamento']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numero': numero,
      'valor': valor,
      'vencimento': vencimento.toIso8601String(),
      'status': status,
      'urlBoleto': urlBoleto,
      'linhaDigitavel': linhaDigitavel,
      'pixCopiaECola': pixCopiaECola,
      'dataPagamento': dataPagamento?.toIso8601String(),
    };
  }
}
```

---

### `lib/core/models/in_app_notification.dart`
> Modelo de dados

```dart
/// Enum para tipos de notificação
enum NotificationType {
  info,
  warning,
  error,
  success,
  promotion,
}

/// Modelo para notificações in-app
class InAppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool read;
  final String? actionUrl;

  const InAppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.expiresAt,
    this.read = false,
    this.actionUrl,
  });

  /// Verifica se a notificação expirou
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Retorna uma cópia com os campos alterados
  InAppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? read,
    String? actionUrl,
  }) {
    return InAppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      read: read ?? this.read,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    return InAppNotification(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.info,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      read: json['read'] as bool? ?? false,
      actionUrl: json['actionUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'read': read,
      'actionUrl': actionUrl,
    };
  }
}
```

---

### `lib/core/models/provider_config.dart`
> Modelo de dados

```dart
import 'package:flutter/foundation.dart';

// --- MODELOS PRINCIPAIS ---

@immutable
class ProviderConfig {
  final String id;
  final String name;
  final String apiUrl;
  final String
      layoutType; // NOVO: Tipo de layout (layout_02, layout_03, layout_06, layout_07)
  final ConfigSection config;
  final FeaturesSection features;
  final MenuConfig menuConfig;
  final Map<String, dynamic>? theme;

  const ProviderConfig({
    required this.id,
    required this.name,
    required this.apiUrl,
    this.layoutType = 'layout_06', // Padrão: Layout 06 (Premium Dark)
    required this.config,
    required this.features,
    required this.menuConfig,
    this.theme,
  });

  factory ProviderConfig.fromJson(
      Map<String, dynamic> json, String providerId) {
    final legacyConfig = json['config'] as Map<String, dynamic>? ?? {};

    // Combina configurações da raiz com as antigas
    final Map<String, dynamic> combinedConfig = {
      ...legacyConfig,
      ...json,
    };

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

    // CORREÇÃO: Substitui IP antigo pelo novo automaticamente
    if (finalApiUrl != null && finalApiUrl.contains('45.176.56.70')) {
      finalApiUrl = finalApiUrl.replaceAll('45.176.56.70', '168.194.13.18');
    }

    // Se não tiver URL, usamos o IP do servidor principal
    // IMPORTANTE: trim() para remover espaços que podem quebrar a URL
    final effectiveApiUrl = (finalApiUrl ?? 'http://168.194.13.18:3000').trim();

    final integrationsMap = (json['integrations'] ??
            legacyConfig['integrations']) as Map<String, dynamic>? ??
        {};
    final providerName = json['name'] as String? ??
        integrationsMap['appName'] as String? ??
        'Provedor';

    // [NEW] Extrai systemUrl de details para fallback
    final detailsMap = json['details'] as Map<String, dynamic>? ?? {};
    final fallbackSgpUrl = detailsMap['systemUrl'] as String? ?? '';

    // NOVO: Extrai layoutType do JSON ou usa padrão 'layout_06'
    final layoutType = json['layoutType'] as String? ?? 'layout_06';

    return ProviderConfig(
      id: providerId,
      name: providerName,
      apiUrl: effectiveApiUrl,
      layoutType: layoutType,
      config: ConfigSection.fromJson(combinedConfig, fallbackSgpUrl),
      features: FeaturesSection.fromJson(
          json['features'] as Map<String, dynamic>? ?? {}),
      menuConfig: MenuConfig.fromJson(
          json['menuConfig'] as Map<String, dynamic>? ?? {}),
      theme: json['theme'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'apiUrl': apiUrl,
      'layoutType': layoutType,
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

  factory ConfigSection.fromJson(Map<String, dynamic> json,
      [String fallbackSgpUrl = '']) {
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
      logoUrl: json['logoUrl'] as String? ?? '',
      loginQuote: json['loginQuote'] as String? ?? 'Acesse sua conta.',
      integrations: SgpIntegration.fromJson(
          json['integrations'] as Map<String, dynamic>? ?? {}, fallbackSgpUrl),
      faq: faqList
          .map((item) => FaqItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      tips: tipsList
          .map((item) => TipItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      supportContacts: contactsList
          .map((item) =>
              SupportContactItem.fromJson(item as Map<String, dynamic>))
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

  const OtherSettings({
    this.useBackgroundImage = false,
    this.speedTestUrl,
  });

  factory OtherSettings.fromJson(Map<String, dynamic> json) {
    return OtherSettings(
      useBackgroundImage: json['useBackgroundImage'] as bool? ?? false,
      speedTestUrl: json['speedTestUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'useBackgroundImage': useBackgroundImage,
      'speedTestUrl': speedTestUrl,
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
      items: itemsMap.map((key, value) => MapEntry(
          key, MenuItemDetails.fromJson(value as Map<String, dynamic>))),
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

  factory SgpIntegration.fromJson(Map<String, dynamic> json,
      [String fallbackUrl = '']) {
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
    return {
      'apiToken': apiToken,
      'appName': appName,
      'sgpBaseUrl': sgpBaseUrl,
    };
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
    return {
      'question': question,
      'answer': answer,
    };
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
    return {
      'title': title,
      'description': description,
    };
  }
}

@immutable
class SupportContactItem {
  final String name;
  final String type;
  final String value;

  const SupportContactItem(
      {required this.name, required this.type, required this.value});

  factory SupportContactItem.fromJson(Map<String, dynamic> json) {
    return SupportContactItem(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'phone',
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'value': value,
    };
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
```

---

### `lib/core/models/theme_config.dart`
> Modelo de dados

```dart
import 'package:flutter/material.dart';

class ThemeConfig {
  final ThemeColors colors;
  final ThemeTypography typography;
  final ThemeSpacing spacing;
  final ThemeBorderRadius borderRadius;
  final ThemeEffects effects;
  final DarkModeConfig darkMode;

  const ThemeConfig({
    required this.colors,
    required this.typography,
    required this.spacing,
    required this.borderRadius,
    required this.effects,
    required this.darkMode,
  });

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      colors: ThemeColors.fromJson(json['colors'] ?? {}),
      typography: ThemeTypography.fromJson(json['typography'] ?? {}),
      spacing: ThemeSpacing.fromJson(json['spacing'] ?? {}),
      borderRadius: ThemeBorderRadius.fromJson(json['borderRadius'] ?? {}),
      effects: ThemeEffects.fromJson(json['effects'] ?? {}),
      darkMode: DarkModeConfig.fromJson(json['darkMode'] ?? {}),
    );
  }

  static ThemeConfig get defaultTheme => const ThemeConfig(
        colors: ThemeColors.defaultColors,
        typography: ThemeTypography.defaultTypography,
        spacing: ThemeSpacing.defaultSpacing,
        borderRadius: ThemeBorderRadius.defaultBorderRadius,
        effects: ThemeEffects.defaultEffects,
        darkMode: DarkModeConfig.defaultDarkMode,
      );
}

class ThemeColors {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color error;
  final Color success;
  final Color warning;
  final Color info;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  const ThemeColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.error,
    required this.success,
    required this.warning,
    required this.info,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
  });

  factory ThemeColors.fromJson(Map<String, dynamic> json) {
    return ThemeColors(
      primary: _parseColor(json['primary'], const Color(0xFF673AB7)),
      secondary: _parseColor(json['secondary'], const Color(0xFF9575CD)),
      background: _parseColor(json['background'], const Color(0xFF0F172A)),
      surface: _parseColor(json['surface'], const Color(0xFF1E293B)),
      error: _parseColor(json['error'], const Color(0xFFEF4444)),
      success: _parseColor(json['success'], const Color(0xFF10B981)),
      warning: _parseColor(json['warning'], const Color(0xFFF59E0B)),
      info: _parseColor(json['info'], const Color(0xFF3B82F6)),
      textPrimary: _parseColor(json['textPrimary'], Colors.white),
      textSecondary:
          _parseColor(json['textSecondary'], const Color(0xFF94A3B8)),
      textHint: _parseColor(json['textHint'], const Color(0xFF64748B)),
    );
  }

  static Color _parseColor(dynamic value, Color fallback) {
    if (value == null) return fallback;
    if (value is String && value.startsWith('#')) {
      try {
        return Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
      } catch (_) {
        return fallback;
      }
    }
    return fallback;
  }

  static const ThemeColors defaultColors = ThemeColors(
    primary: Color(0xFF673AB7),
    secondary: Color(0xFF9575CD),
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    error: Color(0xFFEF4444),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF3B82F6),
    textPrimary: Colors.white,
    textSecondary: Color(0xFF94A3B8),
    textHint: Color(0xFF64748B),
  );
}

class ThemeTypography {
  final String fontFamily;
  final Map<String, double> fontSizes;

  const ThemeTypography({required this.fontFamily, required this.fontSizes});

  factory ThemeTypography.fromJson(Map<String, dynamic> json) {
    final sizes = json['fontSizes'] as Map<String, dynamic>? ?? {};
    return ThemeTypography(
      fontFamily: json['fontFamily'] ?? 'Inter',
      fontSizes: {
        'h1': (sizes['h1'] ?? 32).toDouble(),
        'h2': (sizes['h2'] ?? 24).toDouble(),
        'h3': (sizes['h3'] ?? 20).toDouble(),
        'body': (sizes['body'] ?? 14).toDouble(),
        'caption': (sizes['caption'] ?? 12).toDouble(),
      },
    );
  }

  static const ThemeTypography defaultTypography = ThemeTypography(
    fontFamily: 'Inter',
    fontSizes: {'h1': 32, 'h2': 24, 'h3': 20, 'body': 14, 'caption': 12},
  );
}

class ThemeSpacing {
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  const ThemeSpacing(
      {required this.xs,
      required this.sm,
      required this.md,
      required this.lg,
      required this.xl});

  factory ThemeSpacing.fromJson(Map<String, dynamic> json) {
    return ThemeSpacing(
      xs: (json['xs'] ?? 4).toDouble(),
      sm: (json['sm'] ?? 8).toDouble(),
      md: (json['md'] ?? 16).toDouble(),
      lg: (json['lg'] ?? 24).toDouble(),
      xl: (json['xl'] ?? 32).toDouble(),
    );
  }

  static const ThemeSpacing defaultSpacing =
      ThemeSpacing(xs: 4, sm: 8, md: 16, lg: 24, xl: 32);
}

class ThemeBorderRadius {
  final double sm;
  final double md;
  final double lg;
  final double xl;

  const ThemeBorderRadius(
      {required this.sm, required this.md, required this.lg, required this.xl});

  factory ThemeBorderRadius.fromJson(Map<String, dynamic> json) {
    return ThemeBorderRadius(
      sm: (json['sm'] ?? 4).toDouble(),
      md: (json['md'] ?? 8).toDouble(),
      lg: (json['lg'] ?? 16).toDouble(),
      xl: (json['xl'] ?? 24).toDouble(),
    );
  }

  static const ThemeBorderRadius defaultBorderRadius =
      ThemeBorderRadius(sm: 4, md: 8, lg: 16, xl: 24);
}

class ThemeEffects {
  final bool enableGlassmorphism;
  final bool enableGradients;
  final bool enableAnimations;
  final double glassOpacity;
  final double glassBlur;
  final Color? iconColor; // [NEW]

  const ThemeEffects({
    required this.enableGlassmorphism,
    required this.enableGradients,
    required this.enableAnimations,
    required this.glassOpacity,
    required this.glassBlur,
    this.iconColor, // [NEW]
  });

  factory ThemeEffects.fromJson(Map<String, dynamic> json) {
    return ThemeEffects(
      enableGlassmorphism: json['enableGlassmorphism'] ?? true,
      enableGradients: json['enableGradients'] ?? true,
      enableAnimations: json['enableAnimations'] ?? true,
      glassOpacity: (json['glassOpacity'] ?? 0.7).toDouble(),
      glassBlur: (json['glassBlur'] ?? 12).toDouble(),
      iconColor: json['iconColor'] != null
          ? ThemeColors._parseColor(json['iconColor'], Colors.black)
          : null, // [NEW]
    );
  }

  static const ThemeEffects defaultEffects = ThemeEffects(
    enableGlassmorphism: true,
    enableGradients: true,
    enableAnimations: true,
    glassOpacity: 0.7,
    glassBlur: 12,
    iconColor: null,
  );
}

class DarkModeConfig {
  final bool enabled;
  final String defaultMode;

  const DarkModeConfig({required this.enabled, required this.defaultMode});

  factory DarkModeConfig.fromJson(Map<String, dynamic> json) {
    return DarkModeConfig(
      enabled: json['enabled'] ?? true,
      defaultMode: json['defaultMode'] ?? 'auto',
    );
  }

  static const DarkModeConfig defaultDarkMode =
      DarkModeConfig(enabled: true, defaultMode: 'auto');
}
```

---

### `lib/core/models/usuario.dart`
> Modelo de dados

```dart
class Usuario {
  final String nome;
  final String cpfCnpj;
  final String senha;
  final String plano;
  final String status;
  final String valorFatura;
  final String vencimentoFatura;
  final String? email;
  final int? contratoId;

  Usuario({
    required this.nome,
    required this.cpfCnpj,
    required this.senha,
    required this.plano,
    required this.status,
    required this.valorFatura,
    required this.vencimentoFatura,
    this.email,
    this.contratoId,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      nome: json['nome'] as String,
      cpfCnpj: json['cpfCnpj'] as String,
      senha: json['senha'] as String,
      plano: json['plano'] as String,
      status: json['status'] as String,
      valorFatura: json['valorFatura'] as String,
      vencimentoFatura: json['vencimentoFatura'] as String,
      email: json['email'] as String?,
      contratoId: json['contratoId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'cpfCnpj': cpfCnpj,
      'senha': senha,
      'plano': plano,
      'status': status,
      'valorFatura': valorFatura,
      'vencimentoFatura': vencimentoFatura,
      'email': email,
      'contratoId': contratoId,
    };
  }
}
```


## 🔔 Core / Notifiers
> Notificadores de estado


---

### `lib/core/notifiers/auth_notifier.dart`
> Notifier de autenticação

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../models/provider_config.dart';
import '../repositories/auth_repository.dart';
import '../providers/providers.dart';

class AuthNotifier extends AsyncNotifier<Usuario?> {
  late final AuthRepository _repository;

  @override
  FutureOr<Usuario?> build() async {
    _repository = ref.read(authRepositoryProvider);
    return _loadUser();
  }

  Future<Usuario?> _loadUser() async {
    return await _repository.loadUserFromStorage();
  }

  Future<void> login(String cpf, ProviderConfig config) async {
    state = const AsyncValue.loading();
    try {
      // 1. Authenticate with API
      final user = await _repository.performLoginApi(cpf, config);

      // 2. Save locally
      await _repository.saveUserLocally(user);

      // 3. Update state
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    final currentUser = state.value;
    state = const AsyncValue.loading();
    try {
      await _repository.logout(currentUser);
      state = const AsyncValue.data(null);
    } catch (e) {
      // Even if API logout fails, we clear state to ensure user can "exit"
      state = const AsyncValue.data(null);
    }
  }

  /// Refreshes user data from API silently
  Future<void> refreshUserData(ProviderConfig config) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    try {
      // Re-authenticate to get fresh data (balance, status, etc)
      // Note: We use the stored CPF. Ideally we should have a 'refresh' endpoint,
      // but 'performLoginApi' works as a fetch-latest-data call.

      // We don't set state to loading to avoid flickering UI,
      // just update when data arrives.
      final updatedUser =
          await _repository.performLoginApi(currentUser.cpfCnpj, config);

      // Preserve some local-only fields if any (auth tokens are handled inside repository)

      await _repository.saveUserLocally(updatedUser);
      state = AsyncValue.data(updatedUser);
    } catch (e) {
      debugPrint('Erro ao atualizar dados do usuário em background: $e');
      // Do not change state to error, keep showing cached data
    }
  }

  // Biometry helpers exposed via repository but manageable here if needed
  Future<Map<String, String>?> getBiometrics() =>
      _repository.getCredentialsForBiometry();

  Future<void> clearBiometrics() => _repository.clearBiometryCredentials();

  bool get isAuthenticated => state.value != null;
}
```

## 📚 Core / Repositories
> Camada de acesso a dados


---

### `lib/core/repositories/auth_repository.dart`
> Repository de autenticação

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/usuario.dart';
import '../models/provider_config.dart';

class AuthRepository {
  final _secureStorage = const FlutterSecureStorage();

  // Keys
  static const _bioCpfKey = 'bio_cpf';
  static const _bioPassKey = 'bio_pass';

  Future<Usuario?> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final senha = await _secureStorage.read(key: 'userSenha');

    if (prefs.containsKey('userCpfCnpj') && senha != null) {
      return Usuario(
        cpfCnpj: prefs.getString('userCpfCnpj')!,
        senha: senha,
        nome: prefs.getString('userName')!,
        plano: prefs.getString('userPlan')!,
        status: prefs.getString('userStatus')!,
        valorFatura: prefs.getString('billValue')!,
        vencimentoFatura: prefs.getString('billDueDate')!,
        contratoId: prefs.getInt('userContratoId'),
      );
    }
    return null;
  }

  Future<Usuario> performLoginApi(String cpf, ProviderConfig config) async {
    final apiUrl = config.apiUrl;
    final sgpParams = {
      "token": config.config.integrations.apiToken,
      "app": config.config.integrations.appName,
      "sgpBaseUrl": config.config.integrations.sgpBaseUrl
    };

    final requestBody = {
      'cpf': cpf,
      'sgpParams': sgpParams,
      'sgpBaseUrl': config.config.integrations.sgpBaseUrl,
    };

    final url = '$apiUrl/check-cpf';
    debugPrint('DEBUG: Enviando login para $url');

    final response = await http
        .post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(requestBody),
    )
        .timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Timeout: Servidor demorou para responder');
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Return User object directly from API data
      // Note: We still need to call 'saveUserLocally' effectively,
      // but the repository separation suggests 'performLoginApi' just gets data,
      // and 'saveUserLocally' persists it. However, to keep it simple and aligned
      // with previous logic, we can have a method that does both or separates them.
      // Let's create a User object here.

      return Usuario(
        cpfCnpj: cpf.replaceAll(RegExp(r'[^0-9]'), ''),
        senha: data['senha']?.toString() ?? '',
        nome: (data['nome']?.toString() ?? 'Cliente').split(' ').first,
        plano: data['plano']?.toString() ?? 'Plano Básico',
        status: data['status']?.toString() ?? 'Ativo',
        valorFatura: data['valorFatura']?.toString() ?? '0,00',
        vencimentoFatura: data['vencimentoFatura']?.toString() ?? '',
        contratoId: data['contratoId'] is int
            ? data['contratoId']
            : int.tryParse(data['contratoId']?.toString() ?? ''),
      );
    } else {
      throw Exception(
          'Falha no login: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> saveUserLocally(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();

    await _secureStorage.write(key: 'userSenha', value: usuario.senha);

    await prefs.setString('userCpfCnpj', usuario.cpfCnpj);
    await prefs.setString('userName', usuario.nome);
    await prefs.setString('userPlan', usuario.plano);
    await prefs.setString('userStatus', usuario.status);
    await prefs.setString('billValue', usuario.valorFatura);
    await prefs.setString('billDueDate', usuario.vencimentoFatura);

    if (usuario.contratoId != null) {
      await prefs.setInt('userContratoId', usuario.contratoId!);
    }

    // Biometry persistence
    await saveCredentialsForBiometry(usuario.cpfCnpj, usuario.senha);
    await _saveDeviceToken(usuario.cpfCnpj);
  }

  Future<void> logout(Usuario? currentUser) async {
    try {
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('clientes')
            .doc(currentUser.cpfCnpj)
            .update({
          'fcmToken': FieldValue.delete(),
        });
      }
    } catch (e) {
      debugPrint('ℹ️  Aviso: Falha ao limpar o token FCM durante o logout: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _secureStorage.delete(key: 'userSenha');
  }

  Future<void> _saveDeviceToken(String cpfCnpj) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('clientes')
            .doc(cpfCnpj)
            .set(
          {
            'fcmToken': token,
            'providerId':
                'vibe', // This might need to be dynamic? using 'vibe' as per legacy code
            'lastUpdated': FieldValue.serverTimestamp()
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar o token FCM: $e');
    }
  }

  // --- BIOMETRIA ---

  Future<void> saveCredentialsForBiometry(String cpf, String password) async {
    await _secureStorage.write(key: _bioCpfKey, value: cpf);
    await _secureStorage.write(key: _bioPassKey, value: password);
  }

  Future<Map<String, String>?> getCredentialsForBiometry() async {
    final cpf = await _secureStorage.read(key: _bioCpfKey);
    final pass = await _secureStorage.read(key: _bioPassKey);
    if (cpf != null && pass != null) {
      return {'cpf': cpf, 'password': pass};
    }
    return null;
  }

  Future<void> clearBiometryCredentials() async {
    await _secureStorage.delete(key: _bioCpfKey);
    await _secureStorage.delete(key: _bioPassKey);
  }
}
```
## 🔄 Core / Providers
> Gerenciamento de estado com Riverpod


---

### `lib/core/providers/configuration_provider.dart`
> Provider Riverpod

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/provider_config.dart';

class ConfigurationProvider with ChangeNotifier {
  ProviderConfig? _providerConfig;
  bool _isLoading = true;
  String? _errorMessage;

  ProviderConfig? get providerConfig => _providerConfig;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Retorna uma string dinâmica da configuração ou o valor padrão
  String getString(String key, String defaultValue) {
    if (_providerConfig == null) return defaultValue;
    final val = _providerConfig!.config.strings[key];
    if (val is String && val.isNotEmpty) return val;
    return defaultValue;
  }

  /// Retorna uma lista de strings dinâmica ou o valor padrão
  List<String> getStringList(String key, List<String> defaultValue) {
    if (_providerConfig == null) return defaultValue;
    final val = _providerConfig!.config.strings[key];
    if (val is List) return List<String>.from(val);
    return defaultValue;
  }

  /// Método para carregar a configuração de forma assíncrona.
  Future<void> loadConfig(String providerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 1. Tenta carregar do cache local primeiro
    await _loadFromCache(providerId);

    try {
      // 2. Busca do servidor em segundo plano
      final doc = await FirebaseFirestore.instance
          .collection('provedores')
          .doc(providerId)
          .get(const GetOptions(source: Source.server));

      if (doc.exists && doc.data() != null) {
        final rawData = doc.data()!;
        final safeData = Map<String, dynamic>.from(rawData);

        _providerConfig = ProviderConfig.fromJson(safeData, providerId);

        // DEBUG: Print layoutType and colors being loaded
        debugPrint(
            "🎨 [DEBUG] layoutType from Firestore: ${_providerConfig?.layoutType}");
        debugPrint(
            "🎨 [DEBUG] Raw layoutType in JSON: ${safeData['layoutType']}");
        debugPrint("🎨 [DEBUG] themeColor: ${safeData['themeColor']}");
        debugPrint("🎨 [DEBUG] secondaryColor: ${safeData['secondaryColor']}");
        debugPrint(
            "🎨 [DEBUG] config.themeColor: ${_providerConfig?.config.themeColor}");
        debugPrint(
            "🎨 [DEBUG] config.secondaryColor: ${_providerConfig?.config.secondaryColor}");

        // 3. Atualiza o cache
        await _saveToCache(providerId, safeData);
        debugPrint("✅ Configuração '$providerId' atualizada do servidor.");
      } else {
        if (_providerConfig == null) {
          _errorMessage = "Provedor com ID '$providerId' não encontrado.";
        }
        debugPrint("❌ ERRO: Provedor não encontrado no servidor.");
      }
    } catch (e) {
      if (_providerConfig == null) {
        _errorMessage = "Erro de conexão e sem cache local: $e";
      }
      debugPrint(
          "⚠️ Aviso: Usando versão em cache devido a erro de conexão: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromCache(String providerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('provider_config_$providerId');
      if (cachedString != null) {
        final Map<String, dynamic> data = json.decode(cachedString);
        _providerConfig = ProviderConfig.fromJson(data, providerId);
        _isLoading = false; // Já temos dados para mostrar!
        notifyListeners();
        debugPrint("📦 Configuração carregada do cache local.");
      }
    } catch (e) {
      debugPrint("Erro ao ler cache: $e");
    }
  }

  Future<void> _saveToCache(
      String providerId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final safeData = _sanitizeForJson(data);
      await prefs.setString(
          'provider_config_$providerId', json.encode(safeData));
    } catch (e) {
      debugPrint("Erro ao salvar cache: $e");
    }
  }

  /// Converte Firestore Timestamps e outros objetos não-serializáveis para tipos JSON
  dynamic _sanitizeForJson(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }

    if (value is DateTime) {
      return value.toIso8601String();
    }

    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _sanitizeForJson(v)));
    }

    if (value is List) {
      return value.map((v) => _sanitizeForJson(v)).toList();
    }

    // Valores primitivos (String, int, double, bool) passam direto
    return value;
  }
}
```

---

### `lib/core/providers/connectivity_provider.dart`
> Provider Riverpod

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the current connectivity status stream
final connectivityStatusProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Easy check if online
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityStatusProvider);

  return connectivityAsync.when(
    data: (result) {
      if (result == ConnectivityResult.none) return false;
      return true; // WiFi, Mobile, Ethernet, VPN, etc -> Online
    },
    error: (_, __) => true, // Assume online on error to avoid blocking
    loading: () => true, // Assume online while loading
  );
});
```

---

### `lib/core/providers/consumo_provider.dart`
> Provider Riverpod

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/consumo_service.dart';
import 'providers.dart';

class ConsumoState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? data;
  final int selectedMonth;
  final int selectedYear;

  ConsumoState({
    this.isLoading = false,
    this.error,
    this.data,
    required this.selectedMonth,
    required this.selectedYear,
  });

  ConsumoState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? data,
    int? selectedMonth,
    int? selectedYear,
  }) {
    return ConsumoState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
    );
  }
}

class ConsumoViewModel extends StateNotifier<ConsumoState> {
  final ConsumoService? _service;

  ConsumoViewModel(this._service)
      : super(ConsumoState(
          selectedMonth: DateTime.now().month,
          selectedYear: DateTime.now().year,
        )) {
    loadData();
  }

  Future<void> loadData() async {
    if (_service == null) {
      state = state.copyWith(error: 'Serviço não inicializado');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _service.fetchConsumptionData(
        month: state.selectedMonth,
        year: state.selectedYear,
      );
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void changeMonth(int month, int year) {
    if (state.selectedMonth == month && state.selectedYear == year) return;

    state = state.copyWith(selectedMonth: month, selectedYear: year);
    loadData();
  }
}

/// Provider que fornece o ViewModel de Consumo
final consumoViewModelProvider =
    StateNotifierProvider<ConsumoViewModel, ConsumoState>((ref) {
  final configConfig = ref.watch(configurationProvider).providerConfig?.config;
  final usuario = ref.watch(authNotifierProvider).value;

  if (configConfig == null || usuario == null) {
    return ConsumoViewModel(null);
  }

  // Create service instance
  final service = ConsumoService(
    apiUrl: 'http://168.194.13.18:3000/get-consumption-data',
    sgpParams: {
      'token': configConfig.integrations.apiToken,
      'app': configConfig.integrations.appName,
      'sgpBaseUrl': configConfig.integrations.sgpBaseUrl,
    },
    cpfCnpj: usuario.cpfCnpj,
    senha: usuario.senha,
  );

  return ConsumoViewModel(service);
});
```

---

### `lib/core/providers/financeiro_provider.dart`
> Provider Riverpod

```dart
// ARQUIVO: lib/core/providers/financeiro_provider.dart
// DESCRIÇÃO: Provider para gerenciar o estado da tela financeiro.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fatura.dart';
import '../services/financeiro_service.dart';
import '../../core/providers/providers.dart';

// --- RIVERPOD MIGRATION ---

// Provider do Serviço (depende de config e auth)
final financeiroServiceProvider =
    Provider.autoDispose<FinanceiroService?>((ref) {
  final config = ref.watch(configurationProvider).providerConfig;
  final usuario = ref.watch(authNotifierProvider).value;

  if (config == null || usuario == null) return null;

  return FinanceiroService(
    apiUrl: '${config.apiUrl}/get-invoices',
    cpfCnpjUnformatted: usuario.cpfCnpj.replaceAll(RegExp(r'[^0-9]'), ''),
    senha: usuario.senha,
    sgpParams: {
      'token': config.config.integrations.apiToken,
      'app': config.config.integrations.appName,
      'sgpBaseUrl': config.config.integrations.sgpBaseUrl,
    },
  );
});

// Provider do Estado (ViewModel)
final financeiroViewModelProvider =
    ChangeNotifierProvider.autoDispose<FinanceiroProvider>((ref) {
  final service = ref.watch(financeiroServiceProvider);
  // Se o serviço não estiver pronto (ex: sem login), retorna provider vazio ou lida com erro
  // Como estamos dentro do AuthGate, o usuário deve existir.
  if (service == null) {
    // Fallback seguro ou lance erro se preferir
    // Em dev, isso pode acontecer se hot reload perder estado de auth.
    throw Exception(
        'Serviço Financeiro não pôde ser inicializado (Login/Config ausente)');
  }

  final provider = FinanceiroProvider(service);
  // Auto-fetch ao criar
  provider.fetchHistory();
  return provider;
});

enum FinanceiroState { idle, loading, success, error }

class FinanceiroProvider with ChangeNotifier {
  final FinanceiroService _financeiroService;

  FinanceiroState _state = FinanceiroState.idle;
  List<Fatura> _invoices = [];
  Map<int, double> _monthlyTotals = {};
  String _errorMessage = '';

  FinanceiroState get state => _state;
  List<Fatura> get invoices => _invoices;
  Map<int, double> get monthlyTotals => _monthlyTotals;
  String get errorMessage => _errorMessage;

  /// Faturas pendentes (não pagas)
  List<Fatura> get pendingInvoices =>
      _invoices.where((f) => !f.isPago).toList();

  /// Faturas pagas
  List<Fatura> get paidInvoices => _invoices.where((f) => f.isPago).toList();

  FinanceiroProvider(this._financeiroService);

  /// Carrega as faturas do servidor
  Future<void> fetchHistory() async {
    _state = FinanceiroState.loading;
    notifyListeners();

    try {
      final rawInvoices = await _financeiroService.fetchInvoices();
      _invoices = rawInvoices.map((json) => Fatura.fromJson(json)).toList();

      // Ordena as faturas da mais recente para a mais antiga
      _invoices.sort((a, b) => b.vencimento.compareTo(a.vencimento));

      _calculateMonthlyTotals();

      _state = FinanceiroState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _state = FinanceiroState.error;
    } finally {
      notifyListeners();
    }
  }

  void _calculateMonthlyTotals() {
    _monthlyTotals = {};
    final now = DateTime.now();

    // Considera apenas faturas pagas nos últimos 12 meses para o gráfico
    final paidInvoices = _invoices.where((f) =>
        f.status == 'pago' &&
        f.dataPagamento != null &&
        f.dataPagamento!.isAfter(now.subtract(const Duration(days: 365))));

    for (var invoice in paidInvoices) {
      final month = invoice.dataPagamento!.month;
      _monthlyTotals.update(month, (value) => value + invoice.valor,
          ifAbsent: () => invoice.valor);
    }
  }

  /// Solicita desbloqueio de confiança
  Future<void> solicitarDesbloqueio(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitando desbloqueio... Aguarde.')),
      );

      await _financeiroService.solicitarDesbloqueioConfianca();

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("✅ Sucesso!"),
            content: const Text(
                "Desbloqueio de confiança realizado.\nSua conexão será reativada em até 5 minutos.\n\nLembre-se de pagar a fatura em até 48h para evitar novo bloqueio."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
            ],
          ),
        );
      }
      fetchHistory();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceFirst("Exception: ", "")),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}
```

---

### `lib/core/providers/providers.dart`
> Provider Riverpod

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/analytics_service.dart';
import '../services/review_service.dart';
import '../services/deep_link_service.dart';
import '../services/speed_test_history_service.dart';

import '../repositories/auth_repository.dart';
import '../notifiers/auth_notifier.dart';
import '../models/usuario.dart';
import 'configuration_provider.dart';
import 'theme_provider.dart';
import '../models/theme_config.dart';

// --- Services & Config ---

/// Gerencia a configuração remota do provedor (Firestore/Cache)
final configurationProvider =
    ChangeNotifierProvider<ConfigurationProvider>((ref) {
  return ConfigurationProvider();
});

// --- REPOSITORIES ---
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// --- NOTIFIERS (Async) ---
// Substitui AuthService e authProvider
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, Usuario?>(
  () => AuthNotifier(),
);

// --- PROVIDERS (Legacy/Adapters) ---

// Manteve-se o nome authProvider se necessário para compatibilidade,
// ou idealmente, removeremos o antigo.
// Por enquanto, comentamos o antigo AuthService.

/// Gerencia notificações in-app
final notificationProvider = ChangeNotifierProvider<NotificationService>((ref) {
  return NotificationService();
});

// --- UI & Theme ---

/// Gerencia o tema dinâmico e o modo escuro
/// Observa o configurationProvider para atualizar as cores automaticamente
final themeProvider = ChangeNotifierProvider<DynamicThemeProvider>((ref) {
  final themeNotifer = DynamicThemeProvider();

  // Escuta mudanças na configuração para atualizar o tema em tempo real
  ref.listen<ConfigurationProvider>(configurationProvider, (previous, next) {
    final providerConfig = next.providerConfig;
    if (providerConfig == null) return;

    try {
      ThemeConfig config;

      // Se temos um tema definido no formato completo, usamos ele
      // Se temos um tema definido no formato completo, usamos ele,
      // MAS precisamos garantir que as novas configs (background/icon) tenham prioridade ou sejam mescladas
      // se elas não existirem no themeMap (ou se quisermos forçar a config nova).

      final themeMap = providerConfig.theme;
      final configColors = providerConfig.config;

      if (themeMap != null && themeMap.isNotEmpty) {
        debugPrint('🎨 [DEBUG] Usando themeMap completo (com overrides)');

        // Vamos injetar os valores novos se eles não estiverem explicitamente no themeMap
        // (Ou forçar se a estratégia for "Config manda")
        // Como o Admin Novo salva na Config, vamos garantir que a Config seja respeitada para esses campos novos.

        var effectiveThemeMap = Map<String, dynamic>.from(themeMap);

        // Garante estrutura colors
        if (!effectiveThemeMap.containsKey('colors')) {
          effectiveThemeMap['colors'] = <String, dynamic>{};
        }
        var colorsMap = Map<String, dynamic>.from(effectiveThemeMap['colors']);

        // Garante estrutura effects
        if (!effectiveThemeMap.containsKey('effects')) {
          effectiveThemeMap['effects'] = <String, dynamic>{};
        }
        var effectsMap =
            Map<String, dynamic>.from(effectiveThemeMap['effects']);

        // Overrides
        if (configColors.backgroundColor != null) {
          colorsMap['background'] = configColors.backgroundColor;
        }
        if (configColors.iconColor != null) {
          effectsMap['iconColor'] = configColors.iconColor;
        }
        if (configColors.cardColor != null) {
          colorsMap['surface'] = configColors.cardColor;
        }
        if (configColors.textColor != null) {
          colorsMap['textPrimary'] = configColors.textColor;
        }
        if (configColors.textSecondaryColor != null) {
          colorsMap['textSecondary'] =
              configColors.textSecondaryColor; // [NEW] Secondary Text
        }

        effectiveThemeMap['colors'] = colorsMap;
        effectiveThemeMap['effects'] = effectsMap;

        config = ThemeConfig.fromJson(effectiveThemeMap);
      } else {
        // Caso contrário, criamos um ThemeConfig usando as cores simples
        // do ConfigSection (themeColor, secondaryColor)
        final themeColor = configColors.themeColor;
        final secondaryColor = configColors.secondaryColor ?? themeColor;
        // [NEW] Use configurable colors
        final cardColor = configColors.cardColor;
        final textColor = configColors.textColor;
        final textSecondaryColor = configColors.textSecondaryColor; // [NEW]
        final backgroundColor =
            configColors.backgroundColor; // Load background color
        final iconColor = configColors.iconColor; // [NEW]

        debugPrint(
            '🎨 [DEBUG] Criando tema com themeColor=$themeColor, secondaryColor=$secondaryColor');

        config = ThemeConfig.fromJson({
          'colors': {
            'primary': themeColor,
            'secondary': secondaryColor,
            if (cardColor != null) 'surface': cardColor,
            if (textColor != null) 'textPrimary': textColor,
            if (textSecondaryColor != null)
              'textSecondary': textSecondaryColor, // [NEW]
            // Default mappings for other colors using primary/secondary if not specified
            'error': '#EF4444',
            'success': '#10B981',
            'warning': '#F59E0B',
            'info': '#3B82F6',
            'background': backgroundColor ??
                (configColors.other?.useBackgroundImage == true
                    ? '#00000000' // If using bg image, transparent
                    : '#0F172A'),
          },
          // [NEW] Map icon color if present, otherwise default to primary
          if (iconColor != null)
            'effects': {
              'iconColor': iconColor,
            }
        });
      }

      // Evita updates desnecessários se a config for idêntica
      if (themeNotifer.config != config) {
        final layoutType = providerConfig.layoutType;
        debugPrint(
            '🎨 [DEBUG] Atualizando tema! primary=${config.colors.primary}, layout=$layoutType');
        themeNotifer.updateFromConfig(config, layoutType: layoutType);
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao atualizar tema via Provider: $e');
    }
  });

  return themeNotifer;
});

// ANALYTICS & ENGAGEMENT
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService();
});

final speedTestHistoryServiceProvider =
    ChangeNotifierProvider<SpeedTestHistoryService>((ref) {
  return SpeedTestHistoryService();
});
```

---

### `lib/core/providers/theme_provider.dart`
> Provider Riverpod

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/theme_config.dart';
import '../../layouts/layout_04/theme.dart';

class DynamicThemeProvider with ChangeNotifier {
  ThemeData _lightTheme;
  ThemeData _darkTheme;
  ThemeMode _themeMode = ThemeMode.system;
  ThemeConfig _currentConfig;

  DynamicThemeProvider()
      : _currentConfig = ThemeConfig.defaultTheme,
        _lightTheme = _buildTheme(ThemeConfig.defaultTheme, Brightness.light),
        _darkTheme = _buildTheme(ThemeConfig.defaultTheme, Brightness.dark) {
    // Force Light Mode as default initially
    _themeMode = ThemeMode.light;
  }

  ThemeData get lightTheme => _lightTheme;
  ThemeData get darkTheme => _darkTheme;
  ThemeMode get themeMode => _themeMode;
  ThemeConfig get config => _currentConfig;

  void updateFromConfig(ThemeConfig config, {String? layoutType}) {
    _currentConfig = config;

    if (layoutType == 'layout_06') {
      // Layout 06 uses its own specialized theme builder
      _lightTheme = Layout04Theme.getTheme(config);
      _darkTheme = Layout04Theme.getTheme(config);
      _themeMode = ThemeMode.dark; // Force Dark Mode
    } else {
      _lightTheme = _buildTheme(config, Brightness.light);
      _darkTheme = _buildTheme(config, Brightness.dark);
    }

    // Atualiza o modo do tema baseado na config
    if (config.darkMode.enabled) {
      switch (config.darkMode.defaultMode) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.light;
      }
    } else {
      _themeMode = ThemeMode.light;
    }

    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  static ThemeData _buildTheme(ThemeConfig config, Brightness brightness) {
    final colors = config.colors;
    final isDark = brightness == Brightness.dark;

    // Use configured colors directly if possible, falling back only if needed.
    // NOTE: In our new system, `colors.background` and `colors.surface` are already
    // populated precisely from the user's config in `providers.dart`.
    // So we should trust them unless they are defaults that we successfully identified as "should change based on mode".
    // For now, let's trust the config object as the source of truth for these custom overrides.

    final primary = colors.primary;
    final secondary = colors.secondary;

    // [FIX] Trust the config's background/surface.
    // If the user set a custom color, `colors.background` holds it.
    // If they didn't, it holds the default.
    // To distinguish "User set specific color" vs "Default", we rely on the fact
    // that `providers.dart` constructs this `ThemeConfig` dynamically.
    final background = colors.background;
    final surface = colors.surface;

    final textPrimary = colors.textPrimary; // Trust config
    final textSecondary = colors.textSecondary; // Trust config

    // Typography setup
    final textTheme =
        _buildTextTheme(config.typography, textPrimary, textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: background,

      // [NEW] Map Icon Theme
      iconTheme: IconThemeData(
        color: config.effects.iconColor ?? primary,
      ),

      // Color Scheme
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        error: colors.error,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerLowest: background,
        onSurfaceVariant: textPrimary,
      ),

      // Typography
      textTheme: textTheme,
      fontFamily: config.typography.fontFamily,

      // Card Theme
      cardTheme: CardThemeData(
        color: surface,
        elevation: config.effects.enableGlassmorphism ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(config.borderRadius.md),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius.sm),
          borderSide:
              BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius.sm),
          borderSide:
              BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius.sm),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: colors.textHint),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: config.spacing.lg,
            vertical: config.spacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.borderRadius.sm),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(
      ThemeTypography config, Color primaryColor, Color textSecondaryColor) {
    try {
      return GoogleFonts.getTextTheme(
        config.fontFamily,
        TextTheme(
          displayLarge: TextStyle(
            fontSize: config.fontSizes['h1'],
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
          headlineMedium: TextStyle(
            fontSize: config.fontSizes['h2'],
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
          titleLarge: TextStyle(
            fontSize: config.fontSizes['h3'],
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
          bodyLarge: TextStyle(
            fontSize: config.fontSizes['body'],
            color: primaryColor,
          ),
          bodyMedium: TextStyle(
            fontSize: config.fontSizes['body'],
            color: textSecondaryColor,
          ),
          labelSmall: TextStyle(
            fontSize: config.fontSizes['caption'],
            color: textSecondaryColor,
          ),
        ),
      );
    } catch (e) {
      // Fallback se a fonte não carregar ou não existir
      debugPrint('Erro ao carregar fonte ${config.fontFamily}: $e');
      return TextTheme(
        displayLarge:
            TextStyle(fontSize: config.fontSizes['h1'], color: primaryColor),
        bodyLarge:
            TextStyle(fontSize: config.fontSizes['body'], color: primaryColor),
      );
    }
  }
}
```

## ⚙️ Core / Services
> Serviços de negócio, API e utilitários


---

### `lib/core/services/analytics_service.dart`
> Serviço de negócio

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logLogin() async {
    try {
      await _analytics.logLogin(loginMethod: 'cpf');
      debugPrint('Analytics: Login Logged');
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      debugPrint('Analytics: Screen View $screenName');
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      debugPrint('Analytics: Event $name logged');
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }
}
```

---

### `lib/core/services/biometric_service.dart`
> Serviço de negócio

```dart
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _cpfKey = 'biometric_cpf';
  static const String _passwordKey = 'biometric_pass';
  static const String _enabledKey = 'biometric_enabled';

  /// Verifica se o dispositivo tem suporte a biometria
  Future<bool> get isAvailable async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Verifica se o usuário já ativou a biometria no app anteriormente
  Future<bool> get isEnabled async {
    String? enabled = await _storage.read(key: _enabledKey);
    return enabled == 'true';
  }

  /// Salva as credenciais para uso futuro
  Future<void> saveCredentials(String cpf, String password) async {
    await _storage.write(key: _cpfKey, value: cpf);
    await _storage.write(key: _passwordKey, value: password);
    await _storage.write(key: _enabledKey, value: 'true');
  }

  /// Remove as credenciais (Logout ou desativar)
  Future<void> clearCredentials() async {
    await _storage.delete(key: _cpfKey);
    await _storage.delete(key: _passwordKey);
    await _storage.write(key: _enabledKey, value: 'false');
  }

  /// Autentica o usuário e retorna as credenciais salvas (se sucesso)
  Future<Map<String, String>?> authenticate() async {
    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Autentique-se para acessar sua conta',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Permite PIN se biometria falhar
        ),
      );
    } on PlatformException catch (e) {
      debugPrint("Erro na biometria: $e");
      return null;
    }

    if (authenticated) {
      String? cpf = await _storage.read(key: _cpfKey);
      String? password = await _storage.read(key: _passwordKey);

      if (cpf != null && password != null) {
        return {'cpf': cpf, 'password': password};
      }
    }
    return null;
  }
}
```

---

### `lib/core/services/cache_service.dart`
> Serviço de negócio

```dart
/// Serviço de Cache Inteligente
/// Cache com TTL (Time To Live) e suporte offline

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de entrada de cache com metadados
class CacheEntry<T> {
  final T data;
  final DateTime createdAt;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.createdAt,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;

  Map<String, dynamic> toJson(dynamic Function(T) dataToJson) => {
        'data': dataToJson(data),
        'createdAt': createdAt.toIso8601String(),
        'ttlMs': ttl.inMilliseconds,
      };

  factory CacheEntry.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) dataFromJson,
  ) {
    return CacheEntry(
      data: dataFromJson(json['data']),
      createdAt: DateTime.parse(json['createdAt']),
      ttl: Duration(milliseconds: json['ttlMs']),
    );
  }
}

/// Serviço de Cache Principal
class CacheService {
  static CacheService? _instance;
  SharedPreferences? _prefs;

  // Cache em memória para acesso rápido
  final Map<String, CacheEntry<dynamic>> _memoryCache = {};

  // Prefixo para evitar conflitos
  static const String _prefix = 'cache_';

  // TTL padrão: 5 minutos
  static const Duration defaultTTL = Duration(minutes: 5);

  // TTL para dados que mudam pouco
  static const Duration longTTL = Duration(hours: 1);

  // TTL para dados estáticos
  static const Duration staticTTL = Duration(days: 1);

  CacheService._();

  static CacheService get instance {
    _instance ??= CacheService._();
    return _instance!;
  }

  /// Inicializa o serviço de cache
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFromDisk();
  }

  /// Carrega cache do disco para memória
  Future<void> _loadFromDisk() async {
    if (_prefs == null) return;

    final keys = _prefs!.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      try {
        final jsonString = _prefs!.getString(key);
        if (jsonString != null) {
          final json = jsonDecode(jsonString);
          final entry = CacheEntry<dynamic>.fromJson(json, (d) => d);
          if (!entry.isExpired) {
            _memoryCache[key.replaceFirst(_prefix, '')] = entry;
          } else {
            // Remove entradas expiradas
            await _prefs!.remove(key);
          }
        }
      } catch (e) {
        // Ignora entradas corrompidas
        await _prefs!.remove(key);
      }
    }
  }

  /// Salva dados no cache
  Future<void> set<T>(
    String key,
    T data, {
    Duration? ttl,
    bool persistToDisk = true,
  }) async {
    final entry = CacheEntry<T>(
      data: data,
      createdAt: DateTime.now(),
      ttl: ttl ?? defaultTTL,
    );

    _memoryCache[key] = entry;

    if (persistToDisk && _prefs != null) {
      final jsonString = jsonEncode(entry.toJson((d) => d));
      await _prefs!.setString('$_prefix$key', jsonString);
    }
  }

  /// Recupera dados do cache
  T? get<T>(String key, {bool ignoreExpiry = false}) {
    final entry = _memoryCache[key];
    if (entry == null) return null;

    if (!ignoreExpiry && entry.isExpired) {
      _memoryCache.remove(key);
      _prefs?.remove('$_prefix$key');
      return null;
    }

    return entry.data as T?;
  }

  /// Recupera ou busca dados (cache-first strategy)
  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? ttl,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = get<T>(key);
      if (cached != null) return cached;
    }

    final data = await fetcher();
    await set<T>(key, data, ttl: ttl);
    return data;
  }

  /// Remove item do cache
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _prefs?.remove('$_prefix$key');
  }

  /// Limpa todo o cache
  Future<void> clear() async {
    _memoryCache.clear();
    if (_prefs != null) {
      final keys = _prefs!.getKeys().where((k) => k.startsWith(_prefix));
      for (final key in keys) {
        await _prefs!.remove(key);
      }
    }
  }

  /// Limpa apenas itens expirados
  Future<void> clearExpired() async {
    final expiredKeys = <String>[];

    _memoryCache.forEach((key, entry) {
      if (entry.isExpired) expiredKeys.add(key);
    });

    for (final key in expiredKeys) {
      await remove(key);
    }
  }

  /// Verifica se existe no cache (e não expirou)
  bool has(String key) {
    final entry = _memoryCache[key];
    return entry != null && !entry.isExpired;
  }

  /// Retorna estatísticas do cache
  Map<String, dynamic> get stats => {
        'itemCount': _memoryCache.length,
        'validItems': _memoryCache.values.where((e) => !e.isExpired).length,
        'expiredItems': _memoryCache.values.where((e) => e.isExpired).length,
      };
}

/// Chaves de cache pré-definidas
class CacheKeys {
  static const String userData = 'user_data';
  static const String invoices = 'invoices';
  static const String connectionStatus = 'connection_status';
  static const String speedTestHistory = 'speed_test_history';
  static const String providerConfig = 'provider_config';
  static const String notifications = 'notifications';
}

/// Extension para facilitar uso com Riverpod
extension CacheServiceExtension on CacheService {
  /// Cache de lista de faturas
  Future<List<Map<String, dynamic>>> getInvoices(
    Future<List<Map<String, dynamic>>> Function() fetcher, {
    bool forceRefresh = false,
  }) async {
    return getOrFetch(
      CacheKeys.invoices,
      fetcher,
      ttl: CacheService.longTTL,
      forceRefresh: forceRefresh,
    );
  }

  /// Cache de configuração do provedor
  Future<Map<String, dynamic>> getProviderConfig(
    Future<Map<String, dynamic>> Function() fetcher, {
    bool forceRefresh = false,
  }) async {
    return getOrFetch(
      CacheKeys.providerConfig,
      fetcher,
      ttl: CacheService.staticTTL,
      forceRefresh: forceRefresh,
    );
  }
}
```

---

### `lib/core/services/consumo_service.dart`
> Serviço de negócio

```dart
// ARQUIVO: lib/core/services/consumo_service.dart
// DESCRIÇÃO: Serviço para buscar dados de consumo de internet

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ConsumoService {
  final String apiUrl;
  final Map<String, dynamic> sgpParams;
  final String cpfCnpj;
  final String senha;

  ConsumoService({
    required this.apiUrl,
    required this.sgpParams,
    required this.cpfCnpj,
    required this.senha,
  });

  /// Busca os dados de consumo na API
  /// [month] Mês (1-12)
  /// [year] Ano (ex: 2024)
  Future<Map<String, dynamic>> fetchConsumptionData(
      {int? month, int? year}) async {
    try {
      if (cpfCnpj.isEmpty || senha.isEmpty) {
        throw Exception("CPF/CNPJ ou Senha não podem ser vazios.");
      }

      final requestBody = {
        'cpfCnpj': cpfCnpj,
        'senha': senha,
        'sgpParams': sgpParams,
        'sgpBaseUrl': sgpParams['sgpBaseUrl'],
        if (month != null) 'mes': month,
        if (year != null) 'ano': year,
      };

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body)['data'];
        return responseData as Map<String, dynamic>;
      } else {
        final errorBody = json.decode(response.body)['error'];
        throw Exception(errorBody?['message'] ??
            'Falha ao carregar dados de consumo. Código: ${response.statusCode}');
      }
    } on TimeoutException {
      throw TimeoutException(
          'O servidor demorou muito para responder. Verifique sua conexão.');
    } catch (e) {
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }
}
```

---

### `lib/core/services/deep_link_service.dart`
> Serviço de negócio

```dart
import 'package:app_links/app_links.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../main.dart'; // for navigatorKey

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();

  Future<void> init() async {
    try {
      // Check initial link
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }

      // Listen for stream
      _appLinks.uriLinkStream.listen((uri) {
        _handleDeepLink(uri);
      }, onError: (err) {
        debugPrint('DeepLink Error: $err');
      });
    } catch (e) {
      debugPrint('DeepLink Init Error: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('🔗 Deep Link Received: $uri');

    // Scheme: provedorapp://host/path
    // Example: provedorapp://faturas
    // Example: provedorapp://suporte

    // We can use the navigatorKey to show a SnackBar or Navigate
    final context = navigatorKey.currentState?.context;
    if (context == null) return;

    if (uri.scheme == 'provedorapp') {
      String? destination;
      if (uri.host == 'faturas') destination = 'Faturas';
      if (uri.host == 'suporte') destination = 'Suporte';
      if (uri.host == 'speedtest') destination = 'Speed Test';

      if (destination != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Abrindo $destination via Link...'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.blueAccent,
          ),
        );
        // Real navigation would require accessing the PainelPage state or provider
        // For now, this proves the link works.
      }
    }
  }
}
```

---

### `lib/core/services/diagnostico_service.dart`
> Serviço de negócio

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/diagnostico_state.dart';
import '../models/provider_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:lan_scanner/lan_scanner.dart';

class PingParams {
  final String host;
  final int count;
  final bool discardFirst;
  PingParams(
      {required this.host, required this.count, this.discardFirst = false});
}

Future<String> _pingTestRunner(PingParams params) async {
  final completer = Completer<String>();
  final latencies = <int>[];
  int packetsReceived = 0;
  StreamSubscription<PingData>? subscription;

  // Se discardFirst for true, pedimos 1 pacote extra para compensar
  final int totalCount = params.discardFirst ? params.count + 1 : params.count;

  final ping = Ping(params.host,
      count: totalCount, timeout: 2, interval: 1, ipv6: false);

  int currentIndex = 0;

  subscription = ping.stream.listen((PingData data) {
    if (data.response != null) {
      final isFirst = currentIndex == 0;
      currentIndex++;

      if (params.discardFirst && isFirst) {
        // Ignora o primeiro pacote (warm-up no ARP/Route table)
        return;
      }

      packetsReceived++;
      final time = data.response!.time?.inMilliseconds;
      if (time != null) {
        latencies.add(time);
      }
    }
  }, onDone: () {
    // Se discardFirst=true, packetsLost calcula baseado no params.count (pois pedimos +1 mas ignoramos 1)
    // Se recebemos totalCount, packetsReceived será totalCount - 1 (se o primeiro chegou).
    // Mas simplificando: params.count é o alvo.

    int packetsLost = params.count - packetsReceived;
    if (packetsLost < 0) packetsLost = 0; // Garantia

    double lossPercentage = (packetsLost / params.count) * 100;

    if (!completer.isCompleted) {
      if (latencies.isEmpty) {
        completer.complete('Host inacessível\nPerda: 100%');
      } else {
        int avgLatency =
            (latencies.reduce((a, b) => a + b) / latencies.length).round();
        double jitter = 0.0;
        if (latencies.length > 1) {
          int totalDiff = 0;
          for (int i = 0; i < latencies.length - 1; i++) {
            totalDiff += (latencies[i] - latencies[i + 1]).abs();
          }
          // Use (latencies.length - 1) for Jitter calculation
          jitter = totalDiff / (latencies.length - 1);
        }
        completer.complete(
            'Latência: ${avgLatency}ms\nJitter: ${jitter.toStringAsFixed(1)}ms\nPerda: ${lossPercentage.toStringAsFixed(0)}%');
      }
    }
    subscription?.cancel();
  }, onError: (e) {
    if (!completer.isCompleted) {
      completer.complete('Erro no Ping: ${e.toString()}');
    }
    subscription?.cancel();
  });

  Future.delayed(Duration(seconds: (totalCount * 2) + 5), () {
    if (!completer.isCompleted) {
      subscription?.cancel();
      completer.complete('Erro: Teste de ping expirou (Timeout)');
    }
  });

  return completer.future;
}

class DiagnosticoService {
  final ProviderConfig providerConfig;
  final BuildContext? context;
  final _streamController = StreamController<DiagnosticoState>.broadcast();
  Stream<DiagnosticoState> get stateStream => _streamController.stream;
  late DiagnosticoState _currentState;

  final NetworkInfo _networkInfo = NetworkInfo();
  bool _isWifiConnected = false;
  static const platform = MethodChannel('br.com.ajust.app_provedor/wifi_info');
  final internetSpeedTest = FlutterInternetSpeedTest();
  final Battery _battery = Battery();
  final LanScanner _lanScanner = LanScanner();
  Timer? _realtimeUpdateTimer;

  double _customPeakDownloadMbps = 0;
  double _customPeakUploadMbps = 0;
  double _fastPeakDownloadMbps = 0;
  double _fastPeakUploadMbps = 0;
  int _downloadHistoryCounter = 0;
  int _uploadHistoryCounter = 0;
  int _fastDownloadHistoryCounter = 0;
  int _fastUploadHistoryCounter = 0;

  DiagnosticoService({required this.providerConfig, this.context}) {
    _currentState = DiagnosticoState.initial();
  }

  void dispose() {
    stopAllTests();
    _streamController.close();
  }

  void _updateStatus(String message) {
    if (_streamController.isClosed || !_currentState.isTesting) return;
    _currentState = _currentState.copyWith(geralStatusMessage: message);
    _streamController.add(_currentState);
  }

  void _updateTestState(String key, TestStatus status, String? result) {
    if (_streamController.isClosed) return;
    final newResults = Map<String, Map<String, dynamic>>.from(
        _currentState.testResultsDisplay);
    newResults[key] = {
      ...?newResults[key],
      'status': status,
      'result': result,
    };
    if (key == 'wifiInfo' && status == TestStatus.success) {
      final gatewayIp = _parseResultLine(result, "Gateway (Roteador):");
      if (gatewayIp != "---") {
        newResults[key]?['gatewayIp'] = gatewayIp;
      }
    }
    _currentState = _currentState.copyWith(testResultsDisplay: newResults);
    _streamController.add(_currentState);
  }

  String _parseResultLine(String? resultText, String key) {
    if (resultText == null || resultText.isEmpty) return "---";
    try {
      return resultText
          .split('\n')
          .firstWhere((l) => l.startsWith(key), orElse: () => "$key ---")
          .split(':')
          .sublist(1)
          .join(':')
          .trim();
    } catch (e) {
      return "---";
    }
  }

  double _extractLatencyFromResult(String? result) {
    if (result == null) return 0.0;
    try {
      final latencyPart = result
          .split('\n')
          .firstWhere((l) => l.contains('Latência'), orElse: () => '');
      final match = RegExp(r'(\d+)ms').firstMatch(latencyPart);
      if (match != null) {
        return double.tryParse(match.group(1) ?? '0') ?? 0.0;
      }
    } catch (e) {
      return 0.0;
    }
    return 0.0;
  }

  void stopAllTests() {
    internetSpeedTest.cancelTest();
    _realtimeUpdateTimer?.cancel();
    _realtimeUpdateTimer = null;
    if (_currentState.isTesting) {
      _currentState = _currentState.copyWith(
          isTesting: false,
          geralStatusMessage: "Diagnóstico interrompido pelo usuário.");
      if (!_streamController.isClosed) _streamController.add(_currentState);
    }
  }

  Future<void> _runBatteryTest() async {
    if (!_currentState.isTesting) return;
    _updateTestState(
        'batteryInfo', TestStatus.running, "Verificando bateria...");
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      String stateStr = "Desconhecido";
      if (state == BatteryState.charging) {
        stateStr = "Carregando";
      } else if (state == BatteryState.discharging) {
        stateStr = "Descarregando";
      } else if (state == BatteryState.full) {
        stateStr = "Cheia";
      }

      String warning = "";
      if (level < 20 && state != BatteryState.charging) {
        warning = "\n⚠️ Bateria baixa! O Wi-Fi pode perder potência.";
      }

      _updateTestState('batteryInfo', TestStatus.success,
          "Nível: $level%\nEstado: $stateStr$warning");
    } catch (e) {
      _updateTestState(
          'batteryInfo', TestStatus.error, "Erro ao ler bateria: $e");
    }
  }

  Future<void> _runLanScanTest() async {
    if (!_currentState.isTesting) return;
    _updateTestState('lanScan', TestStatus.running,
        "Escaneando rede local (pode demorar)...");
    try {
      final String? ip = await _networkInfo.getWifiIP();
      if (ip == null) {
        _updateTestState('lanScan', TestStatus.error,
            "Não foi possível obter o IP para escanear.");
        return;
      }
      final String subnet = ip.substring(0, ip.lastIndexOf('.'));
      final List<Host> hosts = await _lanScanner.quickIcmpScanAsync(subnet);

      if (!_currentState.isTesting) return;
      _updateTestState('lanScan', TestStatus.success,
          "Dispositivos encontrados: ${hosts.length}\n(Na sub-rede $subnet.x)");
    } catch (e) {
      if (!_currentState.isTesting) return;
      _updateTestState('lanScan', TestStatus.error, "Erro no scanner: $e");
    }
  }

  Future<void> _runPingTest(String host, String key,
      {int count = 5, bool discardFirst = false}) async {
    if (!_currentState.isTesting) return;
    _updateTestState(key, TestStatus.running, "Iniciando...");
    try {
      final params =
          PingParams(host: host, count: count, discardFirst: discardFirst);
      final String result = await compute(_pingTestRunner, params);
      if (!_currentState.isTesting) return;
      if (result.startsWith('Erro')) {
        _updateTestState(key, TestStatus.error, result);
      } else {
        _updateTestState(key, TestStatus.success, result);
      }
    } catch (e) {
      if (!_currentState.isTesting) return;
      _updateTestState(key, TestStatus.error,
          'Erro fatal ao executar o Isolate de ping: ${e.toString()}');
    }
  }

  Future<void> _runDeviceInfoTest() async {
    if (!_currentState.isTesting) return;
    _updateTestState('deviceInfo', TestStatus.running, "Coletando...");
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _isWifiConnected = connectivityResult == ConnectivityResult.wifi;
      String connectionType = "Desconhecida";
      if (_isWifiConnected) {
        connectionType = "WiFi";
      } else if (connectivityResult == ConnectivityResult.mobile) {
        connectionType = "Dados Móveis (4G/5G)";
      } else if (connectivityResult == ConnectivityResult.ethernet) {
        connectionType = "Cabo (Ethernet)";
      } else if (connectivityResult == ConnectivityResult.none) {
        connectionType = "Sem Conexão";
      } else if (connectivityResult == ConnectivityResult.vpn) {
        connectionType = "VPN (Pode afetar a velocidade!)";
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion =
          "v${packageInfo.version} (Build ${packageInfo.buildNumber})";
      final deviceInfo = DeviceInfoPlugin();
      String deviceModel = "N/A";
      String osVersion = "N/A";
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = "${androidInfo.manufacturer} ${androidInfo.model}";
        osVersion =
            "Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.model;
        osVersion = "iOS ${iosInfo.systemVersion}";
      }
      final resultString =
          "Conexão: $connectionType\nDispositivo: $deviceModel\nVersão OS: $osVersion\nVersão do App: $appVersion";
      _updateTestState('deviceInfo', TestStatus.success, resultString);
    } catch (e) {
      _updateTestState('deviceInfo', TestStatus.error,
          "Erro ao obter dados do dispositivo.");
    }
  }

  Future<void> _runIpTest() async {
    if (!_currentState.isTesting) return;
    _updateTestState('publicIp', TestStatus.running, "Buscando IPv4 e IPv6...");
    try {
      String ipV4 = "N/A";
      String org = "N/A";
      String ipV6 = "Não detectado";

      try {
        final response = await http
            .get(Uri.parse('https://ipinfo.io/json'))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          ipV4 = data['ip'] ?? 'N/A';
          org = data['org'] ?? 'N/A';
        }
      } catch (_) {}

      if (_currentState.isTesting) {
        try {
          final responseV6 = await http
              .get(Uri.parse('https://api64.ipify.org?format=json'))
              .timeout(const Duration(seconds: 5));
          if (responseV6.statusCode == 200) {
            final dataV6 = json.decode(responseV6.body);
            final ip = dataV6['ip'] as String?;
            if (ip != null && ip.contains(':')) {
              ipV6 = "Sim ($ip)";
            } else if (ip != null && ip == ipV4) {
              ipV6 = "Não (IPv4 apenas)";
            }
          }
        } catch (_) {
          ipV6 = "Falha ao verificar";
        }
      }

      if (!_currentState.isTesting) return;

      if (ipV4 != "N/A") {
        _updateTestState('publicIp', TestStatus.success,
            'IPv4: $ipV4\nIPv6: $ipV6\nProvedor: $org');
      } else {
        _updateTestState('publicIp', TestStatus.error,
            'Falha ao conectar aos servidores de IP.');
      }
    } catch (e) {
      if (!_currentState.isTesting) return;
      _updateTestState('publicIp', TestStatus.error, 'Erro: ${e.toString()}');
    }
  }

  Future<bool> _requestLocationPermission() async {
    if (!Platform.isAndroid) return true;
    var status = await Permission.location.request();
    if (context == null || !context!.mounted) return false;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context!).showSnackBar(const SnackBar(
          content: Text(
              'Permissão de localização é necessária para obter informações de WiFi.')));
    }
    return status.isGranted;
  }

  String _getFrequencyBand(int? frequency) {
    if (frequency == null || frequency == -1) return "N/A";
    if (frequency >= 2400 && frequency < 3000) return "2.4 GHz";
    if (frequency >= 5000 && frequency < 6000) return "5 GHz";
    return "$frequency MHz (Desconhecido)";
  }

  String _getSignalQuality(int? rssi) {
    if (rssi == null || rssi == -127) return "N/A";
    if (rssi >= -67) return "Excelente ($rssi dBm)";
    if (rssi >= -70) return "Boa ($rssi dBm)";
    if (rssi >= -80) return "Razoável ($rssi dBm)";
    if (rssi >= -90) return "Fraca ($rssi dBm)";
    return "Muito Fraca ($rssi dBm)";
  }

  Future<void> _runWifiTest() async {
    if (!_currentState.isTesting) return;
    _updateTestState(
        'wifiInfo', TestStatus.running, "Buscando dados de WiFi/DNS...");
    try {
      String? wifiName =
          (await _networkInfo.getWifiName())?.replaceAll("\"", "");
      String? wifiBSSID = await _networkInfo.getWifiBSSID();
      String? wifiIPv4 = await _networkInfo.getWifiIP();
      String? wifiGatewayIP = await _networkInfo.getWifiGatewayIP();
      String wifiFrequencyBand = "N/A";
      String wifiSignalStrength = "N/A";
      String dnsServers = "N/A";
      int dnsTimeMs = 0;

      if (Platform.isAndroid) {
        try {
          final Map<dynamic, dynamic>? wifiDetails =
              await platform.invokeMethod('getWifiDetails');
          final int? frequency = wifiDetails?['frequency'] as int?;
          final int? rssi = wifiDetails?['rssi'] as int?;
          final List<dynamic>? dnsList =
              wifiDetails?['dnsServers'] as List<dynamic>?;
          wifiFrequencyBand = _getFrequencyBand(frequency);
          wifiSignalStrength = _getSignalQuality(rssi);
          dnsServers = (dnsList != null && dnsList.isNotEmpty)
              ? dnsList.join('\n')
              : "Nenhum DNS encontrado";
        } catch (e) {
          debugPrint(
              "ALERTA: Falha ao chamar o MethodChannel 'getWifiDetails'. O código nativo pode estar faltando. $e");
        }
      }

      try {
        final stopwatch = Stopwatch()..start();
        await InternetAddress.lookup('google.com');
        stopwatch.stop();
        dnsTimeMs = stopwatch.elapsedMilliseconds;
      } catch (_) {
        dnsTimeMs = -1;
      }

      final resultString =
          "SSID: ${wifiName ?? 'N/A'}\nFrequência: $wifiFrequencyBand\nForça do Sinal: $wifiSignalStrength\nBSSID: ${wifiBSSID ?? 'N/A'}\nIP Dispositivo: ${wifiIPv4 ?? 'N/A'}\nGateway (Roteador): ${wifiGatewayIP ?? 'N/A'}\nServidores DNS:\n$dnsServers\nTempo DNS: ${dnsTimeMs >= 0 ? '$dnsTimeMs ms' : 'Falha'}";
      _updateTestState('wifiInfo', TestStatus.success, resultString);
    } catch (e) {
      if (!_currentState.isTesting) return;
      _updateTestState('wifiInfo', TestStatus.error,
          'Erro ao obter informações: ${e.toString()}');
    }
  }

  Future<void> _runPingGatewayTest() async {
    if (!_currentState.isTesting) return;
    _updateTestState(
        'pingGateway', TestStatus.running, "Aguardando IP do Roteador...");
    final String? gatewayIp =
        _currentState.testResultsDisplay['wifiInfo']?['gatewayIp'] as String?;
    if (gatewayIp != null && gatewayIp.isNotEmpty) {
      _updateStatus("Testando ping para o Roteador ($gatewayIp)...");
      // Use 10 pings + discardFirst for router
      await _runPingTest(gatewayIp, 'pingGateway',
          count: 10, discardFirst: true);
    } else {
      if (_currentState.isTesting &&
          _currentState.testResultsDisplay['pingGateway']?['status'] !=
              TestStatus.error) {
        _updateTestState('pingGateway', TestStatus.error,
            'Não foi possível obter IP do roteador no teste WiFi.');
      }
    }
  }

  Future<void> _runSpeedTestCustom() async {
    if (!_currentState.isTesting) return;
    String? customUrl = providerConfig.config.other?.speedTestUrl;

    // Default: Infer local server from API URL (same host, port 3001)
    String defaultSpeedTestUrl =
        'https://librespeed.org'; // Fallback of fallback
    try {
      final apiUri = Uri.parse(providerConfig.apiUrl);
      if (apiUri.host.isNotEmpty) {
        // Assume SpeedTest is adjacent on port 3001
        defaultSpeedTestUrl = 'http://${apiUri.host}:3001';
      }
    } catch (_) {
      // Ignore parse error, stick to librespeed
    }

    // Validate URL - use inferred default if invalid or empty
    if (customUrl == null ||
        customUrl.isEmpty ||
        Uri.tryParse(customUrl)?.hasAbsolutePath != true) {
      customUrl = defaultSpeedTestUrl;
      _updateStatus("Usando servidor padrão: $customUrl");
    }

    _updateTestState('speedTestCustom', TestStatus.running,
        "Iniciando teste (Servidor Próprio)...");

    final completer = Completer<void>();
    _downloadHistoryCounter = 0;
    _uploadHistoryCounter = 0;
    _customPeakDownloadMbps = 0;
    _customPeakUploadMbps = 0;
    _currentState =
        _currentState.copyWith(downloadHistory: [], uploadHistory: []);
    _streamController.add(_currentState);

    // TIMERS
    Timer? stallTimer;
    Timer? maxDurationTimer;

    void cancelTimers() {
      stallTimer?.cancel();
      maxDurationTimer?.cancel();
    }

    try {
      // 1. Max Duration Timer: Hard limit per test (prevents 2 min waits)
      maxDurationTimer = Timer(const Duration(seconds: 40), () {
        if (!completer.isCompleted && _currentState.isTesting) {
          internetSpeedTest.cancelTest();
          // Accept current result as final if we timed out but had data
          _updateTestState(
              'speedTestCustom', TestStatus.success, "Tempo limite atingido.");
          if (!completer.isCompleted) completer.complete();
        }
      });

      internetSpeedTest.startTesting(
        downloadTestServer: customUrl,
        uploadTestServer: customUrl,
        // fileSize: 20000000, // Optional: Limit file size if supported to speed up
        onStarted: () {
          if (!_currentState.isTesting) {
            internetSpeedTest.cancelTest();
            return;
          }
          _updateStatus("Testando Download (Servidor Personalizado)...");
        },
        onCompleted: (TestResult download, TestResult upload) {
          cancelTimers();
          if (!_currentState.isTesting) return;
          final downloadMbps = download.transferRate;
          final uploadMbps = upload.transferRate;

          _updateTestState('speedTestCustom', TestStatus.success,
              "Download: ${downloadMbps.toStringAsFixed(1)} Mbps\nUpload: ${uploadMbps.toStringAsFixed(1)} Mbps");

          double latencia = _extractLatencyFromResult(
              _currentState.testResultsDisplay['pingGoogle']?['result']);
          if (latencia == 0) {
            latencia = _extractLatencyFromResult(
                _currentState.testResultsDisplay['pingCloudflare']?['result']);
          }

          _currentState = _currentState.copyWith(
            customDownloadResultMbps: downloadMbps,
            customUploadResultMbps: uploadMbps,
            speedTestPingLatency: latencia,
          );
          _streamController.add(_currentState);
          if (!completer.isCompleted) completer.complete();
        },
        onProgress: (double percent, TestResult data) {
          if (!_currentState.isTesting) return;
          final rate = data.transferRate;
          final isDownload = data.type == TestType.download;

          // 2. Stall Timer: Reset only on progress
          stallTimer?.cancel();
          stallTimer = Timer(const Duration(seconds: 15), () {
            if (!completer.isCompleted && _currentState.isTesting) {
              internetSpeedTest.cancelTest();
              _updateTestState('speedTestCustom', TestStatus.error,
                  "Teste travado (sem progresso).");
              if (!completer.isCompleted) completer.complete();
            }
          });

          if (isDownload) {
            _updateStatus(
                "Testando Download... ${rate.toStringAsFixed(1)} Mbps (${percent.toStringAsFixed(0)}%)");
            if (rate > _customPeakDownloadMbps) _customPeakDownloadMbps = rate;
            final newHistory = List<FlSpot>.from(_currentState.downloadHistory);
            newHistory.add(FlSpot(_downloadHistoryCounter.toDouble(), rate));
            _downloadHistoryCounter++;
            _currentState = _currentState.copyWith(
                downloadHistory: newHistory, customDownloadResultMbps: rate);
          } else {
            _updateStatus(
                "Testando Upload... ${rate.toStringAsFixed(1)} Mbps (${percent.toStringAsFixed(0)}%)");
            if (rate > _customPeakUploadMbps) _customPeakUploadMbps = rate;
            final newHistory = List<FlSpot>.from(_currentState.uploadHistory);
            newHistory.add(FlSpot(_uploadHistoryCounter.toDouble(), rate));
            _uploadHistoryCounter++;
            _currentState = _currentState.copyWith(
                uploadHistory: newHistory, customUploadResultMbps: rate);
          }
          _streamController.add(_currentState);
        },
        onError: (String errorMessage, String speedTestError) {
          cancelTimers();
          if (!_currentState.isTesting) return;

          String cleanError = errorMessage;
          // Enhanced Error Parsing
          if (errorMessage.toLowerCase().contains("socketexception") ||
              errorMessage.toLowerCase().contains("connection refused") ||
              errorMessage.contains("CONNECTION_ERROR") ||
              errorMessage.contains("HTTP 404")) {
            cleanError = "Servidor indisponível.\nVerifique a conexão ou URL.";
          }

          _updateTestState('speedTestCustom', TestStatus.error, cleanError);
          if (!completer.isCompleted) completer.complete();
        },
      );
    } catch (e) {
      cancelTimers();
      _updateTestState(
          'speedTestCustom', TestStatus.error, "Erro ao iniciar: $e");
      if (!completer.isCompleted) completer.complete();
    }

    return completer.future;
  }

  Future<void> _runSpeedTestFastCom() async {
    if (!_currentState.isTesting) return;
    _updateTestState(
        'speedTestFast', TestStatus.running, "Iniciando teste (Fast.com)...");
    final completer = Completer<void>();
    _fastDownloadHistoryCounter = 0;
    _fastUploadHistoryCounter = 0;
    _fastPeakDownloadMbps = 0;
    _fastPeakUploadMbps = 0;
    _currentState =
        _currentState.copyWith(fastDownloadHistory: [], fastUploadHistory: []);
    _streamController.add(_currentState);

    // SAFETY TIMEOUT: Ensure test doesn't hang forever
    Timer? safeguardTimer;

    try {
      safeguardTimer = Timer(const Duration(seconds: 45), () {
        if (!completer.isCompleted && _currentState.isTesting) {
          internetSpeedTest.cancelTest();
          _updateTestState('speedTestFast', TestStatus.error,
              "Tempo limite excedido (Fast.com).");
          if (!completer.isCompleted) completer.complete();
        }
      });

      internetSpeedTest.startTesting(
        onStarted: () {
          if (!_currentState.isTesting) {
            internetSpeedTest.cancelTest();
            return;
          }
          _updateStatus("Testando Download (Fast.com)...");
        },
        onCompleted: (TestResult download, TestResult upload) {
          safeguardTimer?.cancel();
          if (!_currentState.isTesting) return;
          final downloadMbps = download.transferRate;
          final uploadMbps = upload.transferRate;
          _updateTestState('speedTestFast', TestStatus.success,
              "Download: ${downloadMbps.toStringAsFixed(1)} Mbps\nUpload: ${uploadMbps.toStringAsFixed(1)} Mbps");
          _currentState = _currentState.copyWith(
              fastDownloadResultMbps: downloadMbps,
              fastUploadResultMbps: uploadMbps);
          _streamController.add(_currentState);
          if (!completer.isCompleted) completer.complete();
        },
        onProgress: (double percent, TestResult data) {
          if (!_currentState.isTesting) return; // Prevent Zombie updates
          final rate = data.transferRate;
          final isDownload = data.type == TestType.download;

          // Restart safeguard on progress
          safeguardTimer?.cancel();
          safeguardTimer = Timer(const Duration(seconds: 20), () {
            if (!completer.isCompleted && _currentState.isTesting) {
              internetSpeedTest.cancelTest();
              _updateTestState('speedTestFast', TestStatus.error,
                  "Teste travado (sem progresso).");
              if (!completer.isCompleted) completer.complete();
            }
          });

          if (isDownload) {
            _updateStatus(
                "Testando Download (Fast.com)... ${rate.toStringAsFixed(1)} Mbps (${percent.toStringAsFixed(0)}%)");
            if (rate > _fastPeakDownloadMbps) _fastPeakDownloadMbps = rate;
            final newHistory =
                List<FlSpot>.from(_currentState.fastDownloadHistory);
            newHistory
                .add(FlSpot(_fastDownloadHistoryCounter.toDouble(), rate));
            _fastDownloadHistoryCounter++;
            _currentState = _currentState.copyWith(
                fastDownloadHistory: newHistory, fastDownloadResultMbps: rate);
          } else {
            _updateStatus(
                "Testando Upload (Fast.com)... ${rate.toStringAsFixed(1)} Mbps (${percent.toStringAsFixed(0)}%)");
            if (rate > _fastPeakUploadMbps) _fastPeakUploadMbps = rate;
            final newHistory =
                List<FlSpot>.from(_currentState.fastUploadHistory);
            newHistory.add(FlSpot(_fastUploadHistoryCounter.toDouble(), rate));
            _fastUploadHistoryCounter++;
            _currentState = _currentState.copyWith(
                fastUploadHistory: newHistory, fastUploadResultMbps: rate);
          }
          _streamController.add(_currentState);
        },
        onError: (String errorMessage, String speedTestError) {
          safeguardTimer?.cancel();
          if (!_currentState.isTesting) return;
          _updateTestState(
              'speedTestFast', TestStatus.error, "Erro: $errorMessage");
          if (!completer.isCompleted) completer.complete();
        },
      );
    } catch (e) {
      safeguardTimer?.cancel();
      _updateTestState(
          'speedTestFast', TestStatus.error, "Erro ao iniciar: $e");
      if (!completer.isCompleted) completer.complete();
    }

    return completer.future;
  }

  Future<void> runAllTests() async {
    if (_currentState.isTesting) return;
    _currentState = DiagnosticoState.initial().copyWith(
        isTesting: true, geralStatusMessage: "Iniciando diagnóstico...");
    _streamController.add(_currentState);

    try {
      _updateStatus("Verificando informações do dispositivo...");
      await _runDeviceInfoTest();
      await _runBatteryTest();
      if (!_currentState.isTesting) return;

      bool hasPermission = false;
      if (_isWifiConnected) {
        _updateStatus("Solicitando permissão de localização...");
        hasPermission = await _requestLocationPermission();
        if (!_currentState.isTesting) return;
        if (!hasPermission) {
          _updateTestState(
              'wifiInfo', TestStatus.error, 'Permissão de localização negada.');
          _updateTestState('pingGateway', TestStatus.error,
              'Requer info WiFi (permissão negada).');
        }
      } else {
        _updateTestState(
            'wifiInfo', TestStatus.error, 'Não conectado ao WiFi.');
        _updateTestState(
            'pingGateway', TestStatus.error, 'Não conectado ao WiFi.');
      }

      _updateStatus("Verificando Conectividade e IP (IPv4/IPv6)...");
      await _runIpTest();
      if (!_currentState.isTesting) return;

      _updateStatus("Testando ping para Google...");
      // 10 pings, keep all for Google
      await _runPingTest('8.8.8.8', 'pingGoogle', count: 10);
      if (!_currentState.isTesting) return;

      _updateStatus("Testando ping para Cloudflare...");
      // 10 pings, keep all for Cloudflare
      await _runPingTest('1.1.1.1', 'pingCloudflare', count: 10);

      if (!_currentState.isTesting) return;

      if (hasPermission && _isWifiConnected) {
        _updateStatus("Verificando informações de WiFi e DNS...");
        await _runWifiTest();

        _updateStatus("Escaneando Rede Local (LAN)...");
        await _runLanScanTest();

        if (!_currentState.isTesting) return;
        if (_currentState.testResultsDisplay['wifiInfo']?['status'] ==
            TestStatus.success) {
          await _runPingGatewayTest();
          if (!_currentState.isTesting) return;
        }
      }

      await _runSpeedTestCustom();
      if (!_currentState.isTesting) return;

      await _runSpeedTestFastCom();
      if (!_currentState.isTesting) return;

      if (_currentState.isTesting) {
        bool anyError = _currentState.testResultsDisplay.entries
            .any((entry) => entry.value['status'] == TestStatus.error);
        _updateStatus(anyError
            ? "Diagnóstico concluído com erros."
            : "Diagnóstico concluído.");
      }
    } catch (e) {
      if (_currentState.isTesting) {
        _updateStatus("Ocorreu um erro inesperado durante o diagnóstico.");
      }
    } finally {
      if (_currentState.isTesting) {
        _currentState = _currentState.copyWith(isTesting: false);
        _streamController.add(_currentState);
      }
    }
  }

  Future<void> runSpeedTestsOnly() async {
    if (_currentState.isTesting) return;
    _currentState = DiagnosticoState.initial().copyWith(
        isTesting: true,
        geralStatusMessage: "Iniciando teste de velocidade...");
    _streamController.add(_currentState);

    try {
      await _runSpeedTestCustom();
      if (!_currentState.isTesting) return;

      await _runSpeedTestFastCom();
      if (!_currentState.isTesting) return;

      _updateStatus("Teste de velocidade concluído.");
    } catch (e) {
      if (_currentState.isTesting) {
        _updateStatus("Ocorreu um erro durante o teste.");
      }
    } finally {
      if (_currentState.isTesting) {
        _currentState = _currentState.copyWith(isTesting: false);
        _streamController.add(_currentState);
      }
    }
  }
}
```

---

### `lib/core/services/financeiro_service.dart`
> Serviço de negócio

```dart
// ARQUIVO: lib/core/services/financeiro_service.dart
// DESCRIÇÃO: Serviço para buscar faturas e solicitar desbloqueio

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class FinanceiroService {
  final String apiUrl;
  final String cpfCnpjUnformatted;
  final String? senha;
  final Map<String, dynamic> sgpParams;

  FinanceiroService({
    required this.apiUrl,
    required this.cpfCnpjUnformatted,
    this.senha,
    required this.sgpParams,
  });

  /// Busca as faturas do cliente
  Future<List<dynamic>> fetchInvoices() async {
    try {
      // [MOCK] If no token/app configured, return mock data for UI testing
      if ((sgpParams['token'] ?? '').isEmpty ||
          (sgpParams['app'] ?? '').isEmpty) {
        // Retrieve colors to use the correct formatting if needed (though model parses strings mostly)
        return _getMockInvoices();
      }

      if (cpfCnpjUnformatted.isEmpty) {
        throw Exception("O CPF/CNPJ está vazio.");
      }

      final requestBody = {
        'cpfCnpj': cpfCnpjUnformatted,
        'senha': senha,
        'sgpParams': sgpParams,
        'sgpBaseUrl': sgpParams['sgpBaseUrl'],
      };

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        final responseData = responseBody['data'];
        return responseData is List ? responseData : [];
      } else {
        final errorMessage = responseBody['error']?['message'] ??
            responseBody['error'] ??
            'Falha ao carregar faturas. Código: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      throw TimeoutException(
          'O servidor demorou muito para responder. Verifique sua conexão.');
    } catch (e) {
      // If we are debugging/testing, maybe fallback to mock on error too?
      // For now, let's stick to explicit mock only if config is missing.
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  List<dynamic> _getMockInvoices() {
    final now = DateTime.now();
    return [
      {
        'id': 123456,
        'vencimento': now.add(const Duration(days: 5)).toIso8601String(),
        'valor': 99.90,
        'status': 'pendente',
        'linha_digitavel':
            '84670000001 4 59900296202 5 20424263400 3 10328905230',
        'pix_copia_cola':
            '00020101021226870014br.gov.bcb.pix2565qrcode.pix.com.br...',
        'url_boleto': 'https://example.com/boleto',
      },
      {
        'id': 123455,
        'vencimento': now.subtract(const Duration(days: 25)).toIso8601String(),
        'valor': 99.90,
        'status': 'pago',
        'data_pagamento':
            now.subtract(const Duration(days: 26)).toIso8601String(),
        'valor_pago': 99.90,
      },
      {
        'id': 123454,
        'vencimento': now.subtract(const Duration(days: 55)).toIso8601String(),
        'valor': 99.90,
        'status': 'pago',
        'data_pagamento':
            now.subtract(const Duration(days: 56)).toIso8601String(),
        'valor_pago': 99.90,
      },
    ];
  }

  /// Solicita desbloqueio por confiança
  Future<bool> solicitarDesbloqueioConfianca() async {
    try {
      final unlockUrl = apiUrl.replaceAll('get-invoices', 'unlock-trust');

      final requestBody = {
        'cpfCnpj': cpfCnpjUnformatted,
        'senha': senha,
        'sgpParams': sgpParams,
        'sgpBaseUrl': sgpParams['sgpBaseUrl'],
      };

      final response = await http
          .post(
            Uri.parse(unlockUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      } else {
        final body = json.decode(response.body);
        throw Exception(body['message'] ??
            'Não foi possível realizar o desbloqueio. Tente novamente.');
      }
    } catch (e) {
      throw Exception(
          "Erro ao solicitar desbloqueio: ${e.toString().replaceAll('Exception: ', '')}");
    }
  }
}
```

---

### `lib/core/services/meu_ip_service.dart`
> Serviço de negócio

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class MeuIpService {
  final String _apiUrl = 'https://ipinfo.io/json';

  /// Busca os dados de IP do serviço ipinfo.io
  Future<Map<String, dynamic>> fetchIpInfo() async {
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Não foi possível obter os dados de IP. Código: ${response.statusCode}');
      }
    } on TimeoutException {
      throw TimeoutException('O servidor (ipinfo.io) demorou para responder.');
    } catch (e) {
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }
}
```

---

### `lib/core/services/notification_service.dart`
> Serviço de negócio

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/in_app_notification.dart';

class NotificationService with ChangeNotifier {
  List<InAppNotification> _notifications = [];
  bool _isLoading = true;
  static const String _storageKey = 'notifications_v1';

  List<InAppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount =>
      _notifications.where((n) => !n.read && !n.isExpired).length;

  List<InAppNotification> get activeNotifications =>
      _notifications.where((n) => !n.isExpired).toList();

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _notifications = jsonList
            .map((json) => InAppNotification.fromJson(json))
            .where((n) => !n.isExpired) // Filter expired on load
            .toList();
      } else {
        // First run: Add Welcome Notification
        _notifications = [
          InAppNotification(
            id: 'welcome_001',
            type: NotificationType.info,
            title: 'Bem-vindo!',
            message:
                'Obrigado por usar nosso aplicativo. Explore todas as funcionalidades!',
            createdAt: DateTime.now(),
            read: false,
          ),
        ];
        await _saveToPrefs();
      }
    } catch (e) {
      debugPrint('Erro ao carregar notificações: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      notifyListeners();
      await _saveToPrefs();
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
    notifyListeners();
    await _saveToPrefs();
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    _saveToPrefs();
  }

  Future<void> addNotification(InAppNotification notification) async {
    _notifications.insert(0, notification);
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Erro ao salvar notificações: $e');
    }
  }
}
```

---

### `lib/core/services/onu_wifi_service.dart`
> Serviço de negócio

```dart
// ARQUIVO: lib/core/services/onu_wifi_service.dart
// DESCRIÇÃO: Serviço para buscar sinal da ONU e gerenciar WiFi via SGP/TR069

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class OnuData {
  final double? signalRx; // null if N/A or offline
  final double? signalTx; // null if N/A or offline
  final String connectionStatus;
  final bool isOnline;
  final int oltId;
  final String? oltName;
  final int slot;
  final int pon;
  final int onuId;
  final double? temperature;
  final double? voltage;
  final String model;
  final String? serialNumber;
  // New fields from SGP
  final String? mode; // Bridge, Router, etc
  final int? vlan;
  final String? cto; // CTO location
  final String? lastUpdate;

  OnuData({
    this.signalRx,
    this.signalTx,
    required this.connectionStatus,
    required this.isOnline,
    required this.oltId,
    this.oltName,
    required this.slot,
    required this.pon,
    required this.onuId,
    this.temperature,
    this.voltage,
    required this.model,
    this.serialNumber,
    this.mode,
    this.vlan,
    this.cto,
    this.lastUpdate,
  });

  factory OnuData.fromJson(Map<String, dynamic> json) {
    final status = json['connectionStatus']?.toString() ?? 'unknown';
    return OnuData(
      signalRx: json['signalRx']?.toDouble(),
      signalTx: json['signalTx']?.toDouble(),
      connectionStatus: status,
      isOnline: status.toLowerCase() == 'online',
      oltId: json['oltId'] ?? 0,
      oltName: json['oltName'],
      slot: json['slot'] ?? 0,
      pon: json['pon'] ?? 0,
      onuId: json['onuId'] ?? 0,
      temperature: json['temperature']?.toDouble(),
      voltage: json['voltage']?.toDouble(),
      model: json['model'] ?? 'Desconhecido',
      serialNumber: json['serialNumber'],
      mode: json['mode'],
      vlan: json['vlan'],
      cto: json['cto'],
      lastUpdate: json['lastUpdate'],
    );
  }

  /// Qualidade do sinal baseada no RX
  String get signalQuality {
    if (signalRx == null) return 'Sem dados';
    if (signalRx! >= -23) return 'Excelente';
    if (signalRx! >= -25) return 'Bom';
    if (signalRx! >= -27) return 'Regular';
    return 'Ruim';
  }

  /// Cor do sinal baseada no RX
  bool get isSignalGood => signalRx != null && signalRx! >= -25;

  /// Retorna string formatada do sinal RX
  String get signalRxDisplay =>
      signalRx != null ? '${signalRx!.toStringAsFixed(1)} dBm' : 'N/A';

  /// Retorna string formatada do sinal TX
  String get signalTxDisplay =>
      signalTx != null ? '${signalTx!.toStringAsFixed(1)} dBm' : 'N/A';
}

class WifiNetwork {
  final String id;
  final String ssid;
  final String frequency; // 2.4GHz ou 5GHz
  final bool enabled;
  final String? password;

  WifiNetwork({
    required this.id,
    required this.ssid,
    required this.frequency,
    required this.enabled,
    this.password,
  });

  factory WifiNetwork.fromJson(Map<String, dynamic> json) {
    return WifiNetwork(
      id: json['id']?.toString() ?? '',
      ssid: json['ssid'] ?? json['nome'] ?? '',
      frequency: json['frequency'] ?? json['frequencia'] ?? '2.4GHz',
      enabled: json['enabled'] ?? json['ativo'] ?? true,
      password: json['password'] ?? json['senha'],
    );
  }
}

class OnuWifiService {
  final String apiUrl;
  final String cpfCnpj;
  final String? senha;
  final String? contrato;
  final Map<String, String> sgpParams;

  OnuWifiService({
    required this.apiUrl,
    required this.cpfCnpj,
    this.senha,
    this.contrato,
    required this.sgpParams,
  });

  /// Helper to get base proxy URL
  String get _baseUrl {
    // Remove trailing slash and any path like /get-invoices
    String base = apiUrl.trim();
    // If URL ends with a path like /get-invoices, remove it
    final uri = Uri.tryParse(base);
    if (uri != null) {
      return '${uri.scheme}://${uri.host}:${uri.port}';
    }
    // Fallback: remove trailing slash
    return base.replaceAll(RegExp(r'/$'), '');
  }

  /// Busca dados da ONU (sinal, temperatura, etc)
  Future<OnuData> fetchOnuSignal() async {
    final url = '$_baseUrl/diagnostic/onu-signal';
    debugPrint('[ONU-Service] Calling: $url');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'cpfCnpj': cpfCnpj,
              'senha': senha,
              'contrato': contrato,
              'sgpParams': sgpParams,
              'sgpBaseUrl': sgpParams['sgpBaseUrl'],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return OnuData.fromJson(data['data']);
        }
        throw Exception('Dados da ONU não encontrados.');
      } else {
        // Tenta parsear erro do servidor
        try {
          final error = json.decode(response.body);
          throw Exception(error['error']?['message'] ??
              'Erro no servidor (${response.statusCode})');
        } catch (_) {
          throw Exception('Erro no servidor (${response.statusCode})');
        }
      }
    } on http.ClientException catch (_) {
      throw Exception(
          'Servidor indisponível.\nVerifique se o servidor local está rodando.');
    } on FormatException catch (_) {
      throw Exception('Resposta inválida do servidor.');
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        throw Exception('Sem conexão com o servidor local.');
      }
      if (e.toString().contains('Timeout')) {
        throw Exception('Tempo limite excedido ao conectar ao servidor.');
      }
      throw Exception(
          'Erro ao buscar sinal: ${e.toString().replaceAll("Exception:", "").trim()}');
    }
  }

  /// Lista redes WiFi do CPE/Roteador
  Future<List<WifiNetwork>> fetchWifiNetworks() async {
    final url = '$_baseUrl/cpe/wifi/list';
    debugPrint('[WiFi-Service] Calling: $url');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'cpfCnpj': cpfCnpj,
              'senha': senha,
              'contrato': contrato,
              'sgpParams': sgpParams,
              'sgpBaseUrl': sgpParams['sgpBaseUrl'],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'] is List) {
          return (data['data'] as List)
              .map((w) => WifiNetwork.fromJson(w))
              .toList();
        }
        return [];
      } else {
        try {
          final error = json.decode(response.body);
          throw Exception(error['error']?['message'] ??
              'Erro no servidor (${response.statusCode})');
        } catch (_) {
          throw Exception('Erro no servidor (${response.statusCode})');
        }
      }
    } on http.ClientException catch (_) {
      throw Exception(
          'Servidor indisponível.\nVerifique se o servidor local está rodando.');
    } on FormatException catch (_) {
      throw Exception('Resposta inválida do servidor.');
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        throw Exception('Sem conexão com o servidor local.');
      }
      if (e.toString().contains('Timeout')) {
        throw Exception('Tempo limite excedido ao conectar ao servidor.');
      }
      throw Exception(
          'Erro ao buscar WiFi: ${e.toString().replaceAll("Exception:", "").trim()}');
    }
  }

  /// Atualiza configuração WiFi (nome e senha)
  Future<bool> updateWifi({
    required String wifiId,
    required String ssid,
    required String password,
  }) async {
    final url = '$_baseUrl/cpe/wifi/update';
    debugPrint('[WiFi-Service] Calling: $url');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'cpfCnpj': cpfCnpj,
              'senha': senha,
              'contrato': contrato,
              'wifiId': wifiId,
              'ssid': ssid,
              'password': password,
              'sgpParams': sgpParams,
              'sgpBaseUrl': sgpParams['sgpBaseUrl'],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        try {
          final error = json.decode(response.body);
          throw Exception(error['error']?['message'] ??
              'Erro no servidor (${response.statusCode})');
        } catch (_) {
          throw Exception('Erro no servidor (${response.statusCode})');
        }
      }
    } on http.ClientException catch (_) {
      throw Exception(
          'Servidor indisponível.\nVerifique se o servidor local está rodando.');
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        throw Exception('Sem conexão com o servidor local.');
      }
      throw Exception(
          'Erro ao atualizar WiFi: ${e.toString().replaceAll("Exception:", "").trim()}');
    }
  }
}
```

---

### `lib/core/services/push_notification_service.dart`
> Serviço de negócio

```dart
// ARQUIVO: lib/core/services/push_notification_service.dart
// DESCRIÇÃO: Serviço de Push Notifications com Flutter Local Notifications

import 'package:flutter/foundation.dart';

/// Serviço para gerenciar push notifications (sem Firebase)
/// Usa flutter_local_notifications para notificações locais
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  bool _isInitialized = false;

  /// Inicializa o serviço de notificações
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Adicione flutter_local_notifications ao pubspec.yaml:
      // flutter_local_notifications: ^16.0.0

      debugPrint('[PushNotificationService] Inicializado com sucesso');
      _isInitialized = true;
    } catch (e) {
      debugPrint('[PushNotificationService] Erro ao inicializar: $e');
    }
  }

  /// Mostra notificação de fatura vencendo
  Future<void> showInvoiceDueNotification({
    required String invoiceId,
    required String dueDate,
    required double value,
  }) async {
    debugPrint(
        '[Notification] Fatura $invoiceId vence em $dueDate: R\$ $value');
    // Implementar com flutter_local_notifications quando o pacote for adicionado
  }

  /// Mostra notificação de conexão restaurada
  Future<void> showConnectionRestoredNotification() async {
    debugPrint('[Notification] Conexão restaurada');
  }

  /// Mostra notificação de liberação por confiança
  Future<void> showTrustUnlockNotification() async {
    debugPrint('[Notification] Internet liberada por 24h');
  }
}
```

---

### `lib/core/services/review_service.dart`
> Serviço de negócio

```dart
import 'package:in_app_review/in_app_review.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  final InAppReview _inAppReview = InAppReview.instance;

  /// Requests a review if conditions are met.
  /// Conditions:
  /// 1. Not requested strictly recently (e.g. today).
  /// 2. User just had a "Happy Moment" (Speed test good, Invoice paid).
  Future<void> tryRequestReview() async {
    if (await _inAppReview.isAvailable()) {
      // Check cooldown
      final prefs = await SharedPreferences.getInstance();
      final lastRequest = prefs.getInt('last_review_request') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Cooldown: 7 days
      const cooldown = 7 * 24 * 60 * 60 * 1000;

      if (now - lastRequest > cooldown) {
        debugPrint('Review: Requesting In-App Review...');
        await _inAppReview.requestReview();
        await prefs.setInt('last_review_request', now);
      } else {
        debugPrint('Review: Cooldown active');
      }
    } else {
      debugPrint('Review: Not available');
    }
  }

  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing();
    } catch (e) {
      debugPrint('Review: Error opening store listing: $e');
    }
  }
}
```

---

### `lib/core/services/security_service.dart`
> Serviço de negócio

```dart
// Serviço de Segurança
// Secure Storage e proteção de dados sensíveis

import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Serviço de Armazenamento Seguro
class SecureStorageService {
  static SecureStorageService? _instance;
  late final FlutterSecureStorage _storage;

  // Opções de segurança para Android
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  // Opções de segurança para iOS
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  SecureStorageService._() {
    _storage = const FlutterSecureStorage(
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  static SecureStorageService get instance {
    _instance ??= SecureStorageService._();
    return _instance!;
  }

  /// Salva dado de forma segura
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Lê dado seguro
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Deleta dado seguro
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Verifica se existe
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  /// Limpa todos os dados seguros
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Salva objeto JSON de forma segura
  Future<void> writeJson(String key, Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    await write(key, jsonString);
  }

  /// Lê objeto JSON seguro
  Future<Map<String, dynamic>?> readJson(String key) async {
    final jsonString = await read(key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}

/// Chaves de armazenamento seguro
class SecureKeys {
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userCredentials = 'user_credentials';
  static const String biometricEnabled = 'biometric_enabled';
  static const String pinCode = 'pin_code';
  static const String encryptionKey = 'encryption_key';
}

/// Utilitários de Criptografia (sem dependências externas)
class CryptoUtils {
  /// Codifica para Base64
  static String encodeBase64(String input) {
    return base64Encode(utf8.encode(input));
  }

  /// Decodifica de Base64
  static String decodeBase64(String input) {
    return utf8.decode(base64Decode(input));
  }

  /// Gera salt aleatório
  static String generateSalt({int length = 32}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Gera token aleatório
  static String generateToken({int length = 64}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Ofusca string para exibição (ex: cartão de crédito)
  static String mask(String input, {int visibleStart = 4, int visibleEnd = 4}) {
    if (input.length <= visibleStart + visibleEnd) return input;
    final start = input.substring(0, visibleStart);
    final end = input.substring(input.length - visibleEnd);
    final masked = '*' * (input.length - visibleStart - visibleEnd);
    return '$start$masked$end';
  }

  /// Ofusca email
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return email;
    return '${name.substring(0, 2)}***@$domain';
  }

  /// Valida força da senha
  static PasswordStrength checkPasswordStrength(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?:{}|]'))) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }
}

/// Força da senha
enum PasswordStrength {
  weak,
  medium,
  strong;

  String get label {
    switch (this) {
      case PasswordStrength.weak:
        return 'Fraca';
      case PasswordStrength.medium:
        return 'Média';
      case PasswordStrength.strong:
        return 'Forte';
    }
  }

  double get value {
    switch (this) {
      case PasswordStrength.weak:
        return 0.33;
      case PasswordStrength.medium:
        return 0.66;
      case PasswordStrength.strong:
        return 1.0;
    }
  }
}

/// Validadores de Segurança
class SecurityValidators {
  /// Valida CPF
  static bool isValidCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}\$').hasMatch(cpf)) return false;

    // Validação dos dígitos verificadores
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int firstDigit = (sum * 10) % 11;
    if (firstDigit == 10) firstDigit = 0;
    if (firstDigit != int.parse(cpf[9])) return false;

    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    int secondDigit = (sum * 10) % 11;
    if (secondDigit == 10) secondDigit = 0;
    return secondDigit == int.parse(cpf[10]);
  }

  /// Valida email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}\$');
    return emailRegex.hasMatch(email);
  }

  /// Valida telefone brasileiro
  static bool isValidPhone(String phone) {
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return phone.length == 10 || phone.length == 11;
  }

  /// Sanitiza input (remove caracteres perigosos)
  static String sanitizeInput(String input) {
    // Remove HTML tags e caracteres perigosos
    String sanitized = input;
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
    sanitized = sanitized.replaceAll('<', '');
    sanitized = sanitized.replaceAll('>', '');
    return sanitized;
  }
}

/// Serviço de Autenticação Segura
class AuthSecurityService {
  final SecureStorageService _storage = SecureStorageService.instance;

  /// Salva tokens de autenticação
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(SecureKeys.authToken, accessToken);
    if (refreshToken != null) {
      await _storage.write(SecureKeys.refreshToken, refreshToken);
    }
  }

  /// Recupera token de acesso
  Future<String?> getAccessToken() async {
    return await _storage.read(SecureKeys.authToken);
  }

  /// Recupera refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(SecureKeys.refreshToken);
  }

  /// Limpa tokens (logout)
  Future<void> clearTokens() async {
    await _storage.delete(SecureKeys.authToken);
    await _storage.delete(SecureKeys.refreshToken);
  }

  /// Verifica se está autenticado
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
```

---

### `lib/core/services/speed_test_history_service.dart`
> Serviço de negócio

```dart
// ARQUIVO: lib/core/services/speed_test_history_service.dart
// DESCRIÇÃO: Serviço para salvar e recuperar histórico de testes de velocidade

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de resultado de speed test
class SpeedTestResult {
  final DateTime timestamp;
  final double downloadSpeed; // Mbps
  final double uploadSpeed; // Mbps
  final int ping; // ms
  final String? serverName;

  SpeedTestResult({
    required this.timestamp,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.ping,
    this.serverName,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'downloadSpeed': downloadSpeed,
        'uploadSpeed': uploadSpeed,
        'ping': ping,
        'serverName': serverName,
      };

  factory SpeedTestResult.fromJson(Map<String, dynamic> json) {
    return SpeedTestResult(
      timestamp: DateTime.parse(json['timestamp']),
      downloadSpeed: (json['downloadSpeed'] ?? 0).toDouble(),
      uploadSpeed: (json['uploadSpeed'] ?? 0).toDouble(),
      ping: json['ping'] ?? 0,
      serverName: json['serverName'],
    );
  }

  String get formattedDate {
    final d = timestamp;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

/// Serviço para gerenciar histórico de speed tests
class SpeedTestHistoryService with ChangeNotifier {
  static const String _historyKey = 'speed_test_history';
  static const int _maxHistoryItems = 20;

  List<SpeedTestResult> _history = [];
  bool _isLoading = true;

  List<SpeedTestResult> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;
  bool get hasHistory => _history.isNotEmpty;

  /// Último resultado
  SpeedTestResult? get lastResult =>
      _history.isNotEmpty ? _history.first : null;

  /// Média de download
  double get averageDownload {
    if (_history.isEmpty) return 0;
    return _history.map((e) => e.downloadSpeed).reduce((a, b) => a + b) /
        _history.length;
  }

  /// Média de upload
  double get averageUpload {
    if (_history.isEmpty) return 0;
    return _history.map((e) => e.uploadSpeed).reduce((a, b) => a + b) /
        _history.length;
  }

  /// Carrega histórico do storage
  Future<void> loadHistory() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];

      _history = historyJson
          .map((json) => SpeedTestResult.fromJson(jsonDecode(json)))
          .toList();

      // Ordena por data (mais recente primeiro)
      _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('Erro ao carregar histórico: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Salva um novo resultado
  Future<void> saveResult(SpeedTestResult result) async {
    try {
      _history.insert(0, result);

      // Limita o histórico
      if (_history.length > _maxHistoryItems) {
        _history = _history.sublist(0, _maxHistoryItems);
      }

      await _persistHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao salvar resultado: $e');
    }
  }

  /// Adiciona resultado a partir de valores brutos
  Future<void> addResult({
    required double downloadSpeed,
    required double uploadSpeed,
    required int ping,
    String? serverName,
  }) async {
    final result = SpeedTestResult(
      timestamp: DateTime.now(),
      downloadSpeed: downloadSpeed,
      uploadSpeed: uploadSpeed,
      ping: ping,
      serverName: serverName,
    );
    await saveResult(result);
  }

  /// Limpa todo o histórico
  Future<void> clearHistory() async {
    try {
      _history.clear();
      await _persistHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao limpar histórico: $e');
    }
  }

  /// Persiste no storage
  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _history.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_historyKey, historyJson);
  }
}
```

---

### `lib/core/services/suporte_service.dart`
> Serviço de negócio

```dart
// ARQUIVO: lib/core/services/suporte_service.dart
// DESCRIÇÃO: Serviço para criar tickets de suporte

import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SuporteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  SuporteService();

  /// Cria um ticket de suporte
  /// 1. Faz o upload da imagem (se houver) para o Firebase Storage
  /// 2. Cria o documento no Firestore via Cloud Function
  Future<String> createTicket({
    required String subject,
    required String message,
    required XFile? imageFile,
    required String providerId,
    required String providerName,
    required String userEmail,
  }) async {
    String? imageUrl;
    String? requesterUid = FirebaseAuth.instance.currentUser?.uid;

    if (requesterUid == null) {
      throw Exception('Falha na autenticação. Usuário não logado.');
    }

    if (imageFile != null) {
      // Faz upload da imagem
      final fileExtension = imageFile.name.split('.').last;
      final storageRef = _storage.ref().child(
          'ticket_images/$providerId/${DateTime.now().millisecondsSinceEpoch}.$fileExtension');

      await storageRef.putData(await imageFile.readAsBytes());
      imageUrl = await storageRef.getDownloadURL();
    }

    // Cria a requisição para a Cloud Function
    final requestId = _firestore.collection('function_requests').doc().id;
    final requestDocRef =
        _firestore.collection('function_requests').doc(requestId);
    final responseDocRef =
        _firestore.collection('function_responses').doc(requestId);

    try {
      // Envia a requisição
      await requestDocRef.set({
        'type': 'CREATE_TICKET',
        'createdAt': FieldValue.serverTimestamp(),
        'payload': {
          'subject': subject,
          'message': message,
          'providerName': providerName,
          'providerId': providerId,
          'userEmail': userEmail,
          'imageUrl': imageUrl,
          'requesterUid': requesterUid,
        },
      });

      // Aguarda a resposta com timeout de 60 segundos
      final responseSnapshot = await responseDocRef
          .snapshots()
          .firstWhere((snap) => snap.exists)
          .timeout(const Duration(seconds: 60));

      final response = responseSnapshot.data();

      if (response == null || response['completedAt'] == null) {
        throw Exception('Resposta incompleta do servidor.');
      }

      if (response['error'] != null) {
        throw Exception(response['error']);
      }

      return response['result']['ticketId'] ?? 'ID_NÃO_INFORMADO';
    } on TimeoutException {
      throw TimeoutException(
          'O servidor demorou muito para processar o ticket.');
    } catch (e) {
      if (e.toString().contains('PERMISSION_DENIED')) {
        throw Exception('Erro de permissão. Seu login pode estar inválido.');
      }
      rethrow;
    }
  }
}
```

## 🧩 Core / Widgets
> Componentes visuais reutilizáveis


---

### `lib/core/widgets/accessibility_widgets.dart`
> Widget reutilizável

```dart
/// Widgets de Acessibilidade
/// Componentes com suporte a screen readers e acessibilidade

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Botão acessível com Semantics integrado
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final String semanticLabel;
  final String? semanticHint;
  final bool excludeFromSemantics;

  const AccessibleButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
    this.excludeFromSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      excludeSemantics: excludeFromSemantics,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        child: child,
      ),
    );
  }
}

/// IconButton acessível
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  final Color? color;
  final double size;
  final EdgeInsets padding;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.color,
    this.size = 24,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: IconButton(
        icon: Icon(icon, color: color, size: size),
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        padding: padding,
        tooltip: semanticLabel,
      ),
    );
  }
}

/// Card acessível com descrição para screen readers
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final String semanticLabel;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final BoxDecoration? decoration;

  const AccessibleCard({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.onTap,
    this.padding,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: decoration ??
          BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
      child: child,
    );

    return Semantics(
      label: semanticLabel,
      container: true,
      child: onTap != null
          ? GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onTap!();
              },
              child: cardContent,
            )
          : cardContent,
    );
  }
}

/// Status indicator acessível
class AccessibleStatusIndicator extends StatelessWidget {
  final bool isConnected;
  final String? customLabel;

  const AccessibleStatusIndicator({
    super.key,
    required this.isConnected,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = isConnected ? 'Conectado' : 'Desconectado';
    final statusColor = isConnected ? Colors.green : Colors.red;

    return Semantics(
      label: customLabel ?? 'Status da conexão: $statusText',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper para adicionar Semantics a qualquer widget
class SemanticWrapper extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final bool isButton;
  final bool isHeader;
  final bool isLink;

  const SemanticWrapper({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.isButton = false,
    this.isHeader = false,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      header: isHeader,
      link: isLink,
      child: child,
    );
  }
}

/// Extension para adicionar acessibilidade rapidamente
extension AccessibilityExtension on Widget {
  Widget withSemantics({
    required String label,
    String? hint,
    bool isButton = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      child: this,
    );
  }
}
```

---

### `lib/core/widgets/animation_widgets.dart`
> Widget reutilizável

```dart
/// Widgets de Animação Reutilizáveis
/// Componentes com animações otimizadas para performance

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animação FadeSlideIn - Entrada suave com fade + slide
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final Duration duration;
  final Offset slideOffset;
  final Curve curve;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.duration = const Duration(milliseconds: 500),
    this.slideOffset = const Offset(0, 0.15),
    this.curve = Curves.easeOut,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _offset = Tween<Offset>(begin: widget.slideOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delayMs > 0) {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

/// Animação ScalePress - Efeito de escala ao pressionar
class ScalePressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleDown;
  final Duration duration;
  final bool enableHaptic;

  const ScalePressButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.enableHaptic = true,
  });

  @override
  State<ScalePressButton> createState() => _ScalePressButtonState();
}

class _ScalePressButtonState extends State<ScalePressButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (widget.enableHaptic) HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleDown : 1.0,
        duration: widget.duration,
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}

/// Animação Shimmer - Loading placeholder
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                0.0,
                0.5 + _animation.value * 0.25,
                1.0,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Animação Pulse - Pulsação suave (para indicadores de status)
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

/// RepaintBoundary wrapper para otimização
class OptimizedWidget extends StatelessWidget {
  final Widget child;

  const OptimizedWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: child);
  }
}

/// Staggered animation para listas
class StaggeredListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final int baseDelayMs;

  const StaggeredListItem({
    super.key,
    required this.child,
    required this.index,
    this.baseDelayMs = 50,
  });

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delayMs: index * baseDelayMs,
      child: child,
    );
  }
}
```

---

### `lib/core/widgets/app_button.dart`
> Widget reutilizável

```dart
import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 12),
                ],
                Text(label),
              ],
            ),
    );
  }
}
```

---

### `lib/core/widgets/app_colors.dart`
> Widget reutilizável

```dart
import 'package:flutter/material.dart';

/// Cores padrão do aplicativo
/// Essas cores são usadas como fallback quando o provedor não define cores customizadas
class AppColors {
  // Cores principais
  static const Color primaryBlue = Color(0xFF1E6FF8);
  static const Color primaryDark = Color(0xFF0A1929);
  static const Color accent = Color(0xFF00D9FF);
  
  // Background
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color darkBackground = Color(0xFF0F172A);
  
  // Texto
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  
  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Aliases para compatibilidade com diferentes layouts
  static const Color primary = primaryBlue;
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFE2E8F0);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, Color(0xFF8B5CF6)],
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );
}
```

---

### `lib/core/widgets/dashboard_card.dart`
> Widget reutilizável

```dart
import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const DashboardCard(
      {super.key, required this.child, this.padding, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
            blurRadius: 16,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: child,
    );
  }
}
```

---

### `lib/core/widgets/empty_state.dart`
> Widget reutilizável

```dart
// ARQUIVO: lib/core/widgets/empty_state.dart
// DESCRIÇÃO: Widget para estados vazios com ilustração e mensagem

import 'package:flutter/material.dart';

/// Widget para exibir estado vazio com ilustração
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone com efeito
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (iconColor ?? theme.primaryColor).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: iconColor ?? theme.primaryColor.withValues(alpha: 0.7),
              ),
            ),

            const SizedBox(height: 24),

            // Título
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            // Mensagem opcional
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Botão de ação opcional
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado vazio para lista de faturas
class NoInvoicesState extends StatelessWidget {
  final VoidCallback? onRefresh;

  const NoInvoicesState({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'Nenhuma fatura encontrada',
      message: 'Você está em dia! Não há faturas pendentes.',
      iconColor: Colors.green,
      actionLabel: onRefresh != null ? 'Atualizar' : null,
      onAction: onRefresh,
    );
  }
}

/// Estado vazio para diagnóstico sem dados
class NoDiagnosticDataState extends StatelessWidget {
  final VoidCallback? onStart;

  const NoDiagnosticDataState({super.key, this.onStart});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.network_check,
      title: 'Iniciar Diagnóstico',
      message: 'Clique no botão abaixo para verificar sua conexão.',
      actionLabel: onStart != null ? 'Iniciar' : null,
      onAction: onStart,
    );
  }
}

/// Estado de erro genérico
class ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Ops! Algo deu errado',
      message: message ?? 'Não foi possível carregar os dados.',
      iconColor: Colors.red,
      actionLabel: onRetry != null ? 'Tentar novamente' : null,
      onAction: onRetry,
    );
  }
}

/// Estado de sem conexão
class NoConnectionState extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoConnectionState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.wifi_off,
      title: 'Sem conexão',
      message: 'Verifique sua conexão com a internet e tente novamente.',
      iconColor: Colors.orange,
      actionLabel: onRetry != null ? 'Tentar novamente' : null,
      onAction: onRetry,
    );
  }
}
```

---

### `lib/core/widgets/glass_card.dart`
> Widget reutilizável

```dart
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? borderColor;
  final List<BoxShadow>? shadows;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.borderColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final Color fallbackBorder = borderColor ?? Colors.white.withValues(alpha: 0.08);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xAA0F172A),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: fallbackBorder),
            boxShadow: shadows ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 18),
                  ),
                ],
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
```

---

### `lib/core/widgets/offline_banner.dart`
> Widget reutilizável

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    // Use red for error state
    final backgroundColor = Colors.red.shade700;

    return AnimatedSlide(
      offset: isOnline ? const Offset(0, -1) : Offset.zero,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      child: Material(
        elevation: 8,
        color: backgroundColor,
        child: SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Sem conexão com a internet',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

### `lib/core/widgets/premium_invoice_card.dart`
> Widget reutilizável

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Card premium para exibir fatura com design arredondado e colorido
class PremiumInvoiceCard extends StatelessWidget {
  final double amount;
  final DateTime dueDate;
  final VoidCallback onPay;
  final Color? customColor;

  const PremiumInvoiceCard({
    super.key,
    required this.amount,
    required this.dueDate,
    required this.onPay,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = customColor ?? const Color(0xFF1E6FF8);
    final isOverdue = dueDate.isBefore(DateTime.now());
    final statusText = isOverdue ? 'Vencida' : 'Em aberto';
    final statusColor = isOverdue ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fatura atual',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(amount),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vencimento: ${DateFormat("d 'de' MMMM", 'pt_BR').format(dueDate)}',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPay,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'PAGAR AGORA',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### `lib/core/widgets/skeleton_loader.dart`
> Widget reutilizável

```dart
// ARQUIVO: lib/core/widgets/skeleton_loader.dart
// DESCRIÇÃO: Widget de skeleton loading para estados de carregamento modernos

import 'package:flutter/material.dart';

/// Widget de skeleton loading animado
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
    this.isCircle = false,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.isCircle ? widget.height : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.isCircle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton para um card de fatura
class InvoiceSkeletonCard extends StatelessWidget {
  const InvoiceSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonLoader(width: 100, height: 24),
                Spacer(),
                SkeletonLoader(width: 80, height: 28, borderRadius: 14),
              ],
            ),
            SizedBox(height: 12),
            SkeletonLoader(width: 150, height: 14),
            SizedBox(height: 16),
            SkeletonLoader(height: 44, borderRadius: 8),
          ],
        ),
      ),
    );
  }
}

/// Skeleton para uma lista de faturas
class InvoiceListSkeleton extends StatelessWidget {
  final int itemCount;

  const InvoiceListSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const InvoiceSkeletonCard(),
    );
  }
}

/// Skeleton para o card de ONU
class OnuSkeletonCard extends StatelessWidget {
  const OnuSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonLoader(width: 24, height: 24, isCircle: true),
                SizedBox(width: 12),
                SkeletonLoader(width: 150, height: 20),
                Spacer(),
                SkeletonLoader(width: 32, height: 32, isCircle: true),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: SkeletonLoader(height: 80, borderRadius: 12)),
                SizedBox(width: 12),
                Expanded(child: SkeletonLoader(height: 80, borderRadius: 12)),
              ],
            ),
            SizedBox(height: 16),
            SkeletonLoader(height: 44, borderRadius: 12),
            SizedBox(height: 12),
            SkeletonLoader(width: 200, height: 14),
            SizedBox(height: 8),
            SkeletonLoader(width: 160, height: 14),
          ],
        ),
      ),
    );
  }
}
```

---

### `lib/core/widgets/troubleshooter_card.dart`
> Widget reutilizável

```dart
import 'package:flutter/material.dart';
import '../models/diagnostico_state.dart';
import 'dashboard_card.dart';

class TroubleshootingRecommendation {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback? action;
  final String? actionLabel;

  TroubleshootingRecommendation({
    required this.title,
    required this.description,
    required this.icon,
    this.color = Colors.orangeAccent,
    this.action,
    this.actionLabel,
  });
}

class TroubleshooterCard extends StatelessWidget {
  final DiagnosticoState state;
  final VoidCallback? onRetry;
  final bool isDarkLayout;

  const TroubleshooterCard({
    super.key,
    required this.state,
    this.onRetry,
    this.isDarkLayout = false,
  });

  List<TroubleshootingRecommendation> _analyzeProblems(BuildContext context) {
    final List<TroubleshootingRecommendation> problems = [];

    String? wifiResult =
        state.testResultsDisplay['wifiInfo']?['result'] as String?;
    String? pingResult =
        state.testResultsDisplay['pingGateway']?['result'] as String?;
    String? batteryResult =
        state.testResultsDisplay['batteryInfo']?['result'] as String?;
    String? lanResult =
        state.testResultsDisplay['lanScan']?['result'] as String?;

    // 1. Análise de Sinal Wi-Fi
    if (wifiResult != null) {
      if (wifiResult.contains("Muito Fraca") || wifiResult.contains("Fraca")) {
        problems.add(TroubleshootingRecommendation(
          title: "Sinal Wi-Fi Fraco",
          description:
              "Você está longe do roteador ou há obstáculos (paredes/espelhos). Aproxime-se para melhorar a velocidade.",
          icon: Icons.wifi_off,
          color: Colors.redAccent,
        ));
      }
      if (wifiResult.contains("2.4 GHz")) {
        problems.add(TroubleshootingRecommendation(
          title: "Rede 2.4GHz Detectada",
          description:
              "Esta frequência é mais lenta e sofre interferência. Se possível, conecte-se à rede 5GHz do seu roteador.",
          icon: Icons.network_check,
          color: Colors.orangeAccent,
        ));
      }
    }

    // 2. Análise de Bateria
    if (batteryResult != null &&
        (batteryResult.contains("⚠️") ||
            batteryResult.contains("Nível: 1") ||
            batteryResult.contains("Nível: 0"))) {
      problems.add(TroubleshootingRecommendation(
        title: "Economia de Energia",
        description:
            "Bateria baixa reduz a potência da antena Wi-Fi do celular. Conecte ao carregador.",
        icon: Icons.battery_alert,
        color: Colors.orange,
      ));
    }

    // 3. Análise de Jitter/Latência
    if (pingResult != null) {
      try {
        final jitterLine = pingResult
            .split('\n')
            .firstWhere((l) => l.contains('Jitter'), orElse: () => '');
        if (jitterLine.isNotEmpty) {
          final jitterVal =
              double.tryParse(jitterLine.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                  0;
          if (jitterVal > 30) {
            problems.add(TroubleshootingRecommendation(
              title: "Instabilidade (Jitter)",
              description:
                  "Sua conexão está oscilando. Reinicie o roteador (tire da tomada por 10s).",
              icon: Icons.waves,
              color: Colors.redAccent,
            ));
          }
        }
      } catch (_) {}
    }

    // 4. Análise de DNS Lento
    if (wifiResult != null && wifiResult.contains("Tempo DNS")) {
      try {
        final dnsLine = wifiResult
            .split('\n')
            .firstWhere((l) => l.contains('Tempo DNS'), orElse: () => '');
        final dnsVal =
            int.tryParse(dnsLine.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        if (dnsVal > 150) {
          problems.add(TroubleshootingRecommendation(
            title: "Navegação Lenta (DNS)",
            description:
                "Demora para encontrar sites. Reinicie o roteador para limpar o cache.",
            icon: Icons.dns,
            color: Colors.orangeAccent,
          ));
        }
      } catch (_) {}
    }

    // 5. Dispositivos na Rede
    if (lanResult != null) {
      try {
        final devLine = lanResult
            .split('\n')
            .firstWhere((l) => l.contains('Dispositivos'), orElse: () => '');
        final devCount =
            int.tryParse(devLine.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        if (devCount > 12) {
          problems.add(TroubleshootingRecommendation(
            title: "Rede Congestionada?",
            description:
                "Detectamos $devCount dispositivos. Muitos aparelhos simultâneos podem dividir a velocidade.",
            icon: Icons.devices,
            color: Colors.blueGrey,
          ));
        }
      } catch (_) {}
    }

    return problems;
  }

  @override
  Widget build(BuildContext context) {
    final bool isFinished = !state.isTesting &&
        (state.testResultsDisplay.values.any((r) =>
            r['status'] == TestStatus.success ||
            r['status'] == TestStatus.error));

    if (!isFinished) return const SizedBox.shrink();

    final recommendations = _analyzeProblems(context);

    final cardColor = isDarkLayout ? const Color(0xFF1C1C1E) : Colors.white;
    final descriptionColor = isDarkLayout ? const Color(0xFF8E8E93) : null;

    if (recommendations.isEmpty) {
      return DashboardCard(
        color: cardColor,
        child: Row(
          children: [
            const Icon(Icons.thumb_up_alt, color: Colors.greenAccent, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Sua conexão está ótima!",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.greenAccent)),
                  const SizedBox(height: 4),
                  Text("Nenhum problema detectado nos testes.",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: descriptionColor)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return DashboardCard(
      color: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build_circle, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Text("Sugestões de Melhoria",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.amber)),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations
              .map((rec) => _buildRecommendationItem(context, rec)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                if (onRetry != null) onRetry!();
              },
              style: OutlinedButton.styleFrom(
                  foregroundColor: isDarkLayout
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  side: isDarkLayout
                      ? const BorderSide(color: Colors.white54)
                      : null),
              child: const Text("Refazer Testes"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
      BuildContext context, TroubleshootingRecommendation rec) {
    final textColor = isDarkLayout ? Colors.white : null;
    final descriptionColor = isDarkLayout ? const Color(0xFF8E8E93) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: rec.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(rec.icon, color: rec.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor)),
                const SizedBox(height: 4),
                Text(rec.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: descriptionColor)),
                if (rec.action != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: InkWell(
                      onTap: rec.action,
                      child: Text(
                        rec.actionLabel ?? "Resolver",
                        style: TextStyle(
                            color: rec.color,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## 📄 Core / Pages
> Páginas compartilhadas entre layouts


---

### `lib/core/pages/shared_consumo_page.dart`
> Página compartilhada

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/consumo_provider.dart';
import '../../layouts/layout_03/theme.dart';
import '../../layouts/layout_04/theme.dart'; // Ensure this exists or mock it if generic

class ConsumoPage extends ConsumerStatefulWidget {
  const ConsumoPage({super.key});

  @override
  ConsumerState<ConsumoPage> createState() => _ConsumoPageState();
}

class _ConsumoPageState extends ConsumerState<ConsumoPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final configProvider = ref.watch(configurationProvider);
    final consumoState =
        ref.watch(consumoViewModelProvider); // Watch new provider
    final usuario = authState.value;
    final config = configProvider.providerConfig;
    final layoutType = config?.layoutType;
    final isLayout05 = layoutType == 'layout_05';
    // Layout 06 is specifically handled now
    final isLayout06 = layoutType == 'layout_06';
    final isDarkLayout = layoutType == 'layout_06';

    Color backgroundColor;
    Color appBarColor;
    Color appBarTextColor;
    if (isLayout06) {
      // Layout 06 Specific Colors
      backgroundColor = Layout04Theme.background;
      appBarColor = Layout04Theme.background;
      appBarTextColor = Layout04Theme.textPrimary;
    } else if (isDarkLayout) {
      backgroundColor = const Color(0xFF0A0A0A);
      appBarColor = const Color(0xFF0A0A0A);
      appBarTextColor = Colors.white;
    } else if (isLayout05) {
      backgroundColor = Layout03Theme.background;
      appBarColor = Layout03Theme.background;
      appBarTextColor = Layout03Theme.textDark;
    } else {
      backgroundColor = theme.scaffoldBackgroundColor;
      appBarColor = theme.primaryColor;
      appBarTextColor = Colors.white;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Meu Consumo', style: TextStyle(color: appBarTextColor)),
        backgroundColor: appBarColor,
        iconTheme: IconThemeData(color: appBarTextColor),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (isLayout06) {
            await ref.read(consumoViewModelProvider.notifier).loadData();
          } else {
            // Refresh logic for other layouts if any, or remove delay
          }
        },
        child: isLayout06
            ? _buildLayout06Content(context, theme, consumoState)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Card principal - Plano Ilimitado
                  _buildUnlimitedCard(theme, usuario?.plano ?? 'Plano Fibra',
                      config?.name ?? 'Provedor', isLayout05,
                      isDarkLayout: isDarkLayout),

                  const SizedBox(height: 16),

                  // Card de velocidades
                  _buildSpeedCard(theme, usuario, isLayout05,
                      isDarkLayout: isDarkLayout),

                  const SizedBox(height: 16),

                  // Card de status da conexão
                  _buildConnectionStatusCard(theme, isLayout05,
                      isDarkLayout: isDarkLayout),

                  const SizedBox(height: 16),

                  // Card de benefícios
                  _buildBenefitsCard(theme, isLayout05,
                      isDarkLayout: isDarkLayout),

                  const SizedBox(height: 180), // Padding for BottomNav
                ],
              ),
      ),
    );
  }

  // --- LAYOUT 06 SPECIFIC IMPLEMENTATION ---

  Widget _buildLayout06Content(
      BuildContext context, ThemeData theme, ConsumoState state) {
    // Parse consumed data
    final data = state.data;
    final usedGb = data?['usedGb'] as double? ?? 0.0;
    final planName = data?['planName'] as String? ?? 'Carregando...';
    // final period = data?['period'] as String? ?? '';
    final details = data?['details'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Month Selector
        _buildMonthSelector(theme, state),
        const SizedBox(height: 24),

        if (state.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (state.error != null)
          Center(
              child: Text('Erro: ${state.error}',
                  style: const TextStyle(color: Colors.red)))
        else ...[
          // Main Consumption Card (Summary)
          _buildL06SummaryCard(theme, usedGb, planName),

          const SizedBox(height: 24),

          // Chart Section
          if (details.isNotEmpty)
            _buildL06Chart(theme, details)
          else
            _buildL06Chart(theme, []), // Force chart render with empty data
        ],

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildMonthSelector(ThemeData theme, ConsumoState state) {
    final now = DateTime.now();
    // Generate last 6 months
    final months = List.generate(6, (index) {
      final date = DateTime(now.year, now.month - index, 1);
      return date;
    });

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: months.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = months[index];
          final isSelected = date.month == state.selectedMonth &&
              date.year == state.selectedYear;
          final label = DateFormat('MMM yyyy', 'pt_BR')
              .format(date); // Requires intl initialized with pt_BR

          return ChoiceChip(
            label: Text(label.toUpperCase()),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                ref
                    .read(consumoViewModelProvider.notifier)
                    .changeMonth(date.month, date.year);
              }
            },
            selectedColor: theme.primaryColor,
            backgroundColor: const Color(0xFF1C1C1E),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), side: BorderSide.none),
          );
        },
      ),
    );
  }

  Widget _buildL06SummaryCard(ThemeData theme, double usedGb, String planName) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.2),
            const Color(0xFF1C1C1E)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Consumo Total',
              style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '${usedGb.toStringAsFixed(2)} GB',
            style: const TextStyle(
                color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(planName,
                style: TextStyle(
                    color: theme.primaryColor, fontWeight: FontWeight.w600)),
          )
        ],
      ),
    );
  }

  Widget _buildL06Chart(ThemeData theme, List<dynamic> details) {
    // Process details into chart spots
    // Assuming 'details' has { data: 'YYYY-MM-DD', download: bytes, upload: bytes }
    // We'll map day of month (x) to GB (y)

    // Group/Sum by day if needed, but assuming one entry per day or session

    // Mocking logic for safety if structure is unknown, but trying to parse
    List<FlSpot> spots = [];

    // We will show dots for daily total usage (Download + Upload)
    // Map to aggregate by day
    Map<int, double> dailyUsage = {};

    for (var item in details) {
      try {
        // Try to parse date
        // item['data_inicio'] or item['data']?
        // SGP API 'extratouso' usually returns: { data: '2023-10-01', download: 123, upload: 123 }
        String dateStr = item['data'] ?? '';
        if (dateStr.isNotEmpty) {
          DateTime date = DateTime.parse(dateStr);
          double down =
              double.tryParse(item['download']?.toString() ?? '0') ?? 0;
          double up = double.tryParse(item['upload']?.toString() ?? '0') ?? 0;
          double totalGb = (down + up) / (1024 * 1024 * 1024);

          dailyUsage[date.day] = (dailyUsage[date.day] ?? 0) + totalGb;
        }
      } catch (e) {
        // ignore
      }
    }

    dailyUsage.forEach((day, gb) {
      spots.add(FlSpot(day.toDouble(), gb));
    });

    spots.sort((a, b) => a.x.compareTo(b.x));

    // If no real data, generate mock zero spots for the last 5 days so the chart frame appears
    if (spots.isEmpty) {
      final now = DateTime.now();
      for (int i = 4; i >= 0; i--) {
        spots.add(FlSpot(now.day - i.toDouble(), 0));
      }
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Evolução Diária',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 10));
                      },
                      interval: 1,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: theme.primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlimitedCard(
      ThemeData theme, String planName, String providerName, bool isLayout05,
      {bool isDarkLayout = false}) {
    final decoration = isDarkLayout
        ? BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
          )
        : (isLayout05
            ? Layout03Theme.neumorphicDecoration
            : BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor.withValues(alpha: 0.1),
                    theme.primaryColor.withValues(alpha: 0.05),
                  ],
                ),
              ));

    return Card(
      elevation: isLayout05 ? 0 : 4,
      color: isLayout05 ? Colors.transparent : null,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: decoration,
        child: Column(
          children: [
            // Ícone de infinito animado
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withValues(alpha: 0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.all_inclusive,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              '∞ ILIMITADO',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Navegue sem limites!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                planName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedCard(ThemeData theme, dynamic usuario, bool isLayout05,
      {bool isDarkLayout = false}) {
    // Extract speed from plan name (e.g., "100 Mega" -> 100)
    String speedValue = '100';
    String planName = usuario?.plano ?? 'Plano Fibra';
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(planName);
    if (match != null) {
      speedValue = match.group(1)!;
    }

    final decoration = isDarkLayout
        ? BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
          )
        : (isLayout05
            ? Layout03Theme.neumorphicDecoration
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ));

    return Container(
      decoration: isLayout05 ? decoration : null,
      child: Card(
        elevation: isLayout05 ? 0 : 1,
        color: isLayout05 ? Colors.transparent : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.speed,
                      color: isLayout05
                          ? Layout03Theme.primary
                          : theme.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    'Velocidades Contratadas',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkLayout
                          ? Colors.white
                          : (isLayout05 ? Layout03Theme.textDark : null),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildSpeedItem(
                      theme,
                      'Download',
                      '$speedValue Mbps',
                      Icons.arrow_downward,
                      Colors.green,
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: theme.dividerColor,
                  ),
                  Expanded(
                    child: _buildSpeedItem(
                      theme,
                      'Upload',
                      '$speedValue Mbps',
                      Icons.arrow_upward,
                      Colors.blue,
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedItem(
      ThemeData theme, String label, String value, IconData icon, Color color,
      {bool isLayout05 = false, bool isDarkLayout = false}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDarkLayout
                ? Colors.white
                : (isLayout05 ? Layout03Theme.textDark : null),
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isLayout05
                ? Layout03Theme.textGrey
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatusCard(ThemeData theme, bool isLayout05,
      {bool isDarkLayout = false}) {
    final decoration = isDarkLayout
        ? BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
          )
        : (isLayout05
            ? Layout03Theme.neumorphicDecoration
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ));

    return Container(
      decoration: isLayout05 ? decoration : null,
      child: Card(
        elevation: isLayout05 ? 0 : 1,
        color: isLayout05 ? Colors.transparent : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wifi,
                      color: isLayout05
                          ? Layout03Theme.primary
                          : theme.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    'Status da Conexão',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkLayout
                          ? Colors.white
                          : (isLayout05 ? Layout03Theme.textDark : null),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Ativo',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildStatusRow(
                  theme, 'Tipo de Conexão', 'Fibra Óptica', Icons.cable,
                  isDarkLayout: isDarkLayout),
              _buildStatusRow(
                  theme, 'Franquia', 'Ilimitada', Icons.all_inclusive,
                  isDarkLayout: isDarkLayout),
              _buildStatusRow(
                  theme, 'Fidelidade', 'Sem fidelidade', Icons.lock_open,
                  isDarkLayout: isDarkLayout),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(
      ThemeData theme, String label, String value, IconData icon,
      {bool isDarkLayout = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDarkLayout ? Colors.white70 : null,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDarkLayout ? Colors.white : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard(ThemeData theme, bool isLayout05,
      {bool isDarkLayout = false}) {
    final decoration = isDarkLayout
        ? BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
          )
        : (isLayout05
            ? Layout03Theme.neumorphicDecoration
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ));

    return Container(
      decoration: isLayout05 ? decoration : null,
      child: Card(
        elevation: isLayout05 ? 0 : 1,
        color: isLayout05 ? Colors.transparent : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 12),
                  Text(
                    'Benefícios do Seu Plano',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkLayout
                          ? Colors.white
                          : (isLayout05 ? Layout03Theme.textDark : null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBenefitItem(theme, Icons.all_inclusive,
                  'Internet ilimitada', isDarkLayout),
              _buildBenefitItem(
                  theme, Icons.bolt, 'Velocidade garantida', isDarkLayout),
              _buildBenefitItem(
                  theme, Icons.support_agent, 'Suporte 24/7', isDarkLayout),
              _buildBenefitItem(
                  theme, Icons.router, 'Wi-Fi de alta qualidade', isDarkLayout),
              _buildBenefitItem(
                  theme, Icons.security, 'Conexão segura', isDarkLayout),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(
      ThemeData theme, IconData icon, String text, bool isDarkLayout) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDarkLayout ? Colors.white : null,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### `lib/core/pages/shared_contrato_page.dart`
> Página compartilhada

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../layouts/layout_03/theme.dart';

class ContratoPage extends ConsumerWidget {
  const ContratoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configProvider = ref.watch(configurationProvider);
    final authState = ref.watch(authNotifierProvider);
    final usuario = authState.value;
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    final layoutType = configProvider.providerConfig?.layoutType;
    final isLayout05 = layoutType == 'layout_05';
    final isDarkLayout = layoutType == 'layout_06';

    Color backgroundColor;
    Color appBarColor;
    Color appBarTextColor;
    if (isDarkLayout) {
      backgroundColor = const Color(0xFF0A0A0A);
      appBarColor = const Color(0xFF0A0A0A);
      appBarTextColor = Colors.white;
    } else if (isLayout05) {
      backgroundColor = Layout03Theme.background;
      appBarColor = Layout03Theme.background;
      appBarTextColor = Layout03Theme.textDark;
    } else {
      backgroundColor = theme.scaffoldBackgroundColor;
      appBarColor = theme.primaryColor;
      appBarTextColor = Colors.white;
    }

    if (usuario == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text('Meu Contrato', style: TextStyle(color: appBarTextColor)),
          backgroundColor: appBarColor,
          iconTheme: IconThemeData(color: appBarTextColor),
        ),
        body: const Center(child: Text('Usuário não logado')),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Meu Contrato', style: TextStyle(color: appBarTextColor)),
        backgroundColor: appBarColor,
        iconTheme: IconThemeData(color: appBarTextColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Card do Cliente
            _buildAdaptiveCard(
              isLayout05: isLayout05,
              isDarkLayout: isDarkLayout,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: isLayout05
                            ? Layout03Theme.primary.withValues(alpha: 0.1)
                            : primaryColor.withValues(alpha: 0.1),
                        child: Icon(Icons.person,
                            size: 32,
                            color: isLayout05
                                ? Layout03Theme.primary
                                : primaryColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              usuario.nome,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDarkLayout
                                    ? Colors.white
                                    : (isLayout05
                                        ? Layout03Theme.textDark
                                        : null),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CPF/CNPJ: ${_formatCpfCnpj(usuario.cpfCnpj)}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: isDarkLayout
                                    ? const Color(0xFF8E8E93)
                                    : (isLayout05
                                        ? Layout03Theme.textGrey
                                        : textTheme.bodySmall?.color),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card do Plano
            _buildAdaptiveCard(
              isLayout05: isLayout05,
              isDarkLayout: isDarkLayout,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plano Contratado',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkLayout
                            ? Colors.white
                            : (isLayout05 ? Layout03Theme.textDark : null),
                      )),
                  const Divider(height: 24),
                  _buildInfoRow(context,
                      icon: Icons.wifi,
                      label: 'Plano',
                      value: usuario.plano,
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 12),
                  _buildInfoRow(context,
                      icon: Icons.check_circle_outline,
                      label: 'Status',
                      value: usuario.status,
                      valueColor: _getStatusColor(usuario.status),
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout),
                  if (usuario.contratoId != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(context,
                        icon: Icons.tag,
                        label: 'Contrato ID',
                        value: '#${usuario.contratoId}',
                        isLayout05: isLayout05,
                        isDarkLayout: isDarkLayout),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card Financeiro
            _buildAdaptiveCard(
              isLayout05: isLayout05,
              isDarkLayout: isDarkLayout,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informações Financeiras',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkLayout
                            ? Colors.white
                            : (isLayout05 ? Layout03Theme.textDark : null),
                      )),
                  const Divider(height: 24),
                  _buildInfoRow(context,
                      icon: Icons.attach_money,
                      label: 'Valor',
                      value: 'R\$ ${usuario.valorFatura}',
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 12),
                  _buildInfoRow(context,
                      icon: Icons.calendar_today,
                      label: 'Vencimento',
                      value: 'Dia ${usuario.vencimentoFatura}',
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card do Provedor
            if (configProvider.providerConfig != null)
              _buildAdaptiveCard(
                isLayout05: isLayout05,
                isDarkLayout: isDarkLayout,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Provedor',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkLayout
                              ? Colors.white
                              : (isLayout05 ? Layout03Theme.textDark : null),
                        )),
                    const Divider(height: 24),
                    _buildInfoRow(context,
                        icon: Icons.business,
                        label: 'Empresa',
                        value: configProvider.providerConfig!.name,
                        isLayout05: isLayout05,
                        isDarkLayout: isDarkLayout),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdaptiveCard(
      {required Widget child,
      required bool isLayout05,
      bool isDarkLayout = false}) {
    if (isDarkLayout) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      );
    }
    if (isLayout05) {
      return Container(
        decoration: Layout03Theme.neumorphicDecoration,
        padding: const EdgeInsets.all(16),
        child: child,
      );
    }
    return DashboardCard(child: child);
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon,
      required String label,
      required String value,
      Color? valueColor,
      required bool isLayout05,
      bool isDarkLayout = false}) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon,
            size: 20,
            color: isDarkLayout
                ? const Color(0xFF00D9FF)
                : (isLayout05
                    ? Layout03Theme.textGrey
                    : textTheme.bodySmall?.color)),
        const SizedBox(width: 12),
        Text('$label:',
            style: textTheme.bodyMedium?.copyWith(
              color: isDarkLayout
                  ? const Color(0xFF8E8E93)
                  : (isLayout05 ? Layout03Theme.textDark : null),
            )),
        const Spacer(),
        Text(
          value,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ??
                (isDarkLayout
                    ? Colors.white
                    : (isLayout05 ? Layout03Theme.textDark : null)),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ativo':
        return Colors.green;
      case 'bloqueado':
        return Colors.red;
      case 'pendente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatCpfCnpj(String value) {
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 11) {
      return '${clean.substring(0, 3)}.${clean.substring(3, 6)}.${clean.substring(6, 9)}-${clean.substring(9)}';
    } else if (clean.length == 14) {
      return '${clean.substring(0, 2)}.${clean.substring(2, 5)}.${clean.substring(5, 8)}/${clean.substring(8, 12)}-${clean.substring(12)}';
    }
    return value;
  }
}
```

---

### `lib/core/pages/shared_diagnostico_page.dart`
> Página compartilhada

```dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../layouts/layout_03/theme.dart';
import '../../core/services/diagnostico_service.dart';
import '../../core/services/onu_wifi_service.dart';

import '../../core/models/diagnostico_state.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/troubleshooter_card.dart';
import '../../core/utils/pdf_generator_service.dart';

class DiagnosticoPage extends ConsumerStatefulWidget {
  const DiagnosticoPage({super.key});

  @override
  ConsumerState<DiagnosticoPage> createState() => _DiagnosticoPageState();
}

class _DiagnosticoPageState extends ConsumerState<DiagnosticoPage> {
  late final DiagnosticoService _service;
  OnuWifiService? _onuWifiService;
  bool _serviceInitialized = false;

  // ONU State
  bool _loadingOnu = false;
  OnuData? _onuData;
  String? _onuError;

  // WiFi State
  bool _loadingWifi = false;
  List<WifiNetwork> _wifiNetworks = [];
  String? _wifiError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serviceInitialized) {
      final configProvider = ref.read(configurationProvider);
      final providerConfig = configProvider.providerConfig!;
      final authState = ref.read(authNotifierProvider);
      final usuario = authState.value;

      _service =
          DiagnosticoService(providerConfig: providerConfig, context: context);

      // Initialize ONU/WiFi service
      if (usuario != null) {
        _onuWifiService = OnuWifiService(
          apiUrl: providerConfig.apiUrl,
          cpfCnpj: usuario.cpfCnpj,
          senha: usuario.senha,
          contrato: usuario.contratoId?.toString(),
          sgpParams: {
            'token': providerConfig.config.integrations.apiToken,
            'app': providerConfig.config.integrations.appName,
            'sgpBaseUrl': providerConfig.config.integrations.sgpBaseUrl,
          },
        );
      }
      _serviceInitialized = true;
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    return StreamBuilder<DiagnosticoState>(
      stream: _service.stateStream,
      initialData: DiagnosticoState.initial(),
      builder: (context, snapshot) {
        final state = snapshot.data!;

        final configProvider = ref.watch(configurationProvider);
        final layoutType = configProvider.providerConfig?.layoutType;
        final isLayout05 = layoutType == 'layout_05';
        final isDarkLayout = layoutType == 'layout_06';

        final theme = Theme.of(context);

        Color backgroundColor;
        Color appBarColor;
        Color appBarTextColor;
        if (isDarkLayout) {
          backgroundColor = const Color(0xFF0A0A0A);
          appBarColor = const Color(0xFF0A0A0A);
          appBarTextColor = Colors.white;
        } else if (isLayout05) {
          backgroundColor = Layout03Theme.background;
          appBarColor = Layout03Theme.background;
          appBarTextColor = Layout03Theme.textDark;
        } else {
          backgroundColor = theme.scaffoldBackgroundColor;
          appBarColor = theme.primaryColor;
          appBarTextColor = Colors.white;
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text('Diagnóstico de Rede',
                style: TextStyle(color: appBarTextColor)),
            backgroundColor: appBarColor,
            iconTheme: IconThemeData(color: appBarTextColor),
            actions: [
              if (!state.isTesting && state.customDownloadResultMbps > 0)
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Compartilhar PDF',
                  onPressed: () {
                    final pdfService = PdfGeneratorService();
                    pdfService.stopAndSharePdf(state);
                  },
                ),
            ],
          ),
          body: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              color: state.isTesting
                  ? primaryColor.withAlpha(38)
                  : Colors.transparent,
              child: Text(state.geralStatusMessage,
                  style: textTheme.bodyLarge?.copyWith(
                      color: state.isTesting
                          ? primaryColor
                          : (isLayout05 ? Layout03Theme.textDark : null)),
                  textAlign: TextAlign.center),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _buildConnectionJourneyCard(context, state,
                      isLayout05: isLayout05, isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildOnuSignalCard(context,
                      isLayout05: isLayout05, isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildSpeedTestCard(context, state, isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildWifiManagementCard(context,
                      isLayout05: isLayout05, isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildWifiDetailsCard(context, state, isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildLanScanCard(context, state, isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildDeviceInfoCard(context, state, isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildBatteryInfoCard(context, state, isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 24),
                  TroubleshooterCard(
                    state: state,
                    onRetry: () {
                      if (!state.isTesting) _service.runAllTests();
                    },
                    isDarkLayout: isDarkLayout,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
              child: AppButton(
                icon: state.isTesting
                    ? Icons.stop_circle_outlined
                    : Icons.network_check_rounded,
                label: state.isTesting
                    ? "Parar Diagnóstico"
                    : "Iniciar Diagnóstico",
                onPressed: () {
                  if (state.isTesting) {
                    _service.stopAllTests();
                  } else {
                    _service.runAllTests();
                    _fetchOnuSignal();
                    _fetchWifiNetworks();
                  }
                },
              ),
            ),
          ]),
        );
      },
    );
  }

  String _parseResultLine(String? resultText, String key) {
    if (resultText == null || resultText.isEmpty) return "---";
    try {
      final line = resultText
          .split('\n')
          .firstWhere((l) => l.startsWith(key), orElse: () => '');
      if (line.isEmpty) return "---";
      return line.split(':').sublist(1).join(':').trim();
    } catch (e) {
      return "---";
    }
  }

  String _parseResultBlock(String? resultText, String key) {
    if (resultText == null || resultText.isEmpty) return "---";
    try {
      final lines = resultText.split('\n');
      final startIndex = lines.indexWhere((l) => l.startsWith(key));
      if (startIndex == -1) return "---";
      final block = lines
          .sublist(startIndex + 1)
          .takeWhile((l) => l.isNotEmpty && !l.contains(':'))
          .map((l) => l.trim())
          .join('\n');
      return block.isEmpty ? "---" : block;
    } catch (e) {
      return "---";
    }
  }

  Color _getColorForStatus(BuildContext context, TestStatus status) {
    final theme = Theme.of(context);
    switch (status) {
      case TestStatus.running:
        return theme.primaryColor;
      case TestStatus.success:
        return Colors.green;
      case TestStatus.error:
        return theme.colorScheme.error;
      case TestStatus.pending:
        return Colors.grey;
    }
  }

  Widget _buildConnectionJourneyCard(
      BuildContext context, DiagnosticoState state,
      {bool isLayout05 = false, bool isDarkLayout = false}) {
    final wifiStatus =
        state.testResultsDisplay['wifiInfo']?['status'] as TestStatus? ??
            TestStatus.pending;
    final wifiResult =
        state.testResultsDisplay['wifiInfo']?['result'] as String?;
    final gatewayStatus =
        state.testResultsDisplay['pingGateway']?['status'] as TestStatus? ??
            TestStatus.pending;
    final gatewayResult =
        state.testResultsDisplay['pingGateway']?['result'] as String?;
    final ipStatus =
        state.testResultsDisplay['publicIp']?['status'] as TestStatus? ??
            TestStatus.pending;
    final ipResult = state.testResultsDisplay['publicIp']?['result'] as String?;
    final googleStatus =
        state.testResultsDisplay['pingGoogle']?['status'] as TestStatus? ??
            TestStatus.pending;
    final googleResult =
        state.testResultsDisplay['pingGoogle']?['result'] as String?;
    final cloudflareStatus =
        state.testResultsDisplay['pingCloudflare']?['status'] as TestStatus? ??
            TestStatus.pending;
    final cloudflareResult =
        state.testResultsDisplay['pingCloudflare']?['result'] as String?;

    return _buildAdaptiveCard(
        isLayout05: isLayout05,
        isDarkLayout: isDarkLayout,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Jornada da Conexão",
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: isDarkLayout ? Colors.white : null)),
          const SizedBox(height: 20),
          _buildJourneyStep(context,
              icon: Icons.wifi,
              title: "Você (Dispositivo)",
              status: wifiStatus,
              isDarkLayout: isDarkLayout,
              children: [
                _buildJourneyInfo(context, "Sinal:",
                    _parseResultLine(wifiResult, "Força do Sinal:"),
                    isDarkLayout: isDarkLayout),
                _buildJourneyInfo(
                    context, "SSID:", _parseResultLine(wifiResult, "SSID:"),
                    isDarkLayout: isDarkLayout)
              ]),
          _buildJourneyStep(context,
              icon: Icons.router,
              title: "Seu Roteador",
              status: gatewayStatus,
              isDarkLayout: isDarkLayout,
              children: [
                _buildJourneyInfo(context, "IP:",
                    _parseResultLine(wifiResult, "Gateway (Roteador):"),
                    isDarkLayout: isDarkLayout),
                _buildJourneyInfo(context, "Latência:",
                    _parseResultLine(gatewayResult, "Latência:"),
                    isDarkLayout: isDarkLayout),
                _buildJourneyInfo(context, "Jitter:",
                    _parseResultLine(gatewayResult, "Jitter:"),
                    isDarkLayout: isDarkLayout),
              ]),
          _buildJourneyStep(context,
              icon: Icons.cloud_queue,
              title: "Nossa Rede",
              status: ipStatus,
              isDarkLayout: isDarkLayout,
              children: [
                _buildJourneyInfo(
                    context, "IPv4:", _parseResultLine(ipResult, "IPv4:"),
                    isDarkLayout: isDarkLayout),
                _buildJourneyInfo(
                    context, "IPv6:", _parseResultLine(ipResult, "IPv6:"),
                    isLast: true, isDarkLayout: isDarkLayout)
              ]),
          _buildJourneyStep(context,
              icon: Icons.dns_rounded,
              title: "Internet (DNS)",
              isLastStep: true,
              status: (googleStatus == TestStatus.success ||
                      cloudflareStatus == TestStatus.success)
                  ? TestStatus.success
                  : (googleStatus == TestStatus.running ||
                          cloudflareStatus == TestStatus.running)
                      ? TestStatus.running
                      : TestStatus.error,
              isDarkLayout: isDarkLayout,
              children: [
                _buildJourneyInfo(context, "Google:",
                    "${_parseResultLine(googleResult, "Latência:")} (${_parseResultLine(googleResult, "Perda:")})",
                    isDarkLayout: isDarkLayout),
                _buildJourneyInfo(context, "Cloudflare:",
                    "${_parseResultLine(cloudflareResult, "Latência:")} (${_parseResultLine(cloudflareResult, "Perda:")})",
                    isDarkLayout: isDarkLayout)
              ]),
        ]));
  }

  Widget _buildSpeedTestCard(
      BuildContext context, DiagnosticoState state, bool isLayout05,
      {bool isDarkLayout = false}) {
    // Determine state
    final customStatus = state.testResultsDisplay['speedTestCustom']?['status'];
    final fastStatus = state.testResultsDisplay['speedTestFast']?['status'];

    final isCustomRunning = customStatus == TestStatus.running;
    final isFastRunning = fastStatus == TestStatus.running;
    final isRunning = isCustomRunning || isFastRunning;
    final hasError =
        (customStatus == TestStatus.error || fastStatus == TestStatus.error) &&
            !isRunning;

    // Determine values
    double currentSpeed = 0.0;
    bool isDownload = true;
    double download = 0.0;
    double upload = 0.0;

    final textColor = isDarkLayout
        ? Colors.white
        : (isLayout05 ? Layout03Theme.textDark : null);
    final subTextColor = isDarkLayout
        ? Colors.white70
        : (isLayout05 ? Layout03Theme.textGrey : null);

    // Simplification for gauge
    if (isCustomRunning) {
      currentSpeed = state.customDownloadResultMbps > 0
          ? state.customDownloadResultMbps
          : 0;
      if (state.customUploadResultMbps > 1) {
        currentSpeed = state.customUploadResultMbps;
        isDownload = false;
      }
    } else if (isFastRunning) {
      currentSpeed = state.fastDownloadResultMbps;
      if (state.fastUploadResultMbps > 1) {
        currentSpeed = state.fastUploadResultMbps;
        isDownload = false;
      }
    } else if (hasError) {
      // Stop speed display on error
      currentSpeed = 0;
    }

    // Results to show
    download = state.customDownloadResultMbps > 0
        ? state.customDownloadResultMbps
        : state.fastDownloadResultMbps;
    upload = state.customUploadResultMbps > 0
        ? state.customUploadResultMbps
        : state.fastUploadResultMbps;

    final content = Column(
      children: [
        if (isRunning) ...[
          // GAUGE VIEW (Scaled down)
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(PieChartData(
                    startDegreeOffset: 135,
                    sectionsSpace: 0,
                    centerSpaceRadius: 80, // Smaller radius
                    sections: [
                      PieChartSectionData(
                        color: isLayout05 ? Colors.grey[300] : Colors.grey[200],
                        value: 75,
                        title: '',
                        radius: 12, // Smaller
                        showTitle: false,
                      ),
                      PieChartSectionData(
                          color: Colors.transparent,
                          value: 25,
                          title: '',
                          showTitle: false,
                          radius: 12),
                    ])),
                SizedBox(
                  width: 180,
                  height: 180,
                  child: RotationTransition(
                    turns: const AlwaysStoppedAnimation(225 / 360),
                    child: CircularProgressIndicator(
                      value: (currentSpeed / 100).clamp(0.0, 0.75),
                      strokeWidth: 12,
                      color: isDownload
                          ? (isLayout05 ? Colors.cyan : Colors.green)
                          : Colors.purple,
                      backgroundColor: Colors.transparent,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isDownload ? 'DOWNLOAD' : 'UPLOAD',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 10)),
                    Text(currentSpeed.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDarkLayout
                              ? Colors.white
                              : (isLayout05
                                  ? Layout03Theme.textDark
                                  : Theme.of(context).primaryColor),
                        )),
                    Text('Mbps',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          Text(isRunning ? "Testando sua conexão..." : "",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey))
        ] else if (hasError) ...[
          // ERROR VIEW
          Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Column(children: [
                Icon(Icons.error_outline,
                    size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text("Falha no Teste",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 8),
                Text(
                    state.testResultsDisplay['speedTestCustom']?['result'] ??
                        state.testResultsDisplay['speedTestFast']?['result'] ??
                        "Erro de conexão.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: () {
                      // Call service to retry only speed
                      _service.runSpeedTestsOnly();
                    },
                    child: const Text("Tentar Novamente"))
              ]))
        ] else ...[
          // RESULT VIEW (Mini Cards)
          Row(
            children: [
              Expanded(
                child: _buildMiniResultCard(
                    context,
                    "Download",
                    download.toStringAsFixed(1),
                    Icons.arrow_downward,
                    isLayout05 ? Colors.cyan : Colors.green,
                    isLayout05,
                    textColor: textColor,
                    subTextColor: subTextColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniResultCard(
                    context,
                    "Upload",
                    upload.toStringAsFixed(1),
                    Icons.arrow_upward,
                    isLayout05 ? Colors.purpleAccent : Colors.blue,
                    isLayout05,
                    textColor: textColor,
                    subTextColor: subTextColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniResultCard(
                    context,
                    "Ping",
                    "${state.speedTestPingLatency?.toStringAsFixed(0) ?? '-'} ms",
                    Icons.compare_arrows,
                    Colors.orange,
                    isLayout05,
                    textColor: textColor,
                    subTextColor: subTextColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                  onPressed: () {
                    // Retry
                    _service.runSpeedTestsOnly();
                  },
                  child: const Text("Refazer Teste"))
            ],
          )
        ] // end else
      ],
    );

    return _buildAdaptiveCard(
        isLayout05: isLayout05,
        isDarkLayout: isDarkLayout,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildTileHeader(context,
              label: "Velocidade de Internet",
              status: isRunning
                  ? TestStatus.running
                  : (hasError ? TestStatus.error : TestStatus.success),
              isDarkLayout: isDarkLayout),
          const SizedBox(height: 16),
          content,
        ]));
  }

  Widget _buildMiniResultCard(BuildContext context, String title, String value,
      IconData icon, Color color, bool isLayout05,
      {Color? textColor, Color? subTextColor}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: isLayout05
          ? BoxDecoration(
              color: Layout03Theme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)))
          : BoxDecoration(
              color: Colors.grey[100]
                  ?.withValues(alpha: textColor != null ? 0.1 : 1.0),
              borderRadius: BorderRadius.circular(8),
            ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: subTextColor)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
          ),
        ],
      ),
    );
  }

  // Unused method _buildSimpleStat removed

  Widget _buildWifiDetailsCard(
      BuildContext context, DiagnosticoState state, bool isLayout05,
      {bool isDarkLayout = false}) {
    final status =
        state.testResultsDisplay['wifiInfo']?['status'] as TestStatus? ??
            TestStatus.pending;
    final resultText =
        state.testResultsDisplay['wifiInfo']?['result'] as String?;

    return _buildAdaptiveCard(
      isLayout05: isLayout05,
      isDarkLayout: isDarkLayout,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildTileHeader(context,
            label: "Detalhes da Rede Wi-Fi",
            status: status,
            isDarkLayout: isDarkLayout),
        if (status == TestStatus.pending || status == TestStatus.running)
          _buildTileStatusText(context,
              status: status, result: resultText, isDarkLayout: isDarkLayout)
        else ...[
          const Divider(height: 24),
          _buildJourneyInfo(
              context, "BSSID:", _parseResultLine(resultText, "BSSID:"),
              isDarkLayout: isDarkLayout),
          _buildJourneyInfo(context, "IP Local:",
              _parseResultLine(resultText, "IP Dispositivo:"),
              isDarkLayout: isDarkLayout),
          _buildJourneyInfo(context, "Servidores DNS:",
              _parseResultBlock(resultText, "Servidores DNS:"),
              isDarkLayout: isDarkLayout),
        ]
      ]),
    );
  }

  Widget _buildDeviceInfoCard(
      BuildContext context, DiagnosticoState state, bool isLayout05,
      {bool isDarkLayout = false}) {
    final status =
        state.testResultsDisplay['deviceInfo']?['status'] as TestStatus? ??
            TestStatus.pending;
    final resultText =
        state.testResultsDisplay['deviceInfo']?['result'] as String?;

    return _buildAdaptiveCard(
      isLayout05: isLayout05,
      isDarkLayout: isDarkLayout,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildTileHeader(context,
            label: "Informações do Dispositivo",
            status: status,
            isDarkLayout: isDarkLayout),
        if (status == TestStatus.pending || status == TestStatus.running)
          _buildTileStatusText(context,
              status: status, result: resultText, isDarkLayout: isDarkLayout)
        else ...[
          const Divider(height: 24),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _buildDeviceInfoRow(context,
                      icon: Icons.wifi,
                      title: "Conexão",
                      value: _parseResultLine(resultText, "Conexão:"),
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildDeviceInfoRow(context,
                      icon: Icons.android_outlined,
                      title: "Sistema",
                      value: _parseResultLine(resultText, "Versão OS:"),
                      isDarkLayout: isDarkLayout),
                ])),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _buildDeviceInfoRow(context,
                      icon: Icons.smartphone,
                      title: "Dispositivo",
                      value: _parseResultLine(resultText, "Dispositivo:"),
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildDeviceInfoRow(context,
                      icon: Icons.info_outline,
                      title: "Versão do App",
                      value: _parseResultLine(resultText, "Versão do App:"),
                      isDarkLayout: isDarkLayout),
                ])),
          ]),
        ]
      ]),
    );
  }

  Widget _buildBatteryInfoCard(
      BuildContext context, DiagnosticoState state, bool isLayout05,
      {bool isDarkLayout = false}) {
    final status =
        state.testResultsDisplay['batteryInfo']?['status'] as TestStatus? ??
            TestStatus.pending;
    final resultText =
        state.testResultsDisplay['batteryInfo']?['result'] as String?;

    return _buildAdaptiveCard(
      isLayout05: isLayout05,
      isDarkLayout: isDarkLayout,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildTileHeader(context,
            label: "Energia e Bateria",
            status: status,
            isDarkLayout: isDarkLayout),
        if (status == TestStatus.pending || status == TestStatus.running)
          _buildTileStatusText(context,
              status: status, result: resultText, isDarkLayout: isDarkLayout)
        else ...[
          const Divider(height: 24),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _buildDeviceInfoRow(context,
                      icon: Icons.battery_std,
                      title: "Nível",
                      value: _parseResultLine(resultText, "Nível:"),
                      isDarkLayout: isDarkLayout),
                ])),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _buildDeviceInfoRow(context,
                      icon: Icons.power,
                      title: "Estado",
                      value: _parseResultLine(resultText, "Estado:"),
                      isDarkLayout: isDarkLayout),
                ])),
          ]),
          if (resultText != null && resultText.contains("⚠️"))
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.amberAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        resultText.split('\n').lastWhere(
                            (l) => l.contains("⚠️"),
                            orElse: () => "Aviso de energia"),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkLayout ? Colors.white : null)),
                  ),
                ],
              ),
            )
        ]
      ]),
    );
  }

  Widget _buildLanScanCard(
      BuildContext context, DiagnosticoState state, bool isLayout05,
      {bool isDarkLayout = false}) {
    final status =
        state.testResultsDisplay['lanScan']?['status'] as TestStatus? ??
            TestStatus.pending;
    final resultText =
        state.testResultsDisplay['lanScan']?['result'] as String?;

    final textColor = isDarkLayout
        ? Colors.white
        : (isLayout05 ? Layout03Theme.textDark : null);

    return _buildAdaptiveCard(
      isLayout05: isLayout05,
      isDarkLayout: isDarkLayout,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildTileHeader(context,
            label: "Dispositivos na Rede (LAN)",
            status: status,
            isDarkLayout: isDarkLayout),
        if (status == TestStatus.pending || status == TestStatus.running)
          _buildTileStatusText(context,
              status: status, result: resultText, isDarkLayout: isDarkLayout)
        else ...[
          const Divider(height: 24),
          Row(children: [
            Icon(Icons.devices_other,
                size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text("Total Encontrado",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: textColor)),
                  Text(
                      _parseResultLine(resultText, "Dispositivos encontrados:"),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: textColor)),
                  if (resultText != null && resultText.contains("sub-rede"))
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        resultText
                            .split('\n')
                            .lastWhere((l) => l.contains("sub-rede"),
                                orElse: () => "")
                            .replaceAll("(", "")
                            .replaceAll(")", ""),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: textColor),
                      ),
                    ),
                ]))
          ])
        ]
      ]),
    );
  }

  Widget _buildJourneyStep(BuildContext context,
      {required IconData icon,
      required String title,
      required TestStatus status,
      required List<Widget> children,
      bool isLastStep = false,
      bool isDarkLayout = false}) {
    Color statusColor = _getColorForStatus(context, status);
    return IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
          width: 32,
          child: Column(children: [
            Icon(icon, size: 24, color: statusColor),
            if (!isLastStep)
              Expanded(
                  child: Container(
                      width: 2,
                      color: isDarkLayout
                          ? Colors.grey[700]
                          : Theme.of(context).dividerColor,
                      margin: const EdgeInsets.symmetric(vertical: 8.0)))
          ])),
      const SizedBox(width: 16),
      Expanded(
          child: Padding(
              padding: EdgeInsets.only(bottom: isLastStep ? 0 : 24.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: statusColor)),
                    const SizedBox(height: 6),
                    ...children
                  ]))),
    ]));
  }

  Widget _buildJourneyInfo(BuildContext context, String label, String value,
      {bool isLast = false, bool isDarkLayout = false}) {
    final textTheme = Theme.of(context).textTheme;
    final textColor = isDarkLayout ? Colors.white : null;
    final subTextColor = isDarkLayout ? Colors.white70 : null;
    return Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$label ',
              style: textTheme.bodyMedium?.copyWith(color: subTextColor)),
          Expanded(
              child: Text(value,
                  style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500, color: textColor))),
        ]));
  }

  Widget _buildDeviceInfoRow(BuildContext context,
      {required IconData icon,
      required String title,
      required String value,
      bool isDarkLayout = false}) {
    final textTheme = Theme.of(context).textTheme;
    final textColor = isDarkLayout ? Colors.white : null;
    final subTextColor = isDarkLayout ? Colors.white70 : null;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(icon, size: 18, color: subTextColor)),
      const SizedBox(width: 12),
      Flexible(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: textTheme.bodyMedium?.copyWith(color: subTextColor)),
          const SizedBox(height: 4),
          Text(value,
              style: textTheme.titleMedium?.copyWith(color: textColor),
              softWrap: true),
        ]),
      ),
    ]);
  }

  // Unused method _buildSpeedTestTile removed
  // Fragments removed

  // Unused helpers removed

  Widget _buildTileHeader(BuildContext context,
      {required String label,
      required TestStatus status,
      bool isDarkLayout = false}) {
    final theme = Theme.of(context);
    Widget statusIconWidget;
    final color = _getColorForStatus(context, status);
    final textColor = isDarkLayout ? Colors.white : null;

    switch (status) {
      case TestStatus.running:
        statusIconWidget = SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 3, color: color));
        break;
      case TestStatus.success:
        statusIconWidget = Icon(Icons.check_circle, color: color, size: 28);
        break;
      case TestStatus.error:
        statusIconWidget = Icon(Icons.error, color: color, size: 28);
        break;
      case TestStatus.pending:
        statusIconWidget = Icon(Icons.hourglass_empty, color: color, size: 24);
        break;
    }
    return Row(
      children: [
        statusIconWidget,
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: theme.textTheme.titleLarge?.copyWith(color: textColor)),
        ),
      ],
    );
  }

  Widget _buildTileStatusText(BuildContext context,
      {required TestStatus status, String? result, bool isDarkLayout = false}) {
    String text;
    Color color = _getColorForStatus(context, status);
    final textColor = isDarkLayout ? Colors.white70 : color;

    switch (status) {
      case TestStatus.running:
        text =
            result != null && result.isNotEmpty && !result.contains("Iniciando")
                ? result.split('\n').last.trim()
                : "Executando...";
        break;
      case TestStatus.error:
        text = result ?? "Ocorreu um erro desconhecido.";
        break;
      case TestStatus.pending:
        text = "Pendente";
        break;
      default:
        return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Center(
        child: Text(
          text.replaceAll("Exception: ", ""),
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: textColor, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ============== ONU SIGNAL CARD ==============
  Future<void> _fetchOnuSignal() async {
    if (_onuWifiService == null) return;
    setState(() {
      _loadingOnu = true;
      _onuError = null;
    });
    try {
      final data = await _onuWifiService!.fetchOnuSignal();
      setState(() {
        _onuData = data;
        _loadingOnu = false;
      });
    } catch (e) {
      setState(() {
        _onuError = e.toString().replaceAll('Exception: ', '');
        _loadingOnu = false;
      });
    }
  }

  Widget _buildOnuSignalCard(BuildContext context,
      {bool isLayout05 = false, bool isDarkLayout = false}) {
    final theme = Theme.of(context);
    final textColor = isDarkLayout ? Colors.white : null;
    final subTextColor = isDarkLayout ? Colors.white70 : Colors.grey;

    return _buildAdaptiveCard(
      isLayout05: isLayout05,
      isDarkLayout: isDarkLayout,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.router, color: theme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
              child: Text("Sinal da ONU (Fibra)",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor))),
          if (!_loadingOnu)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _fetchOnuSignal,
              tooltip: 'Buscar sinal',
            ),
        ]),
        const Divider(height: 24),
        if (_loadingOnu)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ))
        else if (_onuError != null)
          Center(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Icon(Icons.error_outline, color: Colors.red[300], size: 40),
              const SizedBox(height: 8),
              Text(_onuError!,
                  style: TextStyle(color: Colors.red[300]),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _fetchOnuSignal,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ]),
          ))
        else if (_onuData == null)
          Center(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Icon(Icons.signal_cellular_alt,
                  color: Colors.grey[400], size: 40),
              const SizedBox(height: 8),
              Text('Clique em atualizar para buscar o sinal da ONU',
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchOnuSignal,
                icon: const Icon(Icons.search),
                label: const Text('Buscar Sinal'),
              ),
            ]),
          ))
        else ...[
          // Status indicator at top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _onuData!.isOnline
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(
                _onuData!.isOnline ? Icons.check_circle : Icons.cancel,
                color: _onuData!.isOnline ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 12),
              Text(
                'Status: ${_onuData!.connectionStatus}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _onuData!.isOnline ? Colors.green : Colors.red,
                ),
              ),
              const Spacer(),
              if (_onuData!.lastUpdate != null)
                Text(
                  _onuData!.lastUpdate!,
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
            ]),
          ),
          const SizedBox(height: 16),

          // Signal Strength (only if online)
          Row(children: [
            Expanded(
                child: _buildOnuStatBox(
              context,
              label: 'Sinal RX',
              value: _onuData!.signalRxDisplay,
              icon: Icons.arrow_downward,
              isGood: _onuData!.isSignalGood,
              isLayout05: isLayout05,
              isDarkLayout: isDarkLayout,
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _buildOnuStatBox(
              context,
              label: 'Sinal TX',
              value: _onuData!.signalTxDisplay,
              icon: Icons.arrow_upward,
              isGood: _onuData!.signalTx != null,
              isLayout05: isLayout05,
              isDarkLayout: isDarkLayout,
            )),
          ]),
          const SizedBox(height: 16),

          // Quality indicator
          if (_onuData!.signalRx != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _onuData!.isSignalGood
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(
                  _onuData!.isSignalGood ? Icons.check_circle : Icons.warning,
                  color: _onuData!.isSignalGood ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Text(
                  'Qualidade: ${_onuData!.signalQuality}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        _onuData!.isSignalGood ? Colors.green : Colors.orange,
                  ),
                ),
              ]),
            ),

          // OLT Info
          if (_onuData!.oltName != null)
            _buildOnuInfoTile('OLT', _onuData!.oltName!, Icons.cell_tower,
                isDarkLayout: isDarkLayout),
          _buildOnuInfoTile(
              'Posição',
              'Slot ${_onuData!.slot} | PON ${_onuData!.pon} | ID ${_onuData!.onuId}',
              Icons.pin_drop,
              isDarkLayout: isDarkLayout),

          // Device info
          _buildOnuInfoTile('Modelo', _onuData!.model, Icons.router,
              isDarkLayout: isDarkLayout),
          if (_onuData!.serialNumber != null)
            _buildOnuInfoTile('Serial', _onuData!.serialNumber!, Icons.tag,
                isDarkLayout: isDarkLayout),
          if (_onuData!.mode != null)
            _buildOnuInfoTile('Modo', _onuData!.mode!, Icons.settings,
                isDarkLayout: isDarkLayout),

          // Network info
          if (_onuData!.vlan != null)
            _buildOnuInfoTile('VLAN', _onuData!.vlan.toString(), Icons.lan,
                isDarkLayout: isDarkLayout),
          if (_onuData!.cto != null)
            _buildOnuInfoTile('CTO', _onuData!.cto!, Icons.location_on,
                isDarkLayout: isDarkLayout),

          // Additional info
          Row(children: [
            if (_onuData!.temperature != null)
              Expanded(
                  child: _buildOnuInfoTile(
                      'Temp', '${_onuData!.temperature}°C', Icons.thermostat,
                      isDarkLayout: isDarkLayout)),
            if (_onuData!.voltage != null)
              Expanded(
                  child: _buildOnuInfoTile('Voltagem', '${_onuData!.voltage}V',
                      Icons.electrical_services,
                      isDarkLayout: isDarkLayout)),
          ]),
        ],
      ]),
    );
  }

  Widget _buildOnuStatBox(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required bool isGood,
    bool isLayout05 = false,
    bool isDarkLayout = false,
  }) {
    final textColor = isDarkLayout
        ? Colors.white
        : (isLayout05 ? Layout03Theme.textDark : null);
    final subTextColor = isDarkLayout
        ? Colors.white70
        : (isLayout05 ? Layout03Theme.textGrey : null);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: isLayout05
          ? BoxDecoration(
              color: Layout03Theme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isGood
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3)),
            )
          : BoxDecoration(
              color:
                  isDarkLayout ? Colors.grey[900] : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isGood
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3)),
            ),
      child: Column(children: [
        Icon(icon, color: isGood ? Colors.green : Colors.orange),
        const SizedBox(height: 8),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: subTextColor,
                )),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
      ]),
    );
  }

  Widget _buildOnuInfoTile(String label, String value, IconData icon,
      {bool isDarkLayout = false}) {
    // final textColor = isDarkLayout ? Colors.white : null;
    // final subTextColor = isDarkLayout ? Colors.white70 : Colors.grey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(color: Colors.grey)),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
    );
  }

  // ============== WIFI MANAGEMENT CARD ==============
  Future<void> _fetchWifiNetworks() async {
    if (_onuWifiService == null) return;
    setState(() {
      _loadingWifi = true;
      _wifiError = null;
    });
    try {
      final networks = await _onuWifiService!.fetchWifiNetworks();
      setState(() {
        _wifiNetworks = networks;
        _loadingWifi = false;
      });
    } catch (e) {
      setState(() {
        _wifiError = e.toString().replaceAll('Exception: ', '');
        _loadingWifi = false;
      });
    }
  }

  Widget _buildWifiManagementCard(BuildContext context,
      {bool isLayout05 = false, bool isDarkLayout = false}) {
    final theme = Theme.of(context);
    final textColor = isDarkLayout ? Colors.white : null;

    return _buildAdaptiveCard(
      isLayout05: isLayout05,
      isDarkLayout: isDarkLayout,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.wifi,
              color:
                  isDarkLayout ? const Color(0xFF00D9FF) : theme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
              child: Text("Gerenciar WiFi (TR-069)",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor))),
          if (!_loadingWifi)
            IconButton(
              icon:
                  Icon(Icons.refresh, color: isDarkLayout ? Colors.grey : null),
              onPressed: _fetchWifiNetworks,
              tooltip: 'Buscar redes',
            ),
        ]),
        const Divider(height: 24),
        if (_loadingWifi)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ))
        else if (_wifiError != null)
          Center(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Icon(Icons.error_outline, color: Colors.red[300], size: 40),
              const SizedBox(height: 8),
              Text(_wifiError!,
                  style: TextStyle(color: Colors.red[300]),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _fetchWifiNetworks,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ]),
          ))
        else if (_wifiNetworks.isEmpty)
          Center(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Icon(Icons.wifi_find, color: Colors.grey[400], size: 40),
              const SizedBox(height: 8),
              Text('Clique para buscar as redes WiFi do seu roteador',
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchWifiNetworks,
                icon: const Icon(Icons.search),
                label: const Text('Buscar Redes WiFi'),
              ),
            ]),
          ))
        else
          ..._wifiNetworks.map((network) =>
              _buildWifiNetworkTile(context, network, isLayout05: isLayout05)),
      ]),
    );
  }

  Widget _buildWifiNetworkTile(BuildContext context, WifiNetwork network,
      {bool isLayout05 = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: isLayout05
          ? BoxDecoration(
              color: Layout03Theme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white), // Subtle border
            )
          : BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
      child: Row(children: [
        Icon(
          network.frequency.contains('5') ? Icons.wifi : Icons.wifi_2_bar,
          color: network.enabled ? Colors.green : Colors.grey,
          size: 32,
        ),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(network.ssid,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isLayout05 ? Layout03Theme.textDark : null)),
          Text(network.frequency,
              style: TextStyle(
                  color: isLayout05 ? Layout03Theme.textGrey : Colors.grey[600],
                  fontSize: 13)),
        ])),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showEditWifiDialog(context, network),
          tooltip: 'Editar WiFi',
          color: isLayout05 ? Layout03Theme.primary : null,
        ),
      ]),
    );
  }

  void _showEditWifiDialog(BuildContext context, WifiNetwork network) {
    final ssidController = TextEditingController(text: network.ssid);
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar ${network.frequency}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: ssidController,
            decoration: const InputDecoration(
              labelText: 'Nome da Rede (SSID)',
              prefixIcon: Icon(Icons.wifi),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nova Senha',
              prefixIcon: Icon(Icons.lock),
              hintText: 'Deixe vazio para manter',
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _updateWifi(
                  network.id, ssidController.text, passwordController.text);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateWifi(String wifiId, String ssid, String password) async {
    if (_onuWifiService == null || ssid.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aplicando alterações no WiFi...')),
    );

    try {
      final success = await _onuWifiService!.updateWifi(
        wifiId: wifiId,
        ssid: ssid,
        password: password.isEmpty ? 'keep_current' : password,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'WiFi atualizado com sucesso!'
                : 'Falha ao atualizar WiFi'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _fetchWifiNetworks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildAdaptiveCard(
      {required Widget child,
      required bool isLayout05,
      bool isDarkLayout = false}) {
    if (isDarkLayout) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      );
    }
    if (isLayout05) {
      return Container(
        decoration: Layout03Theme.neumorphicDecoration,
        padding: const EdgeInsets.all(16),
        child: child,
      );
    }
    return DashboardCard(child: child);
  }
}
```

---

### `lib/core/pages/shared_faq_page.dart`
> Página compartilhada

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../layouts/layout_03/theme.dart';

class FaqPage extends ConsumerWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configProvider = ref.watch(configurationProvider);
    final faqList = configProvider.providerConfig?.config.faq ?? [];
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    final layoutType = configProvider.providerConfig?.layoutType;
    final isLayout05 = layoutType == 'layout_05';
    final isDarkLayout = layoutType == 'layout_06';

    Color backgroundColor;
    Color appBarColor;
    Color appBarTextColor;
    if (isDarkLayout) {
      backgroundColor = const Color(0xFF0A0A0A);
      appBarColor = const Color(0xFF0A0A0A);
      appBarTextColor = Colors.white;
    } else if (isLayout05) {
      backgroundColor = Layout03Theme.background;
      appBarColor = Layout03Theme.background;
      appBarTextColor = Layout03Theme.textDark;
    } else {
      backgroundColor = theme.scaffoldBackgroundColor;
      appBarColor = theme.primaryColor;
      appBarTextColor = Colors.white;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Perguntas Frequentes',
            style: TextStyle(color: appBarTextColor)),
        backgroundColor: appBarColor,
        iconTheme: IconThemeData(color: appBarTextColor),
      ),
      body: configProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : configProvider.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(height: 16),
                        Text(configProvider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge),
                      ],
                    ),
                  ),
                )
              : faqList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.help_outline,
                              size: 64, color: textTheme.bodySmall?.color),
                          const SizedBox(height: 16),
                          Text(
                            "Nenhuma pergunta frequente cadastrada.",
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: faqList.length,
                      itemBuilder: (context, index) {
                        final faqItem = faqList[index];
                        if (isDarkLayout) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF3A3A3C)
                                      .withValues(alpha: 0.3)),
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              collapsedIconColor: const Color(0xFF8E8E93),
                              iconColor: primaryColor,
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF3A3A3C),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                faqItem.question,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              children: [
                                const Divider(color: Color(0xFF3A3A3C)),
                                const SizedBox(height: 8),
                                Text(faqItem.answer,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF8E8E93),
                                    )),
                              ],
                            ),
                          );
                        }
                        if (isLayout05) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            decoration: Layout03Theme.neumorphicDecoration,
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              collapsedIconColor: Layout03Theme.textGrey,
                              iconColor: Layout03Theme.primary,
                              leading: CircleAvatar(
                                backgroundColor: Layout03Theme.primary
                                    .withValues(alpha: 0.1),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Layout03Theme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                faqItem.question,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Layout03Theme.textDark,
                                ),
                              ),
                              children: [
                                const Divider(),
                                const SizedBox(height: 8),
                                Text(faqItem.answer,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: Layout03Theme.textGrey,
                                    )),
                              ],
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              leading: CircleAvatar(
                                backgroundColor:
                                    primaryColor.withValues(alpha: 0.1),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                faqItem.question,
                                style: textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              children: [
                                const Divider(),
                                const SizedBox(height: 8),
                                Text(faqItem.answer,
                                    style: textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
```

---

### `lib/core/pages/shared_financeiro_page.dart`
> Página compartilhada

```dart
// Layout 02 - Financeiro Page (VERSÃO CLEAN)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../layouts/layout_04/widgets/skeleton_financeiro_page.dart';
import '../../layouts/layout_04/widgets/error_widget.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../../core/models/fatura.dart';
import '../../core/providers/financeiro_provider.dart';
import '../../core/providers/providers.dart';
import '../../layouts/layout_03/theme.dart';

class FinanceiroPage extends ConsumerStatefulWidget {
  const FinanceiroPage({super.key});

  @override
  ConsumerState<FinanceiroPage> createState() => _FinanceiroPageState();
}

class _FinanceiroPageState extends ConsumerState<FinanceiroPage> {
  bool _showAllOpenInvoices = false;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configurationProvider);
    final providerConfig = config.providerConfig;

    if (providerConfig == null) {
      return const Scaffold(
          body: Center(child: Text('Configuração não encontrada')));
    }

    final layoutType = providerConfig.layoutType;
    final isLayout05 = layoutType == 'layout_05';
    final isDarkLayout = layoutType == 'layout_06';

    final themeData = Theme.of(context);
    // Colors setup (condensed for brevity, keeping original logic)
    Color backgroundColor;
    Color appBarColor;
    Color appBarTextColor;

    if (isDarkLayout) {
      backgroundColor = const Color(0xFF0A0A0A);
      appBarColor = const Color(0xFF0A0A0A);
      appBarTextColor = Colors.white;
    } else if (isLayout05) {
      backgroundColor = Layout03Theme.background;
      appBarColor = Layout03Theme.background;
      appBarTextColor = Layout03Theme.textDark;
    } else {
      backgroundColor = Colors.grey[50]!;
      appBarColor = themeData.primaryColor;
      appBarTextColor = Colors.white;
    }

    final provider = ref.watch(financeiroViewModelProvider);

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text('Faturas', style: TextStyle(color: appBarTextColor)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: appBarColor,
          iconTheme: IconThemeData(color: appBarTextColor),
        ),
        body: Builder(builder: (context) {
          if (provider.state == FinanceiroState.loading) {
            return const SkeletonFinanceiroPage();
          }

          if (provider.state == FinanceiroState.error) {
            if (isDarkLayout) {
              return Layout06ErrorWidget(
                title: 'Erro ao carregar faturas',
                message: provider.errorMessage,
                onRetry: provider.fetchHistory,
              );
            }
            return _buildErrorState(context, provider);
          }

          if (provider.invoices.isEmpty) {
            return _buildEmptyState(context, provider);
          }

          // Segregate Invoices
          final openInvoices = provider.invoices
              .where((i) => !i.isPago)
              .toList()
            ..sort((a, b) => a.vencimento.compareTo(b.vencimento));

          final paidInvoices = provider.invoices.where((i) => i.isPago).toList()
            ..sort((a, b) =>
                b.vencimento.compareTo(a.vencimento)); // Newest paid first

          final displayedOpenInvoices = _showAllOpenInvoices
              ? openInvoices
              : (openInvoices.isNotEmpty ? [openInvoices.first] : []);

          final hiddenCount =
              openInvoices.length - displayedOpenInvoices.length;

          return RefreshIndicator(
            onRefresh: provider.fetchHistory,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                if (openInvoices.isNotEmpty) ...[
                  if (!_showAllOpenInvoices && openInvoices.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text("Próxima Fatura (Pagar Agora)",
                          style: TextStyle(
                              color: isDarkLayout
                                  ? Colors.white70
                                  : Colors.grey[700],
                              fontWeight: FontWeight.bold)),
                    ),
                  ...displayedOpenInvoices.map((i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildInvoiceCard(context, i, ref, isLayout05,
                            isDarkLayout: isDarkLayout),
                      )),
                  if (hiddenCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showAllOpenInvoices = true;
                            });
                          },
                          icon: Icon(Icons.add_circle_outline,
                              color: themeData.primaryColor),
                          label: Text("Ver mais $hiddenCount faturas pendentes",
                              style: TextStyle(color: themeData.primaryColor)),
                        ),
                      ),
                    ),
                  if (_showAllOpenInvoices && openInvoices.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _showAllOpenInvoices = false;
                            });
                          },
                          child: const Text("Mostrar menos faturas"),
                        ),
                      ),
                    ),
                ],
                if (paidInvoices.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("Histórico de Pagamentos",
                              style: TextStyle(
                                  color: isDarkLayout
                                      ? Colors.white54
                                      : Colors.grey)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),
                  ...paidInvoices.map((i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildInvoiceCard(context, i, ref, isLayout05,
                            isDarkLayout: isDarkLayout),
                      )),
                ]
              ],
            ),
          );
        }));
  }

  Widget _buildErrorState(BuildContext context, FinanceiroProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(provider.errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: provider.fetchHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, FinanceiroProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green[400]),
          const SizedBox(height: 16),
          const Text('Nenhuma fatura encontrada',
              style: TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: provider.fetchHistory,
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(
      BuildContext context, Fatura fatura, WidgetRef ref, bool isLayout05,
      {bool isDarkLayout = false}) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final primaryColor =
        isDarkLayout ? const Color(0xFF00D9FF) : Theme.of(context).primaryColor;

    // Status visual
    Color statusColor = Colors.orange;
    String statusText = 'Pendente';
    IconData statusIcon = Icons.schedule;

    if (fatura.isPago) {
      statusColor = isDarkLayout
          ? const Color(0xFF30D158)
          : (isLayout05 ? Layout03Theme.success : Colors.green);
      statusText = 'Pago';
      statusIcon = Icons.check_circle;
    } else if (fatura.isVencido) {
      statusColor = isDarkLayout
          ? const Color(0xFFFF453A)
          : (isLayout05 ? Layout03Theme.error : Colors.red);
      statusText = 'Vencido';
      statusIcon = Icons.error;
    }

    BoxDecoration decoration;
    if (isDarkLayout) {
      decoration = BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
      );
    } else if (isLayout05) {
      decoration = Layout03Theme.neumorphicDecoration;
    } else {
      decoration = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      );
    }

    // final textColor = isDarkLayout ? Colors.white : Colors.black87;
    // final subtitleColor =
    //    isDarkLayout ? const Color(0xFF8E8E93) : Colors.grey[600];

    return Container(
      decoration: decoration,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Valor
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currencyFormat.format(fatura.valor),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fatura.isPago
                            ? 'Pago em ${dateFormat.format(fatura.dataPagamento ?? fatura.vencimento)}'
                            : 'Vence ${dateFormat.format(fatura.vencimento)}',
                        style: TextStyle(
                            color: fatura.isPago
                                ? (isDarkLayout
                                    ? Colors.white70
                                    : Colors.black87)
                                : Colors.grey[600],
                            fontSize: fatura.isPago ? 15 : 13,
                            fontWeight: fatura.isPago
                                ? FontWeight.bold
                                : FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusText,
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Ações de pagamento (apenas para não pagas)
          if (!fatura.isPago) ...[
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.grey[100],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // PIX - Botão principal
                  if (fatura.pixCopiaECola != null &&
                      fatura.pixCopiaECola!.isNotEmpty)
                    _buildActionButton(
                      context,
                      icon: Icons.pix,
                      label: 'Copiar código Pix',
                      color: const Color(0xFF32BCAD),
                      isPrimary: true,
                      onTap: () => _copyToClipboard(
                          context, fatura.pixCopiaECola!, 'Código Pix'),
                    ),

                  if (fatura.pixCopiaECola != null &&
                      fatura.pixCopiaECola!.isNotEmpty)
                    const SizedBox(height: 8),

                  // Linha digitável / Boleto
                  Row(
                    children: [
                      if (fatura.linhaDigitavel != null &&
                          fatura.linhaDigitavel!.isNotEmpty)
                        Expanded(
                          child: _buildActionButton(
                            context,
                            icon: Icons.content_copy,
                            label: 'Código de barras',
                            color: primaryColor,
                            isPrimary: false,
                            onTap: () => _copyToClipboard(context,
                                fatura.linhaDigitavel!, 'Código de barras'),
                          ),
                        ),
                      if (fatura.linhaDigitavel != null &&
                          fatura.urlBoleto != null)
                        const SizedBox(width: 8),
                      if (fatura.urlBoleto != null &&
                          fatura.urlBoleto!.isNotEmpty)
                        Expanded(
                          child: _buildActionButton(
                            context,
                            icon: Icons.open_in_new,
                            label: 'Ver boleto',
                            color: Colors.blue,
                            isPrimary: false,
                            onTap: () => _openUrl(fatura.urlBoleto!),
                          ),
                        ),
                    ],
                  ),

                  // Se não tem nenhuma opção de pagamento
                  if ((fatura.pixCopiaECola == null ||
                          fatura.pixCopiaECola!.isEmpty) &&
                      (fatura.linhaDigitavel == null ||
                          fatura.linhaDigitavel!.isEmpty) &&
                      (fatura.urlBoleto == null || fatura.urlBoleto!.isEmpty))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Dados de pagamento não disponíveis',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ),

                  // DESBLOQUEIO POR CONFIANÇA - Apenas para faturas vencidas
                  if (fatura.isVencido)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildTrustUnlockButton(context, fatura, ref),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrustUnlockButton(
      BuildContext context, Fatura fatura, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade600],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTrustUnlockDialog(context, fatura, ref),
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_open, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Liberar por Confiança',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTrustUnlockDialog(
      BuildContext context, Fatura fatura, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_open, color: Colors.purple),
            SizedBox(width: 12),
            Text('Liberação por Confiança'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Libere sua internet por 24 horas enquanto aguarda a confirmação do pagamento.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Essa liberação é válida por apenas 24 horas.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeTrustUnlock(context, fatura, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Liberação'),
          ),
        ],
      ),
    );
  }

  void _executeTrustUnlock(
      BuildContext context, Fatura fatura, WidgetRef ref) async {
    final config = ref.read(configurationProvider);
    final authState = ref.read(authNotifierProvider);
    final providerConfig = config.providerConfig;
    final usuario = authState.value;

    if (providerConfig == null || usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Configuração não encontrada'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 16),
            Text('Processando liberação...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final response = await http.post(
        Uri.parse('${providerConfig.apiUrl}/unlock-trust'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cpfCnpj': usuario.cpfCnpj.replaceAll(RegExp(r'[^0-9]'), ''),
          'senha': usuario.senha,
          'faturaId': fatura.numero,
          'sgpParams': {
            'token': providerConfig.config.integrations.apiToken,
            'app': providerConfig.config.integrations.appName,
            'sgpBaseUrl': providerConfig.config.integrations.sgpBaseUrl,
          },
        }),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Internet liberada por 24 horas!')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error']?['message'] ?? 'Erro ao liberar');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick(); // Charm
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
```

---

### `lib/core/pages/shared_meu_ip_page.dart`
> Página compartilhada

```dart
import 'package:flutter/material.dart';
import 'dart:async';

import '../../core/services/meu_ip_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../layouts/layout_03/theme.dart';

class MeuIpPage extends ConsumerStatefulWidget {
  const MeuIpPage({super.key});

  @override
  ConsumerState<MeuIpPage> createState() => _MeuIpPageState();
}

class _MeuIpPageState extends ConsumerState<MeuIpPage> {
  late Future<Map<String, dynamic>> _ipFuture;
  final MeuIpService _service = MeuIpService();

  @override
  void initState() {
    super.initState();
    _ipFuture = _service.fetchIpInfo();
  }

  void _retry() {
    setState(() {
      _ipFuture = _service.fetchIpInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = ref.watch(configurationProvider);
    final layoutType = configProvider.providerConfig?.layoutType;
    final isLayout05 = layoutType == 'layout_05';
    final isDarkLayout = layoutType == 'layout_06';

    final theme = Theme.of(context);
    Color backgroundColor;
    Color appBarColor;
    Color appBarTextColor;
    if (isDarkLayout) {
      backgroundColor = const Color(0xFF0A0A0A);
      appBarColor = const Color(0xFF0A0A0A);
      appBarTextColor = Colors.white;
    } else if (isLayout05) {
      backgroundColor = Layout03Theme.background;
      appBarColor = Layout03Theme.background;
      appBarTextColor = Layout03Theme.textDark;
    } else {
      backgroundColor = theme.scaffoldBackgroundColor;
      appBarColor = theme.primaryColor;
      appBarTextColor = Colors.white;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title:
            Text('Meu Endereço IP', style: TextStyle(color: appBarTextColor)),
        backgroundColor: appBarColor,
        iconTheme: IconThemeData(color: appBarTextColor),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _ipFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 64, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      _formatErrorMessage(snapshot.error),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasData) {
            return _buildIpInfoCard(context, snapshot.data!, isLayout05,
                isDarkLayout: isDarkLayout);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _formatErrorMessage(Object? error) {
    if (error is TimeoutException) {
      return 'O servidor demorou muito para responder. Por favor, tente novamente.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  Widget _buildIpInfoCard(
      BuildContext context, Map<String, dynamic> ipData, bool isLayout05,
      {bool isDarkLayout = false}) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    final decoration = isDarkLayout
        ? BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
          )
        : (isLayout05
            ? Layout03Theme.neumorphicDecoration
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4)),
                ],
              ));

    final highlightColor = isDarkLayout
        ? const Color(0xFF00D9FF)
        : (isLayout05 ? Layout03Theme.primary : primaryColor);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: decoration,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language, size: 48, color: highlightColor),
                  const SizedBox(height: 16),
                  Text("Seu IP Público é:",
                      style: textTheme.bodyMedium?.copyWith(
                        color: isDarkLayout
                            ? const Color(0xFF8E8E93)
                            : (isLayout05 ? Layout03Theme.textGrey : null),
                      )),
                  const SizedBox(height: 8),
                  Text(
                    ipData['ip'] ?? 'Não encontrado',
                    style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold, color: highlightColor),
                  ),
                  Divider(
                      height: 40,
                      color: isLayout05 ? Colors.transparent : null),
                  _buildInfoRow(context,
                      icon: Icons.location_city,
                      title: "Localização",
                      value:
                          "${ipData['city'] ?? 'N/A'}, ${ipData['region'] ?? 'N/A'}",
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 12),
                  _buildInfoRow(context,
                      icon: Icons.public,
                      title: "País",
                      value: ipData['country'] ?? 'N/A',
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 12),
                  _buildInfoRow(context,
                      icon: Icons.router,
                      title: "Provedor",
                      value: ipData['org'] ?? 'Não encontrado',
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 12),
                  _buildInfoRow(context,
                      icon: Icons.access_time,
                      title: "Fuso Horário",
                      value: ipData['timezone'] ?? 'N/A',
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: isLayout05
                        ? ElevatedButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Atualizar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Layout03Theme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Atualizar'),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 180), // Padding for BottomNav
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon,
      required String title,
      required String value,
      bool isLayout05 = false,
      bool isDarkLayout = false}) {
    final textTheme = Theme.of(context).textTheme;
    final color = isDarkLayout
        ? Colors.white
        : (isLayout05 ? Layout03Theme.textDark : null);
    final iconColor = isDarkLayout
        ? const Color(0xFF00D9FF)
        : (isLayout05 ? Layout03Theme.primary : textTheme.bodySmall?.color);

    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 16),
        Text("$title:",
            style: textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(value,
                textAlign: TextAlign.end,
                style: textTheme.bodyMedium?.copyWith(color: color))),
      ],
    );
  }
}
```

---

### `lib/core/pages/shared_notification_page.dart`
> Página compartilhada

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../../layouts/layout_04/widgets/glass_card.dart';

class SharedNotificationPage extends ConsumerStatefulWidget {
  const SharedNotificationPage({super.key});

  @override
  ConsumerState<SharedNotificationPage> createState() =>
      _SharedNotificationPageState();
}

class _SharedNotificationPageState
    extends ConsumerState<SharedNotificationPage> {
  @override
  void initState() {
    super.initState();
    // Load notifications on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final notificationService = ref.watch(notificationProvider);
    final notifications = notificationService.notifications;

    return Scaffold(
      backgroundColor: Colors.transparent, // Handled by Layout 06 background
      appBar: AppBar(
        title: Text(
          'Notificações',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Marcar todas como lidas',
            onPressed: () {
              ref.read(notificationProvider).markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Todas marcadas como lidas')),
              );
            },
          ),
        ],
      ),
      body: notificationService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma notificação',
                        style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        ref
                            .read(notificationProvider)
                            .deleteNotification(item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notificação removida')),
                        );
                      },
                      child: GestureDetector(
                        onTap: () {
                          if (!item.read) {
                            ref.read(notificationProvider).markAsRead(item.id);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: GoogleFonts.outfit(
                                                fontWeight: item.read
                                                    ? FontWeight.normal
                                                    : FontWeight.bold,
                                                fontSize: 16,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          if (!item.read)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  left: 8),
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: secondaryColor(theme),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.message,
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.8),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        DateFormat('dd/MM/yyyy HH:mm')
                                            .format(item.createdAt),
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.5),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Color secondaryColor(ThemeData theme) => theme.colorScheme.secondary;
}
```

---

### `lib/core/pages/shared_speed_test_page.dart`
> Página compartilhada

```dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../core/providers/providers.dart';
import '../../layouts/layout_03/theme.dart';
import '../../core/services/diagnostico_service.dart';
import '../../core/models/diagnostico_state.dart';

class SharedSpeedTestPage extends ConsumerStatefulWidget {
  const SharedSpeedTestPage({super.key});

  @override
  ConsumerState<SharedSpeedTestPage> createState() =>
      _SharedSpeedTestPageState();
}

class _SharedSpeedTestPageState extends ConsumerState<SharedSpeedTestPage> {
  late final DiagnosticoService _service;
  bool _serviceInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serviceInitialized) {
      final configProvider = ref.read(configurationProvider);
      final providerConfig = configProvider.providerConfig!;
      _service =
          DiagnosticoService(providerConfig: providerConfig, context: context);
      _serviceInitialized = true;
      _listenToStream();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = ref.watch(configurationProvider);
    final layoutType = config.providerConfig?.layoutType;
    final isLayout05 = layoutType == 'layout_05';
    final isDarkLayout = layoutType == 'layout_06';

    // Theme Colors
    Color backgroundColor;
    Color appBarTextColor;
    Color appBarColor;
    if (isDarkLayout) {
      backgroundColor = const Color(0xFF0A0A0A);
      appBarColor = const Color(0xFF0A0A0A);
      appBarTextColor = Colors.white;
    } else if (isLayout05) {
      backgroundColor = Layout03Theme.background;
      appBarColor = Layout03Theme.background;
      appBarTextColor = Layout03Theme.textDark;
    } else {
      backgroundColor = theme.scaffoldBackgroundColor;
      appBarColor = theme.primaryColor;
      appBarTextColor = Colors.white;
    }

    return StreamBuilder<DiagnosticoState>(
      stream: _service.stateStream,
      initialData: DiagnosticoState.initial(),
      builder: (context, snapshot) {
        final state = snapshot.data!;

        // Use custom speed test results for the gauge if running, or fast.com if running
        // Priority: Custom -> Fast
        final isCustomRunning = state.testResultsDisplay['speedTestCustom']
                ?['status'] ==
            TestStatus.running;
        final isFastRunning = state.testResultsDisplay['speedTestFast']
                ?['status'] ==
            TestStatus.running;
        final isRunning = isCustomRunning || isFastRunning || state.isTesting;

        // Current Speed Value (for Gauge)
        double currentSpeed = 0.0;
        bool isDownload = true;

        if (isCustomRunning) {
          final download = state.customDownloadResultMbps;
          final upload = state.customUploadResultMbps;

          currentSpeed = download > 0 ? download : 0;
          if (upload > 1) {
            currentSpeed = upload;
            isDownload = false;
          }
        }

        // Determine Mode
        Widget content;
        final hasResults = state.customDownloadResultMbps > 0 ||
            state.fastDownloadResultMbps > 0;
        final customStatus = state.testResultsDisplay['speedTestCustom']
            ?['status'] as TestStatus?;
        final fastStatus =
            state.testResultsDisplay['speedTestFast']?['status'] as TestStatus?;
        final hasError = (customStatus == TestStatus.error ||
                fastStatus == TestStatus.error) &&
            !isRunning;

        if (isRunning) {
          content = _buildGaugeView(
              context, state, isLayout05, currentSpeed, isDownload, false,
              isDarkLayout: isDarkLayout);
        } else if (hasError) {
          final errorMsg = state.testResultsDisplay['speedTestCustom']
                  ?['result'] ??
              state.testResultsDisplay['speedTestFast']?['result'] ??
              "Erro desconhecido ao conectar.";
          content = _buildErrorView(context, errorMsg, isLayout05);
        } else if (hasResults) {
          // Reuse Gauge View for Results, but with isFinished=true
          // Calculate final speed to show (likely download or upload based on what we want to emphasize, or maybe download by default)
          double finalSpeed = state.customDownloadResultMbps > 0
              ? state.customDownloadResultMbps
              : state.fastDownloadResultMbps;

          content = _buildGaugeView(
              context, state, isLayout05, finalSpeed, true, true,
              isDarkLayout: isDarkLayout);
        } else {
          content = _buildIdleView(context, isLayout05);
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text('Teste de Velocidade',
                style: TextStyle(color: appBarTextColor)),
            backgroundColor: appBarColor,
            iconTheme: IconThemeData(color: appBarTextColor),
            elevation: 0,
            centerTitle: true,
            actions: [
              if (!isRunning && hasResults)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    _startTest();
                  },
                )
            ],
          ),
          body: content,
        );
      },
    );
  }

  void _startTest() {
    _service.runSpeedTestsOnly();
  }

  void _stopTest() {
    _service.stopAllTests();
  }

  // --- VIEW: ERROR ---
  Widget _buildErrorView(
      BuildContext context, String? errorMessage, bool isLayout05) {
    final theme = Theme.of(context);
    final textColor =
        isLayout05 ? Layout03Theme.textDark : theme.textTheme.bodyLarge?.color;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.signal_wifi_connected_no_internet_4_rounded,
                size: 80,
                color:
                    isLayout05 ? Layout03Theme.error : theme.colorScheme.error),
            const SizedBox(height: 24),
            Text("Ops! Algo deu errado.",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 16),
            Text(
                errorMessage ??
                    "Não foi possível conectar ao servidor de teste.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _startTest,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text("Tentar Novamente",
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isLayout05 ? Layout03Theme.primary : theme.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30))),
            )
          ],
        ),
      ),
    );
  }

  // --- VIEW: IDLE (Start Button) ---
  Widget _buildIdleView(BuildContext context, bool isLayout05) {
    final theme = Theme.of(context);
    final primaryColor =
        isLayout05 ? Layout03Theme.primary : theme.primaryColor;
    final textColor =
        isLayout05 ? Layout03Theme.textDark : theme.textTheme.bodyLarge?.color;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Toque em INICIAR para testar a sua velocidade',
              style: TextStyle(
                  color: textColor?.withValues(alpha: 0.6), fontSize: 14)),
          const SizedBox(height: 60),

          // Start Button Hero
          GestureDetector(
            onTap: _startTest,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLayout05 ? Layout03Theme.background : Colors.white,
                boxShadow: isLayout05
                    ? [
                        const BoxShadow(
                            color: Colors.white,
                            offset: Offset(-8, -8),
                            blurRadius: 16),
                        BoxShadow(
                            color:
                                const Color(0xFFA3B1C6).withValues(alpha: 0.4),
                            offset: const Offset(8, 8),
                            blurRadius: 16),
                      ]
                    : [
                        BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5),
                        const BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5))
                      ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Inner Gradient Circle
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.8)
                            ]),
                        boxShadow: [
                          BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8))
                        ]),
                    child: const Icon(Icons.power_settings_new_rounded,
                        color: Colors.white, size: 48),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 48),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text('Conexão Segura',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(width: 24),
              const Icon(Icons.public, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text('Servidor Otimizado',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 100), // Added bottom padding for nav
        ],
      ),
    );
  }

  // --- VIEW: GAUGE (Active & Result) ---
  Widget _buildGaugeView(BuildContext context, DiagnosticoState state,
      bool isLayout05, double speedMbps, bool isDownload, bool isFinished,
      {bool isDarkLayout = false}) {
    final theme = Theme.of(context);
    final primaryColor =
        isLayout05 ? Layout03Theme.primary : theme.primaryColor;

    // Determine max speed for gauge
    double maxGauge = 100;
    if (speedMbps > 90) maxGauge = 500;
    if (speedMbps > 450) maxGauge = 1000;
    if (speedMbps > 950) maxGauge = 2000;

    return Column(
      children: [
        const SizedBox(height: 32),
        // Gauge Section
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 280,
                width: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background Arc
                    PieChart(PieChartData(
                        startDegreeOffset: 135,
                        sectionsSpace: 0,
                        centerSpaceRadius: 100,
                        sections: [
                          PieChartSectionData(
                            color: isLayout05
                                ? Colors.grey[300]
                                : Colors.grey[200]!.withValues(alpha: 0.5),
                            value: 75, // 270 degrees
                            title: '',
                            radius: 15,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                              color: Colors.transparent,
                              value: 25,
                              title: '',
                              showTitle: false,
                              radius: 15),
                        ])),
                    // Active Arc
                    SizedBox(
                      width: 230,
                      height: 230,
                      child: RotationTransition(
                        turns: const AlwaysStoppedAnimation(225 / 360),
                        child: CircularProgressIndicator(
                          value: (speedMbps / maxGauge).clamp(0.0, 0.75),
                          strokeWidth: 15,
                          // If finished, show a "complete" color mix or just the primary
                          color: isFinished
                              ? primaryColor
                              : (isDownload
                                  ? (isLayout05 ? Colors.cyan : Colors.green)
                                  : Colors.purple),
                          backgroundColor: Colors.transparent,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    ),

                    // Text in Center
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            isFinished
                                ? 'RESULTADO FINAL'
                                : (isDownload ? 'DOWNLOAD' : 'UPLOAD'),
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        Text(speedMbps.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: isDarkLayout
                                  ? Colors.white
                                  : (isLayout05
                                      ? Layout03Theme.textDark
                                      : theme.textTheme.bodyLarge?.color),
                            )),
                        Text('Mbps',
                            style: TextStyle(
                                color: isDarkLayout
                                    ? Colors.white70
                                    : Colors.grey[600],
                                fontSize: 16)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),

        // Stats & Controls
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Real-time Graph (Small)
                if (_downloadPoints.isNotEmpty || _uploadPoints.isNotEmpty)
                  Container(
                    height: 60,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          if (_downloadPoints.isNotEmpty)
                            LineChartBarData(
                              spots: _downloadPoints,
                              isCurved: true,
                              color: Colors.green,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.green.withValues(alpha: 0.1)),
                            ),
                          if (_uploadPoints.isNotEmpty)
                            LineChartBarData(
                              spots: _uploadPoints,
                              isCurved: true,
                              color: Colors.purple,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.purple.withValues(alpha: 0.1)),
                            ),
                        ],
                        lineTouchData: const LineTouchData(enabled: false),
                      ),
                    ),
                  ),

                Text(
                  isFinished
                      ? "Teste Concluído"
                      : (isDownload
                          ? "Testando Download..."
                          : "Testando Upload..."),
                  style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 20),

                // Mini Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat(
                        context,
                        'Ping',
                        '${state.speedTestPingLatency?.toStringAsFixed(0) ?? '-'} ms',
                        isLayout05,
                        isDarkLayout: isDarkLayout),
                    _buildMiniStat(
                        context,
                        'Download',
                        state.customDownloadResultMbps.toStringAsFixed(1),
                        isLayout05,
                        unit: 'Mbps',
                        isDarkLayout: isDarkLayout),
                    _buildMiniStat(
                        context,
                        'Upload',
                        state.customUploadResultMbps.toStringAsFixed(1),
                        isLayout05,
                        unit: 'Mbps',
                        isDarkLayout: isDarkLayout),
                  ],
                ),

                const Spacer(),

                // Action Button (Cancel or Restart)
                if (isFinished)
                  ElevatedButton.icon(
                    onPressed: _startTest,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text("Refazer Teste",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30))),
                  )
                else
                  TextButton.icon(
                    onPressed: _stopTest,
                    icon: const Icon(Icons.close, color: Colors.grey),
                    label: const Text('Cancelar Teste',
                        style: TextStyle(color: Colors.grey)),
                  ),

                // Extra Padding for Bottom Nav Overlap
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // State for Chart
  final List<FlSpot> _downloadPoints = [];
  final List<FlSpot> _uploadPoints = [];
  double _time = 0;
  // ignore: cancel_subscriptions
  StreamSubscription?
      _subscription; // Using cancel_subscriptions ignore because it is cancelled in dispose

  @override
  void initState() {
    super.initState();
    // Reset points on init
  }

  void _listenToStream() {
    _service.stateStream.listen((state) {
      if (state.testResultsDisplay['speedTestCustom']?['status'] ==
          TestStatus.running) {
        final down = state.customDownloadResultMbps;
        final up = state.customUploadResultMbps;
        if (down > 0 && up <= 1) {
          // Downloading
          if (mounted) {
            setState(() {
              _time += 1;
              _downloadPoints.add(FlSpot(_time, down));
              if (_downloadPoints.length > 50) _downloadPoints.removeAt(0);
            });
          }
        } else if (up > 1) {
          // Uploading
          if (mounted) {
            setState(() {
              _time += 1;
              _uploadPoints.add(FlSpot(_time, up));
              if (_uploadPoints.length > 50) _uploadPoints.removeAt(0);
            });
          }
        }
      } else if (state.testResultsDisplay['speedTestCustom']?['status'] ==
          TestStatus.pending) {
        // Reset on idle/pending start
        if (_time > 0 && mounted) {
          setState(() {
            _downloadPoints.clear();
            _uploadPoints.clear();
            _time = 0;
          });
        }
      }
    });
  }

  // To properly implement the listener, I need to call `_listenToStream` once service is ready.
  // But `_service` is lazy loaded in `didChangeDependencies`.

  Widget _buildMiniStat(
      BuildContext context, String title, String value, bool isLayout05,
      {String unit = '', bool isDarkLayout = false}) {
    return Column(
      children: [
        Text(title,
            style: TextStyle(
                color: isDarkLayout ? Colors.white70 : Colors.grey,
                fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isDarkLayout
                        ? Colors.white
                        : (isLayout05
                            ? Layout03Theme.textDark
                            : Colors.black87))),
            if (unit.isNotEmpty)
              Text(" $unit",
                  style: const TextStyle(fontSize: 10, color: Colors.grey))
          ],
        )
      ],
    );
  }
}
```

---

### `lib/core/pages/shared_suporte_page.dart`
> Página compartilhada

```dart
// Layout 02 - Suporte Page
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/providers.dart';

import '../../core/models/provider_config.dart';
import '../../layouts/layout_03/theme.dart';
import '../../layout_selector.dart';

class SuportePage extends ConsumerWidget {
  const SuportePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configurationProvider);
    final authState = ref.read(authNotifierProvider);
    final providerConfig = config.providerConfig;
    final usuario = authState.value;

    if (providerConfig == null || usuario == null) {
      return const Scaffold(
        body: Center(child: Text('Configuração não encontrada')),
      );
    }

    final layoutType = providerConfig.layoutType;
    final isLayout05 = layoutType == 'layout_05';
    final isDarkLayout = layoutType == 'layout_06';

    final theme = Theme.of(context);
    Color backgroundColor;
    Color appBarColor;
    Color appBarTextColor;
    if (isDarkLayout) {
      backgroundColor = const Color(0xFF0A0A0A);
      appBarColor = const Color(0xFF0A0A0A);
      appBarTextColor = Colors.white;
    } else if (isLayout05) {
      backgroundColor = Layout03Theme.background;
      appBarColor = Layout03Theme.background;
      appBarTextColor = Layout03Theme.textDark;
    } else {
      backgroundColor = theme.scaffoldBackgroundColor;
      appBarColor = theme.primaryColor;
      appBarTextColor = Colors.white;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Suporte', style: TextStyle(color: appBarTextColor)),
        backgroundColor: appBarColor,
        iconTheme: IconThemeData(color: appBarTextColor),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildConnectionStatusCard(context, usuario.status, isLayout05,
              isDarkLayout: isDarkLayout),
          const SizedBox(height: 24),
          // Removido "Canais de Atendimento" por solicitação - Redundante com o botão de WhatsApp abaixo
          // _buildContactChannelsCard(...),
          // const SizedBox(height: 24),
          _buildTicketCard(context, providerConfig, isLayout05,
              isDarkLayout: isDarkLayout),
          const SizedBox(height: 100), // Padding for BottomNav
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard(
      BuildContext context, String status, bool isLayout05,
      {bool isDarkLayout = false}) {
    final theme = Theme.of(context);
    final isOk = status.toLowerCase() == 'ativo';

    BoxDecoration decoration;
    if (isDarkLayout) {
      decoration = BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
      );
    } else if (isLayout05) {
      decoration = Layout03Theme.neumorphicDecoration;
    } else {
      decoration = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      );
    }

    // final textColor = isDarkLayout ? Colors.white : Colors.black87;
    // final subtitleColor =
    //    isDarkLayout ? const Color(0xFF8E8E93) : Colors.grey[600];

    return Container(
      decoration: decoration,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status da Conexão',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isLayout05 ? Layout03Theme.textDark : null,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOk ? Colors.green : Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: (isOk ? Colors.green : Colors.red)
                            .withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  status,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isLayout05 ? Layout03Theme.textDark : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isOk
                  ? 'Sua conexão está funcionando normalmente. Se encontrar problemas, tente nosso diagnóstico.'
                  : 'Detectamos um problema com sua conexão. Verifique suas faturas ou entre em contato.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isLayout05 ? Layout03Theme.textGrey : null,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: isLayout05
                  ? ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LayoutSelector.getDiagnosticoPage(
                              layoutType: isLayout05
                                  ? 'layout_05'
                                  : (isDarkLayout ? 'layout_06' : 'layout_02'),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Layout03Theme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Diagnóstico de Rede'),
                    )
                  : OutlinedButton.icon(
                      icon: const Icon(Icons.network_check, size: 20),
                      label: const Text('Diagnóstico de Rede'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LayoutSelector.getDiagnosticoPage(
                              layoutType: isLayout05
                                  ? 'layout_05'
                                  : (isDarkLayout ? 'layout_06' : 'layout_02'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(
      BuildContext context, ProviderConfig? providerConfig, bool isLayout05,
      {bool isDarkLayout = false}) {
    final theme = Theme.of(context);

    BoxDecoration decoration;
    if (isDarkLayout) {
      decoration = BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
      );
    } else if (isLayout05) {
      decoration = Layout03Theme.neumorphicDecoration;
    } else {
      decoration = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      );
    }

    // final textColor = isDarkLayout ? Colors.white : null;
    // final subtitleColor = isDarkLayout ? const Color(0xFF8E8E93) : null;

    return Container(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Precisa de Ajuda?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isLayout05 ? Layout03Theme.textDark : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Entre em contato diretamente com nosso suporte técnico via WhatsApp.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isLayout05 ? Layout03Theme.textGrey : null,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat), // Changed icon to chat
                label:
                    const Text('Abrir Chamado via WhatsApp'), // Updated label
                onPressed: () {
                  if (providerConfig == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erro de configuração.')),
                    );
                    return;
                  }

                  // 1. Tenta achar contato TIPO whatsapp
                  var uniqueContact = providerConfig.config.supportContacts
                      .where((c) =>
                          c.type.toLowerCase() == 'whatsapp' &&
                          c.value.isNotEmpty)
                      .firstOrNull;

                  // 2. Se não achar, tenta achar contato com NOME whatsapp
                  uniqueContact ??= providerConfig.config.supportContacts
                      .where((c) =>
                          c.name.toLowerCase().contains('whatsapp') &&
                          c.value.isNotEmpty)
                      .firstOrNull;

                  if (uniqueContact != null) {
                    final number =
                        uniqueContact.value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (number.isNotEmpty) {
                      launchUrl(
                        Uri.parse('https://wa.me/$number'),
                        mode: LaunchMode.externalApplication,
                      );
                      return;
                    }
                  }

                  // 3. Fallback: Se não achar nada de WhatsApp, tenta o primeiro telefone
                  final firstPhone = providerConfig.config.supportContacts
                      .where((c) =>
                          c.type.toLowerCase() == 'phone' && c.value.isNotEmpty)
                      .firstOrNull;

                  if (firstPhone != null) {
                    final number =
                        firstPhone.value.replaceAll(RegExp(r'[^0-9]'), '');
                    launchUrl(Uri.parse('tel:$number'));
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Nenhum canal de suporte encontrado.')),
                  );
                },
                style: isLayout05
                    ? ElevatedButton.styleFrom(
                        backgroundColor: Layout03Theme.secondary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### `lib/core/pages/shared_traceroute_page.dart`
> Página compartilhada

```dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers/providers.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../layouts/layout_03/theme.dart';

class SharedTraceRoutePage extends ConsumerStatefulWidget {
  const SharedTraceRoutePage({super.key});

  @override
  ConsumerState<SharedTraceRoutePage> createState() =>
      _SharedTraceRoutePageState();
}

class TraceHop {
  final int hop;
  final String ip;
  final String time;
  final String status;

  TraceHop({
    required this.hop,
    required this.ip,
    required this.time,
    required this.status,
  });
}

class _SharedTraceRoutePageState extends ConsumerState<SharedTraceRoutePage> {
  final TextEditingController _ipController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isRunning = false;
  final List<TraceHop> _hops = [];
  String _currentStatus = "Aguardando início...";

  @override
  void dispose() {
    _ipController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startTraceRoute() async {
    final target = _ipController.text.trim();
    if (target.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite um IP ou Domínio.')),
      );
      return;
    }

    setState(() {
      _isRunning = true;
      _hops.clear();
      _currentStatus = "Iniciando Rota (Max 10 saltos)...";
    });

    FocusScope.of(context).unfocus();

    for (int ttl = 1; ttl <= 10; ttl++) {
      if (!_isRunning) break;

      setState(() {
        _currentStatus = "Testando Salto $ttl...";
      });

      try {
        final result = await _pingWithTtl(target, ttl);

        setState(() {
          _hops.add(result);
        });

        // Auto-scroll to bottom
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent +
                80, // estimated item height
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }

        if (result.status == "Alcançado") {
          setState(() => _currentStatus = "Destino alcançado!");
          break;
        }
      } catch (e) {
        setState(() {
          _hops.add(TraceHop(hop: ttl, ip: "*", time: "*", status: "Erro: $e"));
        });
      }
    }

    setState(() {
      _isRunning = false;
      if (_currentStatus.startsWith("Testando")) {
        _currentStatus = "Finalizado (Limite de 10 saltos).";
      }
    });
  }

  Future<TraceHop> _pingWithTtl(String target, int ttl) async {
    final stopwatch = Stopwatch()..start();
    ProcessResult? result;
    try {
      result = await Process.run(
          'ping', ['-c', '1', '-t', '$ttl', '-W', '2', target]);
    } catch (e) {
      stopwatch.stop();
      return TraceHop(
          hop: ttl, ip: "Erro", time: "", status: "Falha ao executar");
    }
    stopwatch.stop();

    final output = result.stdout.toString();
    // print("DEBUG: TTL $ttl Output: $output"); // Uncomment for debugging

    String ip = "*";
    String time = "${stopwatch.elapsedMilliseconds} ms";
    // Default time is wall-clock time (RTT approx)

    String status = "Sem Resposta";

    if (output.contains("Time to live exceeded") ||
        output.contains("exceeded")) {
      // checking for "exceeded" covers generic case
      status = "Salto $ttl"; // Cleaner status
      final match = RegExp(r"From\s+([0-9\.]+)(?::| )").firstMatch(output);
      if (match != null) {
        ip = match.group(1) ?? "*";
      }
    } else if (output.contains("bytes from")) {
      status = "Alcançado";
      final matchIp = RegExp(r"from\s+([0-9\.]+)(?::| )").firstMatch(output);
      if (matchIp != null) ip = matchIp.group(1) ?? target;

      // Try to parse exact ping time, fallback to stopwatch
      final matchTime = RegExp(r"time=([0-9\.]+)").firstMatch(output);
      if (matchTime != null) {
        time = "${matchTime.group(1)} ms";
      }
    } else if (output.contains("100% packet loss")) {
      time = "*";
      status = "Esgotado";
    }

    if (ip == "*" && status == "Sem Resposta") {
      status = "Tempo Esgotado";
      time = "*";
    }

    return TraceHop(hop: ttl, ip: ip, time: time, status: status);
  }

  Future<void> _sharePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Relatório de Rota (Tracert)',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 18)),
                    pw.Text(DateTime.now().toString().split('.')[0]),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Alvo: ${_ipController.text}'),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Salto', 'IP', 'Tempo', 'Status'],
                  ..._hops.map((hop) =>
                      [hop.hop.toString(), hop.ip, hop.time, hop.status]),
                ],
              ),
            ],
          );
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/trace_route_report.pdf");
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)],
          text: 'Relatório de Rota (Tracert)');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compartilhar PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configProvider = ref.watch(configurationProvider);
    final layoutType = configProvider.providerConfig?.layoutType;
    final isLayout05 = layoutType == 'layout_05';
    final isDarkLayout = layoutType == 'layout_06';

    Color backgroundColor;
    Color appBarColor;
    Color appBarTextColor;
    if (isDarkLayout) {
      backgroundColor = const Color(0xFF0A0A0A);
      appBarColor = const Color(0xFF0A0A0A);
      appBarTextColor = Colors.white;
    } else if (isLayout05) {
      backgroundColor = Layout03Theme.background;
      appBarColor = Layout03Theme.background;
      appBarTextColor = Layout03Theme.textDark;
    } else {
      backgroundColor = theme.scaffoldBackgroundColor;
      appBarColor = theme.primaryColor;
      appBarTextColor = Colors.white;
    }

    final cardDecoration = isDarkLayout
        ? BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
          )
        : (isLayout05 ? Layout03Theme.neumorphicDecoration : null);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Rota (Tracert)', style: TextStyle(color: appBarTextColor)),
        backgroundColor: appBarColor,
        iconTheme: IconThemeData(color: appBarTextColor),
        actions: [
          if (_hops.isNotEmpty && !_isRunning)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _sharePdf,
              tooltip: "Compartilhar PDF",
            )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: isDarkLayout
                ? Container(
                    decoration: cardDecoration,
                    padding: const EdgeInsets.all(16),
                    child: _buildInputContent(context, isLayout05,
                        isDarkLayout: isDarkLayout),
                  )
                : (isLayout05
                    ? Container(
                        decoration: Layout03Theme.neumorphicDecoration,
                        padding: const EdgeInsets.all(16),
                        child: _buildInputContent(context, isLayout05,
                            isDarkLayout: isDarkLayout),
                      )
                    : DashboardCard(
                        child: _buildInputContent(context, isLayout05,
                            isDarkLayout: isDarkLayout),
                      )),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 180),
              itemCount: _hops.length,
              itemBuilder: (context, index) {
                final hop = _hops[index];
                return _buildHopCard(hop, isLayout05,
                    isDarkLayout: isDarkLayout);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputContent(BuildContext context, bool isLayout05,
      {bool isDarkLayout = false}) {
    final textColor = isDarkLayout ? Colors.white : Colors.black87;
    // final primaryColor =
    //    isDarkLayout ? const Color(0xFF00D9FF) : Theme.of(context).primaryColor;

    return Column(
      children: [
        TextField(
          controller: _ipController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: 'IP ou Domínio de Destino',
            labelStyle:
                TextStyle(color: isDarkLayout ? const Color(0xFF8E8E93) : null),
            hintText: 'Ex: 8.8.8.8 ou google.com',
            hintStyle:
                TextStyle(color: isDarkLayout ? const Color(0xFF8E8E93) : null),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                  color: isDarkLayout ? const Color(0xFF3A3A3C) : Colors.grey),
            ),
            enabledBorder: isDarkLayout
                ? OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF3A3A3C)),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            focusedBorder: isDarkLayout
                ? OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            prefixIcon: Icon(Icons.search,
                color: isDarkLayout ? const Color(0xFF8E8E93) : null),
            filled: isLayout05 || isDarkLayout,
            fillColor: isDarkLayout
                ? const Color(0xFF1C1C1E)
                : (isLayout05 ? Colors.white.withValues(alpha: 0.5) : null),
          ),
          onSubmitted: (_) => _isRunning ? null : _startTraceRoute(),
        ),
        const SizedBox(height: 16),
        Text(_currentStatus,
            style: TextStyle(
                color: _isRunning
                    ? (isDarkLayout
                        ? const Color(0xFF00D9FF)
                        : (isLayout05
                            ? Layout03Theme.primary
                            : Theme.of(context).primaryColor))
                    : (isDarkLayout ? const Color(0xFF8E8E93) : Colors.grey))),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: isDarkLayout
              ? ElevatedButton.icon(
                  onPressed: () {
                    if (_isRunning) {
                      setState(() => _isRunning = false);
                    } else {
                      _startTraceRoute();
                    }
                  },
                  icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow,
                      color: Colors.black),
                  label: Text(_isRunning ? "Parar" : "Iniciar Rota",
                      style: const TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                )
              : AppButton(
                  label: _isRunning ? "Parar" : "Iniciar Rota",
                  icon: _isRunning ? Icons.stop : Icons.play_arrow,
                  onPressed: () {
                    if (_isRunning) {
                      setState(() => _isRunning = false);
                    } else {
                      _startTraceRoute();
                    }
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHopCard(TraceHop hop, bool isLayout05,
      {bool isDarkLayout = false}) {
    if (isDarkLayout) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: hop.status == "Alcançado"
                ? const Color(0xFF00D9FF)
                : const Color(0xFF3A3A3C),
            child: Text("${hop.hop}",
                style: TextStyle(
                    color: hop.status == "Alcançado"
                        ? Colors.black
                        : Colors.white)),
          ),
          title: Text(hop.ip,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          subtitle: Text(hop.status,
              style: const TextStyle(color: Color(0xFF8E8E93))),
          trailing: Text(hop.time,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF00D9FF))),
        ),
      );
    }
    if (isLayout05) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: Layout03Theme.neumorphicDecoration.copyWith(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: hop.status == "Alcançado"
                ? Layout03Theme.primary
                : Layout03Theme.textGrey.withValues(alpha: 0.3),
            child: Text("${hop.hop}",
                style: TextStyle(
                    color: hop.status == "Alcançado"
                        ? Colors.white
                        : Layout03Theme.textDark)),
          ),
          title: Text(hop.ip,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Layout03Theme.textDark)),
          subtitle: Text(hop.status,
              style: const TextStyle(color: Layout03Theme.textGrey)),
          trailing: Text(hop.time,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Layout03Theme.textDark)),
        ),
      );
    }
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              hop.status == "Alcançado" ? Colors.green : Colors.grey[300],
          child: Text("${hop.hop}",
              style: TextStyle(
                  color: hop.status == "Alcançado"
                      ? Colors.white
                      : Colors.black87)),
        ),
        title:
            Text(hop.ip, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(hop.status),
        trailing:
            Text(hop.time, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
```

## 🛠️ Core / Utils
> Utilitários e helpers


---

### `lib/core/utils/color_utils.dart`
> Utilitário

```dart
import 'package:flutter/material.dart';

/// Converte uma string hexadecimal de cor para Color
/// Suporta formatos: #RRGGBB, #AARRGGBB, RRGGBB, AARRGGBB
Color hexToColor(String hex) {
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  return Color(int.parse(hex, radix: 16));
}

/// Retorna uma cor mais escura baseada na cor original
Color darken(Color color, [double amount = 0.1]) {
  assert(amount >= 0 && amount <= 1);
  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return hslDark.toColor();
}

/// Retorna uma cor mais clara baseada na cor original
Color lighten(Color color, [double amount = 0.1]) {
  assert(amount >= 0 && amount <= 1);
  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
  return hslLight.toColor();
}
```

---

### `lib/core/utils/page_transitions.dart`
> Utilitário

```dart
// ARQUIVO: lib/core/utils/page_transitions.dart
// DESCRIÇÃO: Animações de transição de página personalizadas

import 'package:flutter/material.dart';

/// Transição com fade e slide
class FadeSlideTransition extends PageRouteBuilder {
  final Widget page;
  final Duration duration;
  final Offset beginOffset;

  FadeSlideTransition({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.beginOffset = const Offset(0.0, 0.3),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );

            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: beginOffset,
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}

/// Transição com escala
class ScalePageTransition extends PageRouteBuilder {
  final Widget page;
  final Duration duration;

  ScalePageTransition({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            );

            return FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.9,
                  end: 1.0,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}

/// Transição slide da direita
class SlideRightTransition extends PageRouteBuilder {
  final Widget page;
  final Duration duration;

  SlideRightTransition({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );
          },
        );
}

/// Widget com animação de entrada ao aparecer na tela
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;

  const AnimatedListItem({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Delay baseado no índice
    Future.delayed(
        Duration(milliseconds: widget.delay.inMilliseconds * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Widget de botão com animação de pressão
class AnimatedPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  const AnimatedPressButton({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<AnimatedPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Animação de shimmer para loading
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}
```

---

### `lib/core/utils/pdf_generator_service.dart`
> Utilitário

```dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/diagnostico_state.dart';

class PdfGeneratorService {
  Future<void> stopAndSharePdf(DiagnosticoState state) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Relatório de Diagnóstico',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            _buildSection(
                'Velocidade (Download/Upload)',
                'Download: ${state.customDownloadResultMbps.toStringAsFixed(1)} Mbps\n'
                    'Upload: ${state.customUploadResultMbps.toStringAsFixed(1)} Mbps'),
            _buildSection('Ping (Latência)',
                '${(state.speedTestPingLatency ?? 0.0).toStringAsFixed(0)} ms'),
            _buildSection('Informações WiFi',
                _parseResult(state.testResultsDisplay['wifiInfo'])),
            _buildSection('Gateway (Roteador)',
                _parseResult(state.testResultsDisplay['pingGateway'])),
            _buildSection('IP Público',
                _parseResult(state.testResultsDisplay['publicIp'])),
            _buildSection(
                'Conexão Internet (Google/Cloudflare)',
                'Google: ${_parseResult(state.testResultsDisplay['pingGoogle'])}\n'
                    'Cloudflare: ${_parseResult(state.testResultsDisplay['pingCloudflare'])}'),
            _buildSection('Dispositivo',
                _parseResult(state.testResultsDisplay['deviceInfo'])),
            _buildSection('Bateria',
                _parseResult(state.testResultsDisplay['batteryInfo'])),
          ];
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file =
          File('${output.path}/diagnostico_${now.millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)],
          text: 'Segue relatório de diagnóstico de rede.');
    } catch (e) {
      debugPrint('Erro ao gerar/compartilhar PDF: $e');
    }
  }

  String _parseResult(Map<String, dynamic>? data) {
    if (data == null) return "---";
    final result = data['result'] as String?;
    if (result == null || result.isEmpty) return "---";
    return result;
  }

  pw.Widget _buildSection(String title, String content) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(content, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
```

## 📋 Core / Main Files


---

### `lib/core/design_system.dart`
> Design System centralizado com tokens

```dart
/// Design System Centralizado
/// Tokens de design reutilizáveis para consistência visual

import 'package:flutter/material.dart';

/// Cores do Sistema
class AppColors {
  // Cores Primárias
  static const Color primary = Color(0xFF6366F1); // Indigo moderno
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);

  // Cores Secundárias
  static const Color secondary = Color(0xFF10B981); // Emerald
  static const Color secondaryDark = Color(0xFF059669);
  static const Color secondaryLight = Color(0xFF34D399);

  // Cores de Feedback
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Cores Neutras
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color backgroundDark = Color(0xFF0F172A);

  // Cores de Texto
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Colors.white;

  // Cores de Borda
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  // Cores Especiais (Premium)
  static const Color neonCyan = Color(0xFF00F3FF);
  static const Color neonPink = Color(0xFFBC13FE);
  static const Color gold = Color(0xFFFFD700);
}

/// Tipografia do Sistema
class AppTypography {
  static const String fontFamily = 'Inter';

  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    letterSpacing: 1.0,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  // Button
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

/// Espaçamentos do Sistema
class AppSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Padding padrão
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);

  // Padding horizontal
  static const EdgeInsets paddingHorizontalMd =
      EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg =
      EdgeInsets.symmetric(horizontal: lg);

  // Padding de página
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(lg, md, lg, lg);
  static const EdgeInsets pageWithBottomNav =
      EdgeInsets.fromLTRB(lg, md, lg, 100);
}

/// Sombras do Sistema
class AppShadows {
  // Sombras sutis
  static const BoxShadow xs = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static const BoxShadow sm = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  static const BoxShadow md = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 16,
    offset: Offset(0, 8),
  );

  static const BoxShadow lg = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 24,
    offset: Offset(0, 12),
  );

  static const BoxShadow xl = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 32,
    offset: Offset(0, 16),
  );

  // Sombras coloridas (para efeitos premium)
  static BoxShadow colored(Color color, {double opacity = 0.3}) => BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: 20,
        offset: const Offset(0, 10),
      );

  // Sombra de glow (para efeitos neon)
  static BoxShadow glow(Color color,
          {double opacity = 0.4, double blur = 20}) =>
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: 2,
      );

  // Lista para cards
  static const List<BoxShadow> card = [sm];
  static const List<BoxShadow> cardElevated = [md];
  static const List<BoxShadow> cardFloating = [lg];
}

/// Raios de Borda do Sistema
class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;

  // BorderRadius prontos
  static const BorderRadius borderRadiusSm =
      BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderRadiusMd =
      BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderRadiusLg =
      BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderRadiusXl =
      BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderRadiusFull =
      BorderRadius.all(Radius.circular(full));
}

/// Durações de Animação
class AppDurations {
  static const Duration fast = Duration(milliseconds: 100);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration slower = Duration(milliseconds: 500);
  static const Duration page = Duration(milliseconds: 400);
}

/// Curvas de Animação
class AppCurves {
  static const Curve ease = Curves.easeInOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve bounce = Curves.elasticOut;
  static const Curve smooth = Curves.fastOutSlowIn;
}

/// Decorações Reutilizáveis
class AppDecorations {
  // Card padrão
  static BoxDecoration card({Color? color}) => BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: AppRadius.borderRadiusLg,
        boxShadow: AppShadows.card,
      );

  // Card elevado
  static BoxDecoration cardElevated({Color? color}) => BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: AppRadius.borderRadiusLg,
        boxShadow: AppShadows.cardElevated,
      );

  // Card com borda
  static BoxDecoration cardBordered({Color? borderColor}) => BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(color: borderColor ?? AppColors.border),
      );

  // Card glassmorphism
  static BoxDecoration glass({Color? color, double opacity = 0.1}) =>
      BoxDecoration(
        color: (color ?? Colors.white).withValues(alpha: opacity),
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      );

  // Badge/Chip
  static BoxDecoration badge(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.borderRadiusFull,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      );
}
```

---

### `lib/core/painel_page.dart`
> Página principal que gerencia layouts

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../layouts/layout_04/widgets/skeleton_dashboard_page.dart';
import 'services/diagnostico_service.dart';
import '../layout_selector.dart';
import '../layouts/layout_03/theme.dart';
import '../layouts/layout_03/widgets/neumorphic_bottom_nav.dart';
import 'providers/providers.dart';
import 'widgets/offline_banner.dart';
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

  @override
  void initState() {
    super.initState();
    // Refresh data in background when Painel opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final config = ref.read(configurationProvider).providerConfig;
    if (config != null) {
      // Refresh Configuration (for WhatsApp changes etc)
      ref.read(configurationProvider).loadConfig(config.id);

      // Refresh User Data (for Balance 0.00 fix)
      if (ref.read(authNotifierProvider).value != null) {
        ref.read(authNotifierProvider.notifier).refreshUserData(config);
      }
    }
  }

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
    'trace_route': 'Rota (Tracert)',
  };

  final Map<String, IconData> _pageIcons = {
    'dashboard': Icons.dashboard,
    'invoices': Icons.receipt_long,
    'support': Icons.support_agent,
    'internet_usage': Icons.data_usage,
    'speed_test': Icons.speed,
    'network_diagnostic': Icons.wifi_tethering,
    'trace_route': Icons.alt_route_rounded,
    'contract': Icons.description,
    'my_ip': Icons.public,
    'faq': Icons.help_outline,
    'notifications': Icons.notifications,
  };

  void _navigateToPage(String pageId) {
    setState(() {
      _currentPage = pageId;
    });
    // BI (Analytics)
    ref.read(analyticsServiceProvider).logScreenView(pageId);

    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final configProvider = ref.watch(configurationProvider);
    final usuario = authState.value;

    final layoutType = configProvider.providerConfig?.layoutType ?? 'layout_02';
    // Layouts with custom bottom navigation (Layout 06 handles its own in dashboard)
    // Layout 04 and 06 have their own dark bottom nav, so exclude them
    final hasBottomNav = layoutType == 'layout_05' || layoutType == 'layout_02';

    if (authState.isLoading) {
      return const SkeletonDashboardPage();
    }

    if (usuario == null) {
      return const Scaffold(
        body: Center(child: Text('Erro: Usuário não autenticado')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
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
          if (context.mounted) {
            Navigator.pop(
                context); // Sai do app (PopScope allows exit if we let it, but here we manually pop the route)
          }
          // Actually, for PopScope with canPop: false, we can't just return.
          // We need to use SystemChannels.platform.invokeMethod('SystemNavigator.pop') for pure exit, or let the router handle it.
          // Since this is the main page, popping it exits the app.
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: null, // Respect theme's scaffoldBackgroundColor
        appBar: _buildAppBar(context, layoutType),
        drawer: _buildDrawer(context, usuario, ref, layoutType),
        body: Stack(
          children: [
            _buildBody(layoutType, usuario, context),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: OfflineBanner(),
            ),
            if (hasBottomNav)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: NeumorphicBottomNav(
                  currentIndex: _getBottomNavIndex(),
                  onTap: _onBottomNavTap,
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
    final isNeumorphic = layoutType == 'layout_05';
    // Layout 02 usa cores roxas
    final isLayout02 = layoutType == 'layout_02';

    final isOnDashboard = _currentPage == 'dashboard';
    final pageName = _pageNames[_currentPage] ?? 'Dashboard';

    if (isNeumorphic) {
      return AppBar(
        backgroundColor: Layout03Theme.background,
        elevation: 0,
        centerTitle: true,
        leading: isOnDashboard
            ? Builder(
                builder: (context) => IconButton(
                      icon: const Icon(Icons.menu_rounded,
                          color: Layout03Theme.textDark),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ))
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: Layout03Theme.textDark),
                onPressed: () => setState(() => _currentPage = 'dashboard'),
              ),
        title: Text(pageName,
            style:
                Layout03Theme.heading2.copyWith(color: Layout03Theme.textDark)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Layout03Theme.textDark),
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
    // Layout 04 e Layout 06 também têm seus próprios headers
    if ((isLayout02 ||
            layoutType == 'layout_04' ||
            layoutType == 'layout_06') &&
        isOnDashboard) {
      return null;
    }

    // Default AppBar for Layout 04, Layout 06, etc. OR Layout 02 non-dashboard pages
    final primaryColor = Theme.of(context).primaryColor;
    final bool isDarkLayout =
        layoutType == 'layout_04' || layoutType == 'layout_06';
    Color bgColor;
    if (isLayout02) {
      bgColor = const Color(0xFF673AB7); // Purple for Layout 02
    } else if (isDarkLayout) {
      bgColor = const Color(0xFF0A0A0A); // Pure black for Layout 04/06
    } else {
      bgColor = primaryColor;
    }
    const contentColor = Colors.white;

    return AppBar(
      backgroundColor: bgColor,
      iconTheme: const IconThemeData(color: contentColor),
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
          ? Text(pageName, style: const TextStyle(color: contentColor))
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
                      color: contentColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: contentColor.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  pageName,
                  style: const TextStyle(
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
    final isNeumorphic = layoutType == 'layout_05';
    final primaryColor = Theme.of(context).primaryColor;

    if (isNeumorphic) {
      return Drawer(
        backgroundColor: Layout03Theme.background,
        elevation: 0,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              color: Layout03Theme.background,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Layout03Theme.background,
                      shape: BoxShape.circle,
                      boxShadow: [
                        const BoxShadow(
                          color: Colors.white,
                          offset: Offset(-8, -8),
                          blurRadius: 16,
                        ),
                        BoxShadow(
                          color: const Color(0xFFA3B1C6).withValues(alpha: 0.4),
                          offset: const Offset(8, 8),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Layout03Theme.primary,
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
                                Layout03Theme.heading2.copyWith(fontSize: 16)),
                        Text(usuario.plano,
                            style:
                                Layout03Theme.bodyText.copyWith(fontSize: 12)),
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
                      'trace_route', 'Rota (Tracert)', Icons.alt_route_rounded),
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
                        backgroundColor: Layout03Theme.background,
                        title: Text('Sair', style: Layout03Theme.heading2),
                        content: Text('Deseja realmente sair?',
                            style: Layout03Theme.bodyText),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar',
                                  style: TextStyle(
                                      color: Layout03Theme.textGrey))),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Sim, Sair',
                                  style:
                                      TextStyle(color: Layout03Theme.error))),
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

    // Layout 06: Dark Fintech Drawer
    final isDarkLayout = layoutType == 'layout_06';
    if (isDarkLayout) {
      final colorScheme = Theme.of(context).colorScheme;
      final primaryColor = Theme.of(context).primaryColor;
      final secondaryColor = colorScheme.secondary;
      final surfaceColor = Theme.of(context).cardColor;
      final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
      final textColor =
          Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

      return Drawer(
        backgroundColor: backgroundColor,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, secondaryColor],
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(usuario.nome,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text(usuario.plano,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8))),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDarkMenuItem('dashboard', 'Início', Icons.home_rounded),
                  _buildDarkMenuItem(
                      'invoices', 'Faturas', Icons.receipt_long_rounded),
                  _buildDarkMenuItem('wifi', 'Meu Wi-Fi', Icons.wifi_rounded),
                  _buildDarkMenuItem(
                      'speed_test', 'Velocidade', Icons.speed_rounded),
                  _buildDarkMenuItem('network_diagnostic', 'Diagnóstico',
                      Icons.analytics_rounded),
                  _buildDarkMenuItem(
                      'trace_route', 'Traceroute', Icons.route_rounded),
                  _buildDarkMenuItem(
                      'support', 'Suporte', Icons.headset_mic_rounded),
                  _buildDarkMenuItem(
                      'internet_usage', 'Consumo', Icons.data_usage_rounded),
                  _buildDarkMenuItem('my_ip', 'Meu IP', Icons.public_rounded),
                  _buildDarkMenuItem(
                      'contract', 'Contrato', Icons.description_rounded),
                  _buildDarkMenuItem('faq', 'FAQ', Icons.help_outline_rounded),
                  const SizedBox(height: 24),
                  Divider(color: textColor.withValues(alpha: 0.2)),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.star_rate_rounded,
                        color: Color(0xFFFFD700)),
                    title: const Text('Avalie este App',
                        style: TextStyle(color: Color(0xFFFFD700))),
                    onTap: () {
                      ref.read(reviewServiceProvider).openStoreListing();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded,
                        color: Color(0xFFFF453A)),
                    title: const Text('Sair',
                        style: TextStyle(color: Color(0xFFFF453A))),
                    onTap: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: surfaceColor,
                          title:
                              Text('Sair', style: TextStyle(color: textColor)),
                          content: Text('Deseja realmente sair?',
                              style: TextStyle(
                                  color: textColor.withValues(alpha: 0.7))),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text('Cancelar',
                                    style: TextStyle(
                                        color:
                                            textColor.withValues(alpha: 0.5)))),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Sim, Sair',
                                    style:
                                        TextStyle(color: Color(0xFFFF453A)))),
                          ],
                        ),
                      );
                      if (shouldLogout == true) {
                        ref.read(authNotifierProvider.notifier).logout();
                      }
                    },
                  ),
                  SizedBox(height: 50 + MediaQuery.of(context).padding.bottom),
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
              color: primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
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
                    color: Colors.white.withValues(alpha: 0.8),
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
          _buildMenuItem('trace_route', context),
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
          const SizedBox(height: 50), // Add padding for Android navigation bar
        ],
      ),
    );
  }

  Widget _buildNeumorphicMenuItem(String id, String label, IconData icon,
      {bool isLogout = false, VoidCallback? onTap}) {
    final isSelected = _currentPage == id;
    final color = isLogout
        ? Layout03Theme.error
        : (isSelected ? Layout03Theme.primary : Layout03Theme.textGrey);

    final decoration =
        isSelected ? Layout03Theme.neumorphicPressedDecoration : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: decoration,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: color),
        title: Text(label,
            style: TextStyle(
                color: isLogout ? Layout03Theme.error : Layout03Theme.textDark,
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
      selectedTileColor: primaryColor.withValues(alpha: 0.1),
      onTap: () => _navigateToPage(pageId),
    );
  }

  Widget _buildBody(String layoutType, Usuario usuario, BuildContext context) {
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
        onRefresh: () async {
          final config = ref.read(configurationProvider).providerConfig;
          if (config != null) {
            await ref
                .read(authNotifierProvider.notifier)
                .refreshUserData(config);
          }
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
      final configProvider = ref.read(configurationProvider);
      return LayoutSelector.getSpeedTestPage(
        layoutType: layoutType,
        diagnosticoService: DiagnosticoService(
          providerConfig: configProvider.providerConfig!,
          context: context,
        ),
        onBack: () => setState(() => _currentPage = 'dashboard'),
      );
    }

    if (_currentPage == 'trace_route') {
      return LayoutSelector.getTraceRoutePage(layoutType: layoutType);
    }

    if (_currentPage == 'notifications') {
      return LayoutSelector.getNotificationPage(layoutType: layoutType);
    }

    return _buildPlaceholderPage(layoutType);
  }

  Widget _buildPlaceholderPage(String layoutType) {
    final isLayout05 = layoutType == 'layout_05';
    final backgroundColor =
        isLayout05 ? Layout03Theme.background : Colors.grey[100];

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: isLayout05 ? const EdgeInsets.all(24) : null,
              decoration: isLayout05
                  ? Layout03Theme.neumorphicDecoration
                      .copyWith(shape: BoxShape.circle)
                  : null,
              child: Icon(
                _pageIcons[_currentPage] ?? Icons.construction,
                size: 80,
                color: isLayout05 ? Layout03Theme.textGrey : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _pageNames[_currentPage] ?? _currentPage,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isLayout05 ? Layout03Theme.textDark : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta página será implementada em breve',
              style: TextStyle(
                fontSize: 16,
                color: isLayout05 ? Layout03Theme.textGrey : Colors.grey[600],
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
              style: isLayout05
                  ? ElevatedButton.styleFrom(
                      backgroundColor: Layout03Theme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    )
                  : ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
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

  Widget _buildDarkMenuItem(String pageId, String label, IconData icon) {
    final isSelected = _currentPage == pageId;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? primaryColor : textColor.withValues(alpha: 0.6),
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? primaryColor : textColor,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          _navigateToPage(pageId);
        },
      ),
    );
  }
}
```

---

### `lib/layout_selector.dart`
> Seletor de layouts dinâmico

```dart
import 'package:flutter/material.dart';
import 'core/services/diagnostico_service.dart';

// Imports dos Dashboards (diferentes por layout)
import 'layouts/layout_01/dashboard_page.dart' as l01;
import 'layouts/layout_02/dashboard_page.dart' as l02;
import 'layouts/layout_03/dashboard_page.dart' as l03;
import 'layouts/layout_04/dashboard_page.dart' as l04;
import 'layouts/layout_04/pages/speed_test_page.dart' as l04_speed;
import 'layouts/layout_05/dashboard_page.dart' as l05;
import 'layouts/layout_05/pages/speed_test_page.dart' as l05_speed;
import 'layouts/layout_06/dashboard_page.dart' as l06;
import 'layouts/layout_06/login_page.dart' as l06_login;

// Imports dos Logins (diferentes por layout)
import 'layouts/layout_01/login_page.dart' as l01_login;
import 'layouts/layout_02/login_page.dart' as l02_login;
import 'layouts/layout_03/login_page.dart' as l03_login;
import 'layouts/layout_04/login_page.dart' as l04_login;
import 'layouts/layout_05/login_page.dart' as l05_login;

// ============================================
// PÁGINAS COMPARTILHADAS (idênticas entre layouts)
// ============================================
import 'core/pages/shared_financeiro_page.dart' as shared_fin;
import 'core/pages/shared_suporte_page.dart' as shared_sup;
import 'core/pages/shared_diagnostico_page.dart' as shared_diag;
import 'core/pages/shared_consumo_page.dart' as shared_cons;
import 'core/pages/shared_meu_ip_page.dart' as shared_ip;
import 'core/pages/shared_speed_test_page.dart' as shared_speed;
import 'core/pages/shared_traceroute_page.dart' as shared_trace;

// Layout 03 (ex-05) implementações próprias (Wifi)
import 'layouts/layout_03/wifi_page.dart' as l03_wifi;

// Imports do FAQ e Contrato (também compartilhados)
import 'core/pages/shared_faq_page.dart' as shared_faq;
import 'core/pages/shared_contrato_page.dart' as shared_cont;
import 'core/pages/shared_notification_page.dart' as shared_notif;

/// Classe utilitária que seleciona o layout correto baseado na configuração
/// carregada do Firestore (campo `layoutType`).
///
/// Uso:
/// ```dart
/// final layoutType = configProvider.providerConfig?.layoutType ?? 'layout_01';
/// return LayoutSelector.getLoginPage(layoutType: layoutType);
/// ```
class LayoutSelector {
  /// Retorna o widget de Dashboard correto para o layout especificado
  static Widget getDashboard({
    required String layoutType,
    required String customerName,
    required String planName,
    required String connectionStatus,
    required double billAmount,
    required DateTime billDueDate,
    required double usedGb,
    required double totalGb,
    required double downloadMbps,
    required double uploadMbps,
    required Function(String) onNavigate,
    List<Map<String, dynamic>>? menuItems,
    Color? customCardBg,
    Color? customCardText,
    Color? invoiceColor,
    Color? actionColor,
    Future<void> Function()? onRefresh,
  }) {
    switch (layoutType) {
      case 'layout_01':
        return l01.ProviderDashboardPage(
          customerName: customerName,
          planName: planName,
          connectionStatus: connectionStatus,
          billAmount: billAmount,
          billDueDate: billDueDate,
          usedGb: usedGb,
          totalGb: totalGb,
          downloadMbps: downloadMbps,
          uploadMbps: uploadMbps,
          onNavigate: onNavigate,
          menuItems: menuItems,
          customCardBg: customCardBg,
          customCardText: customCardText,
          invoiceColor: invoiceColor,
          actionColor: actionColor,
        );

      case 'layout_02':
        return l02.ProviderDashboardPage(
          customerName: customerName,
          planName: planName,
          connectionStatus: connectionStatus,
          billAmount: billAmount,
          billDueDate: billDueDate,
          usedGb: usedGb,
          totalGb: totalGb,
          downloadMbps: downloadMbps,
          uploadMbps: uploadMbps,
          onNavigate: onNavigate,
          menuItems: menuItems,
          customCardBg: customCardBg,
          customCardText: customCardText,
          invoiceColor: invoiceColor,
          actionColor: actionColor,
        );

      case 'layout_03':
        return l03.DashboardPage(
          customerName: customerName,
          planName: planName,
          connectionStatus: connectionStatus,
          billAmount: billAmount,
          billDueDate: billDueDate,
          usedGb: usedGb,
          totalGb: totalGb,
          downloadMbps: downloadMbps,
          uploadMbps: uploadMbps,
          onNavigate: onNavigate,
        );

      case 'layout_04':
        return l04.DashboardPage(
          customerName: customerName,
          planName: planName,
          connectionStatus: connectionStatus,
          billAmount: billAmount,
          billDueDate: billDueDate,
          usedGb: usedGb,
          totalGb: totalGb,
          downloadMbps: downloadMbps,
          uploadMbps: uploadMbps,
          onNavigate: onNavigate,
          menuItems: menuItems,
          onRefresh: onRefresh,
        );

      case 'layout_05':
        return l05.ProviderDashboardPage(
          customerName: customerName,
          planName: planName,
          connectionStatus: connectionStatus,
          billAmount: billAmount,
          billDueDate: billDueDate,
          usedGb: usedGb,
          totalGb: totalGb,
          downloadMbps: downloadMbps,
          uploadMbps: uploadMbps,
          onNavigate: onNavigate,
          menuItems: menuItems,
          customCardBg: customCardBg,
          customCardText: customCardText,
          invoiceColor: invoiceColor,
          actionColor: actionColor,
          onRefresh: onRefresh,
        );

      case 'layout_06':
        return l06.DashboardPage(
          customerName: customerName,
          planName: planName,
          connectionStatus: connectionStatus,
          billAmount: billAmount,
          billDueDate: billDueDate,
          usedGb: usedGb,
          totalGb: totalGb,
          downloadMbps: downloadMbps,
          uploadMbps: uploadMbps,
          onNavigate: onNavigate,
          menuItems: menuItems,
          onRefresh: onRefresh,
        );

      default:
        // Default to Layout 01 if unknown
        return l01.ProviderDashboardPage(
          customerName: customerName,
          planName: planName,
          connectionStatus: connectionStatus,
          billAmount: billAmount,
          billDueDate: billDueDate,
          usedGb: usedGb,
          totalGb: totalGb,
          downloadMbps: downloadMbps,
          uploadMbps: uploadMbps,
          onNavigate: onNavigate,
          menuItems: menuItems,
          customCardBg: customCardBg,
          customCardText: customCardText,
          invoiceColor: invoiceColor,
          actionColor: actionColor,
        );
    }
  }

  /// Retorna o widget de Login correto para o layout especificado
  static Widget getLoginPage(
      {required String layoutType, Map<String, dynamic>? arguments}) {
    switch (layoutType) {
      case 'layout_01':
        return const l01_login.LoginPage();
      case 'layout_02':
        return const l02_login.LoginPage();
      case 'layout_03':
        return const l03_login.LoginPage();
      case 'layout_04':
        return const l04_login.LoginPage();
      case 'layout_05':
        return const l05_login.LoginPage();
      case 'layout_06':
        return const l06_login.LoginPage();

      default:
        return const l01_login.LoginPage();
    }
  }

  /// Retorna o widget de Financeiro (Faturas) - COMPARTILHADO entre layouts
  static Widget getFinanceiroPage({required String layoutType}) {
    return const shared_fin.FinanceiroPage();
  }

  /// Retorna o widget de Suporte - COMPARTILHADO entre layouts
  static Widget getSuportePage({required String layoutType}) {
    return const shared_sup.SuportePage();
  }

  /// Retorna o widget de Diagnóstico - COMPARTILHADO entre layouts
  static Widget getDiagnosticoPage({required String layoutType}) {
    return const shared_diag.DiagnosticoPage();
  }

  /// Retorna o widget de Consumo - COMPARTILHADO entre layouts
  static Widget getConsumoPage({required String layoutType}) {
    return const shared_cons.ConsumoPage();
  }

  /// Retorna o widget de Meu IP - COMPARTILHADO entre layouts
  static Widget getMeuIpPage({required String layoutType}) {
    return const shared_ip.MeuIpPage();
  }

  /// Retorna o widget de Teste de Velocidade
  static Widget getSpeedTestPage({
    required String layoutType,
    required DiagnosticoService diagnosticoService,
    required VoidCallback onBack,
  }) {
    switch (layoutType) {
      case 'layout_04':
        return const l04_speed.Layout06SpeedTestPage();
      case 'layout_05':
        return const l05_speed.Layout09SpeedTestPage();

      default:
        return const shared_speed.SharedSpeedTestPage();
    }
  }

  static Widget getTraceRoutePage({required String layoutType}) {
    return const shared_trace.SharedTraceRoutePage();
  }

  /// Retorna o widget de FAQ - COMPARTILHADO entre layouts
  static Widget getFaqPage({required String layoutType}) {
    return const shared_faq.FaqPage();
  }

  /// Retorna o widget de Contrato - COMPARTILHADO entre layouts
  static Widget getContratoPage({required String layoutType}) {
    return const shared_cont.ContratoPage();
  }

  /// Retorna o widget de Notificações - COMPARTILHADO
  static Widget getNotificationPage({required String layoutType}) {
    return const shared_notif.SharedNotificationPage();
  }

  /// Retorna o widget de Wifi correto para o layout especificado
  static Widget getWifiPage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_03':
        return const l03_wifi.WifiPage();
      case 'layout_01':
        return const l03_wifi.WifiPage();
      case 'layout_04':
        return const l03_wifi.WifiPage();
      default:
        return const Center(
            child: Text('Funcionalidade não disponível neste layout'));
    }
  }

  /// Lista de layouts disponíveis (útil para UI de seleção)
  static const List<Map<String, String>> availableLayouts = [
    {
      'id': 'layout_01',
      'name': 'Clássico',
      'description': 'Gradiente roxo, grid de serviços'
    },
    {
      'id': 'layout_02',
      'name': 'Minimalista',
      'description': 'Cards brancos, ações rápidas'
    },
    {
      'id': 'layout_03',
      'name': 'Neo Digital',
      'description': 'Estilo futurista com efeitos neon e vidro'
    },
    {
      'id': 'layout_04',
      'name': 'Premium Dark',
      'description': 'Fintech-style com Cyan/Teal'
    },
    {
      'id': 'layout_05',
      'name': 'Organic / Biomorphic',
      'description': 'Formas suaves e fluidas inspiradas na natureza'
    },
    {
      'id': 'layout_06',
      'name': 'Cyberpunk / Neon',
      'description': 'Tema futurista escuro com detalhes em neon Cyan e Pink'
    },
  ];
}
```

---


---

### `lib/firebase_options.dart`
> Configurações do Firebase

```dart
// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBcLSCsZsTSd4fcBQubZ8E4_JHOxuIs6is',
    appId: '1:2735150999:android:f173118efa2923100a56d2',
    messagingSenderId: '2735150999',
    projectId: 'app-ajust-provedor',
    storageBucket: 'app-ajust-provedor.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCMU1hEhtvjS354Kir3HagygF-Xc8JgBeg',
    appId: '1:2735150999:ios:3aaa47397d6fa0030a56d2',
    messagingSenderId: '2735150999',
    projectId: 'app-ajust-provedor',
    storageBucket: 'app-ajust-provedor.firebasestorage.app',
    iosBundleId: 'br.com.ajust.appProvedor',
  );
}
```
### `lib/main.dart`
> Ponto de entrada do app

```dart
import 'package:flutter/material.dart';
import 'dart:ui'; // For PlatformDispatcher
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'core/providers/providers.dart';
import 'core/painel_page.dart';
import 'layout_selector.dart';

// ========================================
// CONFIGURAÇÃO DO PROVEDOR
// ========================================
const String providerId = '3kdrQFcCkRga234iB1YX';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Crashlytics Setup (Immortal Mode)
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch Theme Provider
    final themeNotifer = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'App Provedor',
      theme: themeNotifer.lightTheme,
      darkTheme: themeNotifer.darkTheme,
      themeMode: themeNotifer.themeMode,
      home: const AppInitializationWrapper(),
    );
  }
}

class AppInitializationWrapper extends ConsumerStatefulWidget {
  const AppInitializationWrapper({super.key});

  @override
  ConsumerState<AppInitializationWrapper> createState() =>
      _AppInitializationWrapperState();
}

class _AppInitializationWrapperState
    extends ConsumerState<AppInitializationWrapper> {
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeApp();
  }

  Future<void> _initializeApp() async {
    await FirebaseMessaging.instance.requestPermission();
    if (mounted) {
      // Usamos read aqui pois é uma ação única na inicialização
      await ref.read(configurationProvider).loadConfig(providerId);
      await ref.read(notificationProvider).loadNotifications();
      // Init Deep Links
      ref.read(deepLinkServiceProvider).init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return FatalErrorScreen(error: snapshot.error.toString());
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return const AuthGate();
        }
        return const SplashScreen();
      },
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configurationProvider);
    final authState = ref.watch(authNotifierProvider);

    if (config.isLoading || authState.isLoading) {
      return const SplashScreen();
    }

    if (config.errorMessage != null) {
      return FatalErrorScreen(error: config.errorMessage!);
    }

    // Se houve erro no carregamento inicial do auth, consideramos deslogado
    // ou mostramos erro se for crucial.
    // Para simplificar, se não temos usuário auth e deu erro, é login.
    // Mas AsyncNotifier geralmente inicia loading -> data(null) se não tiver user.

    final layoutType = config.providerConfig?.layoutType ?? 'layout_06';

    if (authState.value != null) {
      return const PainelPage();
    } else {
      return LayoutSelector.getLoginPage(layoutType: layoutType);
    }
  }
}

class SplashScreen extends StatelessWidget {
  final Color backgroundColor;
  const SplashScreen({super.key, this.backgroundColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class FatalErrorScreen extends StatelessWidget {
  final String error;
  const FatalErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text('Erro crítico',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

# 🎨 LAYOUTS - TEMAS VISUAIS

> Cada layout é um tema visual completo com sua própria identidade.
> Todos compartilham a mesma lógica de negócio do Core.

## 🟣 Layout 01 - Clássico (Gradiente Roxo)
> Design tradicional com gradiente roxo elegante. Animações FadeInUp.


---

### `lib/layouts/layout_01/dashboard_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

typedef NavigateToPageCallback = void Function(String pageId);

class ProviderDashboardPage extends StatefulWidget {
  final String customerName, planName, connectionStatus;
  final double billAmount, usedGb, totalGb, downloadMbps, uploadMbps;
  final DateTime billDueDate;
  final NavigateToPageCallback onNavigate;
  final List<Map<String, dynamic>>? menuItems;
  final Future<void> Function()? onRefresh;

  // CORES PERSONALIZADAS
  final Color? customCardBg;
  final Color? customCardText;
  final Color? invoiceColor;
  final Color? actionColor;

  const ProviderDashboardPage({
    super.key,
    required this.customerName,
    required this.planName,
    required this.connectionStatus,
    required this.billAmount,
    required this.billDueDate,
    required this.usedGb,
    required this.totalGb,
    required this.downloadMbps,
    required this.uploadMbps,
    required this.onNavigate,
    this.menuItems,
    this.customCardBg,
    this.customCardText,
    this.invoiceColor,
    this.actionColor,
    this.onRefresh,
  });

  @override
  State<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends State<ProviderDashboardPage> {
  @override
  Widget build(BuildContext context) {
    // Cores (roxo padrão recuperado ou customizado)
    final primaryColor = Theme.of(context).primaryColor;
    const secondaryColor = Color(0xFF0EA5E9);

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.onRefresh != null) {
          HapticFeedback.mediumImpact();
          await widget.onRefresh!();
        }
      },
      color: primaryColor,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            FadeInUp(
              child:
                  _buildWelcomeSection(context, primaryColor, secondaryColor),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: _buildStatusCard(context, primaryColor),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: _buildInvoiceSection(
                        context, primaryColor, secondaryColor),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: _buildServiceGrid(context, primaryColor),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: _buildDiagnosticoButton(context, primaryColor),
                  ),
                  const SizedBox(height: 180), // Footer spacer
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(
      BuildContext context, Color primaryColor, Color secondaryColor) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF673AB7), // Deep Purple
            Color(0xFF512DA8), // Darker Purple
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        // Use SafeArea to respect StatusBar
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Menu and Notification
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu_rounded,
                        color: Colors.white, size: 28),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: Colors.white, size: 26),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onNavigate('notifications');
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Mensagem de boas vindas
              Text(
                'Bem-vindo(a),',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.customerName,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Badge do Plano
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      widget.planName,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Remainder of _buildStatusCard and others remains similar but tweaked styles if needed)
  // Keeping logic identical but ensuring context usage works.

  Widget _buildStatusCard(BuildContext context, Color primaryColor) {
    final isConnected = widget.connectionStatus.toLowerCase() == 'ativo' ||
        widget.connectionStatus.toLowerCase() == 'conectado';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF673AB7)
                .withValues(alpha: 0.08), // Colored shadow
            blurRadius: 25,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                      isConnected
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      color: isConnected ? const Color(0xFF4CAF50) : Colors.red,
                      size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isConnected ? 'Conectado' : 'Desconectado',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF1F2937)),
                    ),
                    Text(
                      isConnected ? 'Status Online' : 'Verifique sua rede',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF6B7280)),
                    )
                  ],
                )
              ],
            ),
            // No vertical divider, cleaner look
            Container(
              height: 40,
              width: 1,
              color: Colors.grey.shade100,
            ),
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onNavigate('contract');
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description_outlined,
                        color: Colors.grey[400], size: 22),
                    const SizedBox(height: 4),
                    Text(
                      'Contrato',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                          fontSize: 10),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceSection(
      BuildContext context, Color primaryColor, Color secondaryColor) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formattedValue = currencyFormat.format(widget.billAmount);
    final formattedDate = DateFormat('dd/MM').format(widget.billDueDate);

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            )
          ]),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fatura Atual',
                      style: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(formattedValue,
                      style: GoogleFonts.inter(
                          color: Colors.black87,
                          fontSize: 28,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('Vence em',
                        style: GoogleFonts.inter(
                            color: primaryColor.withValues(alpha: 0.7),
                            fontSize: 10)),
                    Text(formattedDate,
                        style: GoogleFonts.inter(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.onNavigate('invoices');
                  },
                  icon: const Icon(Icons.pix, size: 18),
                  label: const Text('Pagar Pix'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.onNavigate('invoices');
                  },
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('Faturas'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(
                        color: primaryColor.withValues(alpha: 0.2), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Keeping _buildActionButton for potential reuse or removal if unused.
  // Looks like it was used in previous layout, replaced by buttons inside InvoiceSection above.

  Widget _buildServiceGrid(BuildContext context, Color primaryColor) {
    // Using Wrap to handle any number of items auto-adjusting rows
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildServiceItemWrapper(context, 'speed_test', 'Velocidade',
            Icons.speed, Colors.purple.shade50, Colors.purple),
        _buildServiceItemWrapper(context, 'internet_usage', 'Consumo',
            Icons.data_usage, Colors.blue.shade50, Colors.blue),
        _buildServiceItemWrapper(context, 'support', 'Suporte',
            Icons.support_agent, Colors.orange.shade50, Colors.orange),
        _buildServiceItemWrapper(context, 'my_ip', 'Meu IP', Icons.public,
            Colors.cyan.shade50, Colors.cyan),
        _buildServiceItemWrapper(
            context,
            'faq',
            'Dicas',
            Icons.lightbulb_outline,
            Colors.yellow.shade50,
            Colors.orangeAccent),
        _buildServiceItemWrapper(context, 'network_diagnostic', 'Conexão',
            Icons.wifi_tethering, Colors.green.shade50, Colors.green),
        _buildServiceItemWrapper(context, 'trace_route', 'Rota',
            Icons.alt_route_rounded, Colors.purple.shade50, Colors.deepPurple),
        _buildServiceItemWrapper(context, 'wifi', 'Wi-Fi', Icons.wifi_rounded,
            Colors.teal.shade50, Colors.teal),
      ],
    );
  }

  // Wrapper to size items properly within a Wrap (approx 3 items per row)
  Widget _buildServiceItemWrapper(BuildContext context, String pageId,
      String label, IconData icon, Color bgColor, Color iconColor) {
    // Calculate width for 3 items per row minus spacing
    // Screen width - padding (40) - spacing (12*2) / 3
    final width = (MediaQuery.of(context).size.width - 40 - 24) / 3;
    return SizedBox(
      width: width,
      child: _buildServiceItem(pageId, label, icon, bgColor, iconColor),
    );
  }

  Widget _buildServiceItem(String pageId, String label, IconData icon,
      Color bgColor, Color iconColor) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onNavigate(pageId);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticoButton(BuildContext context, Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          widget.onNavigate('network_diagnostic');
        },
        icon: const Icon(Icons.build, size: 20),
        label: const Text('Rodar Diagnóstico Completo'),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: primaryColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: primaryColor.withValues(alpha: 0.2)))),
      ),
    );
  }
}

class FadeInUp extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const FadeInUp({super.key, required this.child, this.delay = Duration.zero});

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _translate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _translate =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _translate,
        child: widget.child,
      ),
    );
  }
}
```

---

### `lib/layouts/layout_01/login_page.dart`
```dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/biometric_service.dart';
import '../../core/widgets/app_colors.dart';
import '../../core/utils/color_utils.dart';
import '../../core/providers/providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _cpfController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final BiometricService _biometricService = BiometricService();
  bool _canUseBiometry = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();

    _checkBiometry();
  }

  Future<void> _checkBiometry() async {
    final available = await _biometricService.isAvailable;
    final enabled = await _biometricService.isEnabled;

    if (available) {
      setState(() => _canUseBiometry = enabled);
      if (enabled) {
        // Se já estiver habilitado, tenta login direto
        _handleBiometricLogin();
      }
    }
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({String? overrideCpf}) async {
    if (overrideCpf == null && !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final cpfInput = overrideCpf ?? _cpfController.text;

    try {
      final configProvider = ref.read(configurationProvider);
      final providerConfig = configProvider.providerConfig;
      if (providerConfig == null) throw Exception('Configuração não carregada');

      await ref
          .read(authNotifierProvider.notifier)
          .login(cpfInput, providerConfig);

      // Se sucesso, navega para o painel
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/painel');
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
            'Erro no Login', e.toString().replaceFirst("Exception: ", ""));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  Future<void> _handleBiometricLogin() async {
    final creds = await _biometricService.authenticate();
    if (creds != null) {
      _cpfController.text = creds['cpf']!; // Preenche visualmente
      _handleLogin(overrideCpf: creds['cpf']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configurationProvider);

    if (config.isLoading || config.providerConfig == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }

    final providerConfig = config.providerConfig!.config;
    final logoUrl = providerConfig.logoUrl;
    final loginQuote = providerConfig.loginQuote;

    // --- CORREÇÃO: Obtém a cor customizada dos botões ---
    final actionColor = providerConfig.actionColor != null
        ? hexToColor(providerConfig.actionColor!)
        : AppColors.primaryBlue;

    return Scaffold(
      backgroundColor: AppColors.background, // Branco limpo
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO
                    if (logoUrl.isNotEmpty)
                      Hero(
                        tag: 'logo',
                        child: CachedNetworkImage(
                          imageUrl: logoUrl,
                          height: 100,
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              const SizedBox(height: 100),
                          errorWidget: (context, url, error) => const Icon(
                              Icons.wifi_tethering,
                              size: 80,
                              color: AppColors.primaryBlue),
                        ),
                      )
                    else
                      Icon(Icons.wifi_tethering, size: 80, color: actionColor),

                    const SizedBox(height: 32),

                    // TEXTOS
                    Text('Bem-vindo de volta!',
                        style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(
                      loginQuote,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),

                    const SizedBox(height: 40),

                    // FORMULÁRIO
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10))
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _cpfController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'CPF ou CNPJ',
                                hintText: 'Digite apenas números',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade200)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: actionColor, width: 2)),
                                prefixIcon: const Icon(Icons.person_outline_rounded,
                                    color: AppColors.textSecondary),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                              ),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                      ? 'Informe seu documento'
                                      : null,
                            ),

                            const SizedBox(height: 16),

                            // Checkbox Biometria
                            Row(
                              children: [
                                Checkbox(
                                    value: _rememberMe,
                                    activeColor:
                                        actionColor, // Usa a cor customizada
                                    onChanged: (val) =>
                                        setState(() => _rememberMe = val!)),
                                Text('Lembrar com Biometria',
                                    style: GoogleFonts.inter(
                                        color: AppColors.textSecondary,
                                        fontSize: 13)),
                              ],
                            ),

                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : () => _handleLogin(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      actionColor, // <--- CORREÇÃO APLICADA AQUI
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : Text('ACESSAR CONTA',
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // BOTÃO BIOMETRIA EXTERNO
                    if (_canUseBiometry && !_isLoading) ...[
                      const SizedBox(height: 32),
                      IconButton(
                        onPressed: _handleBiometricLogin,
                        iconSize: 48,
                        icon:
                            Icon(Icons.fingerprint_rounded, color: actionColor),
                        style: IconButton.styleFrom(
                          backgroundColor: actionColor.withValues(alpha: 0.1),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Toque para entrar',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

## ⚪ Layout 02 - Minimalista (Cards Brancos)
> Design clean e minimalista. Sombras suaves e animações sutis.


---

### `lib/layouts/layout_02/dashboard_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/premium_invoice_card.dart';

typedef NavigateToPageCallback = void Function(String pageId);

class ProviderDashboardPage extends StatefulWidget {
  final String customerName, planName, connectionStatus;
  final double billAmount, usedGb, totalGb, downloadMbps, uploadMbps;
  final DateTime billDueDate;
  final NavigateToPageCallback onNavigate;
  final List<Map<String, dynamic>>? menuItems;
  final Future<void> Function()? onRefresh;

  // CORES PERSONALIZADAS
  final Color? customCardBg;
  final Color? customCardText;
  final Color? invoiceColor;
  final Color? actionColor;

  const ProviderDashboardPage({
    super.key,
    required this.customerName,
    required this.planName,
    required this.connectionStatus,
    required this.billAmount,
    required this.billDueDate,
    required this.usedGb,
    required this.totalGb,
    required this.downloadMbps,
    required this.uploadMbps,
    required this.onNavigate,
    this.menuItems,
    this.customCardBg,
    this.customCardText,
    this.invoiceColor,
    this.actionColor,
    this.onRefresh,
  });

  @override
  State<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends State<ProviderDashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.customerName.split(' ')[0];
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;

    final cardBg = widget.customCardBg ?? textColor.withValues(alpha: 0.08);
    final cardText = widget.customCardText ?? textColor;
    final buttonColor = widget.actionColor ?? Colors.black;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        title: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Olá, $firstName',
                  style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(widget.planName,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                  ),
                  const SizedBox(width: 8),
                  _SimpleStatusBadge(
                      status: widget.connectionStatus, textColor: textColor),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24, top: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onNavigate('notifications');
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_none_rounded,
                    color: textColor, size: 24),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (widget.onRefresh != null) {
            HapticFeedback.mediumImpact();
            await widget.onRefresh!();
          }
        },
        color: buttonColor,
        backgroundColor: Colors.white,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
            children: [
              // Invoice Card with subtle animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: PremiumInvoiceCard(
                  amount: widget.billAmount,
                  dueDate: widget.billDueDate,
                  onPay: () {
                    HapticFeedback.lightImpact();
                    widget.onNavigate('invoices');
                  },
                  customColor: widget.invoiceColor,
                ),
              ),
              const SizedBox(height: 24),

              // Speed Card
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: buttonColor.withValues(alpha: 0.08),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFF0F9FF),
                              const Color(0xFFE0F2FE),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.speed_rounded,
                            color: Color(0xFF0EA5E9), size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Minha Velocidade',
                                style: GoogleFonts.inter(
                                    color: const Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('${widget.downloadMbps.toInt()} Mega',
                                style: GoogleFonts.inter(
                                    color: const Color(0xFF0F172A),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          widget.onNavigate('speed_test');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Testar',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Quick Actions Section
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Acesso Rápido',
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor)),
                    const SizedBox(height: 16),
                    _CleanActionsRow(
                      onNavigate: widget.onNavigate,
                      textColor: textColor,
                      menuItems: widget.menuItems,
                    ),
                    const SizedBox(height: 24),

                    // Diagnostic Card
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onNavigate('network_diagnostic');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: cardText.withValues(alpha: 0.15)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (widget.actionColor ??
                                        const Color(0xFFFBBC05))
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.build_circle_outlined,
                                  color: widget.actionColor ??
                                      widget.customCardText ??
                                      const Color(0xFFFBBC05),
                                  size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Problemas técnicos?',
                                    style: GoogleFonts.inter(
                                        color: cardText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                const SizedBox(height: 2),
                                Text('Iniciar auto-diagnóstico da rede.',
                                    style: GoogleFonts.inter(
                                        color: cardText.withValues(alpha: 0.7),
                                        fontSize: 12)),
                              ],
                            )),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: cardText.withValues(alpha: 0.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleStatusBadge extends StatelessWidget {
  final String status;
  final Color textColor;
  const _SimpleStatusBadge({required this.status, required this.textColor});
  @override
  Widget build(BuildContext context) {
    final isConnected =
        status.toLowerCase() == 'ativo' || status.toLowerCase() == 'conectado';
    final bgColor = isConnected
        ? const Color(0xFF10B981).withValues(alpha: 0.15)
        : Colors.red.withValues(alpha: 0.15);
    final badgeColor = isConnected ? const Color(0xFF10B981) : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(status,
              style: GoogleFonts.inter(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11)),
        ],
      ),
    );
  }
}

class _CleanActionsRow extends StatelessWidget {
  final NavigateToPageCallback onNavigate;
  final Color textColor;
  final List<Map<String, dynamic>>? menuItems;

  const _CleanActionsRow(
      {required this.onNavigate, required this.textColor, this.menuItems});

  @override
  Widget build(BuildContext context) {
    final actions = menuItems ??
        [
          {
            'id': 'invoices',
            'icon': Icons.receipt_long_rounded,
            'label': 'Faturas',
            'color': const Color(0xFF1E6FF8)
          },
          {
            'id': 'support',
            'icon': Icons.support_agent_rounded,
            'label': 'Suporte',
            'color': const Color(0xFF10B981)
          },
          {
            'id': 'contract',
            'icon': Icons.description_rounded,
            'label': 'Contrato',
            'color': const Color(0xFF8B5CF6)
          },
          {
            'id': 'my_ip',
            'icon': Icons.public_rounded,
            'label': 'Meu IP',
            'color': const Color(0xFFF97316)
          },
          {
            'id': 'trace_route',
            'icon': Icons.alt_route_rounded,
            'label': 'Rota',
            'color': const Color(0xFF7C3AED)
          },
          {
            'id': 'wifi',
            'icon': Icons.wifi_rounded,
            'label': 'Wi-Fi',
            'color': const Color(0xFF0891B2)
          },
          {
            'id': 'internet_usage',
            'icon': Icons.data_usage_rounded,
            'label': 'Consumo',
            'color': const Color(0xFF059669)
          },
        ];

    return Wrap(
      spacing: 12,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      children: actions.map((item) {
        final color = item['color'] as Color? ?? Colors.blue;
        final icon = item['icon'] as IconData;
        final label = item['label'] as String;
        final id = item['id'] as String;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onNavigate(id);
          },
          child: Container(
            width: 75,
            color: Colors.transparent,
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(height: 10),
                Text(label,
                    style: GoogleFonts.inter(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
```

---

### `lib/layouts/layout_02/login_page.dart`
```dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/providers.dart';
import '../../core/services/biometric_service.dart';
import '../../core/widgets/app_colors.dart';
import '../../core/utils/color_utils.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _cpfController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final BiometricService _biometricService = BiometricService();
  bool _canUseBiometry = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();

    _checkBiometry();
  }

  Future<void> _checkBiometry() async {
    final available = await _biometricService.isAvailable;
    final enabled = await _biometricService.isEnabled;

    if (available) {
      setState(() => _canUseBiometry = enabled);
      if (enabled) {
        // Se já estiver habilitado, tenta login direto
        _handleBiometricLogin();
      }
    }
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({String? overrideCpf}) async {
    if (overrideCpf == null && !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final cpfInput = overrideCpf ?? _cpfController.text;

    try {
      // A lógica de login agora está centralizada no AuthService
      final configProvider = ref.read(configurationProvider);
      final providerConfig = configProvider.providerConfig!;
      await ref
          .read(authNotifierProvider.notifier)
          .login(cpfInput, providerConfig);

      // Se sucesso, navega para o painel
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/painel');
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
            'Erro no Login', e.toString().replaceFirst("Exception: ", ""));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  Future<void> _handleBiometricLogin() async {
    final creds = await _biometricService.authenticate();
    if (creds != null) {
      _cpfController.text = creds['cpf']!; // Preenche visualmente
      _handleLogin(overrideCpf: creds['cpf']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = ref.watch(configurationProvider);

    if (configProvider.isLoading || configProvider.providerConfig == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }

    final providerConfig = configProvider.providerConfig!.config;
    final logoUrl = providerConfig.logoUrl;
    final loginQuote = providerConfig.loginQuote;

    // --- CORREÇÃO: Obtém a cor customizada dos botões ---
    final actionColor = providerConfig.actionColor != null
        ? hexToColor(providerConfig.actionColor!) // Added ! force unwrap
        : AppColors.primaryBlue;

    return Scaffold(
      backgroundColor: AppColors.background, // Branco limpo
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO
                    if (logoUrl.isNotEmpty)
                      Hero(
                        tag: 'logo',
                        child: CachedNetworkImage(
                          imageUrl: logoUrl,
                          height: 100,
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              const SizedBox(height: 100),
                          errorWidget: (context, url, error) => const Icon(
                              Icons.wifi_tethering,
                              size: 80,
                              color: AppColors.primaryBlue),
                        ),
                      )
                    else
                      Icon(Icons.wifi_tethering, size: 80, color: actionColor),

                    const SizedBox(height: 32),

                    // TEXTOS
                    Text('Bem-vindo de volta!',
                        style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(
                      loginQuote,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),

                    const SizedBox(height: 40),

                    // FORMULÁRIO
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10))
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _cpfController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'CPF ou CNPJ',
                                hintText: 'Digite apenas números',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade200)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: actionColor, width: 2)),
                                prefixIcon: const Icon(Icons.person_outline_rounded,
                                    color: AppColors.textSecondary),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                              ),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                      ? 'Informe seu documento'
                                      : null,
                            ),

                            const SizedBox(height: 16),

                            // Checkbox Biometria
                            Row(
                              children: [
                                Checkbox(
                                    value: _rememberMe,
                                    activeColor:
                                        actionColor, // Usa a cor customizada
                                    onChanged: (val) =>
                                        setState(() => _rememberMe = val!)),
                                Text('Lembrar com Biometria',
                                    style: GoogleFonts.inter(
                                        color: AppColors.textSecondary,
                                        fontSize: 13)),
                              ],
                            ),

                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : () => _handleLogin(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      actionColor, // <--- CORREÇÃO APLICADA AQUI
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : Text('ACESSAR CONTA',
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // BOTÃO BIOMETRIA EXTERNO
                    if (_canUseBiometry && !_isLoading) ...[
                      const SizedBox(height: 32),
                      IconButton(
                        onPressed: _handleBiometricLogin,
                        iconSize: 48,
                        icon:
                            Icon(Icons.fingerprint_rounded, color: actionColor),
                        style: IconButton.styleFrom(
                          backgroundColor: actionColor.withValues(alpha: 0.1),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Toque para entrar',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

## 🔵 Layout 03 - Neo Digital (Neumorphic)
> Design neumórfico com efeitos de profundidade. FadeSlideIn animations.


---

### `lib/layouts/layout_03/dashboard_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import 'theme.dart';

class DashboardPage extends ConsumerStatefulWidget {
  final String customerName;
  final String planName;
  final String connectionStatus;
  final double billAmount;
  final DateTime billDueDate;
  final double usedGb;
  final double totalGb;
  final double downloadMbps;
  final double uploadMbps;
  final Function(String) onNavigate;
  final Future<void> Function()? onRefresh;

  const DashboardPage({
    super.key,
    required this.customerName,
    required this.planName,
    required this.connectionStatus,
    required this.billAmount,
    required this.billDueDate,
    required this.usedGb,
    required this.totalGb,
    required this.downloadMbps,
    required this.uploadMbps,
    required this.onNavigate,
    this.onRefresh,
  });

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.value;

    final name = user?.nome ?? widget.customerName;
    final plan = user?.plano ?? widget.planName;
    final status = user?.status ?? widget.connectionStatus;

    return Scaffold(
      backgroundColor: Layout03Theme.background, // Soft Grey
      body: RefreshIndicator(
        onRefresh: () async {
          if (widget.onRefresh != null) {
            HapticFeedback.mediumImpact();
            await widget.onRefresh!();
          }
        },
        color: Layout03Theme.primary,
        backgroundColor: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                24, 32, 24, 120), // Added bottom padding for Nav Bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FadeSlideIn(
                  delay: 0,
                  child: _buildHeader(name, plan),
                ),
                const SizedBox(height: 40),

                _FadeSlideIn(
                  delay: 100,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Connection Status - Neumorphic Card
                      Expanded(flex: 1, child: _buildNeumorphicStatus(status)),
                      const SizedBox(width: 20),
                      // Bill Card - Neumorphic but highlighted
                      Expanded(
                          flex: 1,
                          child: _buildNeumorphicBill(
                              widget.billAmount, widget.billDueDate)),
                    ],
                  ),
                ),

                _FadeSlideIn(
                  delay: 200,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onNavigate('speed_test');
                    },
                    child: _buildSpeedCard(widget.downloadMbps),
                  ),
                ),

                const SizedBox(height: 32),

                _FadeSlideIn(
                  delay: 300,
                  child: Text('Ações Rápidas', style: Layout03Theme.label),
                ),
                const SizedBox(height: 16),

                // Shortcuts Grid
                LayoutBuilder(builder: (ctx, constraints) {
                  final width = (constraints.maxWidth - 20) / 2;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      SizedBox(
                          width: width,
                          child: _buildNeuShortcut(Icons.wifi_rounded,
                              'Meu Wi-Fi', () => widget.onNavigate('wifi'))),
                      SizedBox(
                          width: width,
                          child: _buildNeuShortcut(Icons.receipt_long_rounded,
                              'Faturas', () => widget.onNavigate('invoices'))),
                      SizedBox(
                          width: width,
                          child: _buildNeuShortcut(
                              Icons.speed_rounded, // Changed Icon
                              'Diagnóstico', // Changed Title
                              () => widget.onNavigate(
                                  'network_diagnostic'))), // Changed Route
                      SizedBox(
                          width: width,
                          child: _buildNeuShortcut(Icons.alt_route_rounded,
                              'Rota', () => widget.onNavigate('trace_route'))),
                      SizedBox(
                          width: width,
                          child: _buildNeuShortcut(Icons.support_agent_rounded,
                              'Suporte', () => widget.onNavigate('support'))),
                      SizedBox(
                          width: width,
                          child: _buildNeuShortcut(Icons.public_rounded,
                              'Meu IP', () => widget.onNavigate('my_ip'))),
                      SizedBox(
                          width: width,
                          child: _buildNeuShortcut(Icons.description_rounded,
                              'Contrato', () => widget.onNavigate('contract'))),
                      SizedBox(
                          width: width,
                          child: _buildNeuShortcut(
                              Icons.data_usage_rounded,
                              'Consumo',
                              () => widget.onNavigate('internet_usage'))),
                    ],
                  );
                }),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String plan) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá,',
                style: Layout03Theme.heading2.copyWith(
                    color: Layout03Theme.textGrey,
                    fontWeight: FontWeight.normal)),
            Text(name.split(' ').first,
                style: Layout03Theme.heading1
                    .copyWith(color: Layout03Theme.textDark)),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Layout03Theme.background,
            boxShadow: [
              const BoxShadow(
                  color: Colors.white, offset: Offset(-5, -5), blurRadius: 10),
              BoxShadow(
                  color: const Color(0xFFA3B1C6).withValues(alpha: 0.4),
                  offset: const Offset(5, 5),
                  blurRadius: 10),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Layout03Theme.primary, // Pop of color
            ),
            child:
                const Icon(Icons.person_rounded, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildNeumorphicStatus(String status) {
    final isOnline =
        status.toLowerCase() == 'ativo' || status.toLowerCase() == 'conectado';
    final color = isOnline ? Layout03Theme.success : Layout03Theme.error;

    return Container(
      height: 150,
      padding: const EdgeInsets.all(20),
      decoration: Layout03Theme.neumorphicDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Layout03Theme.background,
              boxShadow: [
                BoxShadow(
                    color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                BoxShadow(
                    color: Color(0x22A3B1C6),
                    offset: Offset(2, 2),
                    blurRadius: 4),
              ],
            ),
            child: Icon(isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status', style: Layout03Theme.label),
              const SizedBox(height: 4),
              Text(isOnline ? 'Online' : 'Offline',
                  style: Layout03Theme.heading2
                      .copyWith(fontSize: 18, color: color)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildNeumorphicBill(double amount, DateTime dueDate) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(20),
      decoration: Layout03Theme.neumorphicDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Text('Vence ${dueDate.day}/${dueDate.month}',
                style: Layout03Theme.label
                    .copyWith(fontSize: 11, color: Layout03Theme.primary)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fatura', style: Layout03Theme.label),
              const SizedBox(height: 4),
              Text('R\$ ${amount.toStringAsFixed(0)}',
                  style: Layout03Theme.heading2
                      .copyWith(color: Layout03Theme.textDark, fontSize: 22)),
              Text(',${amount.toStringAsFixed(2).split('.')[1]}',
                  style: Layout03Theme.heading2
                      .copyWith(color: Layout03Theme.textGrey, fontSize: 16)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSpeedCard(double speed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: Layout03Theme.neumorphicDecoration,
      child: Row(
        children: [
          const Icon(Icons.speed_rounded,
              color: Layout03Theme.primary, size: 36),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sua Velocidade', style: Layout03Theme.label),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${speed.toInt()}',
                        style: Layout03Theme.heading1
                            .copyWith(color: Layout03Theme.textDark)),
                    const SizedBox(width: 4),
                    Text('MEGA',
                        style: Layout03Theme.label
                            .copyWith(color: Layout03Theme.primary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeuShortcut(IconData icon, String title, VoidCallback onTap) {
    return _AnimatedPressButton(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 100,
        decoration: Layout03Theme.flatDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Layout03Theme.textGrey, size: 28),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: Layout03Theme.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// Animated Fade Slide In Widget
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delay;

  const _FadeSlideIn({required this.child, this.delay = 0});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _offset = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

// Animated Press Button with Scale Effect
class _AnimatedPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedPressButton({required this.child, required this.onTap});

  @override
  State<_AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<_AnimatedPressButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
```

---

### `lib/layouts/layout_03/login_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/models/provider_config.dart';
import 'theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _cpfController = TextEditingController();
  bool _isLoading = false;
  String? _localErrorMessage;

  // Animation constants
  // static const Duration _animDuration = Duration(milliseconds: 800);

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(ProviderConfig? config) async {
    if (_cpfController.text.isEmpty) {
      setState(() => _localErrorMessage = 'Por favor, digite seu CPF ou CNPJ');
      return;
    }
    if (config == null) {
      setState(
          () => _localErrorMessage = 'Erro de configuração. Tente novamente.');
      return;
    }

    setState(() {
      _isLoading = true;
      _localErrorMessage = null;
    });

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .login(_cpfController.text.trim(), config);
      // Sucesso navega automaticamente via AuthGate
    } catch (e) {
      if (mounted) {
        setState(() =>
            _localErrorMessage = 'CPF não encontrado ou erro de conexão.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Config via Riverpod
    final configProvider = ref.watch(configurationProvider);
    final config = configProvider.providerConfig;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox.expand(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // 1. Logo Section
                Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Layout03Theme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: config?.config.logoUrl != null
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Image.network(config!.config.logoUrl),
                          )
                        : const Icon(Icons.wifi,
                            size: 40, color: Layout03Theme.primary),
                  ),
                ),

                const SizedBox(height: 48),

                // 2. Welcome Text
                Text(
                  'Bem-vindo de volta',
                  style: Layout03Theme.heading1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Acesse sua área de cliente para gerenciar suas faturas e serviços.',
                  style: Layout03Theme.bodyText
                      .copyWith(color: Layout03Theme.textGrey),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                // 3. Input Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CPF / CNPJ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Layout03Theme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Layout03Theme.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: TextField(
                        controller: _cpfController,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Layout03Theme.textDark),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '000.000.000-00',
                          hintStyle: TextStyle(
                              color: Layout03Theme.textGrey
                                  .withValues(alpha: 0.5)),
                          prefixIcon: const Icon(Icons.person_outline_rounded,
                              color: Layout03Theme.textGrey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(20),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 4. Action Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleLogin(config),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Layout03Theme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Acessar Conta',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                Center(
                  child: IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Funcionalidade Bio-Login em breve!'),
                            backgroundColor: Layout03Theme.textGrey),
                      );
                    },
                    icon: const Icon(Icons.fingerprint,
                        size: 40, color: Layout03Theme.primary),
                    tooltip: 'Entrar com Biometria',
                  ),
                ),

                // 5. Error Feedback
                if (_localErrorMessage != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Layout03Theme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Layout03Theme.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _localErrorMessage!,
                            style: const TextStyle(
                                color: Layout03Theme.error,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Precisa de ajuda? ', style: Layout03Theme.bodyText),
                    GestureDetector(
                      onTap: () {
                        // TODO: Implementar ação de ajuda se necessário
                      },
                      child: const Text(
                        'Fale com o suporte',
                        style: TextStyle(
                          color: Layout03Theme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

### `lib/layouts/layout_03/theme.dart`
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Layout03Theme {
  // --- Soft UI Colors ---
  static const Color background = Color(0xFFEFEEEE); // Light Platinum
  static const Color surface = Color(0xFFEFEEEE); // Same as BG for Neumorphism

  static const Color primary = Color(0xFF7280FF); // Soft Indigo/Blue
  static const Color secondary = Color(0xFF4FD1C5); // Soft Teal
  static const Color accent = Color(0xFFFF7B9C); // Soft Pink

  static const Color textDark = Color(0xFF3E4E68); // Dark Blue-Grey
  static const Color textGrey = Color(0xFF7D8CA3); // Soft Grey
  static const Color textWhite = Colors.white;

  static const Color error = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF51CF66);
  static const Color warning = Color(0xFFFFC078);

  // --- Neumorphic Decorations ---

  // 1. Convex (Standard "pop out" card/button)
  static BoxDecoration get neumorphicDecoration => BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-8, -8),
            blurRadius: 16,
          ),
          BoxShadow(
            color: const Color(0xFFA3B1C6).withValues(alpha: 0.4),
            offset: const Offset(8, 8),
            blurRadius: 16,
          ),
        ],
      );

  // 1b. Convex Circle (for Avatars/Icons)
  static BoxDecoration get neumorphicCircleDecoration => BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: [
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-8, -8),
            blurRadius: 16,
          ),
          BoxShadow(
            color: const Color(0xFFA3B1C6).withValues(alpha: 0.4),
            offset: const Offset(8, 8),
            blurRadius: 16,
          ),
        ],
      );

  // 2. Concave (Pressed state or Input)
  static BoxDecoration get neumorphicPressedDecoration => BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA3B1C6).withValues(alpha: 0.2),
            offset: const Offset(6, 6),
            blurRadius: 10,
            // inset: true // Requires customized implementation or specialized package,
            // but standard flutter BoxDecoration doesn't support 'inset'.
            // We simulate "pressed" by flipping shadows or darkening inner.
            // For valid Flutter code without extra packages:
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            offset: const Offset(-6, -6),
            blurRadius: 10,
            // inset: true
          ),
        ],
        // Note: Standard BoxDecoration does NOT support 'inset' shadows natively without custom painting
        // or packages like flutter_neumorphic.
        // We will simulate "Concave" using a slightly darker/flat look or standard shadows
        // inverted if we had a package.
        // For standard Flutter, we'll just use a flatter, darker style for inputs/pressed.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE6E6E6), // Slightly darker top-left
            Color(0xFFF7F7F7), // Lighter bottom-right
          ],
        ),
      );

  // 3. Flat / Simple for small elements
  static BoxDecoration get flatDecoration => BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-4, -4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: const Color(0xFFA3B1C6).withValues(alpha: 0.3),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
        ],
      );

  // Alias for compatibility with previous layout code
  static BoxDecoration get cardDecoration => neumorphicDecoration;
  static BoxDecoration get glassDecoration =>
      neumorphicDecoration; // Map glass to neumorphic
  static BoxDecoration get solidCardDecoration => flatDecoration;

  // --- Typography ---
  static TextStyle get heading1 => GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: textDark,
        height: 1.2,
      );

  static TextStyle get heading2 => GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textDark,
      );

  static TextStyle get bodyText => GoogleFonts.nunito(
        fontSize: 15,
        color: textGrey,
        height: 1.5,
      );

  static TextStyle get label => GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: textGrey,
        letterSpacing: 0.5,
      );

  // --- Constants ---
  static const double radiusM = 20.0;
  static const double radiusL = 30.0;
  static const double padding = 24.0;
}
```

---

### `lib/layouts/layout_03/wifi_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/onu_wifi_service.dart';
import '../../core/providers/providers.dart';
import 'theme.dart';

class WifiPage extends ConsumerStatefulWidget {
  const WifiPage({super.key});

  @override
  ConsumerState<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends ConsumerState<WifiPage> {
  bool _isLoading = true;
  List<WifiNetwork> _networks = [];
  String? _errorMessage;
  OnuWifiService? _wifiService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServiceAndFetch();
    });
  }

  Future<void> _initServiceAndFetch() async {
    final authState = ref.read(authNotifierProvider);
    final configProvider = ref.read(configurationProvider);
    final user = authState.value;
    final config = configProvider.providerConfig;

    if (user == null || config == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro de autenticação ou configuração.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // Check if TR069/SGP integration is configured
      final sgpBaseUrl = config.config.integrations.sgpBaseUrl;
      if (sgpBaseUrl.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Gerenciamento WiFi não disponível.\n\nO seu provedor não possui integração TR069 configurada para gerenciamento remoto do roteador.';
            _isLoading = false;
          });
        }
        return;
      }

      // Constructing the real service
      _wifiService = OnuWifiService(
        apiUrl: config.apiUrl,
        cpfCnpj: user.cpfCnpj,
        senha: user.senha,
        contrato: user.contratoId?.toString(),
        sgpParams: {
          'token': config.config.integrations.apiToken,
          'app': config.config.integrations.appName,
          'sgpBaseUrl': sgpBaseUrl,
        },
      );

      await _fetchNetworks();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao inicializar serviço: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchNetworks() async {
    if (_wifiService == null) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final networks = await _wifiService!.fetchWifiNetworks();
      if (mounted) {
        setState(() {
          _networks = networks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Não foi possível carregar as redes. Verifique seu equipamento.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateWifi(
      WifiNetwork network, String newSsid, String newPassword) async {
    if (_wifiService == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: Layout03Theme.primary)),
    );

    try {
      final success = await _wifiService!
          .updateWifi(wifiId: network.id, ssid: newSsid, password: newPassword);

      if (!mounted) return;
      Navigator.pop(context); // Hide loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Wi-Fi atualizado com sucesso!'),
              backgroundColor: Layout03Theme.success),
        );
        _fetchNetworks(); // Refresh
      } else {
        throw Exception('Falha ao atualizar');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Hide loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro: $e'), backgroundColor: Layout03Theme.error),
      );
    }
  }

  void _showEditDialog(WifiNetwork network) {
    final ssidController = TextEditingController(text: network.ssid);
    final passwordController = TextEditingController(); // Empty for security

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar ${network.frequency}',
            style:
                Layout03Theme.heading2.copyWith(color: Layout03Theme.textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ssidController,
              decoration:
                  const InputDecoration(labelText: 'Nome da Rede (SSID)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Nova Senha',
                hintText: 'Deixe vazio para manter',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR',
                style: TextStyle(color: Layout03Theme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateWifi(
                  network, ssidController.text, passwordController.text);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Layout03Theme.primary),
            child: const Text('SALVAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = ref.watch(configurationProvider);
    final layoutType = configProvider.providerConfig?.layoutType;
    final isDarkLayout = layoutType == 'layout_04' || layoutType == 'layout_06';

    Color backgroundColor;
    Color appBarColor;
    Color appBarTextColor;
    if (isDarkLayout) {
      backgroundColor = const Color(0xFF0A0A0A);
      appBarColor = const Color(0xFF0A0A0A);
      appBarTextColor = Colors.white;
    } else {
      backgroundColor = Layout03Theme.background;
      appBarColor = Layout03Theme.background;
      appBarTextColor = Layout03Theme.textDark;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Minha Rede Wi-Fi',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appBarTextColor)),
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: appBarTextColor),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Layout03Theme.primary))
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Layout03Theme.error),
                      textAlign: TextAlign.center))
              : _networks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off,
                              size: 64, color: Layout03Theme.textGrey),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma rede Wi-Fi encontrada.',
                            style: Layout03Theme.heading2
                                .copyWith(color: Layout03Theme.textDark),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'O gerenciamento de Wi-Fi pode não estar disponível para o seu equipamento ou contrato.',
                              textAlign: TextAlign.center,
                              style: Layout03Theme.bodyText,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _fetchNetworks,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar Novamente'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Layout03Theme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                      itemCount: _networks.length,
                      itemBuilder: (context, index) {
                        final network = _networks[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: isDarkLayout
                              ? BoxDecoration(
                                  color: const Color(0xFF1C1C1E),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: const Color(0xFF3A3A3C)
                                          .withValues(alpha: 0.3)),
                                )
                              : Layout03Theme.neumorphicDecoration,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(20),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDarkLayout
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : Layout03Theme.background,
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.white,
                                      offset: Offset(-2, -2),
                                      blurRadius: 3),
                                  BoxShadow(
                                      color: Color(0x11000000),
                                      offset: Offset(2, 2),
                                      blurRadius: 3),
                                ],
                              ),
                              child: Icon(
                                network.frequency.contains('5')
                                    ? Icons.wifi_tethering
                                    : Icons.wifi,
                                color: isDarkLayout
                                    ? const Color(0xFF00D9FF)
                                    : Layout03Theme.primary,
                                size: 28,
                              ),
                            ),
                            title: Text(network.ssid,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDarkLayout
                                        ? Colors.white
                                        : Layout03Theme.textDark)),
                            subtitle: Text(
                                '${network.frequency} - ${network.enabled ? 'Ativo' : 'Inativo'}',
                                style: Layout03Theme.bodyText.copyWith(
                                    fontSize: 13,
                                    color:
                                        isDarkLayout ? Colors.white70 : null)),
                            trailing: Container(
                              decoration: BoxDecoration(
                                color: isDarkLayout
                                    ? Colors.transparent
                                    : Layout03Theme.background,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.white,
                                      offset: Offset(-3, -3),
                                      blurRadius: 5),
                                  BoxShadow(
                                      color: Color(0x1FA3B1C6),
                                      offset: Offset(3, 3),
                                      blurRadius: 5),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.edit_rounded,
                                    color: Layout03Theme.textGrey),
                                onPressed: () => _showEditDialog(network),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
```

---

### `lib/layouts/layout_03/widgets/neumorphic_bottom_nav.dart`
> Widget do Layout 03

```dart
import 'package:flutter/material.dart';
import '../theme.dart';

class NeumorphicBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NeumorphicBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Obtém o padding inferior do sistema (safe area)
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      // Adiciona o padding do sistema e um extra para garantir que fique acima dos botões do Android
      padding: EdgeInsets.only(bottom: 30 + bottomPadding, left: 24, right: 24),
      color: Colors.transparent, // Background allows Scaffold color to show
      child: Container(
        height: 70, // Reduzido levemente para 70 para ficar mais compacto
        decoration: BoxDecoration(
          color: Layout03Theme.background,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-4, -4), // Sombras mais suaves
              blurRadius: 10,
            ),
            BoxShadow(
              color: const Color(0xFFA3B1C6).withValues(alpha: 0.3),
              offset: const Offset(4, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Início'),
            _buildNavItem(1, Icons.wifi_rounded, 'Wi-Fi'),
            _buildNavItem(2, Icons.receipt_long_rounded, 'Finan.'),
            _buildNavItem(3, Icons.headset_mic_rounded, 'Suporte'),
            _buildNavItem(4, Icons.menu_rounded, 'Menu'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    final color = isSelected ? Layout03Theme.primary : Layout03Theme.textGrey;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: Layout03Theme.background,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA3B1C6).withValues(alpha: 0.2),
                      offset: const Offset(4, 4),
                      blurRadius: 8,
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      offset: Offset(-4, -4),
                      blurRadius: 8,
                    ),
                  ]) // Pressed/Concave Simulation
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
```

## ⚫ Layout 04 - Premium Dark
> Tema escuro premium com glass effects. BottomNav próprio.


---

### `lib/layouts/layout_04/dashboard_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/glass_card.dart';

class DashboardPage extends StatefulWidget {
  final String customerName;
  final String planName;
  final String connectionStatus;
  final double billAmount;
  final DateTime billDueDate;
  final double usedGb;
  final double totalGb;
  final double downloadMbps;
  final double uploadMbps;
  final Function(String) onNavigate;
  final List<Map<String, dynamic>>? menuItems;

  const DashboardPage({
    super.key,
    required this.customerName,
    required this.planName,
    required this.connectionStatus,
    required this.billAmount,
    required this.billDueDate,
    required this.usedGb,
    required this.totalGb,
    required this.downloadMbps,
    required this.uploadMbps,
    required this.onNavigate,
    this.menuItems,
    this.onRefresh,
  });

  final Future<void> Function()? onRefresh;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final remainingDays = widget.billDueDate.difference(DateTime.now()).inDays;

    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final secondaryColor = theme.colorScheme.secondary;
    final surfaceColor = theme.cardColor;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final borderColor = theme.dividerColor;

    // Create dynamic gradient
    final dynamicGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryColor, secondaryColor],
    );

    return Column(
      children: [
        // Main Scrollable Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (widget.onRefresh != null) {
                HapticFeedback.mediumImpact();
                await widget.onRefresh!();
              }
            },
            color: primaryColor,
            backgroundColor: surfaceColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Menu Button
                            GestureDetector(
                              onTap: () => Scaffold.of(context).openDrawer(),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.menu_rounded,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  primaryColor.withValues(alpha: 0.2),
                              child: Text(
                                widget.customerName.isNotEmpty
                                    ? widget.customerName[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Olá, ${widget.customerName.split(' ').first}',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  widget.planName,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => widget.onNavigate('notifications'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.notifications_none_rounded,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Balance Card (Main Feature)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: dynamicGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Próxima Fatura',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.connectionStatus,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'R\$ ${widget.billAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 14, color: Colors.black54),
                              const SizedBox(width: 6),
                              Text(
                                remainingDays >= 0
                                    ? 'Vence em $remainingDays dias'
                                    : 'Vencida há ${remainingDays.abs()} dias',
                                style: TextStyle(
                                  color: remainingDays >= 0
                                      ? Colors.black54
                                      : Colors.red[900],
                                  fontSize: 14,
                                  fontWeight: remainingDays < 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions (Corrected route names)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickAction(
                            Icons.receipt_long_rounded, 'Faturas', 'invoices',
                            primaryColor: primaryColor,
                            surfaceColor: surfaceColor,
                            textSecondary: textSecondary,
                            borderColor: borderColor),
                        _buildQuickAction(
                            Icons.speed_rounded, 'Velocidade', 'speed_test',
                            primaryColor: primaryColor,
                            surfaceColor: surfaceColor,
                            textSecondary: textSecondary,
                            borderColor: borderColor),
                        _buildQuickAction(
                            Icons.support_agent_rounded, 'Suporte', 'support',
                            primaryColor: primaryColor,
                            surfaceColor: surfaceColor,
                            textSecondary: textSecondary,
                            borderColor: borderColor),
                        _buildQuickAction(Icons.wifi_rounded, 'Wi-Fi', 'wifi',
                            primaryColor: primaryColor,
                            surfaceColor: surfaceColor,
                            textSecondary: textSecondary,
                            borderColor: borderColor),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Plan Card
                    GlassCard(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.router_rounded,
                              color: Theme.of(context).iconTheme.color ??
                                  primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Seu Plano',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.planName,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: widget.connectionStatus.toLowerCase() ==
                                      'ativo'
                                  ? const Color(0xFF30D158)
                                      .withValues(alpha: 0.1)
                                  : const Color(0xFFFF453A)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        widget.connectionStatus.toLowerCase() ==
                                                'ativo'
                                            ? const Color(0xFF30D158)
                                            : const Color(0xFFFF453A),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.connectionStatus,
                                  style: TextStyle(
                                    color:
                                        widget.connectionStatus.toLowerCase() ==
                                                'ativo'
                                            ? const Color(0xFF30D158)
                                            : const Color(0xFFFF453A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Menu Section Title
                    Text(
                      'Serviços',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Services List
                    _buildServiceItem(
                      Icons.analytics_rounded,
                      'Diagnóstico Completo',
                      'Verificar conexão e problemas',
                      'network_diagnostic',
                      primaryColor: primaryColor,
                      surfaceColor: surfaceColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                    ),
                    _buildServiceItem(
                      Icons.route_rounded,
                      'Traceroute',
                      'Rastrear rota de rede',
                      'trace_route',
                      primaryColor: primaryColor,
                      surfaceColor: surfaceColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                    ),
                    _buildServiceItem(
                      Icons.data_usage_rounded,
                      'Consumo',
                      'Monitorar uso de dados',
                      'internet_usage',
                      primaryColor: primaryColor,
                      surfaceColor: surfaceColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                    ),
                    _buildServiceItem(
                      Icons.public_rounded,
                      'Meu IP',
                      'Ver endereço IP atual',
                      'my_ip',
                      primaryColor: primaryColor,
                      surfaceColor: surfaceColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                    ),
                    _buildServiceItem(
                      Icons.description_rounded,
                      'Contrato',
                      'Ver termos do serviço',
                      'contract',
                      primaryColor: primaryColor,
                      surfaceColor: surfaceColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                    ),
                    _buildServiceItem(
                      Icons.help_outline_rounded,
                      'FAQ',
                      'Perguntas frequentes',
                      'faq',
                      primaryColor: primaryColor,
                      surfaceColor: surfaceColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Fixed Dark Bottom Navigation Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(
              top: BorderSide(color: borderColor.withValues(alpha: 0.3)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 'Início', 0,
                    primaryColor: primaryColor, textSecondary: textSecondary),
                _buildNavItem(Icons.wifi_rounded, 'Wi-Fi', 1,
                    primaryColor: primaryColor, textSecondary: textSecondary),
                _buildNavItem(Icons.receipt_long_rounded, 'Faturas', 2,
                    primaryColor: primaryColor, textSecondary: textSecondary),
                _buildNavItem(Icons.headset_mic_rounded, 'Suporte', 3,
                    primaryColor: primaryColor, textSecondary: textSecondary),
                _buildNavItem(Icons.menu_rounded, 'Menu', 4,
                    primaryColor: primaryColor, textSecondary: textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, String route,
      {required Color primaryColor,
      required Color surfaceColor,
      required Color textSecondary,
      required Color borderColor}) {
    // [NEW] Use dynamic icon color
    final iconColor = Theme.of(context).iconTheme.color ?? primaryColor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onNavigate(route);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(
      IconData icon, String title, String subtitle, String route,
      {required Color primaryColor,
      required Color surfaceColor,
      required Color textPrimary,
      required Color textSecondary,
      required Color borderColor}) {
    final iconColor = Theme.of(context).iconTheme.color ?? primaryColor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onNavigate(route);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: borderColor.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index,
      {required Color primaryColor, required Color textSecondary}) {
    final isSelected = _currentNavIndex == index;
    final iconColor = Theme.of(context).iconTheme.color ?? primaryColor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentNavIndex = index);
        switch (index) {
          case 0: // Home - already here
            break;
          case 1:
            widget.onNavigate('wifi');
            break;
          case 2:
            widget.onNavigate('invoices');
            break;
          case 3:
            widget.onNavigate('support');
            break;
          case 4:
            Scaffold.of(context).openDrawer();
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color:
                isSelected ? primaryColor : (iconColor.withValues(alpha: 0.7)),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? primaryColor : textSecondary,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          // Selection Indicator
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isSelected ? 20 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### `lib/layouts/layout_04/login_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../../core/providers/providers.dart';
import '../../core/models/usuario.dart'; // Import Usuario explicitly
import 'widgets/glass_card.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _cpfController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Animation
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final configProvider = ref.read(configurationProvider);
    final config = configProvider.providerConfig;

    if (_cpfController.text.isEmpty) {
      setState(() => _errorMessage = 'Por favor, digite seu CPF/CNPJ');
      HapticFeedback.vibrate(); // Error Haptic
      return;
    }
    if (config == null) {
      setState(() => _errorMessage = 'Erro de configuração');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Just trigger the login. The listener in build() handles success/error.
    await ref.read(authNotifierProvider.notifier).login(
          _cpfController.text.trim(),
          config,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to Auth State changes for Navigation and Error Handling
    ref.listen<AsyncValue<Usuario?>>(authNotifierProvider, (previous, next) {
      if (next is AsyncError) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Falha no login: ${next.error.toString().replaceAll('Exception:', '').trim()}';
        });
      } else if (next is AsyncData && next.value != null) {
        // Login Success
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
        // Navigate to Dashboard (PainelPage is wrapper)
        // Ensure we replace the route so user can't go back to login
        Navigator.of(context).pushReplacementNamed('/painel');
      }
    });

    final config = ref.watch(configurationProvider).providerConfig;
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).cardColor;
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final errorColor = Theme.of(context).colorScheme.error;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background gradient orb 1 (Aurora)
          Positioned(
            top: -150,
            right: -100,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animController.value * 2.0 * 3.14159,
                  child: child,
                );
              },
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.15),
                      Colors.transparent,
                      primaryColor.withValues(alpha: 0.15),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Background gradient orb 2 (Aurora Counter-Clockwise)
          Positioned(
            bottom: -100,
            left: -100,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -_animController.value * 2.0 * 3.14159,
                  child: child,
                );
              },
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      secondaryColor.withValues(alpha: 0.1),
                      Colors.transparent,
                      secondaryColor.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  // Logo
                  if (config?.config.logoUrl != null)
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: CachedNetworkImage(
                          imageUrl: config!.config.logoUrl,
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) {
                            return Image.asset(
                              'assets/images/ajust.png',
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/ajust.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                  const SizedBox(height: 60),

                  // Title
                  Text(
                    'Bem-vindo\nde Volta',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Acesse sua conta para gerenciar\nseus serviços de internet',
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Input Card
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CPF / CNPJ',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _cpfController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: '000.000.000-00',
                            hintStyle: TextStyle(
                              color: textSecondary.withValues(alpha: 0.5),
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: primaryColor,
                            ),
                            filled: true,
                            fillColor: surfaceColor.withValues(alpha: 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Error Message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: errorColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: errorColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Login Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              _handleLogin();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors
                            .black, // Keep text black for contrast on bright primary
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Entrar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### `lib/layouts/layout_04/theme.dart`
```dart
import 'package:flutter/material.dart';
import '../../core/models/theme_config.dart';

/// Layout 06: Premium Light Fintech Theme
/// Clean, modern light theme with cyan/teal accents
class Layout04Theme {
  // Core Colors (Defaults) - LIGHT THEME
  static const Color background = Color(0xFFF5F7FA); // Light grey-blue
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceLight = Color(0xFFF0F2F5); // Lighter surface
  static const Color _defaultPrimary = Color(0xFF0891B2); // Cyan-600
  static const Color _defaultSecondary = Color(0xFF059669); // Emerald-600

  static const Color accent = Color(0xFF7C3AED); // Purple accent
  static const Color textPrimary = Color(0xFF1F2937); // Dark grey
  static const Color textSecondary = Color(0xFF6B7280); // Grey
  static const Color border = Color(0xFFE5E7EB);
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);

  // Dynamic Color Getters
  static Color primary(ThemeConfig? config) {
    if (config?.colors.primary != null) {
      return config!.colors.primary;
    }
    return _defaultPrimary;
  }

  static Color secondary(ThemeConfig? config) {
    if (config?.colors.secondary != null) {
      return config!.colors.secondary;
    }
    return _defaultSecondary;
  }

  // Gradients
  static LinearGradient primaryGradient(ThemeConfig? config) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary(config), secondary(config)],
      );

  static LinearGradient gaugeGradient(ThemeConfig? config) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [primary(config), secondary(config)],
      );

  // Text Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: textSecondary,
  );

  static const TextStyle balanceText = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -1,
  );

  // Box Decorations
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get glassmorphism => BoxDecoration(
        color: surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      );

  // ThemeData - LIGHT
  static ThemeData getTheme(ThemeConfig? config) {
    final primaryColor = primary(config);
    final secondaryColor = secondary(config);
    final iconColor = config?.effects.iconColor ?? primaryColor;

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      iconTheme: IconThemeData(color: iconColor),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: iconColor),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      useMaterial3: true,
    );
  }
}
```

---

### `lib/layouts/layout_04/widgets/bottom_nav.dart`
> Componente do Layout 04

```dart
import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get colors from context
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceColor = Theme.of(context).cardColor;
    final textSecondaryColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
              context, Icons.home_rounded, 0, primaryColor, textSecondaryColor),
          _buildNavItem(context, Icons.receipt_long_rounded, 1, primaryColor,
              textSecondaryColor),
          _buildNavItem(context, Icons.speed_rounded, 2, primaryColor,
              textSecondaryColor),
          _buildNavItem(context, Icons.person_rounded, 3, primaryColor,
              textSecondaryColor),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, int index,
      Color primaryColor, Color secondaryColor) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: isSelected
            ? BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Icon(
          icon,
          color: isSelected ? primaryColor : secondaryColor,
          size: 24,
        ),
      ),
    );
  }
}
```

---

### `lib/layouts/layout_04/widgets/error_widget.dart`
> Componente do Layout 04

```dart
import 'package:flutter/material.dart';
import 'glass_card.dart';

class Layout06ErrorWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const Layout06ErrorWidget({
    super.key,
    this.icon = Icons.error_outline_rounded,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Tentar Novamente',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      retryLabel!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### `lib/layouts/layout_04/widgets/glass_card.dart`
> Componente do Layout 04

```dart
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? height;
  final VoidCallback? onTap;
  final bool useGradientBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.onTap,
    this.useGradientBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    // Layout 06 is designed as a Dark theme.
    // Even if the global theme is Light, these cards must remain dark (Black).
    final surfaceColor = Theme.of(context).cardColor;

    final dynamicGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryColor, secondaryColor],
    );

    final glassmorphism = BoxDecoration(
      color: surfaceColor, // Removed .withValues(alpha: 0.6) to allow vibrant colors
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: padding ?? const EdgeInsets.all(20),
        decoration: useGradientBorder
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: dynamicGradient,
              )
            : glassmorphism,
        child: useGradientBorder
            ? Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: padding ?? const EdgeInsets.all(20),
                child: child,
              )
            : child,
      ),
    );
  }
}
```

---

### `lib/layouts/layout_04/widgets/skeleton_dashboard_page.dart`
> Componente do Layout 04

```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonDashboardPage extends StatelessWidget {
  const SkeletonDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          enabled: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 100,
                            height: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 60,
                            height: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Balance Card
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                    4,
                    (index) => Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 40,
                              height: 10,
                              color: Colors.white,
                            ),
                          ],
                        )),
              ),
              const SizedBox(height: 28),

              // Plan Card
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 24),

              // Services List
              Column(
                children: List.generate(
                    3,
                    (index) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          width: double.infinity,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### `lib/layouts/layout_04/widgets/skeleton_financeiro_page.dart`
> Componente do Layout 04

```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonFinanceiroPage extends StatelessWidget {
  const SkeletonFinanceiroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 100,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            )),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, // Don't show back arrow placeholder
      ),
      body: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

### `lib/layouts/layout_04/pages/speed_test_page.dart`
> Componente do Layout 04

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/diagnostico_service.dart';
import '../../../core/models/diagnostico_state.dart';
import '../widgets/glass_card.dart';

class Layout06SpeedTestPage extends ConsumerStatefulWidget {
  const Layout06SpeedTestPage({super.key});

  @override
  ConsumerState<Layout06SpeedTestPage> createState() =>
      _Layout06SpeedTestPageState();
}

class _Layout06SpeedTestPageState extends ConsumerState<Layout06SpeedTestPage>
    with SingleTickerProviderStateMixin {
  late final DiagnosticoService _service;
  bool _serviceInitialized = false;

  late AnimationController _gaugeController;
  DiagnosticoState _state = DiagnosticoState.initial();
  StreamSubscription? _subscription;

  // Chart Data
  final List<FlSpot> _spots = [];
  int _xCounter = 0;

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serviceInitialized) {
      final configProvider = ref.read(configurationProvider);
      final providerConfig = configProvider.providerConfig!;
      _service =
          DiagnosticoService(providerConfig: providerConfig, context: context);

      // Listen to stream manually to accumulate chart points
      _subscription = _service.stateStream.listen((newState) {
        setState(() {
          _state = newState;
          _updateChart(newState);
        });
      });

      _serviceInitialized = true;
    }
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }

  void _updateChart(DiagnosticoState state) {
    if (state.isTesting ||
        state.testResultsDisplay['speedTestCustom']?['status'] ==
            TestStatus.running) {
      double speed = 0;
      if (state.customUploadResultMbps > 1) {
        speed = state.customUploadResultMbps;
      } else {
        speed = state.customDownloadResultMbps > 0
            ? state.customDownloadResultMbps
            : 0;
      }

      // Add spot (limit to last 50 points for performance)
      _spots.add(FlSpot(_xCounter.toDouble(), speed));
      _xCounter++;

      if (_spots.length > 50) {
        _spots.removeAt(0);
      }
    }
  }

  void _startTest() {
    HapticFeedback.mediumImpact();
    // Reset gauge and chart
    _gaugeController.repeat(reverse: true);
    setState(() {
      _spots.clear();
      _xCounter = 0;
    });
    _service.runSpeedTestsOnly();
  }

  void _stopTest() {
    _service.stopAllTests();
    _gaugeController.stop();
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SpeedHistorySheet(),
    );
  }

  String _extractJitter(DiagnosticoState state) {
    String? result = state.testResultsDisplay['pingGoogle']?['result'];
    // Try Google first, then Cloudflare
    if (result == null || !result.contains('Jitter')) {
      result = state.testResultsDisplay['pingCloudflare']?['result'];
    }

    if (result != null && result.contains('Jitter:')) {
      try {
        final jitterPart =
            result.split('\n').firstWhere((l) => l.contains('Jitter:'));
        // "Jitter: 12.5ms" -> "12.5ms"
        return jitterPart.split(':')[1].trim();
      } catch (_) {}
    }
    return '- ms';
  }

  @override
  Widget build(BuildContext context) {
    // Theme data from context (dynamic)
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final secondaryColor = theme.colorScheme.secondary;

    final isRunning = _state.isTesting ||
        _state.testResultsDisplay['speedTestCustom']?['status'] ==
            TestStatus.running;

    // Determine current values
    final download = _state.customDownloadResultMbps;
    final upload = _state.customUploadResultMbps;
    double displaySpeed = 0.0;
    double progress = 0.0; // 0.0-1.0 for Download, 1.0-2.0 for Upload
    bool isUpload = false;

    if (isRunning) {
      // Logic to determine what to show
      if (upload > 1) {
        displaySpeed = upload;
        progress = 1.5; // Arbitrary "Upload Phase" for gauge
        isUpload = true;
      } else {
        displaySpeed = download > 0 ? download : 0;
        progress = 0.5; // Arbitrary "Download Phase"
      }
    } else if (download > 0 || upload > 0) {
      // Finished
      _gaugeController.stop();
      displaySpeed = download; // Show download by default on finish
      progress = 2.0; // Finished
    } else {
      _gaugeController.stop();
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (isRunning) {
          _stopTest();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent, // Handled by Layout 06 background
        appBar: AppBar(
          title: Text(
            'Teste de Velocidade',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            if (isRunning)
              IconButton(
                icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                tooltip: 'Cancelar Teste',
                onPressed: _stopTest,
              ),
            IconButton(
              icon: const Icon(Icons.history_edu_rounded),
              tooltip: 'Histórico de Testes',
              onPressed: () => _showHistory(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Gauge Section
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 250,
                    width: 250,
                    child: AnimatedBuilder(
                        animation: _gaugeController,
                        builder: (context, child) {
                          // If running, oscillate the gauge a bit for effect + real value
                          final oscillation =
                              isRunning ? (_gaugeController.value * 0.1) : 0.0;

                          // Combine progress (phase) with fill
                          double fill = 0.0;
                          if (progress >= 2.0) {
                            fill = 1.0;
                          } else if (displaySpeed > 0) {
                            fill = (displaySpeed / 500).clamp(0.0, 1.0);
                          }

                          return CustomPaint(
                            painter: SpeedGaugePainter(
                              progress:
                                  fill + oscillation, // Use fill for visual
                              primaryColor: primaryColor,
                              secondaryColor: secondaryColor,
                              trackColor: theme.colorScheme.surface,
                            ),
                          );
                        }),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isRunning
                            ? (isUpload ? 'UPLOAD' : 'DOWNLOAD')
                            : (displaySpeed > 0 ? 'PRONTO' : 'PARADO'),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displaySpeed.toStringAsFixed(1),
                        style: GoogleFonts.outfit(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Mbps',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // [NEW] Real-time Graph
              if (_spots.isNotEmpty)
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _spots,
                          isCurved: true,
                          color: isUpload ? secondaryColor : primaryColor,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: (isUpload ? secondaryColor : primaryColor)
                                .withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                      lineTouchData: const LineTouchData(enabled: false),
                    ),
                  ),
                ),

              const SizedBox(height: 20), // Adjusted spacing

              // Start Button
              if (!isRunning)
                GestureDetector(
                  onTap: _startTest,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      'INICIAR TESTE',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Contrast on bright gradient
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // Results Grid
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.download, color: primaryColor, size: 28),
                          const SizedBox(height: 8),
                          Text('Download',
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7))),
                          const SizedBox(height: 4),
                          Text(
                            '${download.toStringAsFixed(1)} Mbps',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.upload, color: secondaryColor, size: 28),
                          const SizedBox(height: 8),
                          Text('Upload',
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7))),
                          const SizedBox(height: 4),
                          Text(
                            '${upload.toStringAsFixed(1)} Mbps',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.wifi_tethering,
                            color: theme.colorScheme.tertiary, size: 28),
                        const SizedBox(height: 8),
                        Text('Ping',
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7))),
                        const SizedBox(height: 4),
                        Text(
                          '${_state.speedTestPingLatency?.toStringAsFixed(0) ?? '-'} ms',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.computer,
                            color: theme.colorScheme.tertiary, size: 28),
                        const SizedBox(height: 8),
                        Text('Jitter',
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7))),
                        const SizedBox(height: 4),
                        Text(
                          _extractJitter(_state),
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SpeedGaugePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color primaryColor;
  final Color secondaryColor;
  final Color trackColor;

  SpeedGaugePainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const startAngle = 135 * (3.14159 / 180);
    const sweepAngle = 270 * (3.14159 / 180);

    // Track Paint
    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Progress Paint (Gradient)
    final gradient = LinearGradient(
      colors: [primaryColor, secondaryColor],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final progressPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    final currentSweep = sweepAngle * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      currentSweep,
      false,
      progressPaint,
    );

    // Glow Effect
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      currentSweep,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SpeedGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor;
  }
}

class _SpeedHistorySheet extends ConsumerStatefulWidget {
  const _SpeedHistorySheet();

  @override
  ConsumerState<_SpeedHistorySheet> createState() => _SpeedHistorySheetState();
}

class _SpeedHistorySheetState extends ConsumerState<_SpeedHistorySheet> {
  @override
  void initState() {
    super.initState();
    // Load history when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(speedTestHistoryServiceProvider).loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyService = ref.watch(speedTestHistoryServiceProvider);
    final history = historyService.history;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Text(
            'Histórico de Resultados',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // List
          Expanded(
            child: historyService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : history.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum teste realizado ainda',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = history[index];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.speed_rounded,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            title: Text(
                              '${item.downloadSpeed.toStringAsFixed(1)} Mbps',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(item.formattedDate),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.arrow_upward,
                                        size: 14, color: Colors.grey),
                                    Text(
                                      ' ${item.uploadSpeed.toStringAsFixed(1)}',
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
```

## 🟢 Layout 05 - Organic (Biomorphic)
> Design orgânico com formas curvas e blob effects. BottomNav próprio.


---

### `lib/layouts/layout_05/dashboard_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

class ProviderDashboardPage extends StatefulWidget {
  final String customerName;
  final String planName;
  final String connectionStatus;
  final double billAmount;
  final DateTime billDueDate;
  final double usedGb;
  final double totalGb;
  final double downloadMbps;
  final double uploadMbps;
  final Function(String) onNavigate;
  final List<Map<String, dynamic>>? menuItems;
  final Color? customCardBg;
  final Color? customCardText;
  final Color? invoiceColor;
  final Color? actionColor;
  final Future<void> Function()? onRefresh;

  const ProviderDashboardPage({
    super.key,
    required this.customerName,
    required this.planName,
    required this.connectionStatus,
    required this.billAmount,
    required this.billDueDate,
    required this.usedGb,
    required this.totalGb,
    required this.downloadMbps,
    required this.uploadMbps,
    required this.onNavigate,
    this.menuItems,
    this.customCardBg,
    this.customCardText,
    this.invoiceColor,
    this.actionColor,
    this.onRefresh,
  });

  @override
  State<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends State<ProviderDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.actionColor ?? Layout09Theme.primary(null);
    const bgColor = Layout09Theme.background;

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: widget.onRefresh ?? () async {},
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header Orgânico (Blob)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 240,
                child: Stack(
                  children: [
                    // Fundo curvo (Blob)
                    Positioned(
                      top: -100,
                      left: -50,
                      right: -50,
                      child: Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.elliptical(300, 100),
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Bem-vindo,',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 16),
                                    ),
                                    Text(
                                      widget.customerName.split(' ').first,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                        Icons.notifications_none_rounded,
                                        color: Colors.white),
                                    onPressed: () =>
                                        widget.onNavigate('notifications'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Card de Fatura Flutuante
                    Positioned(
                      bottom: 0,
                      left: 24,
                      right: 24,
                      child: Container(
                        decoration: Layout09Theme.organicDecoration(
                          color: widget.invoiceColor ?? Colors.white,
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Próxima Fatura',
                                    style: TextStyle(
                                      color: (widget.invoiceColor != null)
                                          ? Colors.white70
                                          : Colors.blueGrey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'R\$ ${widget.billAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: (widget.invoiceColor != null)
                                          ? Colors.white
                                          : const Color(0xFF2C3E50),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => widget.onNavigate('invoices'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (widget.invoiceColor != null)
                                    ? Colors.white
                                    : primaryColor,
                                foregroundColor: (widget.invoiceColor != null)
                                    ? primaryColor
                                    : Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('PAGAR'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Ações Rápidas (Pills)
                  const Text(
                    'SERVIÇOS RÁPIDOS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildPillAction(Icons.speed_rounded, 'Teste',
                            'speed_test', primaryColor),
                        _buildPillAction(Icons.wifi_rounded, 'Wi-Fi', 'wifi',
                            const Color(0xFF8E44AD)),
                        _buildPillAction(Icons.support_agent_rounded, 'Suporte',
                            'support', const Color(0xFFE67E22)),
                        _buildPillAction(Icons.history_rounded, 'Histórico',
                            'invoices', const Color(0xFF1ABC9C)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Status de Conexão (Organic Card)
                  Container(
                    decoration: Layout09Theme.organicDecoration(
                      color: primaryColor.withValues(alpha: 0.05),
                      showShadow: false,
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: primaryColor.withValues(alpha: 0.1)),
                              ),
                              child: Icon(Icons.check_circle_rounded,
                                  color: primaryColor),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Conexão Ativa',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                  Text(
                                    widget.planName,
                                    style: const TextStyle(
                                        color: Colors.blueGrey, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Uso de Dados
                        LinearProgressIndicator(
                          value: widget.usedGb /
                              (widget.totalGb > 0 ? widget.totalGb : 1),
                          backgroundColor: Colors.white,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(primaryColor),
                          borderRadius: BorderRadius.circular(10),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                '${widget.usedGb.toStringAsFixed(1)} GB usados',
                                style: const TextStyle(fontSize: 12)),
                            Text(
                                'Limite: ${widget.totalGb.toStringAsFixed(0)} GB',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Lista de Atalhos
                  _buildOrganicTile(Icons.analytics_outlined,
                      'Diagnóstico de Rede', 'network_diagnostic'),
                  _buildOrganicTile(
                      Icons.description_outlined, 'Meu Contrato', 'contract'),
                  _buildOrganicTile(
                      Icons.alt_route_rounded, 'Traceroute', 'trace_route'),
                  _buildOrganicTile(Icons.public_rounded, 'Meu IP', 'my_ip'),
                  _buildOrganicTile(Icons.data_usage_rounded,
                      'Consumo de Dados', 'internet_usage'),
                  _buildOrganicTile(
                      Icons.help_outline_rounded, 'Dúvidas Frequentes', 'faq'),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildOrganicNavBar(primaryColor),
    );
  }

  Widget _buildPillAction(
      IconData icon, String label, String route, Color color) {
    return _AnimatedPressButton(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onNavigate(route);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganicTile(IconData icon, String label, String route) {
    return _AnimatedPressButton(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onNavigate(route);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Layout09Theme.background,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: Icon(icon, color: const Color(0xFF2C3E50), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.blueGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganicNavBar(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.grid_view_rounded, primaryColor),
          _buildNavItem(1, Icons.wifi_rounded, primaryColor),
          _buildNavItem(2, Icons.receipt_long_rounded, primaryColor),
          _buildNavItem(3, Icons.person_rounded, primaryColor),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, Color primaryColor) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedIndex = index);
        // Implement navigation logic same as other layouts
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.blueGrey,
        ),
      ),
    );
  }
}

// Animated Press Button with Scale Effect
class _AnimatedPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedPressButton({required this.child, required this.onTap});

  @override
  State<_AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<_AnimatedPressButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
```

---

### `lib/layouts/layout_05/login_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../../core/providers/providers.dart';
import '../../core/models/usuario.dart';
import 'theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _cpfController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _blobController;

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final configProvider = ref.read(configurationProvider);
    final config = configProvider.providerConfig;

    if (_cpfController.text.isEmpty) {
      setState(() => _errorMessage = 'Por favor, digite seu CPF/CNPJ');
      HapticFeedback.lightImpact();
      return;
    }
    if (config == null) {
      setState(() => _errorMessage = 'Erro de configuração');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await ref.read(authNotifierProvider.notifier).login(
          _cpfController.text.trim(),
          config,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Usuario?>>(authNotifierProvider, (previous, next) {
      if (next is AsyncError) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Falha ao acessar sua conta';
        });
      } else if (next is AsyncData && next.value != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
        Navigator.of(context).pushReplacementNamed('/painel');
      }
    });

    final config = ref.watch(configurationProvider).providerConfig;
    final primaryColor = Layout09Theme.primary(ref.watch(themeProvider).config);

    return Scaffold(
      backgroundColor:
          Layout09Theme.backgroundColor(ref.watch(themeProvider).config),
      body: Stack(
        children: [
          // Background Blobs (Organic)
          AnimatedBuilder(
            animation: _blobController,
            builder: (context, child) {
              return CustomPaint(
                painter: BlobBackgroundPainter(
                  animationValue: _blobController.value,
                  color: primaryColor.withValues(alpha: 0.1),
                ),
                size: Size.infinite,
              );
            },
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Logo in a soft circle
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: config?.config.logoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: config!.config.logoUrl,
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) =>
                                  Image.asset('assets/images/ajust.png'),
                            )
                          : Image.asset('assets/images/ajust.png'),
                    ),
                  ),

                  const SizedBox(height: 60),

                  const Text(
                    'Bem-vindo',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Conecte-se aos seus serviços de forma fluida e simples.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 60),

                  // Input Field with soft design
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 8),
                        child: Text(
                          'IDENTIFICAÇÃO:',
                          style: TextStyle(
                            color: primaryColor.withValues(alpha: 0.7),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      TextField(
                        controller: _cpfController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 18),
                        decoration: InputDecoration(
                          hintText: 'Digite seu CPF ou CNPJ',
                          prefixIcon: Icon(Icons.person_pin_rounded,
                              color: primaryColor),
                        ),
                      ),
                    ],
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: Color(0xFFE74C3C), fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // Login Button (Pill shaped)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'ACESSAR CONTA',
                            style: TextStyle(fontSize: 16, letterSpacing: 1.1),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BlobBackgroundPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  BlobBackgroundPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    // Simplificar blobs para performance, usando senos para movimento orgânico
    final path1 = Path();
    path1.moveTo(0, size.height * 0.7);
    path1.quadraticBezierTo(
        size.width * 0.25,
        size.height * (0.6 + 0.1 * (1 + 0.5 * (1 + (animationValue * 2)))),
        size.width * 0.5,
        size.height * 0.75);
    path1.quadraticBezierTo(
        size.width * 0.8, size.height * 0.9, size.width, size.height * 0.7);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(size.width, size.height * 0.3);
    path2.quadraticBezierTo(
        size.width * 0.7,
        size.height * (0.2 + 0.05 * (1 + (animationValue * 3))),
        size.width * 0.4,
        size.height * 0.35);
    path2.quadraticBezierTo(
        size.width * 0.2, size.height * 0.5, 0, size.height * 0.25);
    path2.lineTo(0, 0);
    path2.lineTo(size.width, 0);
    path2.close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

---

### `lib/layouts/layout_05/theme.dart`
```dart
import 'package:flutter/material.dart';
import '../../core/models/theme_config.dart';

/// Layout 09: Organic / Biomorphic Theme
/// Fluid shapes, soft colors, and rounded corners (blobs).
class Layout09Theme {
  // Core Colors (Defaults)
  static const Color background = Color(0xFFF0F4F8);
  static const Color surface = Color(0xFFFFFFFF);

  // Natural Defaults
  static const Color _defaultPrimary = Color(0xFF1A5276); // Ocean Blue
  static const Color _defaultSecondary = Color(0xFF1D8348); // forest Green
  static const Color _defaultError = Color(0xFFE74C3C);

  // Dynamic Color Getters
  static Color primary(ThemeConfig? config) =>
      config?.colors.primary ?? _defaultPrimary;
  static Color secondary(ThemeConfig? config) =>
      config?.colors.secondary ?? _defaultSecondary;
  static Color surfaceColor(ThemeConfig? config) =>
      config?.colors.surface ?? surface;
  static Color backgroundColor(ThemeConfig? config) =>
      config?.colors.background ?? background;

  // Organic Decoration (Large Radii)
  static BoxDecoration organicDecoration({
    required Color color,
    BorderRadius? borderRadius,
    bool showShadow = true,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(32),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      );

  // ThemeData
  static ThemeData getTheme(ThemeConfig? config) {
    final primaryColor = primary(config);
    final secondaryColor = secondary(config);
    final bgColor = backgroundColor(config);

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bgColor,
      fontFamily: 'Outfit', // A soft, modern font
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surface,
        error: _defaultError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFF2C3E50),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Color(0xFF2C3E50),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryColor.withValues(alpha: 0.4),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: primaryColor),
        hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.6)),
      ),
      useMaterial3: true,
    );
  }
}
```

---

### `lib/layouts/layout_05/pages/speed_test_page.dart`
> Componente do Layout 05

```dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/diagnostico_service.dart';
import '../../../core/models/diagnostico_state.dart';
import '../theme.dart';

class Layout09SpeedTestPage extends ConsumerStatefulWidget {
  const Layout09SpeedTestPage({super.key});

  @override
  ConsumerState<Layout09SpeedTestPage> createState() =>
      _Layout09SpeedTestPageState();
}

class _Layout09SpeedTestPageState extends ConsumerState<Layout09SpeedTestPage>
    with SingleTickerProviderStateMixin {
  late final DiagnosticoService _service;
  bool _serviceInitialized = false;
  DiagnosticoState _state = DiagnosticoState.initial();
  StreamSubscription? _subscription;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serviceInitialized) {
      final configProvider = ref.read(configurationProvider);
      final providerConfig = configProvider.providerConfig!;
      _service =
          DiagnosticoService(providerConfig: providerConfig, context: context);
      _subscription = _service.stateStream.listen((newState) {
        setState(() {
          _state = newState;
          if (_state.isTesting) {
            if (!_pulseController.isAnimating) {
              _pulseController.repeat(reverse: true);
            }
          } else {
            _pulseController.stop();
          }
        });
      });
      _serviceInitialized = true;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTest() {
    HapticFeedback.mediumImpact();
    _service.runSpeedTestsOnly();
  }

  void _stopTest() {
    _service.stopAllTests();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Layout09Theme.primary(ref.watch(themeProvider).config);
    final secondaryColor = Layout09Theme.secondary(null);
    final isRunning = _state.isTesting ||
        _state.testResultsDisplay['speedTestCustom']?['status'] ==
            TestStatus.running;

    final download = _state.customDownloadResultMbps;
    final upload = _state.customUploadResultMbps;
    final displaySpeed = upload > 1 ? upload : download;

    return Scaffold(
      backgroundColor: Layout09Theme.backgroundColor(null),
      appBar: AppBar(title: const Text('MEDIDOR DE VELOCIDADE')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Blob Pulsante Central
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.1);
                  final speedFactor = (displaySpeed / 500).clamp(0.0, 1.0);

                  return Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: isRunning
                          ? Color.lerp(
                                  primaryColor, secondaryColor, speedFactor)!
                              .withValues(alpha: 0.1)
                          : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.05),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Transform.scale(
                      scale: scale,
                      child: CustomPaint(
                        painter: SpeedBlobPainter(
                          progress: speedFactor,
                          color: isRunning
                              ? Color.lerp(
                                  primaryColor, secondaryColor, speedFactor)!
                              : Colors.blueGrey.withValues(alpha: 0.2),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                displaySpeed.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Layout09Theme.primary(null),
                                ),
                              ),
                              const Text(
                                'Mbps',
                                style: TextStyle(
                                    color: Colors.blueGrey,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 60),

            // Resultados
            Row(
              children: [
                Expanded(
                  child: _buildResultCard('Download', download,
                      Icons.download_rounded, primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildResultCard(
                      'Upload', upload, Icons.upload_rounded, secondaryColor),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // Botão Orgânico
            GestureDetector(
              onTap: isRunning ? _stopTest : _startTest,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: isRunning
                      ? Colors.red.withValues(alpha: 0.1)
                      : primaryColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: isRunning
                      ? null
                      : [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Center(
                  child: Text(
                    isRunning ? 'PARAR TESTE' : 'INICIAR TESTE',
                    style: TextStyle(
                      color: isRunning ? Colors.red : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(
      String label, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          const SizedBox(height: 4),
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class SpeedBlobPainter extends CustomPainter {
  final double progress;
  final Color color;

  SpeedBlobPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    for (int i = 0; i < 360; i += 10) {
      final angle = i * math.pi / 180;
      // Adicionar variação orgânica baseada no progresso
      final variation = math.sin(angle * 3) * (5 + 15 * progress);
      final currentRadius = radius + variation;

      final x = center.dx + currentRadius * math.cos(angle);
      final y = center.dy + currentRadius * math.sin(angle);

      if (i == 0) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      } else {
        // Apenas desenha pontos para um efeito "floaty"
        canvas.drawCircle(Offset(x, y), 2 + (progress * 2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

## 🔷 Layout 06 - Cyberpunk Neon
> Design futurista com neon cyan/pink. GridPainter background. BottomNav próprio.


---

### `lib/layouts/layout_06/dashboard_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DashboardPage extends StatefulWidget {
  final String customerName;
  final String planName;
  final String connectionStatus;
  final double billAmount;
  final DateTime billDueDate;
  final double usedGb;
  final double totalGb;
  final double downloadMbps;
  final double uploadMbps;
  final Function(String) onNavigate;
  final List<Map<String, dynamic>>? menuItems;
  final Future<void> Function()? onRefresh;

  const DashboardPage({
    super.key,
    required this.customerName,
    required this.planName,
    required this.connectionStatus,
    required this.billAmount,
    required this.billDueDate,
    required this.usedGb,
    required this.totalGb,
    required this.downloadMbps,
    required this.uploadMbps,
    required this.onNavigate,
    this.menuItems,
    this.onRefresh,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentNavIndex = 0;

  // Cyberpunk Color Palette
  static const Color _bgDark = Color(0xFF050A14);
  static const Color _cardBg = Color(0xFF131B2C);
  static const Color _neonCyan = Color(0xFF00F3FF);
  static const Color _neonPink = Color(0xFFBC13FE);
  static const Color _textWhite = Colors.white;
  static const Color _textGray = Color(0xFF8A9BB8);

  @override
  Widget build(BuildContext context) {
    final remainingDays = widget.billDueDate.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          // Background Grid Effect (Optional)
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(),
            ),
          ),

          Column(
            children: [
              // Main Scrollable Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    if (widget.onRefresh != null) {
                      HapticFeedback.mediumImpact();
                      await widget.onRefresh!();
                    }
                  },
                  color: _neonCyan,
                  backgroundColor: _cardBg,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(context),

                        const SizedBox(height: 32),

                        // Balance / Bill Card (Cyberpunk Style)
                        _buildBalanceCard(remainingDays),

                        const SizedBox(height: 24),

                        // Quick Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQuickAction(Icons.receipt_long_rounded,
                                'Faturas', 'invoices', _neonCyan),
                            _buildQuickAction(Icons.speed_rounded, 'Velocidade',
                                'speed_test', _neonPink),
                            _buildQuickAction(Icons.support_agent_rounded,
                                'Suporte', 'support', _neonCyan),
                            _buildQuickAction(
                                Icons.wifi_rounded, 'Wi-Fi', 'wifi', _neonPink),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Plan Details (Holo Card)
                        _buildPlanCard(),

                        const SizedBox(height: 32),

                        // Services Title
                        const Text(
                          'DIAGNÓSTICO & SERVIÇOS',
                          style: TextStyle(
                            color: _textGray,
                            fontSize: 12,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Services List
                        _buildServiceItem(
                            Icons.analytics_rounded,
                            'Diagnóstico Rede',
                            'Verificar stauts da conexão',
                            'network_diagnostic'),
                        _buildServiceItem(Icons.route_rounded, 'Traceroute',
                            'Rastrear rota de pacotes', 'trace_route',
                            color: _neonPink),
                        _buildServiceItem(Icons.data_usage_rounded, 'Consumo',
                            'Histórico de uso de dados', 'internet_usage'),
                        _buildServiceItem(Icons.public_rounded, 'Meu IP',
                            'Visualizar endereço IP', 'my_ip',
                            color: _neonPink),
                        _buildServiceItem(Icons.description_rounded, 'Contrato',
                            'Termos de serviço', 'contract'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom Nav
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _neonCyan.withOpacity(0.3)),
                ),
                child: const Icon(Icons.menu_rounded, color: _neonCyan),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BEM-VINDO,',
                  style: TextStyle(
                    color: _textGray,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.customerName.split(' ').first.toUpperCase(),
                  style: const TextStyle(
                    color: _textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(2), // Gradient border trick
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_neonCyan, _neonPink]),
            shape: BoxShape.circle,
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: _bgDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: _textWhite, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(int remainingDays) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _neonPink.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: _neonPink.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.bolt_rounded,
              size: 150,
              color: _neonPink.withOpacity(0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'FATURA ATUAL',
                      style: TextStyle(
                        color: _textGray,
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _neonCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _neonCyan.withOpacity(0.5)),
                      ),
                      child: Text(
                        widget.connectionStatus.toUpperCase(),
                        style: const TextStyle(
                          color: _neonCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'R\$ ${widget.billAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _textWhite,
                    fontSize: 42,
                    fontFamily: 'Roboto', // Or relevant monospace
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    shadows: [
                      Shadow(
                        color: _neonPink,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 14, color: _textGray),
                    const SizedBox(width: 8),
                    Text(
                      remainingDays >= 0
                          ? 'Vence em $remainingDays dias'
                          : 'Vencida há ${remainingDays.abs()} dias',
                      style: TextStyle(
                        color: remainingDays < 0 ? _neonPink : _textGray,
                        fontSize: 14,
                        fontWeight: remainingDays < 0
                            ? FontWeight.bold
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      IconData icon, String label, String route, Color accentColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onNavigate(route);
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _bgDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accentColor.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.15),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: _textGray,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard() {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [_neonCyan, Colors.transparent, _neonPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg.withOpacity(0.95),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _neonCyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.router_outlined, color: _neonCyan),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.planName,
                    style: const TextStyle(
                      color: _textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.download_rounded, size: 14, color: _textGray),
                      Text('${widget.downloadMbps.toInt()} Mb',
                          style:
                              const TextStyle(color: _textGray, fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.upload_rounded, size: 14, color: _textGray),
                      Text('${widget.uploadMbps.toInt()} Mb',
                          style:
                              const TextStyle(color: _textGray, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _neonPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('PRO',
                  style: TextStyle(
                      color: _neonPink,
                      fontWeight: FontWeight.bold,
                      fontSize: 10)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(
      IconData icon, String title, String subtitle, String route,
      {Color color = _neonCyan}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onNavigate(route);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color.withOpacity(0.8), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _textWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _textGray.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _textGray),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: _bgDark.withOpacity(0.9),
        border: Border(top: BorderSide(color: _neonCyan.withOpacity(0.2))),
        boxShadow: const [
          BoxShadow(
              color: Colors.black54, blurRadius: 20, offset: Offset(0, -5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_filled, 0),
          _buildNavItem(Icons.wifi, 1),
          _buildNavItem(Icons.receipt_long, 2),
          _buildNavItem(Icons.headset_mic, 3),
          _buildNavItem(Icons.person, 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentNavIndex = index);
        switch (index) {
          case 1:
            widget.onNavigate('wifi');
            break;
          case 2:
            widget.onNavigate('invoices');
            break;
          case 3:
            widget.onNavigate('support');
            break;
          case 4:
            Scaffold.of(context).openDrawer();
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: isSelected
            ? BoxDecoration(
                color: _neonCyan.withOpacity(0.1),
                shape: BoxShape.circle,
              )
            : null,
        child: Icon(
          icon,
          color: isSelected ? _neonCyan : _textGray,
          size: 26,
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    const spacing = 40.0;

    for (var i = 0.0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (var i = 0.0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

---

### `lib/layouts/layout_06/login_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../../core/providers/providers.dart';
import '../../core/models/usuario.dart'; // Import Usuario explicitly
import 'widgets/glass_card.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _cpfController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Animation
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final configProvider = ref.read(configurationProvider);
    final config = configProvider.providerConfig;

    if (_cpfController.text.isEmpty) {
      setState(() => _errorMessage = 'Por favor, digite seu CPF/CNPJ');
      HapticFeedback.vibrate(); // Error Haptic
      return;
    }
    if (config == null) {
      setState(() => _errorMessage = 'Erro de configuração');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Just trigger the login. The listener in build() handles success/error.
    await ref.read(authNotifierProvider.notifier).login(
          _cpfController.text.trim(),
          config,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to Auth State changes for Navigation and Error Handling
    ref.listen<AsyncValue<Usuario?>>(authNotifierProvider, (previous, next) {
      if (next is AsyncError) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Falha no login: ${next.error.toString().replaceAll('Exception:', '').trim()}';
        });
      } else if (next is AsyncData && next.value != null) {
        // Login Success
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
        // Navigate to Dashboard (PainelPage is wrapper)
        // Ensure we replace the route so user can't go back to login
        Navigator.of(context).pushReplacementNamed('/painel');
      }
    });

    final config = ref.watch(configurationProvider).providerConfig;
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).cardColor;
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final errorColor = Theme.of(context).colorScheme.error;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background gradient orb 1 (Aurora)
          Positioned(
            top: -150,
            right: -100,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animController.value * 2.0 * 3.14159,
                  child: child,
                );
              },
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.15),
                      Colors.transparent,
                      primaryColor.withValues(alpha: 0.15),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Background gradient orb 2 (Aurora Counter-Clockwise)
          Positioned(
            bottom: -100,
            left: -100,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -_animController.value * 2.0 * 3.14159,
                  child: child,
                );
              },
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      secondaryColor.withValues(alpha: 0.1),
                      Colors.transparent,
                      secondaryColor.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  // Logo
                  if (config?.config.logoUrl != null)
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: CachedNetworkImage(
                          imageUrl: config!.config.logoUrl,
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) {
                            return Image.asset(
                              'assets/images/ajust.png',
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/ajust.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                  const SizedBox(height: 60),

                  // Title
                  Text(
                    'Bem-vindo\nde Volta',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Acesse sua conta para gerenciar\nseus serviços de internet',
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Input Card
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CPF / CNPJ',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _cpfController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: '000.000.000-00',
                            hintStyle: TextStyle(
                              color: textSecondary.withValues(alpha: 0.5),
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: primaryColor,
                            ),
                            filled: true,
                            fillColor: surfaceColor.withValues(alpha: 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Error Message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: errorColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: errorColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Login Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              _handleLogin();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors
                            .black, // Keep text black for contrast on bright primary
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Entrar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### `lib/layouts/layout_06/widgets/bottom_nav.dart`
> Widget do Layout 06

```dart
import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get colors from context
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceColor = Theme.of(context).cardColor;
    final textSecondaryColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
              context, Icons.home_rounded, 0, primaryColor, textSecondaryColor),
          _buildNavItem(context, Icons.receipt_long_rounded, 1, primaryColor,
              textSecondaryColor),
          _buildNavItem(context, Icons.speed_rounded, 2, primaryColor,
              textSecondaryColor),
          _buildNavItem(context, Icons.person_rounded, 3, primaryColor,
              textSecondaryColor),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, int index,
      Color primaryColor, Color secondaryColor) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: isSelected
            ? BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Icon(
          icon,
          color: isSelected ? primaryColor : secondaryColor,
          size: 24,
        ),
      ),
    );
  }
}
```

---

### `lib/layouts/layout_06/widgets/error_widget.dart`
> Widget do Layout 06

```dart
import 'package:flutter/material.dart';
import 'glass_card.dart';

class Layout06ErrorWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const Layout06ErrorWidget({
    super.key,
    this.icon = Icons.error_outline_rounded,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Tentar Novamente',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      retryLabel!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### `lib/layouts/layout_06/widgets/glass_card.dart`
> Widget do Layout 06

```dart
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? height;
  final VoidCallback? onTap;
  final bool useGradientBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.onTap,
    this.useGradientBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    // Layout 06 is designed as a Dark theme.
    // Even if the global theme is Light, these cards must remain dark (Black).
    final surfaceColor = Theme.of(context).cardColor;

    final dynamicGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryColor, secondaryColor],
    );

    final glassmorphism = BoxDecoration(
      color: surfaceColor, // Removed .withValues(alpha: 0.6) to allow vibrant colors
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: padding ?? const EdgeInsets.all(20),
        decoration: useGradientBorder
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: dynamicGradient,
              )
            : glassmorphism,
        child: useGradientBorder
            ? Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: padding ?? const EdgeInsets.all(20),
                child: child,
              )
            : child,
      ),
    );
  }
}
```

---

### `lib/layouts/layout_06/widgets/skeleton_dashboard_page.dart`
> Widget do Layout 06

```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonDashboardPage extends StatelessWidget {
  const SkeletonDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          enabled: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 100,
                            height: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 60,
                            height: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Balance Card
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                    4,
                    (index) => Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 40,
                              height: 10,
                              color: Colors.white,
                            ),
                          ],
                        )),
              ),
              const SizedBox(height: 28),

              // Plan Card
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 24),

              // Services List
              Column(
                children: List.generate(
                    3,
                    (index) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          width: double.infinity,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### `lib/layouts/layout_06/widgets/skeleton_financeiro_page.dart`
> Widget do Layout 06

```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonFinanceiroPage extends StatelessWidget {
  const SkeletonFinanceiroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 100,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            )),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, // Don't show back arrow placeholder
      ),
      body: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

# �� Estatísticas Finais

- **Total de arquivos:** 87
- **Total de linhas:** 21666
- **Layouts disponíveis:** 6

## 🌅 Layout 07 - Pôr-do-Sol Tropical
> Tema quente e amigável com gradientes suaves.


---

### `lib/layouts/layout_07/theme.dart`
> Definição de cores e tipografia (Poppins)

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema para o layout 07 (Pôr‑do‑Sol Tropical).
class Layout07Theme {
  // Cores principais
  static const Color headerStart = Color(0xFFFF6B6B); // coral quente
  static const Color headerMid = Color(0xFFFFB66C); // tom de pêssego
  static const Color headerEnd = Color(0xFF56CCF2); // azul‑turquesa
  static const Color background = Color(0xFFFFF7EE); // fundo claro
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color accent = Color(0xFF2D9CDB); // azul‑verde para destaques

  /// Cria um [ThemeData] completo com base nas cores do layout.
  static ThemeData getTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: accent,
      scaffoldBackgroundColor: background,
      cardColor: cardBackground,
      // Usa a fonte Poppins via GoogleFonts
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: ColorScheme.light(
        primary: accent,
        secondary: accent,
        background: background,
        surface: cardBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      useMaterial3: true,
    );
  }

  /// Gradiente usado no cabeçalho superior.
  static LinearGradient headerGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [headerStart, headerMid, headerEnd],
    );
  }
}
```

---

### `lib/layouts/layout_07/dashboard_page.dart`
> Dashboard com gradiente e cards de serviços

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'theme.dart';

typedef NavigateToPageCallback = void Function(String pageId);

/// Página principal do provedor para o layout 07.
///
/// Exibe uma saudação, status da conexão, detalhes de fatura, um grid de serviços
/// e um botão para iniciar o diagnóstico completo. Todas as cores e estilos são
/// baseados em [Layout07Theme].
class ProviderDashboardPage extends StatelessWidget {
  final String customerName;
  final String planName;
  final String connectionStatus;
  final double billAmount;
  final double usedGb;
  final double totalGb;
  final double downloadMbps;
  final double uploadMbps;
  final DateTime billDueDate;
  final NavigateToPageCallback onNavigate;
  final Future<void> Function()? onRefresh;

  const ProviderDashboardPage({
    super.key,
    required this.customerName,
    required this.planName,
    required this.connectionStatus,
    required this.billAmount,
    required this.billDueDate,
    required this.usedGb,
    required this.totalGb,
    required this.downloadMbps,
    required this.uploadMbps,
    required this.onNavigate,
    this.onRefresh,
  });

  /// Verifica se a conexão está ativa.
  bool get isConnected =>
      connectionStatus.toLowerCase() == 'ativo' ||
      connectionStatus.toLowerCase() == 'conectado';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          if (onRefresh != null) {
            await onRefresh!();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Cabeçalho com gradiente
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: Layout07Theme.headerGradient(),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.menu),
                              color: Colors.white,
                              onPressed: () =>
                                  Scaffold.of(context).openDrawer(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.notifications_none),
                              color: Colors.white,
                              onPressed: () => onNavigate('notifications'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Olá,',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          customerName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.signal_cellular_alt,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                planName,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildStatusCard(context),
                    const SizedBox(height: 16),
                    _buildInvoiceCard(context),
                    const SizedBox(height: 16),
                    _buildServicesGrid(context),
                    const SizedBox(height: 16),
                    _buildDiagnosticButton(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o cartão de status de conexão.
  Widget _buildStatusCard(BuildContext context) {
    final theme = Theme.of(context);
    final bool connected = isConnected;
    final Color iconBg = connected
        ? Colors.greenAccent.withOpacity(0.2)
        : Colors.redAccent.withOpacity(0.2);
    final Color iconColor =
        connected ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Ícone de status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                connected ? Icons.check_circle : Icons.error,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected ? 'Conectado' : 'Desconectado',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Layout07Theme.textPrimary,
                  ),
                ),
                Text(
                  connected ? 'Status Online' : 'Verifique sua rede',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Layout07Theme.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.download, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${downloadMbps.toStringAsFixed(1)} Mbps',
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.upload, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${uploadMbps.toStringAsFixed(1)} Mbps',
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o cartão de fatura.
  Widget _buildInvoiceCard(BuildContext context) {
    final theme = Theme.of(context);
    final daysLeft = billDueDate.difference(DateTime.now()).inDays;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Layout07Theme.accent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Layout07Theme.accent,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fatura',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Layout07Theme.textPrimary,
                    ),
                  ),
                  Text(
                    'R\$ ${billAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Layout07Theme.textPrimary,
                    ),
                  ),
                  Text(
                    'Vence em ${DateFormat('dd/MM/yyyy').format(billDueDate)} (${daysLeft}d)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Layout07Theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Layout07Theme.accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => onNavigate('invoices'),
              child: const Text('Ver'),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o grid de serviços (faturas, suporte, serviços, diagnóstico).
  Widget _buildServicesGrid(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      shrinkWrap: true,
      childAspectRatio: 3 / 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _ServiceButton(
          icon: Icons.receipt_long,
          label: 'Faturas',
          color: const Color(0xFFFDECC8),
          onTap: () => onNavigate('invoices'),
        ),
        _ServiceButton(
          icon: Icons.support_agent,
          label: 'Suporte',
          color: const Color(0xFFE0F7FA),
          onTap: () => onNavigate('support'),
        ),
        _ServiceButton(
          icon: Icons
              .wifi, // Changed from dashboard_customize to match intent better
          label: 'Wi-Fi',
          color: const Color(0xFFEFFBF5),
          onTap: () => onNavigate('wifi'),
        ),
        _ServiceButton(
          icon: Icons.speed,
          label: 'Diagnóstico',
          color: const Color(0xFFF6E6F6),
          onTap: () => onNavigate('network_diagnostic'),
        ),
      ],
    );
  }

  /// Constrói o botão para iniciar o diagnóstico completo.
  Widget _buildDiagnosticButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Layout07Theme.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () => onNavigate('network_diagnostic'),
        child: const Text(
          'Diagnóstico Completo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Widget interno usado para representar um botão de serviço na grade.
class _ServiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ServiceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Layout07Theme.accent,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Layout07Theme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### `lib/layouts/layout_07/login_page.dart`
> Login simplificado com gradiente

```dart
import 'package:flutter/material.dart';

import 'theme.dart';

/// Página de login simplificada para o layout 07.
///
/// Aceita um callback opcional [onLogin] que será chamado com o CPF/CNPJ
/// digitado. Também aceita um [onBiometricLogin] opcional para autenticação
/// biométrica.
class LoginPage extends StatefulWidget {
  final Future<void> Function(String cpf)? onLogin;
  final VoidCallback? onBiometricLogin;

  const LoginPage({
    super.key,
    this.onLogin,
    this.onBiometricLogin,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _cpfController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho gradiente
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                gradient: Layout07Theme.headerGradient(),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wb_sunny_rounded,
                          size: 60, color: Colors.white.withOpacity(0.9)),
                      const SizedBox(height: 16),
                      Text(
                        'Bem‑vindo',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Insira seu CPF/CNPJ',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Layout07Theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cpfController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Layout07Theme.cardBackground,
                      hintText: '000.000.000-00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Layout07Theme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                      shadowColor: Layout07Theme.accent.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final cpf = _cpfController.text.trim();
                            if (cpf.isEmpty) return;
                            setState(() {
                              _isLoading = true;
                            });
                            if (widget.onLogin != null) {
                              await widget.onLogin!(cpf);
                            }
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          },
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Entrar',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 24),
                  if (widget.onBiometricLogin != null)
                    OutlinedButton.icon(
                      onPressed: widget.onBiometricLogin,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Entrar com biometria'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Layout07Theme.accent,
                        side: BorderSide(color: Layout07Theme.accent),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

# 📊 Estatísticas Finais

- **Total de arquivos:** 90
- **Total de linhas:** 22323
- **Layouts disponíveis:** 7

