import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProviderDashboardPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final backgroundColor = theme.scaffoldBackgroundColor;

    // Layout 12: Minimalist, Big Type, Sharp Edges
    // AI Inspiration: "Bold Numeric Hierarchy", "Negative Space"

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (onRefresh != null) await onRefresh!();
          },
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Header (Minimal)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "OLÁ, ${customerName.split(' ').first.toUpperCase()}",
                          style: TextStyle(
                            fontSize: 14,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w900,
                            color: theme.textTheme.bodyLarge?.color
                                ?.withOpacity(0.5),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.menu_rounded),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Big Status (Typographic)
                    Text(
                      connectionStatus.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                        color: connectionStatus.toLowerCase() == 'ativo'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      planName,
                      style: TextStyle(
                        fontSize: 42,
                        height: 1.0,
                        fontWeight: FontWeight.w900, // Black weight
                        letterSpacing: -1.5,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Invoice Section (Main Call to Action)
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: primaryColor,
                            width: 4,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.only(left: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "PRÓXIMA FATURA",
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "R\$${billAmount.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight:
                                  FontWeight.w300, // Thin font for numbers
                              letterSpacing: -2,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _BigSquareButton(
                            label: "PAGAR AGORA",
                            icon: Icons.arrow_forward,
                            color: primaryColor,
                            textColor: Colors.white,
                            onTap: () => onNavigate('invoices'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Grid Navigation (Sharp Buttons)
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _MinimalCard(
                          title: "Wi-Fi",
                          subtitle: "Gerenciar",
                          icon: Icons.wifi,
                          onTap: () => onNavigate('wifi'),
                        ),
                        _MinimalCard(
                          title: "Suporte",
                          subtitle: "Ajuda",
                          icon: Icons.chat_bubble_outline,
                          onTap: () => onNavigate('support'),
                        ),
                        _MinimalCard(
                          title: "Velocidade",
                          subtitle: "${downloadMbps.toInt()} Mega",
                          icon: Icons.speed,
                          onTap: () => onNavigate('speed_test'),
                        ),
                        _MinimalCard(
                          title: "Mais",
                          subtitle: "Serviços",
                          icon: Icons.grid_view,
                          onTap: () => Scaffold.of(context).openDrawer(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigSquareButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _BigSquareButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.zero, // Sharp edges
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, color: textColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MinimalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MinimalCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.zero, // Minimalist sharp
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
