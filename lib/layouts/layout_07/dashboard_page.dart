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
