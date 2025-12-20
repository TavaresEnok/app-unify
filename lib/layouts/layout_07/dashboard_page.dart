import 'package:flutter/material.dart';

import 'theme.dart';
import 'wave_clipper.dart';

typedef NavigateToPageCallback = void Function(String pageId);

/// Dashboard para Layout 07 - Pôr-do-Sol Tropical
/// Implementação fiel ao mockup com cards lado a lado,
/// grid de serviços colorido e botão com gradiente.
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

  bool get isConnected =>
      connectionStatus.toLowerCase() == 'ativo' ||
      connectionStatus.toLowerCase() == 'conectado';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout07Theme.background,
      body: RefreshIndicator(
        onRefresh: () async {
          if (onRefresh != null) await onRefresh!();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildStatusAndInvoiceRow(context),
                    const SizedBox(height: 24),
                    _buildServicesSection(context),
                    const SizedBox(height: 24),
                    _buildDiagnosticButton(context),
                    const SizedBox(height: 100), // Space for BottomNav
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Cabeçalho com gradiente e onda
  Widget _buildHeader(BuildContext context) {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: Layout07Theme.headerGradient(),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar with menu and notification
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, size: 28),
                      color: Colors.white,
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none, size: 28),
                          color: Colors.white,
                          onPressed: () => onNavigate('notifications'),
                        ),
                        // Red notification badge
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Greeting
                Text(
                  'Olá, $customerName!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),
                // Plan badge (yellow/gold)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F), // Gold/yellow
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    planName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D4037), // Dark brown text
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Cards de status e fatura lado a lado
  Widget _buildStatusAndInvoiceRow(BuildContext context) {
    return Row(
      children: [
        // Status card
        Expanded(child: _buildStatusCard()),
        const SizedBox(width: 12),
        // Invoice card
        Expanded(child: _buildInvoiceCard()),
      ],
    );
  }

  Widget _buildStatusCard() {
    final bool connected = isConnected;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: connected
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              connected ? Icons.check_circle : Icons.error,
              color: connected ? Colors.green : Colors.red,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            connected ? 'Conectado' : 'Desconectado',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Layout07Theme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            connected ? 'Tudo funcionando' : 'Verificar rede',
            style: TextStyle(
              fontSize: 12,
              color: Layout07Theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard() {
    final day = billDueDate.day.toString().padLeft(2, '0');
    final months = [
      '',
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Maio',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez'
    ];
    final monthName = months[billDueDate.month];

    return GestureDetector(
      onTap: () => onNavigate('invoices'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Layout07Theme.textSecondary,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Fatura',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Layout07Theme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'R\$ ${billAmount.toStringAsFixed(2).replaceAll('.', ',')}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Layout07Theme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vencimento: $day $monthName',
              style: TextStyle(
                fontSize: 12,
                color: Layout07Theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Seção de Serviços com grid 2x2
  Widget _buildServicesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Serviços',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Layout07Theme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ServiceButton(
                icon: Icons.wifi,
                label: 'Internet',
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A65), Color(0xFFFF5722)],
                ),
                onTap: () => onNavigate('internet_usage'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ServiceButton(
                icon: Icons.headset_mic,
                label: 'Suporte',
                gradient: const LinearGradient(
                  colors: [Color(0xFF4DD0E1), Color(0xFF00ACC1)],
                ),
                onTap: () => onNavigate('support'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ServiceButton(
                icon: Icons.tv,
                label: 'TV',
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFFFFC107)],
                ),
                onTap: () => onNavigate('contract'), // TV ou outro serviço
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ServiceButton(
                icon: Icons.settings,
                label: 'Config',
                gradient: const LinearGradient(
                  colors: [Color(0xFFB39DDB), Color(0xFF7E57C2)],
                ),
                onTap: () => onNavigate('wifi'), // Configurações Wi-Fi
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Botão de diagnóstico com gradiente coral-laranja
  Widget _buildDiagnosticButton(BuildContext context) {
    return GestureDetector(
      onTap: () => onNavigate('network_diagnostic'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8A65), Color(0xFFFF5722)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5722).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Diagnóstico Rápido',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão de serviço com gradiente
class _ServiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ServiceButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
