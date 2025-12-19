import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/soft_card.dart';

class DashboardPage extends StatefulWidget {
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
    this.menuItems,
    this.onRefresh,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final remainingDays = widget.billDueDate.difference(DateTime.now()).inDays;
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final secondaryColor = theme.colorScheme.secondary;
    final surfaceColor = theme.cardColor;
    final bgColor = theme.scaffoldBackgroundColor;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final iconColor = theme.iconTheme.color ?? primaryColor;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (widget.onRefresh != null) {
                HapticFeedback.mediumImpact();
                await widget.onRefresh!();
              }
            },
            color: primaryColor,
            backgroundColor: surfaceColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Scaffold.of(context).openDrawer(),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.menu_rounded,
                                    color: textPrimary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Olá! 👋',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  widget.customerName.split(' ').first,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => widget.onNavigate('notifications'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(Icons.notifications_none_rounded,
                                color: textSecondary),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Hero Balance Card
                    GradientHeroCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Próxima Fatura',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: widget.connectionStatus
                                                    .toLowerCase() ==
                                                'ativo'
                                            ? Colors.greenAccent
                                            : Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.connectionStatus,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'R\$ ${widget.billAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 16, color: Colors.white70),
                              const SizedBox(width: 8),
                              Text(
                                remainingDays >= 0
                                    ? 'Vence em $remainingDays dias'
                                    : 'Vencida há ${remainingDays.abs()} dias',
                                style: TextStyle(
                                  color: remainingDays >= 0
                                      ? Colors.white70
                                      : Colors.yellowAccent,
                                  fontSize: 14,
                                  fontWeight: remainingDays < 0
                                      ? FontWeight.bold
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildHeroButton(
                                  'Ver Faturas',
                                  Icons.receipt_long_rounded,
                                  () => widget.onNavigate('invoices'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildHeroButton(
                                  'Suporte',
                                  Icons.headset_mic_rounded,
                                  () => widget.onNavigate('support'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Quick Actions Horizontal Scroll
                    Text(
                      'Acesso Rápido',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildQuickAction(
                            Icons.speed_rounded,
                            'Velocidade',
                            'speed_test',
                            primaryColor,
                            secondaryColor,
                            surfaceColor,
                            iconColor,
                            textSecondary,
                          ),
                          _buildQuickAction(
                            Icons.wifi_rounded,
                            'Wi-Fi',
                            'wifi',
                            primaryColor,
                            secondaryColor,
                            surfaceColor,
                            iconColor,
                            textSecondary,
                          ),
                          _buildQuickAction(
                            Icons.analytics_rounded,
                            'Diagnóstico',
                            'network_diagnostic',
                            primaryColor,
                            secondaryColor,
                            surfaceColor,
                            iconColor,
                            textSecondary,
                          ),
                          _buildQuickAction(
                            Icons.public_rounded,
                            'Meu IP',
                            'my_ip',
                            primaryColor,
                            secondaryColor,
                            surfaceColor,
                            iconColor,
                            textSecondary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Plan Info Card
                    SoftCard(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.router_rounded,
                                color: iconColor, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Seu Plano',
                                  style: TextStyle(
                                      color: textSecondary, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.planName,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: textSecondary),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Services Section
                    Text(
                      'Serviços',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildServiceItem(
                        Icons.route_rounded,
                        'Traceroute',
                        'Rastrear rota de rede',
                        'trace_route',
                        primaryColor,
                        surfaceColor,
                        textPrimary,
                        textSecondary,
                        iconColor),
                    _buildServiceItem(
                        Icons.data_usage_rounded,
                        'Consumo',
                        'Monitorar uso de dados',
                        'internet_usage',
                        primaryColor,
                        surfaceColor,
                        textPrimary,
                        textSecondary,
                        iconColor),
                    _buildServiceItem(
                        Icons.description_rounded,
                        'Contrato',
                        'Ver termos do serviço',
                        'contract',
                        primaryColor,
                        surfaceColor,
                        textPrimary,
                        textSecondary,
                        iconColor),
                    _buildServiceItem(
                        Icons.help_outline_rounded,
                        'FAQ',
                        'Perguntas frequentes',
                        'faq',
                        primaryColor,
                        surfaceColor,
                        textPrimary,
                        textSecondary,
                        iconColor),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Bottom Navigation
        _buildBottomNav(
            primaryColor, secondaryColor, surfaceColor, textSecondary),
      ],
    );
  }

  Widget _buildHeroButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    String label,
    String route,
    Color primaryColor,
    Color secondaryColor,
    Color surfaceColor,
    Color iconColor,
    Color textSecondary,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onNavigate(route);
      },
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.15),
                    secondaryColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(
    IconData icon,
    String title,
    String subtitle,
    String route,
    Color primaryColor,
    Color surfaceColor,
    Color textPrimary,
    Color textSecondary,
    Color iconColor,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onNavigate(route);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(Color primaryColor, Color secondaryColor,
      Color surfaceColor, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
              Icons.home_rounded, 'Início', 0, primaryColor, textSecondary),
          _buildNavItem(
              Icons.wifi_rounded, 'Wi-Fi', 1, primaryColor, textSecondary),
          _buildCenterNavButton(primaryColor, secondaryColor),
          _buildNavItem(Icons.receipt_long_rounded, 'Faturas', 2, primaryColor,
              textSecondary),
          _buildNavItem(
              Icons.menu_rounded, 'Menu', 3, primaryColor, textSecondary),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index,
      Color primaryColor, Color textSecondary) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentNavIndex = index);
        switch (index) {
          case 1:
            widget.onNavigate('wifi');
            break;
          case 2:
            widget.onNavigate('invoices');
            break;
          case 3:
            Scaffold.of(context).openDrawer();
            break;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Icon(
          icon,
          color: isSelected ? primaryColor : textSecondary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildCenterNavButton(Color primaryColor, Color secondaryColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onNavigate('speed_test');
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.speed_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
