import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'theme.dart';

typedef NavigateToPageCallback = void Function(String pageName);

class DashboardPage extends StatelessWidget {
  final String customerName;
  final String planName;
  final String connectionStatus;
  final double billAmount;
  final DateTime billDueDate;
  final double usedGb;
  final double totalGb;
  final double downloadMbps;
  final double uploadMbps;
  final NavigateToPageCallback onNavigate;

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
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat("d 'de' MMMM", 'pt_BR');

    // Status Logic
    final isConnectionActive = connectionStatus.toLowerCase() == 'ativo';
    final statusColor =
        isConnectionActive ? Layout04Theme.success : Layout04Theme.error;

    // Usage Logic
    final usageProgress =
        (totalGb > 0) ? (usedGb / totalGb).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: Layout04Theme.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // --- HEADER ---
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, $customerName',
                            style: Layout04Theme.heading2,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            planName,
                            style: Layout04Theme.bodyMedium,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: statusColor.withOpacity(0.2)),
                        ),
                        child: Row(
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
                              connectionStatus,
                              style: Layout04Theme.caption.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- CONTENT ---
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // BILL CARD
                    Container(
                      decoration: Layout04Theme.activeCardDecoration,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Próxima Fatura',
                                  style: Layout04Theme.bodyMedium),
                              Icon(Icons.receipt_long_rounded,
                                  color: Layout04Theme.primary, size: 20),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currencyFormat.format(billAmount),
                            style: Layout04Theme.heading1,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vence em ${dateFormat.format(billDueDate)}',
                            style: Layout04Theme.bodySmall.copyWith(
                              color: Layout04Theme.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => onNavigate('invoices'),
                              style: Layout04Theme.primaryButtonStyle.copyWith(
                                minimumSize: WidgetStateProperty.all(
                                    const Size(double.infinity, 48)),
                              ),
                              child: const Text('PAGAR AGORA'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // USAGE & SPEED ROW
                    Row(
                      children: [
                        // Usage Card
                        Expanded(
                          child: Container(
                            decoration: Layout04Theme.cardDecoration,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Consumo',
                                    style: Layout04Theme.bodyMedium),
                                const SizedBox(height: 16),
                                Stack(
                                  children: [
                                    Container(
                                      height: 6,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Layout04Theme.surfaceHighlight,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: usageProgress,
                                      child: Container(
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: Layout04Theme.accent,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${usedGb.toInt()} GB',
                                      style: Layout04Theme.heading3
                                          .copyWith(fontSize: 16),
                                    ),
                                    Text(
                                      'de ${totalGb.toInt()}',
                                      style: Layout04Theme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Speed Card
                        Expanded(
                          child: InkWell(
                            onTap: () => onNavigate('speed_test'),
                            child: Container(
                              decoration: Layout04Theme.cardDecoration,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Velocidade',
                                      style: Layout04Theme.bodyMedium),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.arrow_downward_rounded,
                                          color: Layout04Theme.success,
                                          size: 16),
                                      const SizedBox(width: 4),
                                      Text('${downloadMbps.toInt()}',
                                          style: Layout04Theme.heading3
                                              .copyWith(fontSize: 18)),
                                      Text(' Mb',
                                          style: Layout04Theme.bodySmall),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.arrow_upward_rounded,
                                          color: Layout04Theme.primary,
                                          size: 16),
                                      const SizedBox(width: 4),
                                      Text('${uploadMbps.toInt()}',
                                          style: Layout04Theme.heading3
                                              .copyWith(fontSize: 18)),
                                      Text(' Mb',
                                          style: Layout04Theme.bodySmall),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // QUICK ACTIONS TITLE
                    Text('Acesso Rápido', style: Layout04Theme.heading3),
                    const SizedBox(height: 16),

                    // GRID
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _QuickAction(
                          icon: Icons.receipt_long_outlined,
                          label: 'Faturas',
                          onTap: () => onNavigate('invoices'),
                        ),
                        _QuickAction(
                          icon: Icons.wifi_rounded,
                          label: 'Meu Wi-Fi',
                          onTap: () => onNavigate('wifi'),
                        ),
                        _QuickAction(
                          icon: Icons.support_agent_rounded,
                          label: 'Suporte',
                          onTap: () => onNavigate('support'),
                        ),
                        _QuickAction(
                          icon: Icons.speed_rounded,
                          label: 'Speedtest',
                          onTap: () => onNavigate('speed_test'),
                        ),
                        _QuickAction(
                          icon: Icons.build_outlined,
                          label: 'Técnico',
                          onTap: () => onNavigate('network_diagnostic'),
                        ),
                        _QuickAction(
                          icon: Icons.settings_outlined,
                          label: 'Dados',
                          onTap: () => onNavigate('my_ip'),
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: Layout04Theme.cardDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Layout04Theme.surfaceHighlight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Layout04Theme.primary, size: 24),
            ),
            const SizedBox(height: 12),
            Text(label, style: Layout04Theme.bodySmall),
          ],
        ),
      ),
    );
  }
}
