import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import 'theme.dart';
import 'widgets/neu_button.dart';
import 'widgets/feature_tile.dart';

/// Layout 03 Neumorphic Dashboard
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
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _navIndex = 0;
  bool _featuresExpanded = false;
  int _bannerPage = 0;
  late PageController _bannerController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _features = [
    {
      'label': 'Velocidade',
      'icon': Icons.speed_rounded,
      'color': Layout03Theme.iconBlue,
      'route': 'speed_test'
    },
    {
      'label': 'Diagnóstico',
      'icon': Icons.healing_rounded,
      'color': Layout03Theme.iconTeal,
      'route': 'network_diagnostic'
    },
    {
      'label': 'Contrato',
      'icon': Icons.description_rounded,
      'color': Layout03Theme.iconMauve,
      'route': 'contract'
    },
    {
      'label': 'FAQ',
      'icon': Icons.help_outline_rounded,
      'color': Layout03Theme.iconMist,
      'route': 'faq'
    },
    {
      'label': 'Traceroute',
      'icon': Icons.route_rounded,
      'color': Layout03Theme.iconSlate,
      'route': 'trace_route'
    },
    {
      'label': 'Consumo',
      'icon': Icons.pie_chart_rounded,
      'color': Layout03Theme.iconSage,
      'route': 'internet_usage'
    },
    {
      'label': 'Meu IP',
      'icon': Icons.public_rounded,
      'color': Layout03Theme.iconStorm,
      'route': 'my_ip'
    },
    {
      'label': 'Faturas',
      'icon': Icons.receipt_long_rounded,
      'color': Layout03Theme.iconDusk,
      'route': 'invoices'
    },
    {
      'label': 'Suporte',
      'icon': Icons.headset_mic_rounded,
      'color': Layout03Theme.iconFog,
      'route': 'support'
    },
  ];

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _autoScrollBanner();
  }

  void _autoScrollBanner() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _bannerController.hasClients) {
        _bannerController.animateToPage(
          (_bannerPage + 1) % 2,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _autoScrollBanner();
      }
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Layout03Theme.neuBase,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildConnectionCard(),
                    const SizedBox(height: 18),
                    _buildPromoBanner(),
                    const SizedBox(height: 22),
                    _buildFeaturesSection(),
                    const SizedBox(height: 22),
                    _buildInvoicesSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildNavbar(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Header
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            NeuButton(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: const Icon(Icons.menu_rounded,
                  color: Layout03Theme.textMedium, size: 22),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final configProvider = ref.watch(configurationProvider);
                    return Text(
                      configProvider.providerConfig?.name ?? 'Provedor Online',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Layout03Theme.textDark,
                      ),
                    );
                  },
                ),
                Text(
                  'Olá, ${widget.customerName.split(' ').first}! 👋',
                  style: const TextStyle(
                      fontSize: 13, color: Layout03Theme.textMedium),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            NeuButton(
              onTap: () => widget.onNavigate('notifications'),
              child: const Icon(Icons.notifications_none_rounded,
                  color: Layout03Theme.textMedium, size: 22),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Connection Card
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildConnectionCard() {
    final isOnline = widget.connectionStatus.toLowerCase() == 'online' ||
        widget.connectionStatus.toLowerCase() == 'ativo';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Layout03Theme.neuBase,
        borderRadius: BorderRadius.circular(24),
        boxShadow: Layout03Theme.neuConvex(distance: 10, blur: 20),
      ),
      child: Row(
        children: [
          // Status indicator - CONCAVE (sunken)
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Layout03Theme.neuBase,
              shape: BoxShape.circle,
              boxShadow: Layout03Theme.neuConcave(distance: 5, blur: 10),
            ),
            child: Icon(
              Icons.wifi_rounded,
              color: isOnline ? Layout03Theme.success : Layout03Theme.error,
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline
                            ? Layout03Theme.success
                            : Layout03Theme.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnline ? 'Conectado' : 'Desconectado',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isOnline
                            ? Layout03Theme.success
                            : Layout03Theme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.planName,
                  style: const TextStyle(
                      fontSize: 12, color: Layout03Theme.textMedium),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.downloadMbps.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Layout03Theme.textDark,
                      height: 1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Text(
                      ' Mbps',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Layout03Theme.textMedium,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.signal_cellular_alt_rounded,
                    size: 12,
                    color: isOnline
                        ? Layout03Theme.success
                        : Layout03Theme.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOnline ? 'Conectado' : 'Offline',
                    style: const TextStyle(
                        fontSize: 11, color: Layout03Theme.textMedium),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Promo Banner - Clean design without sunken border
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPromoBanner() {
    return Column(
      children: [
        // PageView sem container afundado - design limpo
        SizedBox(
          height: 140,
          child: PageView(
            controller: _bannerController,
            onPageChanged: (i) => setState(() => _bannerPage = i),
            children: [_buildUpgradeBanner(), _buildSupportBanner()],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (i) {
            final active = _bannerPage == i;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active
                    ? Layout03Theme.primary
                    : Layout03Theme.neuShadowDark.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildUpgradeBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '🔥 Oferta',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Upgrade para 1 Gbps',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Por apenas + R\$ 30/mês',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.rocket_launch_rounded,
                size: 26, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF38B2AC), Color(0xFF4FD1C5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '⚡ 24/7',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Suporte Técnico',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Equipe sempre disponível',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.headset_mic_rounded,
                size: 26, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Features Section
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFeaturesSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Acesso Rápido',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Layout03Theme.textDark,
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _featuresExpanded = !_featuresExpanded);
              },
              child: Row(
                children: [
                  Text(
                    _featuresExpanded ? 'Menos' : 'Ver todos',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Layout03Theme.primary,
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _featuresExpanded ? 0.5 : 0,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Layout03Theme.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _featuresExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: SizedBox(
            height: 95,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _features.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (_, i) => FeatureTile(
                label: _features[i]['label'] as String,
                icon: _features[i]['icon'] as IconData,
                color: _features[i]['color'] as Color,
                onTap: () => widget.onNavigate(_features[i]['route'] as String),
              ),
            ),
          ),
          secondChild: Wrap(
            spacing: 16,
            runSpacing: 18,
            children: _features
                .map((f) => FeatureTile(
                      label: f['label'] as String,
                      icon: f['icon'] as IconData,
                      color: f['color'] as Color,
                      onTap: () => widget.onNavigate(f['route'] as String),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Invoices Section
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildInvoicesSection() {
    final now = DateTime.now();
    final daysUntilDue = widget.billDueDate.difference(now).inDays;
    final isPending = daysUntilDue >= 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Faturas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Layout03Theme.textDark,
              ),
            ),
            GestureDetector(
              onTap: () => widget.onNavigate('invoices'),
              child: const Text(
                'Ver todas',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Layout03Theme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInvoiceCard(
                _getMonthName(widget.billDueDate.month),
                'R\$ ${widget.billAmount.toStringAsFixed(2).replaceAll('.', ',')}',
                '${widget.billDueDate.day}/${widget.billDueDate.month}',
                isPending ? 'Pendente' : 'Vencida',
                isPending ? Layout03Theme.warning : Layout03Theme.error,
                isPending: isPending,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildInvoiceCard(
                _getMonthName(widget.billDueDate.month - 1 == 0
                    ? 12
                    : widget.billDueDate.month - 1),
                'R\$ ${widget.billAmount.toStringAsFixed(2).replaceAll('.', ',')}',
                '${widget.billDueDate.day}/${widget.billDueDate.month - 1 == 0 ? 12 : widget.billDueDate.month - 1}',
                'Pago',
                Layout03Theme.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(
    String month,
    String value,
    String due,
    String status,
    Color statusColor, {
    bool isPending = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Layout03Theme.neuBase,
        borderRadius: BorderRadius.circular(18),
        boxShadow: Layout03Theme.neuConvex(distance: 5, blur: 10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Layout03Theme.neuBase,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: Layout03Theme.neuConcave(distance: 2, blur: 5),
                ),
                child:
                    Icon(Icons.receipt_rounded, size: 18, color: statusColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(month,
              style: const TextStyle(
                  fontSize: 10, color: Layout03Theme.textMedium)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Layout03Theme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_rounded,
                      size: 10, color: Layout03Theme.textLight),
                  const SizedBox(width: 3),
                  Text(
                    'Venc: $due',
                    style: const TextStyle(
                        fontSize: 9, color: Layout03Theme.textLight),
                  ),
                ],
              ),
              if (isPending)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onNavigate('financeiro');
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pagar',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Navbar
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNavbar() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home', 'route': 'home'},
      {'icon': Icons.speed_rounded, 'label': 'Speed', 'route': 'speed_test'},
      {
        'icon': Icons.receipt_long_rounded,
        'label': 'Faturas',
        'route': 'invoices'
      },
      {
        'icon': Icons.headset_mic_rounded,
        'label': 'Suporte',
        'route': 'support'
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Layout03Theme.neuBase,
        boxShadow: [
          BoxShadow(
            color: Layout03Theme.neuShadowDark.withOpacity(0.2),
            offset: const Offset(0, -6),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final selected = _navIndex == i;

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _navIndex = i);
                if (i > 0) widget.onNavigate(item['route'] as String);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Layout03Theme.neuBase,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: selected
                      ? Layout03Theme.neuFlat(distance: 4, blur: 8)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 22,
                      color: selected
                          ? Layout03Theme.primary
                          : Layout03Theme.textLight,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected
                            ? Layout03Theme.primary
                            : Layout03Theme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Drawer
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDrawer() {
    final items = [
      {
        'icon': Icons.home_rounded,
        'label': 'Início',
        'route': 'home',
        'selected': true
      },
      {
        'icon': Icons.speed_rounded,
        'label': 'Velocidade',
        'route': 'speed_test'
      },
      {
        'icon': Icons.healing_rounded,
        'label': 'Diagnóstico',
        'route': 'network_diagnostic'
      },
      {
        'icon': Icons.route_rounded,
        'label': 'Traceroute',
        'route': 'trace_route'
      },
      {
        'icon': Icons.pie_chart_rounded,
        'label': 'Consumo',
        'route': 'internet_usage'
      },
      {'icon': Icons.public_rounded, 'label': 'Meu IP', 'route': 'my_ip'},
      {
        'icon': Icons.description_rounded,
        'label': 'Contrato',
        'route': 'contract'
      },
      {
        'icon': Icons.receipt_long_rounded,
        'label': 'Faturas',
        'route': 'invoices'
      },
      {'icon': Icons.help_outline_rounded, 'label': 'FAQ', 'route': 'faq'},
      {
        'icon': Icons.headset_mic_rounded,
        'label': 'Suporte',
        'route': 'support'
      },
    ];

    return Drawer(
      backgroundColor: Layout03Theme.neuBase,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Layout03Theme.neuBase,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: Layout03Theme.neuConvex(distance: 5, blur: 10),
                    ),
                    child: const Icon(Icons.wifi_rounded,
                        color: Layout03Theme.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer(
                        builder: (context, ref, _) {
                          final configProvider =
                              ref.watch(configurationProvider);
                          return Text(
                            configProvider.providerConfig?.name ??
                                'Seu Provedor',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Layout03Theme.textDark,
                            ),
                          );
                        },
                      ),
                      Text(
                        widget.planName,
                        style: const TextStyle(
                            fontSize: 12, color: Layout03Theme.textMedium),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  final selected = item['selected'] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Layout03Theme.neuBase,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: selected
                          ? Layout03Theme.neuFlat(distance: 4, blur: 8)
                          : null,
                    ),
                    child: ListTile(
                      leading: Icon(
                        item['icon'] as IconData,
                        color: selected
                            ? Layout03Theme.primary
                            : Layout03Theme.textMedium,
                        size: 22,
                      ),
                      title: Text(
                        item['label'] as String,
                        style: TextStyle(
                          color: selected
                              ? Layout03Theme.primary
                              : Layout03Theme.textDark,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        if (item['route'] != 'home') {
                          widget.onNavigate(item['route'] as String);
                        }
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
    return months[(month - 1).clamp(0, 11)];
  }
}
