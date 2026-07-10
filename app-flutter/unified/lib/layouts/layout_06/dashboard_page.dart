// Layout 06 Dashboard - Clean Dark Theme (Versão Completa)
// Design elegante e moderno com todos os elementos premium

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'theme.dart';
import '../../core/providers/weekly_usage_provider.dart';
import '../../core/providers/providers.dart';

class DashboardPage extends ConsumerStatefulWidget {
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
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Removido: _days fixo (dias da semana); agora vem dinamicamente do provider mensal

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = widget.connectionStatus.toLowerCase() == 'online' ||
        widget.connectionStatus.toLowerCase() == 'ativo';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Layout06Theme.background,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                if (widget.onRefresh != null) {
                  HapticFeedback.mediumImpact();
                  await widget.onRefresh!();
                }
              },
              color: Layout06Theme.primary,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildConnectionCard(isOnline),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildPlanCard(),
                      const SizedBox(height: 24),
                      _buildUsageChart(),
                      const SizedBox(height: 24),
                      _buildServiceStatus(),
                      const SizedBox(height: 24),
                      _buildPromoBanner(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: Layout06Theme.backgroundGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Layout06Theme.primary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Layout06Theme.tertiary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _scaffoldKey.currentState?.openDrawer();
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: Layout06Theme.primaryGradient,
              boxShadow: Layout06Theme.primaryShadow(),
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
              Row(
                children: [
                  Text(
                    widget.customerName.split(' ').first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: Layout06Theme.accentGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'FIBRA',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Cliente Premium desde 2022',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        _buildHeaderBtn(
            Icons.headset_mic_rounded, () => widget.onNavigate('suporte')),
        const SizedBox(width: 10),
        _buildHeaderBtn(Icons.notifications_outlined,
            () => widget.onNavigate('notificacoes'),
            badge: 3),
      ],
    );
  }

  Widget _buildHeaderBtn(IconData icon, VoidCallback onTap, {int? badge}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: Layout06Theme.glassBtnDecoration(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 22),
            if (badge != null)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    gradient: Layout06Theme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(bool isOnline) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: Layout06Theme.connectionCardDecoration(
              isOnline, _pulseController.value),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isOnline)
                      ...List.generate(3, (i) {
                        final delay = i * 0.25;
                        final progress =
                            ((_pulseController.value + delay) % 1.0);
                        return Opacity(
                          opacity: (1 - progress) * 0.4,
                          child: Container(
                            width: 40 + (progress * 30),
                            height: 40 + (progress * 30),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Layout06Theme.primary, width: 2),
                            ),
                          ),
                        );
                      }),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: isOnline
                            ? Layout06Theme.primaryGradient
                            : const LinearGradient(colors: [
                                Layout06Theme.error,
                                Layout06Theme.errorDark
                              ]),
                        shape: BoxShape.circle,
                        boxShadow: Layout06Theme.glowShadow(isOnline
                            ? Layout06Theme.primary
                            : Layout06Theme.error),
                      ),
                      child: Icon(
                        isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                        color: Colors.white,
                        size: 26,
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
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline
                                ? Layout06Theme.success
                                : Layout06Theme.error,
                            boxShadow: Layout06Theme.glowShadow(
                                isOnline
                                    ? Layout06Theme.success
                                    : Layout06Theme.error,
                                blur: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOnline ? 'Conectado' : 'Desconectado',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isOnline
                          ? 'Fibra Óptica • ${widget.planName} • Latência: 3ms'
                          : 'Verifique seu roteador',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'label': 'Faturas',
        'icon': Icons.receipt_long_rounded,
        'color': Layout06Theme.primary,
        'route': 'invoices'
      },
      {
        'label': 'Suporte',
        'icon': Icons.support_agent_rounded,
        'color': Layout06Theme.warning,
        'route': 'support'
      },
      {
        'label': 'Diagnóstico',
        'icon': Icons.healing_rounded,
        'color': const Color(0xFF00ACC1),
        'route': 'network_diagnostic'
      },
      {
        'label': 'Velocidade',
        'icon': Icons.speed_rounded,
        'color': const Color(0xFF7C4DFF),
        'route': 'speed_test'
      },
      {
        'label': 'Roteador',
        'icon': Icons.router_rounded,
        'color': Layout06Theme.secondary,
        'route': 'wifi'
      },
      {
        'label': 'Consumo',
        'icon': Icons.data_usage_rounded,
        'color': const Color(0xFF9C27B0),
        'route': 'internet_usage'
      },
      {
        'label': 'Contrato',
        'icon': Icons.description_rounded,
        'color': const Color(0xFF607D8B),
        'route': 'contract'
      },
      {
        'label': 'FAQ',
        'icon': Icons.help_outline_rounded,
        'color': const Color(0xFF795548),
        'route': 'faq'
      },
      {
        'label': 'Traceroute',
        'icon': Icons.route_rounded,
        'color': const Color(0xFF5C6BC0),
        'route': 'trace_route'
      },
      {
        'label': 'Meu IP',
        'icon': Icons.public_rounded,
        'color': const Color(0xFF26A69A),
        'route': 'my_ip'
      },
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ações Rápidas',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showAllActionsModal(context, actions);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Layout06Theme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver todos',
                      style: TextStyle(
                          color: Layout06Theme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.grid_view_rounded,
                        color: Layout06Theme.primary, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            children: actions
                .take(5)
                .map((a) => _buildAction(
                      a['label'] as String,
                      a['icon'] as IconData,
                      a['color'] as Color,
                      a['route'] as String,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  void _showAllActionsModal(
      BuildContext context, List<Map<String, dynamic>> actions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Layout06Theme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Todas as Ações',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 20),
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
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    HapticFeedback.lightImpact();
                    widget.onNavigate(a['route'] as String);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (a['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: (a['color'] as Color).withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (a['color'] as Color).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(a['icon'] as IconData,
                              color: a['color'] as Color, size: 24),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          a['label'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildAction(String label, IconData icon, Color color, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onNavigate(route);
        },
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard() {
    final remainingDays = widget.billDueDate.difference(DateTime.now()).inDays;
    final formattedDate =
        '${widget.billDueDate.day.toString().padLeft(2, '0')}/${widget.billDueDate.month.toString().padLeft(2, '0')}/${widget.billDueDate.year}'
        '${remainingDays > 0 ? ' (${remainingDays}d)' : remainingDays == 0 ? ' (hoje)' : ' (vencida)'}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seu Plano',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        widget.planName.split(' ').first,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.planName.split(' ').length > 1
                            ? widget.planName.split(' ').sublist(1).join(' ')
                            : '',
                        style: const TextStyle(
                            color: Color(0xFFFFD740),
                            fontSize: 26,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('Ativo',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPlanBadge('${widget.downloadMbps.toStringAsFixed(0)} Mbps',
                  Icons.speed_rounded),
              _buildPlanBadge('${widget.totalGb.toStringAsFixed(0)} GB',
                  Icons.data_usage_rounded),
              _buildPlanBadge('Wi-Fi 6', Icons.wifi_rounded),
              _buildPlanBadge('IP Fixo', Icons.language_rounded),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Próxima Fatura',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${widget.billAmount.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Vencimento: $formattedDate',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onNavigate('financeiro');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Pagar',
                      style: TextStyle(
                          color: Color(0xFF7C4DFF),
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanBadge(String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 22),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildUsageChart() {
    final monthlyState = ref.watch(weeklyUsageProvider);
    final usageHistory = monthlyState.usageData;
    final dayLabels = monthlyState.dayLabels;
    final maxUsage =
        usageHistory.isNotEmpty ? usageHistory.reduce(math.max) : 0.0;

    // Mês/ano para exibição no título
    final now = DateTime.now();
    final displayMonth = monthlyState.month > 0 ? monthlyState.month : now.month;
    final displayYear = monthlyState.year > 0 ? monthlyState.year : now.year;
    final monthNames = [
      '', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    final monthLabel =
        '${monthNames[displayMonth]}/$displayYear';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consumo do Mês',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  monthLabel,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => ref.read(weeklyUsageProvider.notifier).refresh(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (monthlyState.isLoading)
                      const SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Layout06Theme.primary,
                        ),
                      )
                    else
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Layout06Theme.primary,
                            shape: BoxShape.circle),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      '${monthlyState.totalMonthlyUsage.toStringAsFixed(1)} GB',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              if (monthlyState.isLoading && usageHistory.isEmpty)
                const SizedBox(
                  height: 125,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Layout06Theme.primary,
                    ),
                  ),
                )
              else if (usageHistory.isEmpty)
                SizedBox(
                  height: 125,
                  child: Center(
                    child: Text(
                      monthlyState.error != null
                          ? 'Sem dados disponíveis'
                          : 'Carregando...',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 125,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(usageHistory.length, (i) {
                      final height =
                          maxUsage > 0 ? (usageHistory[i] / maxUsage) * 100 : 0.0;
                      final isToday = i == usageHistory.length - 1;
                      final label = i < dayLabels.length ? dayLabels[i] : '';
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, _) {
                                  return Container(
                                    height: math.max(height, 4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: isToday
                                            ? [
                                                Layout06Theme.primary,
                                                Layout06Theme.primaryDark
                                              ]
                                            : [
                                                Colors.white
                                                    .withValues(alpha: 0.15),
                                                Colors.white
                                                    .withValues(alpha: 0.08)
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: isToday
                                          ? [
                                              BoxShadow(
                                                color: Layout06Theme.primary
                                                    .withValues(
                                                        alpha: 0.3 +
                                                            _pulseController
                                                                    .value *
                                                                0.1),
                                                blurRadius: 8,
                                              )
                                            ]
                                          : null,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 6),
                              Text(
                                label,
                                style: TextStyle(
                                  color: isToday
                                      ? Layout06Theme.primary
                                      : Colors.white.withValues(alpha: 0.35),
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${monthlyState.totalMonthlyUsage.toStringAsFixed(1)} GB',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13),
                  ),
                  Text(
                    monthLabel,
                    style: TextStyle(
                        color: Layout06Theme.primary.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceStatus() {
    final config = ref.watch(configurationProvider);
    final otherSettings = config.providerConfig?.config.other;
    final showTv = otherSettings?.showTvService ?? false;
    // Telefone fixo removido — provedores de internet oferecem apenas Internet e/ou IPTV

    // Status real baseado no estado da conta do usuário
    final userStatus = widget.connectionStatus.toLowerCase();
    final isActive = userStatus == 'ativo' || userStatus == 'operacional' || userStatus == 'active';
    final internetStatus = isActive ? 'Operacional' : widget.connectionStatus;
    final internetColor = isActive ? Layout06Theme.success : Layout06Theme.error;

    final services = <Widget>[
      Expanded(
          child: _buildStatusCard('Internet', internetStatus,
              Icons.public_rounded, internetColor, isActive)),
    ];

    if (showTv) {
      services.add(const SizedBox(width: 12));
      services.add(Expanded(
          child: _buildStatusCard('IPTV', internetStatus, Icons.tv_rounded,
              internetColor, isActive)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status dos Serviços',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(children: services),
      ],
    );
  }

  Widget _buildStatusCard(
      String title, String status, IconData icon, Color color, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                  color: color, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    final promos = [
      {
        'title': '🎄 Feliz Ano Novo!',
        'subtitle': 'Desejamos um 2026 cheio de conexão e alegria!',
        'gradient': const [Color(0xFF7C4DFF), Color(0xFF536DFE)],
        'icon': Icons.celebration_rounded,
      },
      {
        'title': '🚀 Upgrade Disponível',
        'subtitle': 'Dobre sua velocidade por apenas +R\$ 20/mês',
        'gradient': const [Color(0xFF00BCD4), Color(0xFF00838F)],
        'icon': Icons.rocket_launch_rounded,
      },
      {
        'title': '📅 Manutenção Programada',
        'subtitle': 'Dia 15/01 das 02h às 05h - Melhorias na rede',
        'gradient': const [Color(0xFFFF7043), Color(0xFFE64A19)],
        'icon': Icons.build_rounded,
      },
      {
        'title': '🎁 Indique e Ganhe',
        'subtitle': 'Ganhe 1 mês grátis para cada amigo indicado',
        'gradient': const [Color(0xFF00E676), Color(0xFF00C853)],
        'icon': Icons.card_giftcard_rounded,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Novidades',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: List.generate(promos.length, (i) {
                return AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) {
                    final isActive =
                        ((_waveController.value * promos.length).floor() %
                                promos.length) ==
                            i;
                    return Container(
                      width: isActive ? 16 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Layout06Theme.primary
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 125,
          child: PageView.builder(
            itemCount: promos.length,
            controller: PageController(viewportFraction: 0.92),
            itemBuilder: (context, index) {
              final promo = promos[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => HapticFeedback.lightImpact(),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: promo['gradient'] as List<Color>,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (promo['gradient'] as List<Color>)[0]
                              .withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            promo['icon'] as IconData,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                promo['title'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                promo['subtitle'] as String,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    final menuItems = [
      {
        'icon': Icons.home_rounded,
        'label': 'Início',
        'route': 'dashboard',
        'color': Layout06Theme.primary
      },
      {
        'icon': Icons.speed_rounded,
        'label': 'Velocidade',
        'route': 'speed_test',
        'color': const Color(0xFF00E676)
      },
      {
        'icon': Icons.receipt_long_rounded,
        'label': 'Faturas',
        'route': 'invoices',
        'color': const Color(0xFFFF7043)
      },
      {
        'icon': Icons.router_rounded,
        'label': 'Wi-Fi / Roteador',
        'route': 'wifi',
        'color': const Color(0xFF7C4DFF)
      },
      {
        'icon': Icons.data_usage_rounded,
        'label': 'Consumo',
        'route': 'internet_usage',
        'color': const Color(0xFF9C27B0)
      },
      {
        'icon': Icons.healing_rounded,
        'label': 'Diagnóstico',
        'route': 'network_diagnostic',
        'color': const Color(0xFF00ACC1)
      },
      {
        'icon': Icons.route_rounded,
        'label': 'Traceroute',
        'route': 'trace_route',
        'color': const Color(0xFF5C6BC0)
      },
      {
        'icon': Icons.public_rounded,
        'label': 'Meu IP',
        'route': 'my_ip',
        'color': const Color(0xFF26A69A)
      },
      {
        'icon': Icons.rocket_launch_rounded,
        'label': 'Upgrade',
        'route': 'planos',
        'color': const Color(0xFFE91E63)
      },
      {
        'icon': Icons.description_rounded,
        'label': 'Contrato',
        'route': 'contract',
        'color': const Color(0xFF607D8B)
      },
      {
        'icon': Icons.support_agent_rounded,
        'label': 'Suporte',
        'route': 'support',
        'color': Layout06Theme.warning
      },
      {
        'icon': Icons.help_outline_rounded,
        'label': 'FAQ',
        'route': 'faq',
        'color': const Color(0xFF795548)
      },
      {
        'icon': Icons.notifications_rounded,
        'label': 'Notificações',
        'route': 'notifications',
        'color': const Color(0xFFFF5252)
      },
    ];

    return Drawer(
      backgroundColor: Layout06Theme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: Layout06Theme.primaryGradient,
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customerName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.planName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: menuItems
                    .map((item) => _buildDrawerItem(
                          icon: item['icon'] as IconData,
                          label: item['label'] as String,
                          route: item['route'] as String,
                          color: item['color'] as Color,
                        ))
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                  widget.onNavigate('logout');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Layout06Theme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Layout06Theme.error.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded,
                          color: Layout06Theme.error, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Sair',
                        style: TextStyle(
                            color: Layout06Theme.error,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required String route,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          HapticFeedback.lightImpact();
          widget.onNavigate(route);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.3), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            decoration: BoxDecoration(
              color: Layout06Theme.background.withValues(alpha: 0.92),
              border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_rounded, 'Início', 0),
                  _buildNavItem(Icons.speed_rounded, 'Velocidade', 1),
                  _buildCenterNav(),
                  _buildNavItem(Icons.receipt_long_rounded, 'Faturas', 2),
                  _buildNavItem(Icons.person_rounded, 'Conta', 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedIndex = index);
        if (index == 1) widget.onNavigate('diagnostico');
        if (index == 2) widget.onNavigate('financeiro');
        if (index == 3) widget.onNavigate('perfil');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Layout06Theme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Layout06Theme.primary
                  : Colors.white.withValues(alpha: 0.35),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Layout06Theme.primary
                    : Colors.white.withValues(alpha: 0.35),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNav() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onNavigate('diagnostico');
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          return Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: Layout06Theme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Layout06Theme.primary
                      .withValues(alpha: 0.35 + _pulseController.value * 0.1),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child:
                const Icon(Icons.speed_rounded, color: Colors.white, size: 28),
          );
        },
      ),
    );
  }
}
