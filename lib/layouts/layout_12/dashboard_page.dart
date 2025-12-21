import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

class Layout12DashboardPage extends StatefulWidget {
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
  final Future<void> Function()? onRefresh;

  const Layout12DashboardPage({
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
    this.onRefresh,
  });

  @override
  State<Layout12DashboardPage> createState() => _Layout12DashboardPageState();
}

class _Layout12DashboardPageState extends State<Layout12DashboardPage> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final remainingDays = widget.billDueDate.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: Layout12Palette.bg,
      body: Stack(
        children: [
          // Aurora background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x3300C3FF),
                    Color(0x220F1727),
                    Color(0x3300FFC3),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: widget.onRefresh ?? () async {},
              color: Layout12Palette.primary,
              backgroundColor: Layout12Palette.surface,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildBillCard(remainingDays),
                    const SizedBox(height: 20),
                    _buildMetrics(),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildPlanCard(),
                    const SizedBox(height: 24),
                    Text(
                      'Diagnóstico & Serviços',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Layout12Palette.textSecondary,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildServiceItem(
                      icon: Icons.analytics_rounded,
                      title: 'Diagnóstico de Rede',
                      subtitle: 'Verificar status da conexão',
                      route: 'network_diagnostic',
                    ),
                    _buildServiceItem(
                      icon: Icons.route_rounded,
                      title: 'Traceroute',
                      subtitle: 'Rastrear rota de pacotes',
                      route: 'trace_route',
                      color: Layout12Palette.secondary,
                    ),
                    _buildServiceItem(
                      icon: Icons.data_usage_rounded,
                      title: 'Consumo',
                      subtitle: 'Histórico de uso de dados',
                      route: 'internet_usage',
                    ),
                    _buildServiceItem(
                      icon: Icons.public_rounded,
                      title: 'Meu IP',
                      subtitle: 'Visualizar endereço IP',
                      route: 'my_ip',
                      color: Layout12Palette.secondary,
                    ),
                    _buildServiceItem(
                      icon: Icons.description_rounded,
                      title: 'Contrato',
                      subtitle: 'Termos de serviço',
                      route: 'contract',
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Layout12Palette.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Layout12Palette.primary.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Layout12Palette.primary.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child:
                    Icon(Icons.menu_rounded, color: Layout12Palette.textPrimary),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bem-vindo,',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Layout12Palette.textSecondary,
                        letterSpacing: 0.8,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.customerName.split(' ').first,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Layout12Palette.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Layout12Palette.primary, Layout12Palette.secondary],
            ),
            shape: BoxShape.circle,
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Layout12Palette.bg,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded,
                color: Layout12Palette.textPrimary, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildBillCard(int remainingDays) {
    final statusColor =
        remainingDays < 0 ? Layout12Palette.error : Layout12Palette.success.withValues(alpha: 0.9);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Layout12Palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Layout12Palette.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Layout12Palette.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fatura Atual',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Layout12Palette.textSecondary,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: statusColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      widget.connectionStatus.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'R\$ ${widget.billAmount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Layout12Palette.textPrimary,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: Layout12Palette.secondary.withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ],
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 14, color: Layout12Palette.textSecondary),
              const SizedBox(width: 8),
              Text(
                remainingDays >= 0
                    ? 'Vence em $remainingDays dias'
                    : 'Vencida há ${remainingDays.abs()} dias',
                style: TextStyle(
                  color: remainingDays < 0 ? Layout12Palette.error : Layout12Palette.textSecondary,
                  fontWeight: remainingDays < 0 ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _metricCard(
          title: 'Download',
          value: '${widget.downloadMbps.toStringAsFixed(0)} Mbps',
          icon: Icons.download_rounded,
          color: Layout12Palette.primary,
          detail: '+12% vs mês anterior',
        ),
        _metricCard(
          title: 'Upload',
          value: '${widget.uploadMbps.toStringAsFixed(0)} Mbps',
          icon: Icons.upload_rounded,
          color: Layout12Palette.secondary,
          detail: '+8% vs mês anterior',
        ),
        _metricCard(
          title: 'Uso de Dados',
          value: '${widget.usedGb.toStringAsFixed(1)} GB',
          icon: Icons.data_thresholding_rounded,
          color: Layout12Palette.accent,
          detail: 'de ${widget.totalGb.toStringAsFixed(1)} GB',
        ),
        _metricCard(
          title: 'Próxima Fatura',
          value: 'R\$ ${widget.billAmount.toStringAsFixed(2)}',
          icon: Icons.receipt_long_rounded,
          color: Layout12Palette.success,
          detail: 'Vence em ${widget.billDueDate.day}/${widget.billDueDate.month}',
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String detail,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Layout12Palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.16),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Icon(Icons.trending_up_rounded, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: Layout12Palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: Layout12Palette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            detail,
            style: TextStyle(color: Layout12Palette.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final items = [
      (Icons.receipt_long_rounded, 'Faturas', 'invoices', Layout12Palette.primary),
      (Icons.speed_rounded, 'Velocidade', 'speed_test', Layout12Palette.secondary),
      (Icons.support_agent_rounded, 'Suporte', 'support', Layout12Palette.accent),
      (Icons.wifi_rounded, 'Wi-Fi', 'wifi', Layout12Palette.primary),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final (icon, label, route, color) = items[index];
        return _quickActionCard(icon, label, route, color);
      },
    );
  }

  Widget _quickActionCard(IconData icon, String label, String route, Color color) {
    return GestureDetector(
      onTap: () => widget.onNavigate(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Layout12Palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                color: Layout12Palette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Acessar',
              style: TextStyle(color: Layout12Palette.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard() {
    final used = widget.usedGb;
    final total = widget.totalGb;
    final percent = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Layout12Palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Layout12Palette.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Layout12Palette.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
                    'Plano',
                    style: TextStyle(
                      color: Layout12Palette.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.planName,
                    style: TextStyle(
                      color: Layout12Palette.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Layout12Palette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Layout12Palette.primary.withValues(alpha: 0.45)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.speed_rounded,
                        size: 16, color: Layout12Palette.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.downloadMbps.toStringAsFixed(0)} / ${widget.uploadMbps.toStringAsFixed(0)} Mbps',
                      style: TextStyle(
                        color: Layout12Palette.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: percent,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Layout12Palette.primary, Layout12Palette.secondary],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Layout12Palette.primary.withValues(alpha: 0.25),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${used.toStringAsFixed(1)} GB usados',
                style:
                    TextStyle(color: Layout12Palette.textPrimary, fontSize: 13),
              ),
              Text(
                '${(percent * 100).toStringAsFixed(0)}% do pacote',
                style:
                    TextStyle(color: Layout12Palette.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    Color? color,
  }) {
    final c = color ?? Layout12Palette.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => widget.onNavigate(route),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Layout12Palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: c, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Layout12Palette.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Layout12Palette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Layout12Palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Layout12Palette.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Layout12Palette.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.dashboard_rounded, 0, 'Início'),
          _navItem(Icons.receipt_long_rounded, 1, 'Faturas'),
          _navItem(Icons.speed_rounded, 2, 'Teste'),
          _navItem(Icons.person_rounded, 3, 'Perfil'),
        ],
      ),
    );
  }

  Widget _navItem(
      IconData icon, int index, String label) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentNavIndex = index);
        switch (index) {
          case 0:
            break;
          case 1:
            widget.onNavigate('invoices');
            break;
          case 2:
            widget.onNavigate('speed_test');
            break;
          case 3:
            widget.onNavigate('profile');
            break;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Layout12Palette.primary.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Layout12Palette.primary.withValues(alpha: 0.45))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected
                    ? Layout12Palette.primary
                    : Layout12Palette.textSecondary,
                size: isSelected ? 24 : 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Layout12Palette.primary
                    : Layout12Palette.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
