import 'package:flutter/material.dart';
import '../../models/dashboard_config.dart';
import '../../services/dashboard_service.dart';
import 'invoice_widget.dart';
import 'stats_card_widget.dart';
import 'banner_widget.dart';
import 'action_grid_widget.dart';
import 'carousel_widget.dart';
import 'chart_widget.dart';
import 'announcements_widget.dart';
import 'promotion_widget.dart';
import 'quick_links_widget.dart';

/// Widget principal que constrói o dashboard dinâmico baseado na configuração
class DynamicDashboard extends StatelessWidget {
  final String providerId;

  const DynamicDashboard({
    super.key,
    required this.providerId,
  });

  @override
  Widget build(BuildContext context) {
    final dashboardService = DashboardService();

    return StreamBuilder<DashboardConfig>(
      stream: dashboardService.watchConfig(providerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erro ao carregar dashboard: ${snapshot.error}'),
              ],
            ),
          );
        }

        final config = snapshot.data ?? DashboardConfig.defaultConfig;
        final widgets = config.widgets
          ..sort((a, b) => a.order.compareTo(b.order));

        final enabledWidgets = widgets.where((w) => w.enabled).toList();

        if (enabledWidgets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dashboard, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Nenhum widget configurado',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: enabledWidgets.length,
          itemBuilder: (context, index) {
            return _buildWidget(enabledWidgets[index]);
          },
        );
      },
    );
  }

  Widget _buildWidget(DashboardWidget widget) {
    switch (widget.type) {
      case DashboardWidgetType.invoice:
        return InvoiceWidget(config: widget.config);

      case DashboardWidgetType.stats:
        return StatsCardWidget(config: widget.config);

      case DashboardWidgetType.banner:
        return BannerWidget(config: widget.config);

      case DashboardWidgetType.actions:
        return ActionGridWidget(config: widget.config);

      case DashboardWidgetType.carousel:
        return CarouselWidget(config: widget.config);

      case DashboardWidgetType.chart:
        return ChartWidget(config: widget.config);

      case DashboardWidgetType.announcements:
        return AnnouncementsWidget(config: widget.config);

      case DashboardWidgetType.promotion:
        return PromotionWidget(config: widget.config);

      case DashboardWidgetType.quickLinks:
        return QuickLinksWidget(config: widget.config);
    }
  }
}
