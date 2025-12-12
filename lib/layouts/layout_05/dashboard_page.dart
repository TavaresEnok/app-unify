import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'theme.dart';

typedef NavigateToPageCallback = void Function(String pageId);

class DashboardPage extends StatelessWidget {
  final String customerName, planName, connectionStatus;
  final double billAmount, usedGb, totalGb, downloadMbps, uploadMbps;
  final DateTime? billDueDate;
  final NavigateToPageCallback? onNavigate;

  const DashboardPage({
    super.key,
    this.customerName = '',
    this.planName = '',
    this.connectionStatus = '',
    this.billAmount = 0.0,
    this.billDueDate,
    this.usedGb = 0.0,
    this.totalGb = 0.0,
    this.downloadMbps = 0.0,
    this.uploadMbps = 0.0,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    // Default date if null
    final date = billDueDate ?? DateTime.now();

    return Scaffold(
      backgroundColor: Layout05Theme.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusCard(
                      connectionStatus: connectionStatus, planName: planName),
                  const SizedBox(height: 20),
                  _buildStatsRow(),
                  const SizedBox(height: 20),
                  _BillCardNeo(
                      amount: billAmount,
                      dueDate: date,
                      onNavigate: onNavigate),
                  const SizedBox(height: 20),
                  const Text(
                    'ACESSO RÁPIDO',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _QuickActionsGrid(onNavigate: onNavigate),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: Layout05Theme.background,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Layout05Theme.primary.withOpacity(0.2),
              child: Text(customerName.isNotEmpty ? customerName[0] : 'U',
                  style: const TextStyle(color: Layout05Theme.primary)),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OLÁ, ${customerName.split(' ')[0].toUpperCase()}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.white),
                ),
                Text(
                  'Bem-vindo de volta',
                  style: TextStyle(
                      fontSize: 10, color: Colors.white.withOpacity(0.6)),
                ),
              ],
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Layout05Theme.surface, Layout05Theme.background],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'DOWNLOAD',
            value: '${downloadMbps.toInt()}',
            unit: 'MB',
            icon: Icons.download_rounded,
            color: Layout05Theme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'UPLOAD',
            value: '${uploadMbps.toInt()}',
            unit: 'MB',
            icon: Icons.upload_rounded,
            color: Layout05Theme.secondary,
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String connectionStatus, planName;

  const _StatusCard({required this.connectionStatus, required this.planName});

  @override
  Widget build(BuildContext context) {
    final isActive = connectionStatus.toLowerCase() == 'ativo';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: Layout05Theme.glassDecoration.copyWith(
        border: Border.all(
            color: isActive
                ? const Color(0xFF00E676).withOpacity(0.3)
                : Layout05Theme.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF00E676).withOpacity(0.1)
                  : Layout05Theme.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi,
              color: isActive ? const Color(0xFF00E676) : Layout05Theme.error,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STATUS DA REDE',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                connectionStatus.toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(planName,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _BillCardNeo extends StatelessWidget {
  final double amount;
  final DateTime dueDate;
  final NavigateToPageCallback? onNavigate;

  const _BillCardNeo(
      {required this.amount, required this.dueDate, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: Layout05Theme.neonBorderDecoration,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PRÓXIMA FATURA',
                      style: TextStyle(
                          color: Layout05Theme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                        .format(amount),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace'),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Layout05Theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_2,
                    color: Layout05Theme.primary, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vence em ${DateFormat('dd/MM').format(dueDate)}',
                style: const TextStyle(color: Colors.white54),
              ),
              ElevatedButton(
                onPressed: () => onNavigate?.call('invoices'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Layout05Theme.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('PAGAR'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Layout05Theme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text(unit,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final NavigateToPageCallback? onNavigate;

  const _QuickActionsGrid({this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {'id': 'invoices', 'icon': Icons.receipt_long, 'label': 'Faturas'},
      {'id': 'support', 'icon': Icons.headset_mic, 'label': 'Suporte'},
      {'id': 'internet_usage', 'icon': Icons.data_usage, 'label': 'Consumo'},
      {'id': 'contract', 'icon': Icons.description, 'label': 'Contrato'},
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          onTap: () => onNavigate?.call(action['id'] as String),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Layout05Theme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action['icon'] as IconData, color: Colors.white70),
                const SizedBox(height: 8),
                Text(
                  action['label'] as String,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
