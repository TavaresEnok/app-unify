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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
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
        // Menu button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _scaffoldKey.currentState?.openDrawer();
          },
          child: Container(
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
            child:
                const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
          ),
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
          // Plan info indicators - Premium style
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildPlanIndicator(
                    'Plano',
                    _extractSpeed(widget.planName),
                    'Mega',
                    Icons.rocket_launch_rounded,
                    Layout02Theme.secondary,
                  ),
                ),
                Container(
                  width: 1,
                  height: 45,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildPlanIndicator(
                    'Mensalidade',
                    'R\$ ${widget.billAmount.toStringAsFixed(0)}',
                    '/mês',
                    Icons.payments_rounded,
                    Layout02Theme.green,
                  ),
                ),
                Container(
                  width: 1,
                  height: 45,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildPlanIndicator(
                    'Vence dia',
                    '${widget.billDueDate.day}',
                    _getMonthName(widget.billDueDate.month),
                    Icons.event_rounded,
                    Layout02Theme.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _extractSpeed(String planName) {
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(planName);
    return match?.group(1) ?? '100';
  }

  Widget _buildPlanIndicator(
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
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: 11,
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
          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6)),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    // Calculate days until due date
    final now = DateTime.now();
    final daysUntilDue = widget.billDueDate.difference(now).inDays;
    final daysText = daysUntilDue < 0
        ? 'Vencida'
        : daysUntilDue == 0
            ? 'Vence Hoje'
            : 'Vence em $daysUntilDue dias';
    final daysColor = daysUntilDue < 0
        ? Layout02Theme.red
        : daysUntilDue <= 3
            ? Layout02Theme.orange
            : Layout02Theme.green;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Faturas',
            daysText,
            Icons.receipt_long_rounded,
            daysColor,
            onTap: () => widget.onNavigate('financeiro'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            'Suporte',
            '24h Online',
            Icons.headset_mic_rounded,
            Layout02Theme.purple,
            onTap: () => widget.onNavigate('suporte'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            'Consumo',
            widget.usedGb > 0
                ? '${widget.usedGb.toStringAsFixed(0)} GB'
                : 'Ilimitado',
            Icons.data_usage_rounded,
            Layout02Theme.cyan,
            onTap: () => widget.onNavigate('consumo'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
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
        // Primeira linha - 4 ações
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
              Icons.network_check_rounded,
              'Diagnóstico',
              [Layout02Theme.green, Layout02Theme.cyan],
              'diagnostico',
            ),
            _buildActionItem(
              Icons.route_rounded,
              'Rota\n(Tracert)',
              [Layout02Theme.purple, Layout02Theme.accent],
              'traceroute',
            ),
            _buildActionItem(
              Icons.description_rounded,
              'Contrato',
              [Layout02Theme.orange, const Color(0xFFFF6B35)],
              'contrato',
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Segunda linha - 3 ações centralizadas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 8),
            _buildActionItem(
              Icons.language_rounded,
              'Meu IP',
              [Layout02Theme.cyan, Layout02Theme.primary],
              'meu_ip',
            ),
            _buildActionItem(
              Icons.quiz_rounded,
              'FAQ',
              [const Color(0xFFFF6B9D), Layout02Theme.purple],
              'faq',
            ),
            _buildActionItem(
              Icons.wifi_rounded,
              'Configurar\nWi-Fi',
              [Layout02Theme.secondary, Layout02Theme.green],
              'wifi',
            ),
            const SizedBox(width: 8),
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
    return _buildPromotionCarousel();
  }

  Widget _buildPromotionCarousel() {
    final promotions = [
      {
        'title': 'Combo TV + Internet',
        'description': 'Streaming e Internet por apenas R\$199',
        'icon': Icons.tv_rounded,
        'colors': [const Color(0xFFE040FB), const Color(0xFF7C4DFF)],
      },
      {
        'title': 'Upgrade de Velocidade',
        'description': 'Migre para o plano Giga com desconto',
        'icon': Icons.speed_rounded,
        'colors': [const Color(0xFF00BCD4), const Color(0xFF2196F3)],
      },
      {
        'title': 'Indique um Amigo',
        'description': 'Ganhe 1 mês grátis por indicação',
        'icon': Icons.people_rounded,
        'colors': [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ofertas Especiais',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Layout02Theme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: PageView.builder(
            itemCount: promotions.length,
            controller: PageController(viewportFraction: 0.92),
            itemBuilder: (context, index) {
              final promo = promotions[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: promo['colors'] as List<Color>,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (promo['colors'] as List<Color>)[0]
                            .withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Background pattern
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Icon(
                          promo['icon'] as IconData,
                          size: 120,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'OFERTA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              promo['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              promo['description'] as String,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Arrow indicator
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: (promo['colors'] as List<Color>)[0],
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Layout02Theme.primary,
              Layout02Theme.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header do Drawer
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2), width: 2),
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.customerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.planName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    _buildDrawerItem(Icons.home_rounded, 'Início', 'home'),
                    _buildDrawerItem(
                        Icons.receipt_long_rounded, 'Faturas', 'financeiro'),
                    const Divider(
                        color: Colors.white24,
                        indent: 24,
                        endIndent: 24,
                        height: 16),
                    _buildDrawerItem(Icons.speed_rounded, 'Teste de Velocidade',
                        'diagnostico'),
                    _buildDrawerItem(Icons.network_check_rounded,
                        'Diagnóstico de Rede', 'diagnostico'),
                    _buildDrawerItem(
                        Icons.route_rounded, 'Rota (Tracert)', 'traceroute'),
                    _buildDrawerItem(
                        Icons.language_rounded, 'Meu IP', 'meu_ip'),
                    _buildDrawerItem(
                        Icons.wifi_rounded, 'Configurar Wi-Fi', 'wifi'),
                    const Divider(
                        color: Colors.white24,
                        indent: 24,
                        endIndent: 24,
                        height: 16),
                    _buildDrawerItem(
                        Icons.description_rounded, 'Contrato', 'contrato'),
                    _buildDrawerItem(Icons.quiz_rounded, 'FAQ', 'faq'),
                    _buildDrawerItem(
                        Icons.support_agent_rounded, 'Suporte', 'suporte'),
                    _buildDrawerItem(Icons.notifications_rounded,
                        'Notificações', 'notificacoes'),
                    const Divider(
                        color: Colors.white24,
                        indent: 24,
                        endIndent: 24,
                        height: 16),
                    _buildDrawerItem(Icons.logout_rounded, 'Sair', 'logout'),
                  ],
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '© 2024 - Versão 1.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        HapticFeedback.lightImpact();
        if (route == 'logout') {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        } else if (route != 'home') {
          widget.onNavigate(route);
        }
      },
    );
  }
}
