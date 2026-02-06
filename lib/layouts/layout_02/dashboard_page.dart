import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import 'widgets/bottom_nav.dart';

/// Layout 02 - NetLink Premium Dashboard
/// Design moderno com gradientes azul/cyan, cards premium e animações fluidas
class ProviderDashboardPage extends ConsumerStatefulWidget {
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
  ConsumerState<ProviderDashboardPage> createState() =>
      _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends ConsumerState<ProviderDashboardPage> {
  final PageController _promoController =
      PageController(viewportFraction: 0.92);
  Timer? _promoTimer;
  int _currentPromoPage = 0;
  static const int _promoCount = 3; // Number of promotions

  @override
  void initState() {
    super.initState();
    _startPromoAutoScroll();
  }

  void _startPromoAutoScroll() {
    _promoTimer?.cancel();
    _promoTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_promoController.hasClients) {
        _currentPromoPage = (_currentPromoPage + 1) % _promoCount;
        _promoController.animateToPage(
          _currentPromoPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopPromoAutoScroll() {
    _promoTimer?.cancel();
    _promoTimer = null;
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoController.dispose();
    super.dispose();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // Get ThemeConfig from provider (must be first to use its colors)
    final themeConfig = ref.watch(themeProvider).config;
    final primary = themeConfig.colors.primary;
    final secondary = themeConfig.colors.secondary;

    final quickActionsBg = themeConfig.colors.quickActionsCardColor;
    final otherCardsBg = themeConfig.colors.otherCardsColor;
    final quickActionsTextColor =
        themeConfig.colors.quickActionsTextColor; // [NEW]
    final otherCardsTextColor = themeConfig.colors.otherCardsTextColor; // [NEW]

    // Dynamic Gradients
    final primaryGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, secondary],
    );

    // Calculate a darker primary for gradients
    final hsl = HSLColor.fromColor(primary);
    final primaryDark =
        hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();

    final primaryDarkGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, primaryDark],
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Container(
        // Dynamic background (from Scaffold)
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh ?? () async {},
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  _buildHeader(
                      primaryGradient, primary, themeConfig.colors.textPrimary),
                  const SizedBox(height: 24),
                  _buildConnectionStatus(primaryDarkGradient),
                  const SizedBox(height: 24),
                  _buildPromotionCarousel(secondary,
                      themeConfig.colors.textPrimary), // Ofertas Especiais
                  const SizedBox(height: 24),
                  _buildQuickStats(Theme.of(context), otherCardsBg,
                      otherCardsTextColor), // Pass dynamic color
                  const SizedBox(height: 24),
                  _buildQuickActions(primary, secondary, quickActionsBg,
                      quickActionsTextColor), // Pass dynamic color
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Layout02BottomNav(
        currentIndex: 0,
        onTap: (index) {
          // Map index to navigation route
          final routes = ['home', 'invoices', 'speed_test', 'support'];
          if (index > 0 && index < routes.length) {
            widget.onNavigate(routes[index]);
          }
        },
        items: const [
          BottomNavItem(icon: Icons.home_rounded, label: 'Home', route: 'home'),
          BottomNavItem(
              icon: Icons.receipt_long_rounded,
              label: 'Faturas',
              route: 'invoices'),
          BottomNavItem(
              icon: Icons.speed_rounded,
              label: 'Velocidade',
              route: 'speed_test'),
          BottomNavItem(
              icon: Icons.support_agent_rounded,
              label: 'Suporte',
              route: 'support'),
        ],
      ),
    );
  }

  Widget _buildHeader(
      Gradient primaryGradient, Color primary, Color textColor) {
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
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.4),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.planName,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor.withOpacity(0.7),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        // Notification bell
        GestureDetector(
          onTap: () => widget.onNavigate('notifications'),
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

  Widget _buildConnectionStatus(Gradient primaryDarkGradient) {
    final isOnline = widget.connectionStatus.toLowerCase() == 'online' ||
        widget.connectionStatus.toLowerCase() == 'ativo';

    // Use dynamic gradient instead of static primaryCardDecoration
    final decoration = BoxDecoration(
      gradient: primaryDarkGradient,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color:
              Colors.black.withOpacity(0.2), // Generic shadow for dynamic color
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: decoration,
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
                    'Valor',
                    'R\$ ${widget.billAmount.toStringAsFixed(0)}',
                    '',
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
                    'Vencimento',
                    '${widget.billDueDate.day}/${_getMonthName(widget.billDueDate.month)}',
                    '',
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

  Widget _buildQuickStats(ThemeData theme, Color cardColor, Color textColor) {
    // Get color based on days until due date
    final now = DateTime.now();
    final daysUntilDue = widget.billDueDate.difference(now).inDays;
    final daysColor = daysUntilDue < 0
        ? Layout02Theme.red
        : daysUntilDue <= 3
            ? Layout02Theme.orange
            : Layout02Theme.green;

    // Use dynamic colors where appropriate
    final primary = theme.primaryColor;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Faturas',
            '',
            Icons.receipt_long_rounded,
            daysColor,
            cardColor: cardColor,
            textColor: textColor,
            onTap: () => widget.onNavigate('invoices'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Suporte',
            '',
            Icons.headset_mic_rounded,
            primary, // Replaced purple with primary for branding
            cardColor: cardColor,
            textColor: textColor,
            onTap: () => widget.onNavigate('support'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Consumo',
            '',
            Icons.data_usage_rounded,
            Layout02Theme.cyan,
            cardColor: cardColor,
            textColor: textColor,
            onTap: () => widget.onNavigate('internet_usage'),
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
    Color cardColor = Colors.white,
    Color textColor = Layout02Theme.textDark,
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
          color: cardColor,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            if (value.isNotEmpty) ...[
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(
      Color primary, Color secondary, Color cardColor, Color textColor) {
    final actions = [
      {
        'icon': Icons.speed_rounded,
        'label': 'Velocidade',
        'colors': [primary, secondary], // Dynamic
        'route': 'speed_test'
      },
      {
        'icon': Icons.network_check_rounded,
        'label': 'Diagnóstico',
        'colors': [Layout02Theme.green, Layout02Theme.cyan], // Dynamic
        'route': 'network_diagnostic'
      },
      {
        'icon': Icons.description_rounded,
        'label': 'Contrato',
        'colors': [Layout02Theme.orange, const Color(0xFFFF6B35)], // Dynamic
        'route': 'contract'
      },
      {
        'icon': Icons.quiz_rounded,
        'label': 'FAQ',
        'colors': [
          const Color(0xFFFF6B9D),
          primary.withOpacity(0.7)
        ], // Dynamic
        'route': 'faq'
      },
      {
        'icon': Icons.route_rounded,
        'label': 'Tracert',
        'colors': [primary, secondary], // Dynamic
        'route': 'trace_route'
      },
      {
        'icon': Icons.language_rounded,
        'label': 'Meu IP',
        'colors': [Layout02Theme.cyan, primary], // Dynamic
        'route': 'my_ip'
      },
      {
        'icon': Icons.wifi_rounded,
        'label': 'Wi-Fi',
        'colors': [secondary, Layout02Theme.green], // Dynamic
        'route': 'wifi'
      },
      {
        'icon': Icons.receipt_long_rounded,
        'label': 'Faturas',
        'colors': [Layout02Theme.orange, primary], // Dynamic
        'route': 'invoices'
      },
      {
        'icon': Icons.support_agent_rounded,
        'label': 'Suporte',
        'colors': [Layout02Theme.green, Layout02Theme.cyan], // Dynamic
        'route': 'support'
      },
      {
        'icon': Icons.data_usage_rounded,
        'label': 'Consumo',
        'colors': [
          const Color(0xFF9C27B0),
          primary.withOpacity(0.8)
        ], // Dynamic
        'route': 'internet_usage'
      },
      {
        'icon': Icons.notifications_rounded,
        'label': 'Alertas',
        'colors': [const Color(0xFFEF5350), Layout02Theme.orange], // Dynamic
        'route': 'notifications'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Ações Rápidas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Layout02Theme.textDark,
                ),
              ),
            ),
            GestureDetector(
              onTap: () =>
                  _showActionsGrid(context, actions, cardColor, textColor),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ver mais',
                        style: TextStyle(
                            color: primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Icon(Icons.grid_view_rounded, color: primary, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: 5, // Mostrar apenas 5 no slider
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final action = actions[index];
              return _buildSliderActionItem(
                action['icon'] as IconData,
                action['label'] as String,
                action['colors'] as List<Color>,
                action['route'] as String,
                cardColor,
                textColor, // [NEW]
              );
            },
          ),
        ),
      ],
    );
  }

  void _showActionsGrid(BuildContext context,
      List<Map<String, dynamic>> actions, Color cardColor, Color textColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Todas as Ações',
                    style: TextStyle(
                        color: Layout02Theme.textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.grey, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final a = actions[index];
                final colors = a['colors'] as List<Color>;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    if (a['route'] != null) {
                      widget.onNavigate(a['route'] as String);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colors[0].withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: colors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colors[0].withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            a['icon'] as IconData,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          a['label'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderActionItem(
    IconData icon,
    String label,
    List<Color> gradientColors,
    String route,
    Color cardColor,
    Color textColor,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onNavigate(route);
      },
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    LinearGradient(colors: gradientColors).createShader(bounds),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textColor.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionCarousel(Color secondary, Color textColor) {
    final bannerImages = [
      'assets/banners/banner_upgrade.png',
      'assets/banners/banner_indique.png',
      'assets/banners/banner_combo.png',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ofertas Especiais',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onPanDown: (_) => _stopPromoAutoScroll(),
          onPanEnd: (_) => _startPromoAutoScroll(),
          onPanCancel: () => _startPromoAutoScroll(),
          child: SizedBox(
            height: 140,
            child: PageView.builder(
              itemCount: bannerImages.length,
              controller: _promoController,
              onPageChanged: (index) => _currentPromoPage = index,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      bannerImages[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to gradient if image not found
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [secondary, secondary.withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.local_offer_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
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
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final hsl = HSLColor.fromColor(primary);
    final primaryDark =
        hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primary,
              primaryDark,
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
