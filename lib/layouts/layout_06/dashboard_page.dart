import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/app_colors.dart';

typedef NavigateToPageCallback = void Function(String pageId);

class ProviderDashboardPage extends StatelessWidget {
  final String customerName, planName, connectionStatus;
  final double billAmount, usedGb, totalGb, downloadMbps, uploadMbps;
  final DateTime billDueDate;
  final NavigateToPageCallback onNavigate;

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
  });

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder para adaptar os cards em telas maiores
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 680;
        final usagePercent =
            (totalGb == 0) ? 0.0 : (usedGb / totalGb).clamp(0.0, 1.0);

        // Constrói os cards de Uso e Velocidade
        final usageAndSpeed = isWide
            ? Row(
                children: [
                  Expanded(
                    child: _UsageCard(
                      usedGb: usedGb,
                      totalGb: totalGb,
                      usagePercent: usagePercent,
                      onNavigate: onNavigate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SpeedCard(
                      download: downloadMbps,
                      upload: uploadMbps,
                      onNavigate: onNavigate,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _UsageCard(
                    usedGb: usedGb,
                    totalGb: totalGb,
                    usagePercent: usagePercent,
                    onNavigate: onNavigate,
                  ),
                  const SizedBox(height: 16),
                  _SpeedCard(
                    download: downloadMbps,
                    upload: uploadMbps,
                    onNavigate: onNavigate,
                  ),
                ],
              );

        return CustomScrollView(
          slivers: [
            _DashboardHeader(
              customerName: customerName,
              planName: planName,
              connectionStatus: connectionStatus,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _BillCard(
                      amount: billAmount,
                      dueDate: billDueDate,
                      onNavigate: onNavigate),
                  const SizedBox(height: 16),
                  usageAndSpeed, // Inserção dinâmica baseada na largura
                  const SizedBox(height: 16),
                  _QuickActionsGrid(
                      onNavigate: onNavigate,
                      crossAxisCount:
                          isWide ? 4 : 3 // Mais colunas em tela larga
                      ),
                  const SizedBox(height: 16),
                  _SupportCard(onNavigate: onNavigate),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- WIDGETS AUXILIARES REFATORADOS ---

class _DashboardHeader extends StatelessWidget {
  final String customerName, planName, connectionStatus;

  const _DashboardHeader(
      {required this.customerName,
      required this.planName,
      required this.connectionStatus});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;
    final isConnectionOk = connectionStatus.toLowerCase() == 'ativo';
    final statusColor = isConnectionOk ? AppColors.success : AppColors.error;

    return SliverAppBar(
      elevation: 0,
      pinned: true,
      expandedHeight: 220.0,
      backgroundColor: primaryColor,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text('Painel do Cliente',
            style: textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: LayoutBuilder(
          builder: (context, constraints) {
            final settings = context.dependOnInheritedWidgetOfExactType<
                FlexibleSpaceBarSettings>()!;
            final deltaExtent = settings.maxExtent - settings.minExtent;
            final t = (1.0 -
                    (settings.currentExtent - settings.minExtent) / deltaExtent)
                .clamp(0.0, 1.0);
            final opacity = 1.0 - t;

            return Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.7)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // Padrão de fundo sutil (Opcional)
                Positioned.fill(
                    child: Opacity(
                  opacity: 0.05,
                  child: Image.asset('assets/images/pattern.png',
                      repeat: ImageRepeat.repeat,
                      errorBuilder: (_, __, ___) => const SizedBox()),
                )),
                Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Olá, $customerName',
                            style: textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(planName,
                            style: textTheme.bodyLarge
                                ?.copyWith(color: Colors.white70)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white10),
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
                                      boxShadow: [
                                        BoxShadow(
                                            color: statusColor.withValues(
                                                alpha: 0.5),
                                            blurRadius: 6)
                                      ])),
                              const SizedBox(width: 8),
                              Text(connectionStatus,
                                  style: textTheme.labelMedium
                                      ?.copyWith(color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final double amount;
  final DateTime dueDate;
  final NavigateToPageCallback onNavigate;

  const _BillCard(
      {required this.amount, required this.dueDate, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isOverdue = dueDate.isBefore(DateTime.now());

    return DashboardCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ÍCONE PRIMARY
              Icon(Icons.receipt_long_outlined,
                  color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              Text('Sua Fatura',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                    .format(amount),
                style: textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold, fontSize: 32),
              ),
              const SizedBox(width: 12),
              _BillStatusBadge(isOverdue: isOverdue),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Vencimento: ${DateFormat("d 'de' MMMM", 'pt_BR').format(dueDate)}',
            style:
                textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppButton(
                    onPressed: () => onNavigate('invoices'),
                    label: 'Pagar agora'),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () => onNavigate('invoices'),
                icon: const Text('Ver faturas'),
                label: const Icon(Icons.arrow_forward, size: 16),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillStatusBadge extends StatelessWidget {
  final bool isOverdue;
  const _BillStatusBadge({required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    final Color color = isOverdue ? const Color(0xFFEF5350) : AppColors.success;
    final String text = isOverdue ? 'Vencida' : 'Em dia';
    final IconData icon = isOverdue
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  final double usedGb, totalGb, usagePercent;
  final NavigateToPageCallback onNavigate;

  const _UsageCard(
      {required this.usedGb,
      required this.totalGb,
      required this.usagePercent,
      required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;
    final percentText = (usagePercent * 100).round();
    final Color ringColor = usagePercent < 0.6
        ? primaryColor
        : (usagePercent < 0.9 ? Colors.amberAccent : AppColors.error);

    return InkWell(
      onTap: () => onNavigate('internet_usage'),
      borderRadius: BorderRadius.circular(20),
      child: DashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Consumo',
                style: textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Animação suave do gráfico
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: usagePercent),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) =>
                            CircularProgressIndicator(
                          value: value,
                          strokeWidth: 6,
                          valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                          backgroundColor: Colors.black12,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Center(
                          child: Text('$percentText%',
                              style: textTheme.labelMedium
                                  ?.copyWith(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${usedGb.toStringAsFixed(1)} GB',
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('de ${totalGb.toStringAsFixed(1)} GB',
                          style: textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedCard extends StatelessWidget {
  final double download, upload;
  final NavigateToPageCallback onNavigate;

  const _SpeedCard(
      {required this.download, required this.upload, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => onNavigate('speed_test'),
      borderRadius: BorderRadius.circular(20),
      child: DashboardCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Velocidade Contratada',
                style: textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _SpeedNumber(
                        label: 'Download',
                        value: download,
                        icon: Icons.arrow_downward_rounded)),
                Container(width: 1, height: 30, color: Colors.black12),
                Expanded(
                    child: _SpeedNumber(
                        label: 'Upload',
                        value: upload,
                        icon: Icons.arrow_upward_rounded)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedNumber extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;

  const _SpeedNumber(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ÍCONE PRIMARY
        Icon(icon, color: Theme.of(context).primaryColor, size: 28),
        const SizedBox(height: 4),
        Text('${value.toInt()} Mega',
            style:
                textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label,
            style: textTheme.bodySmall
                ?.copyWith(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final NavigateToPageCallback onNavigate;
  final int crossAxisCount;

  const _QuickActionsGrid({required this.onNavigate, this.crossAxisCount = 3});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
          id: 'invoices', icon: Icons.receipt_long_rounded, label: 'Faturas'),
      _QuickActionData(
          id: 'internet_usage',
          icon: Icons.data_usage_rounded,
          label: 'Consumo'),
      _QuickActionData(
          id: 'support', icon: Icons.support_agent_rounded, label: 'Suporte'),
      _QuickActionData(
          id: 'network_diagnostic',
          icon: Icons.wifi_tethering_rounded,
          label: 'Diagnóstico'),
      _QuickActionData(
          id: 'speed_test', icon: Icons.speed_rounded, label: 'Speedtest'),
      _QuickActionData(
          id: 'trace_route', icon: Icons.alt_route_rounded, label: 'Rota'),
      _QuickActionData(
          id: 'my_ip', icon: Icons.public_rounded, label: 'Meu IP'),
    ];

    return DashboardCard(
      child: GridView.builder(
        shrinkWrap: true,
        itemCount: actions.length,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _QuickActionItem(data: action, onNavigate: onNavigate);
        },
      ),
    );
  }
}

class _QuickActionData {
  final String id;
  final IconData icon;
  final String label;

  _QuickActionData({required this.id, required this.icon, required this.label});
}

class _QuickActionItem extends StatelessWidget {
  final _QuickActionData data;
  final NavigateToPageCallback onNavigate;

  const _QuickActionItem({required this.data, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onNavigate(data.id),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ÍCONE PRIMARY
            Icon(data.icon, color: Theme.of(context).primaryColor, size: 28),
            const SizedBox(height: 8),
            Text(data.label,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall
                    ?.copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final NavigateToPageCallback onNavigate;
  const _SupportCard({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;

    return DashboardCard(
      child: Row(
        children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.error)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Problemas técnicos?',
                    style: textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Faça um diagnóstico automático.',
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
              onPressed: () => onNavigate('network_diagnostic'),
              style: TextButton.styleFrom(foregroundColor: primaryColor),
              child: const Text('Iniciar')),
        ],
      ),
    );
  }
}
