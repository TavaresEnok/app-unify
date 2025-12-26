import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'widgets/bottom_nav.dart';

/// Layout 02 - NetLink Premium Dashboard
/// Design moderno com gradientes azul/cyan, cards premium e animações fluidas
class ProviderDashboardPage extends StatefulWidget {
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
  final Color? customCardBg;
  final Color? customCardText;
  final Color? invoiceColor;
  final Color? actionColor;
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
    this.menuItems,
    this.customCardBg,
    this.customCardText,
    this.invoiceColor,
    this.actionColor,
    this.onRefresh,
  });

  @override
  State<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends State<ProviderDashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: Layout02Theme.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: RefreshIndicator(
                onRefresh: widget.onRefresh ?? () async {},
                color: Layout02Theme.primary,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildConnectionStatus(),
                        const SizedBox(height: 24),
                        _buildQuickStats(),
                        const SizedBox(height: 28),
                        _buildQuickActions(),
                        const SizedBox(height: 28),
                        _buildCurrentPlan(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Layout02BottomNav(
        currentIndex: 0,
        onTap: (index) {
          // Map index to navigation route
          final routes = ['home', 'financeiro', 'diagnostico', 'suporte'];
          if (index > 0 && index < routes.length) {
            widget.onNavigate(routes[index]);
          }
        },
        items: const [
          BottomNavItem(icon: Icons.home_rounded, label: 'Home', route: 'home'),
          BottomNavItem(
              icon: Icons.receipt_long_rounded,
              label: 'Faturas',
              route: 'financeiro'),
          BottomNavItem(
              icon: Icons.speed_rounded,
              label: 'Velocidade',
              route: 'diagnostico'),
          BottomNavItem(
              icon: Icons.support_agent_rounded,
              label: 'Suporte',
              route: 'suporte'),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Logo with glow
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: Layout02Theme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Layout02Theme.primary.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.wifi_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, ${widget.customerName.split(' ').first}! 👋',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Layout02Theme.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.planName,
                style: TextStyle(
                  fontSize: 13,
                  color: Layout02Theme.textGrey.withOpacity(0.9),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        // Notification bell
        GestureDetector(
          onTap: () => widget.onNavigate('notification'),
          child: Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  color: Layout02Theme.textGrey,
                  size: 22,
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Layout02Theme.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    final isOnline = widget.connectionStatus.toLowerCase() == 'online';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: Layout02Theme.primaryCardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              // Status indicator
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color:
                            isOnline ? Layout02Theme.green : Layout02Theme.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isOnline
                                    ? Layout02Theme.green
                                    : Layout02Theme.red)
                                .withOpacity(0.6),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (isOnline
                                  ? Layout02Theme.green
                                  : Layout02Theme.red)
                              .withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isOnline ? 'Conexão Ativa' : 'Sem Conexão',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (isOnline
                                    ? Layout02Theme.green
                                    : Layout02Theme.red)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: (isOnline
                                      ? Layout02Theme.green
                                      : Layout02Theme.red)
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isOnline
                                  ? Layout02Theme.green
                                  : Layout02Theme.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fibra Óptica • ${widget.planName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Speed indicators
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSpeedIndicator(
                    'Download',
                    widget.downloadMbps.toStringAsFixed(0),
                    'Mbps',
                    Icons.arrow_downward_rounded,
                    Layout02Theme.green,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.white.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildSpeedIndicator(
                    'Upload',
                    widget.uploadMbps.toStringAsFixed(0),
                    'Mbps',
                    Icons.arrow_upward_rounded,
                    Layout02Theme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedIndicator(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Consumo',
            '${widget.usedGb.toStringAsFixed(1)} GB',
            Icons.data_usage_rounded,
            Layout02Theme.purple,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            'Status',
            widget.connectionStatus,
            Icons.verified_rounded,
            widget.connectionStatus.toLowerCase() == 'online'
                ? Layout02Theme.green
                : Layout02Theme.red,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            'Fatura',
            'R\$ ${widget.billAmount.toStringAsFixed(0)}',
            Icons.receipt_long_rounded,
            Layout02Theme.cyan,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (label == 'Fatura') widget.onNavigate('financeiro');
        if (label == 'Consumo') widget.onNavigate('consumo');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Layout02Theme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Layout02Theme.textGrey.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ações Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Layout02Theme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem(
              Icons.speed_rounded,
              'Teste de\nVelocidade',
              [Layout02Theme.primary, Layout02Theme.secondary],
              'diagnostico',
            ),
            _buildActionItem(
              Icons.router_rounded,
              'Configurar\nWi-Fi',
              [Layout02Theme.purple, Layout02Theme.accent],
              'wifi',
            ),
            _buildActionItem(
              Icons.receipt_long_rounded,
              'Segunda\nVia',
              [Layout02Theme.green, Layout02Theme.cyan],
              'financeiro',
            ),
            _buildActionItem(
              Icons.headset_mic_rounded,
              'Falar com\nSuporte',
              [Layout02Theme.orange, const Color(0xFFFF6B35)],
              'suporte',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String label,
    List<Color> gradientColors,
    String route,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onNavigate(route);
      },
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradientColors[0].withOpacity(0.15),
                  gradientColors[1].withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  LinearGradient(colors: gradientColors).createShader(bounds),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Layout02Theme.textGrey.withOpacity(0.9),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlan() {
    // Extract speed from plan name
    String speed = '100';
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(widget.planName);
    if (match != null) {
      speed = match.group(1)!;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: Layout02Theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Seu Plano Atual',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Layout02Theme.textDark,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: Layout02Theme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'FIBRA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Layout02Theme.primary, Layout02Theme.primaryLight],
                ).createShader(bounds),
                child: Text(
                  speed,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Mega',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Layout02Theme.textGrey,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R\$ ${widget.billAmount.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Layout02Theme.textDark,
                    ),
                  ),
                  Text(
                    '/mês',
                    style: TextStyle(
                      fontSize: 13,
                      color: Layout02Theme.textGrey.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Layout02Theme.greyLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPlanFeature(
                  Icons.calendar_today_rounded,
                  'Vence ${widget.billDueDate.day}/${_getMonthName(widget.billDueDate.month)}',
                ),
                Container(
                    width: 1, height: 30, color: Layout02Theme.greyMedium),
                _buildPlanFeature(Icons.all_inclusive_rounded, 'Ilimitado'),
                Container(
                    width: 1, height: 30, color: Layout02Theme.greyMedium),
                _buildPlanFeature(Icons.wifi_rounded, 'Wi-Fi 6'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez'
    ];
    return months[month - 1];
  }

  Widget _buildPlanFeature(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Layout02Theme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Layout02Theme.textGrey,
          ),
        ),
      ],
    );
  }
}
