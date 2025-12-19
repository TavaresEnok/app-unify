import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'widgets/gradient_card.dart';

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
                    // Hero Header with Gradient
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            primaryColor.withValues(alpha: 0.6),
                            primaryColor.withValues(alpha: 0.2),
                            bgColor,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Top Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        Scaffold.of(context).openDrawer(),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            surfaceColor.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.menu_rounded,
                                          color: Colors.white),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        'Olá! 👋',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14),
                                      ),
                                      Text(
                                        widget.customerName.split(' ').first,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        widget.onNavigate('notifications'),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            surfaceColor.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                          Icons.notifications_none_rounded,
                                          color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // Balance Display
                              Text(
                                'Próxima Fatura',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'R\$ ${widget.billAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
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
                                    const SizedBox(width: 8),
                                    Text(
                                      '${widget.connectionStatus} • ${remainingDays >= 0 ? 'Vence em $remainingDays dias' : 'Vencida'}',
                                      style: TextStyle(
                                        color: remainingDays >= 0
                                            ? Colors.white
                                            : Colors.yellowAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Quick Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildQuickHeroButton(
                                      'Ver Faturas',
                                      Icons.receipt_long_rounded,
                                      () => widget.onNavigate('invoices'),
                                      primaryColor),
                                  const SizedBox(width: 16),
                                  _buildQuickHeroButton(
                                      'Suporte',
                                      Icons.headset_mic_rounded,
                                      () => widget.onNavigate('support'),
                                      secondaryColor),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Content Below Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Actions Grid
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionCard(
                                  Icons.speed_rounded,
                                  'Velocidade',
                                  'Teste agora',
                                  'speed_test',
                                  primaryColor,
                                  surfaceColor,
                                  iconColor,
                                  textSecondary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildQuickActionCard(
                                  Icons.wifi_rounded,
                                  'Wi-Fi',
                                  'Configurar',
                                  'wifi',
                                  secondaryColor,
                                  surfaceColor,
                                  iconColor,
                                  textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionCard(
                                  Icons.router_rounded,
                                  widget.planName,
                                  'Seu plano',
                                  'plan',
                                  Layout10Theme.defaultAccent,
                                  surfaceColor,
                                  iconColor,
                                  textSecondary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildQuickActionCard(
                                  Icons.public_rounded,
                                  'Meu IP',
                                  'Ver detalhes',
                                  'my_ip',
                                  Layout10Theme.success,
                                  surfaceColor,
                                  iconColor,
                                  textSecondary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // Services Section
                          const Text(
                            'Serviços',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildServiceItem(
                              Icons.analytics_rounded,
                              'Diagnóstico Completo',
                              'Análise detalhada da rede',
                              'network_diagnostic',
                              primaryColor,
                              surfaceColor,
                              textSecondary,
                              iconColor),
                          _buildServiceItem(
                              Icons.route_rounded,
                              'Traceroute',
                              'Rastrear rota de rede',
                              'trace_route',
                              secondaryColor,
                              surfaceColor,
                              textSecondary,
                              iconColor),
                          _buildServiceItem(
                              Icons.data_usage_rounded,
                              'Consumo',
                              'Monitorar uso de dados',
                              'internet_usage',
                              Layout10Theme.defaultAccent,
                              surfaceColor,
                              textSecondary,
                              iconColor),
                          _buildServiceItem(
                              Icons.description_rounded,
                              'Contrato',
                              'Ver termos do serviço',
                              'contract',
                              Layout10Theme.success,
                              surfaceColor,
                              textSecondary,
                              iconColor),
                          _buildServiceItem(
                              Icons.help_outline_rounded,
                              'FAQ',
                              'Perguntas frequentes',
                              'faq',
                              Colors.orange,
                              surfaceColor,
                              textSecondary,
                              iconColor),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
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

  Widget _buildQuickHeroButton(
      String label, IconData icon, VoidCallback onTap, Color bgColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
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

  Widget _buildQuickActionCard(
    IconData icon,
    String title,
    String subtitle,
    String route,
    Color accentColor,
    Color surfaceColor,
    Color iconColor,
    Color textSecondary,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onNavigate(route);
      },
      child: GradientCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: textSecondary, fontSize: 12),
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
    Color accentColor,
    Color surfaceColor,
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: textSecondary, fontSize: 13),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_rounded, 0, primaryColor, textSecondary),
          _buildNavItem(Icons.wifi_rounded, 1, primaryColor, textSecondary),
          _buildCenterNavButton(primaryColor, secondaryColor),
          _buildNavItem(
              Icons.receipt_long_rounded, 2, primaryColor, textSecondary),
          _buildNavItem(Icons.menu_rounded, 3, primaryColor, textSecondary),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, int index, Color primaryColor, Color textSecondary) {
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
        padding: const EdgeInsets.all(12),
        decoration: isSelected
            ? BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ],
              )
            : null,
        child: Icon(
          icon,
          color: isSelected ? primaryColor : textSecondary,
          size: 26,
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
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.speed_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
