import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/glass_card.dart';

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

  final Future<void> Function()? onRefresh;

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
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    final borderColor = theme.dividerColor;

    // Create dynamic gradient
    final dynamicGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryColor, secondaryColor],
    );

    return Column(
      children: [
        // Main Scrollable Content
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
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Menu Button
                            GestureDetector(
                              onTap: () => Scaffold.of(context).openDrawer(),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.menu_rounded,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  primaryColor.withValues(alpha: 0.2),
                              child: Text(
                                widget.customerName.isNotEmpty
                                    ? widget.customerName[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Olá, ${widget.customerName.split(' ').first}',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  widget.planName,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => widget.onNavigate('notifications'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.notifications_none_rounded,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Balance Card (Main Feature) - Navigates to Invoices
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onNavigate('invoices');
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: dynamicGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Próxima Fatura',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.connectionStatus,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'R\$ ${widget.billAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 14, color: Colors.black54),
                                const SizedBox(width: 6),
                                Text(
                                  remainingDays >= 0
                                      ? 'Vence em $remainingDays dias'
                                      : 'Vencida há ${remainingDays.abs()} dias',
                                  style: TextStyle(
                                    color: remainingDays >= 0
                                        ? Colors.black54
                                        : Colors.red[900],
                                    fontSize: 14,
                                    fontWeight: remainingDays < 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions (Corrected route names)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickAction(
                            Icons.receipt_long_rounded, 'Faturas', 'invoices',
                            primaryColor: primaryColor,
                            surfaceColor: surfaceColor,
                            textSecondary: textSecondary,
                            borderColor: borderColor),
                        _buildQuickAction(
                            Icons.speed_rounded, 'Velocidade', 'speed_test',
                            primaryColor: primaryColor,
                            surfaceColor: surfaceColor,
                            textSecondary: textSecondary,
                            borderColor: borderColor),
                        _buildQuickAction(
                            Icons.support_agent_rounded, 'Suporte', 'support',
                            primaryColor: primaryColor,
                            surfaceColor: surfaceColor,
                            textSecondary: textSecondary,
                            borderColor: borderColor),
                        _buildQuickAction(Icons.network_check_rounded,
                            'Diagnóstico', 'network_diagnostic',
                            primaryColor: primaryColor,
                            surfaceColor: surfaceColor,
                            textSecondary: textSecondary,
                            borderColor: borderColor),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Plan Card
                    GlassCard(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.router_rounded,
                              color: Theme.of(context).iconTheme.color ??
                                  primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Seu Plano',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: widget.connectionStatus.toLowerCase() ==
                                      'ativo'
                                  ? const Color(0xFF30D158)
                                      .withValues(alpha: 0.1)
                                  : const Color(0xFFFF453A)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        widget.connectionStatus.toLowerCase() ==
                                                'ativo'
                                            ? const Color(0xFF30D158)
                                            : const Color(0xFFFF453A),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.connectionStatus,
                                  style: TextStyle(
                                    color:
                                        widget.connectionStatus.toLowerCase() ==
                                                'ativo'
                                            ? const Color(0xFF30D158)
                                            : const Color(0xFFFF453A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Menu Section Title
                    Text(
                      'Serviços',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Services List
                    _buildServiceItem(
                      Icons.analytics_rounded,
                      'Diagnóstico Completo',
                      'Verificar conexão e problemas',
                      'network_diagnostic',
                      primaryColor: primaryColor,
                      surfaceColor: surfaceColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                    ),
                    _buildServiceItem(
                      Icons.route_rounded,
                      'Traceroute',
                      'Rastrear rota de rede',
                      'trace_route',
                      primaryColor: primaryColor,
                      surfaceColor: surfaceColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                    ),
                    _buildServiceItem(
                      Icons.data_usage_rounded,
                      'Consumo',
                      'Monitorar uso de dados',
                      'internet_usage',
                      primaryColor: primaryColor,
                      surfaceColor: surfaceColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                    ),
                    _buildServiceItem(
                      Icons.public_rounded,
                      'Meu IP',
                      'Ver endereço IP atual',
                      'my_ip',
                      primaryColor: primaryColor,
                      surfaceColor: surfaceColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                    ),
                    _buildServiceItem(
                      Icons.description_rounded,
                      'Contrato',
                      'Ver termos do serviço',
                      'contract',
                      primaryColor: primaryColor,
                      surfaceColor: surfaceColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                    ),
                    _buildServiceItem(
                      Icons.help_outline_rounded,
                      'FAQ',
                      'Perguntas frequentes',
                      'faq',
                      primaryColor: primaryColor,
                      surfaceColor: surfaceColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Fixed Dark Bottom Navigation Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(
              top: BorderSide(color: borderColor.withValues(alpha: 0.3)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 'Início', 0,
                    primaryColor: primaryColor, textSecondary: textSecondary),
                _buildNavItem(Icons.wifi_rounded, 'Wi-Fi', 1,
                    primaryColor: primaryColor, textSecondary: textSecondary),
                _buildNavItem(Icons.receipt_long_rounded, 'Faturas', 2,
                    primaryColor: primaryColor, textSecondary: textSecondary),
                _buildNavItem(Icons.headset_mic_rounded, 'Suporte', 3,
                    primaryColor: primaryColor, textSecondary: textSecondary),
                _buildNavItem(Icons.menu_rounded, 'Menu', 4,
                    primaryColor: primaryColor, textSecondary: textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, String route,
      {required Color primaryColor,
      required Color surfaceColor,
      required Color textSecondary,
      required Color borderColor}) {
    // [NEW] Use dynamic icon color
    final iconColor = Theme.of(context).iconTheme.color ?? primaryColor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onNavigate(route);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(
      IconData icon, String title, String subtitle, String route,
      {required Color primaryColor,
      required Color surfaceColor,
      required Color textPrimary,
      required Color textSecondary,
      required Color borderColor}) {
    final iconColor = Theme.of(context).iconTheme.color ?? primaryColor;

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
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: borderColor.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
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
                      fontWeight: FontWeight.w500,
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
            Icon(
              Icons.chevron_right_rounded,
              color: textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index,
      {required Color primaryColor, required Color textSecondary}) {
    final isSelected = _currentNavIndex == index;
    final iconColor = Theme.of(context).iconTheme.color ?? primaryColor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentNavIndex = index);
        switch (index) {
          case 0: // Home - already here
            break;
          case 1:
            widget.onNavigate('wifi');
            break;
          case 2:
            widget.onNavigate('invoices');
            break;
          case 3:
            widget.onNavigate('support');
            break;
          case 4:
            Scaffold.of(context).openDrawer();
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color:
                isSelected ? primaryColor : (iconColor.withValues(alpha: 0.7)),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? primaryColor : textSecondary,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          // Selection Indicator
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isSelected ? 20 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
