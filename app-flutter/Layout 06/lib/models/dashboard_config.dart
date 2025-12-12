/// Configuração do dashboard personalizável
class DashboardConfig {
  final List<DashboardWidget> widgets;

  DashboardConfig({required this.widgets});

  factory DashboardConfig.fromJson(Map<String, dynamic> json) {
    final widgetsData = json['widgets'] as List<dynamic>? ?? [];
    return DashboardConfig(
      widgets: widgetsData
          .map((w) => DashboardWidget.fromJson(w as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'widgets': widgets.map((w) => w.toJson()).toList(),
      };

  static DashboardConfig get defaultConfig => DashboardConfig(
        widgets: [
          DashboardWidget(
            id: 'default_invoice',
            type: DashboardWidgetType.invoice,
            order: 1,
            enabled: true,
            config: {},
          ),
          DashboardWidget(
            id: 'default_actions',
            type: DashboardWidgetType.actions,
            order: 2,
            enabled: true,
            config: {
              'actions': ['support', 'speed_test', 'invoices']
            },
          ),
        ],
      );
}

/// Representa um widget individual no dashboard
class DashboardWidget {
  final String id;
  final DashboardWidgetType type;
  final int order;
  final bool enabled;
  final Map<String, dynamic> config;

  DashboardWidget({
    required this.id,
    required this.type,
    required this.order,
    required this.enabled,
    required this.config,
  });

  factory DashboardWidget.fromJson(Map<String, dynamic> json) {
    return DashboardWidget(
      id: json['id'] as String,
      type: dashboardWidgetTypeFromString(json['type'] as String),
      order: json['order'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? true,
      config: json['config'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'order': order,
        'enabled': enabled,
        'config': config,
      };
}

/// Tipos de widgets disponíveis
enum DashboardWidgetType {
  stats, // Card de estatística
  banner, // Banner promocional
  actions, // Grid de ações rápidas
  carousel, // Carrossel de notícias
  chart, // Gráfico de consumo
  announcements, // Avisos importantes
  promotion, // Promoção em destaque
  quickLinks, // Links rápidos
  invoice, // Fatura pendente
}

extension DashboardWidgetTypeExtension on DashboardWidgetType {
  String get name {
    switch (this) {
      case DashboardWidgetType.stats:
        return 'stats';
      case DashboardWidgetType.banner:
        return 'banner';
      case DashboardWidgetType.actions:
        return 'actions';
      case DashboardWidgetType.carousel:
        return 'carousel';
      case DashboardWidgetType.chart:
        return 'chart';
      case DashboardWidgetType.announcements:
        return 'announcements';
      case DashboardWidgetType.promotion:
        return 'promotion';
      case DashboardWidgetType.quickLinks:
        return 'quick_links';
      case DashboardWidgetType.invoice:
        return 'invoice';
    }
  }
}

DashboardWidgetType dashboardWidgetTypeFromString(String type) {
  switch (type) {
    case 'stats':
      return DashboardWidgetType.stats;
    case 'banner':
      return DashboardWidgetType.banner;
    case 'actions':
      return DashboardWidgetType.actions;
    case 'carousel':
      return DashboardWidgetType.carousel;
    case 'chart':
      return DashboardWidgetType.chart;
    case 'announcements':
      return DashboardWidgetType.announcements;
    case 'promotion':
      return DashboardWidgetType.promotion;
    case 'quick_links':
      return DashboardWidgetType.quickLinks;
    case 'invoice':
      return DashboardWidgetType.invoice;
    default:
      print('⚠️ Tipo de widget desconhecido: $type');
      return DashboardWidgetType.stats;
  }
}
