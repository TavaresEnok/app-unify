import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/app_colors.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/app_button.dart';

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
    final isConnectionOk = connectionStatus.toLowerCase() == 'ativo';
    final statusColor = isConnectionOk ? AppColors.success : AppColors.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // --- HEADER ---
          SliverAppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            pinned: true,
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Olá, $customerName",
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "$planName • $connectionStatus",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () {}, // Notificações
                          icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- CONTEÚDO ---
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // CARTÃO DE FATURA (Prioridade para o cliente)
                _BillCard(
                  amount: billAmount,
                  dueDate: billDueDate,
                  onNavigate: onNavigate,
                ),
                const SizedBox(height: 20),

                // CONSUMO DE INTERNET
                _UsageCard(
                  usedGb: usedGb,
                  totalGb: totalGb,
                  onNavigate: onNavigate,
                ),
                const SizedBox(height: 20),

                // AÇÕES RÁPIDAS
                Text("Acesso Rápido", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _QuickActionsGrid(onNavigate: onNavigate),
                
                const SizedBox(height: 20),
                // TESTE DE VELOCIDADE (Resumo)
                _SpeedCardSummary(
                  download: downloadMbps,
                  upload: uploadMbps,
                  onNavigate: onNavigate,
                ),
                
                const SizedBox(height: 80), // Espaço final
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final double amount;
  final DateTime dueDate;
  final NavigateToPageCallback onNavigate;

  const _BillCard({required this.amount, required this.dueDate, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isOverdue = dueDate.isBefore(DateTime.now());
    final statusText = isOverdue ? "Vencida" : "Em Aberto";
    final statusColor = isOverdue ? AppColors.error : AppColors.success;

    return DashboardCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Sua Fatura",
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(
            NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(amount),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1.0,
            ),
          ),
          Text(
            "Vence dia ${DateFormat("d 'de' MMMM", 'pt_BR').format(dueDate)}",
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              onPressed: () => onNavigate('invoices'),
              label: 'PAGAR AGORA',
              icon: Icons.qr_code,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  final double usedGb;
  final double totalGb;
  final NavigateToPageCallback onNavigate;

  const _UsageCard({required this.usedGb, required this.totalGb, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final percent = (totalGb == 0) ? 0.0 : (usedGb / totalGb).clamp(0.0, 1.0);

    return InkWell(
      onTap: () => onNavigate('internet_usage'),
      child: DashboardCard(
        child: Row(
          children: [
            SizedBox(
              height: 60,
              width: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: percent,
                    backgroundColor: AppColors.divider,
                    color: AppColors.primary,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                  ),
                  const Center(
                    child: Icon(Icons.data_usage, color: AppColors.primary),
                  )
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Consumo Internet",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: AppColors.textPrimary),
                      children: [
                        TextSpan(text: "${usedGb.toStringAsFixed(1)} GB", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        TextSpan(text: " de ${totalGb.toStringAsFixed(0)} GB", style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final NavigateToPageCallback onNavigate;
  const _QuickActionsGrid({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickActionItem(
          icon: Icons.support_agent_rounded,
          label: "Suporte",
          color: Colors.blue,
          onTap: () => onNavigate('support'),
        ),
        _QuickActionItem(
          icon: Icons.wifi_tethering,
          label: "Diagnóstico",
          color: Colors.purple,
          onTap: () => onNavigate('network_diagnostic'),
        ),
        _QuickActionItem(
          icon: Icons.speed_rounded,
          label: "Velocidade",
          color: Colors.orange,
          onTap: () => onNavigate('speed_test'),
        ),
        _QuickActionItem(
          icon: Icons.description_outlined,
          label: "Contrato",
          color: Colors.teal,
          onTap: () => onNavigate('contract'),
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedCardSummary extends StatelessWidget {
  final double download, upload;
  final NavigateToPageCallback onNavigate;

  const _SpeedCardSummary({required this.download, required this.upload, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onNavigate('speed_test'),
      child: DashboardCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SpeedItem(label: "Download", value: download, icon: Icons.arrow_downward, color: AppColors.success),
            Container(width: 1, height: 30, color: AppColors.border),
            _SpeedItem(label: "Upload", value: upload, icon: Icons.arrow_upward, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _SpeedItem extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const _SpeedItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            Text("${value.toInt()} Mbps", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        )
      ],
    );
  }
}
