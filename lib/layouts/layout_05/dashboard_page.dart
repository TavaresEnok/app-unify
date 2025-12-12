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
    return Scaffold(
      backgroundColor: Layout05Theme.background,
      body: CustomScrollView(
        slivers: [
          // 1. App Bar Moderno
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: Layout05Theme.background,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              title: Text(
                'Olá, ${customerName.split(' ').first}',
                style: Layout05Theme.heading1.copyWith(fontSize: 24),
              ),
              background: Container(color: Layout05Theme.background),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Layout05Theme.textDark),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 10),

                // 2. Main Bill Card (Destaque)
                _buildBillCard(),
                const SizedBox(height: 24),

                // 3. Plan & Status
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.wifi,
                        title: 'Seu Plano',
                        value: planName,
                        color: Layout05Theme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        icon: connectionStatus.toLowerCase() == 'online' ||
                                connectionStatus.toLowerCase() == 'ativo'
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        title: 'Status',
                        value: connectionStatus,
                        color: connectionStatus.toLowerCase() == 'online' ||
                                connectionStatus.toLowerCase() == 'ativo'
                            ? Layout05Theme.success
                            : Layout05Theme.error,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 4. Quick Actions Grid
                Text('Acesso Rápido', style: Layout05Theme.heading2),
                const SizedBox(height: 16),
                _buildQuickActionsGrid(),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard() {
    return Container(
      decoration: Layout05Theme.cardDecoration.copyWith(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF4338CA)], // Indigo gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fatura Atual',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (billDueDate != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Vence ${DateFormat('dd/MM').format(billDueDate!)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'R\$ ${billAmount.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => onNavigate?.call('financeiro'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Layout05Theme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('VISUALIZAR FATURA',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Layout05Theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title,
              style:
                  const TextStyle(color: Layout05Theme.textGrey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Layout05Theme.textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      {
        'icon': Icons.description_outlined,
        'label': '2ª Via',
        'id': 'financeiro',
        'color': Layout05Theme.primary
      },
      {
        'icon': Icons.speed,
        'label': 'Consumo',
        'id': 'consumo',
        'color': Colors.orange
      },
      {
        'icon': Icons.build_circle_outlined,
        'label': 'Suporte',
        'id': 'suporte',
        'color': Layout05Theme.secondary
      },
      {
        'icon': Icons.router_outlined,
        'label': 'Meu IP',
        'id': 'meu_ip',
        'color': Colors.purple
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GestureDetector(
          onTap: () => onNavigate?.call(action['id'] as String),
          child: Column(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: Layout05Theme.softShadow,
                ),
                child: Icon(
                  action['icon'] as IconData,
                  color: action['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                action['label'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Layout05Theme.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
