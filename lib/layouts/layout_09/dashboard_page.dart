import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'widgets/bento_card.dart';

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
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final iconColor = theme.iconTheme.color ?? primaryColor;

    return Stack(
      children: [
        // Gradient Background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Layout09Theme.pastelPink.withValues(alpha: 0.4),
                Layout09Theme.pastelBlue.withValues(alpha: 0.3),
                Layout09Theme.pastelGreen.withValues(alpha: 0.2),
              ],
            ),
          ),
        ),

        // Content
        Column(
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
                                  onTap: () =>
                                      Scaffold.of(context).openDrawer(),
                                  child: CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        primaryColor.withValues(alpha: 0.1),
                                    child: Text(
                                      widget.customerName.isNotEmpty
                                          ? widget.customerName[0].toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
                            _buildGlassIconButton(
                              Icons.notifications_none_rounded,
                              () => widget.onNavigate('notifications'),
                              textSecondary,
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Bento Grid
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Large Balance Card
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [primaryColor, secondaryColor],
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          primaryColor.withValues(alpha: 0.3),
                                      blurRadius: 24,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
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
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'R\$ ${widget.billAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          remainingDays >= 0
                                              ? 'Vence em $remainingDays dias'
                                              : 'Vencida há ${remainingDays.abs()} dias',
                                          style: TextStyle(
                                            color: remainingDays >= 0
                                                ? Colors.white70
                                                : Colors.yellowAccent,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Two stacked cards
                            Expanded(
                              child: Column(
                                children: [
                                  // Plan Card
                                  BentoCard(
                                    height: 92,
                                    backgroundColor: Layout09Theme.pastelPurple,
                                    onTap: () => widget.onNavigate('plan'),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.router_rounded,
                                            color: primaryColor, size: 24),
                                        const SizedBox(height: 8),
                                        Text(
                                          widget.planName,
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Speed Card
                                  BentoCard(
                                    height: 92,
                                    backgroundColor: Layout09Theme.pastelCyan,
                                    onTap: () =>
                                        widget.onNavigate('speed_test'),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.speed_rounded,
                                            color: secondaryColor, size: 24),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Velocidade',
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Quick Actions Row
                        Row(
                          children: [
                            _buildQuickAction(
                                Icons.receipt_long_rounded,
                                'Faturas',
                                'invoices',
                                Layout09Theme.pastelPink,
                                primaryColor,
                                iconColor,
                                textSecondary),
                            const SizedBox(width: 12),
                            _buildQuickAction(
                                Icons.wifi_rounded,
                                'Wi-Fi',
                                'wifi',
                                Layout09Theme.pastelBlue,
                                secondaryColor,
                                iconColor,
                                textSecondary),
                            const SizedBox(width: 12),
                            _buildQuickAction(
                                Icons.headset_mic_rounded,
                                'Suporte',
                                'support',
                                Layout09Theme.pastelGreen,
                                Layout09Theme.success,
                                iconColor,
                                textSecondary),
                            const SizedBox(width: 12),
                            _buildQuickAction(
                                Icons.public_rounded,
                                'Meu IP',
                                'my_ip',
                                Layout09Theme.pastelYellow,
                                Colors.orange,
                                iconColor,
                                textSecondary),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Services Section
                        Text(
                          'Serviços',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildServiceCard(
                            Icons.analytics_rounded,
                            'Diagnóstico',
                            'Análise completa da rede',
                            'network_diagnostic',
                            primaryColor,
                            textPrimary,
                            textSecondary,
                            iconColor),
                        _buildServiceCard(
                            Icons.route_rounded,
                            'Traceroute',
                            'Rastrear rota de rede',
                            'trace_route',
                            secondaryColor,
                            textPrimary,
                            textSecondary,
                            iconColor),
                        _buildServiceCard(
                            Icons.data_usage_rounded,
                            'Consumo',
                            'Monitorar uso de dados',
                            'internet_usage',
                            Colors.orange,
                            textPrimary,
                            textSecondary,
                            iconColor),
                        _buildServiceCard(
                            Icons.description_rounded,
                            'Contrato',
                            'Ver termos do serviço',
                            'contract',
                            Layout09Theme.success,
                            textPrimary,
                            textSecondary,
                            iconColor),
                        _buildServiceCard(
                            Icons.help_outline_rounded,
                            'FAQ',
                            'Perguntas frequentes',
                            'faq',
                            Colors.pink,
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
            _buildBottomNav(primaryColor, secondaryColor, textSecondary),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassIconButton(
      IconData icon, VoidCallback onTap, Color iconColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(icon, color: iconColor),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    String label,
    String route,
    Color bgColor,
    Color accentColor,
    Color iconColor,
    Color textSecondary,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onNavigate(route);
        },
        child: BentoCard(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          backgroundColor: bgColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    IconData icon,
    String title,
    String subtitle,
    String route,
    Color accentColor,
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
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
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(
      Color primaryColor, Color secondaryColor, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                    Icons.home_rounded, 0, primaryColor, textSecondary),
                _buildNavItem(
                    Icons.wifi_rounded, 1, primaryColor, textSecondary),
                _buildCenterFAB(primaryColor, secondaryColor),
                _buildNavItem(
                    Icons.receipt_long_rounded, 2, primaryColor, textSecondary),
                _buildNavItem(
                    Icons.menu_rounded, 3, primaryColor, textSecondary),
              ],
            ),
          ),
        ),
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
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
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

  Widget _buildCenterFAB(Color primaryColor, Color secondaryColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onNavigate('speed_test');
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.speed_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}
