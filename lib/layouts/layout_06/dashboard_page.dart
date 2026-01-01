// Layout 06 Dashboard - Clean Dark Theme
// Design elegante e moderno

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'theme.dart';

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

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  final List<double> _usageHistory = [120, 180, 250, 200, 280, 320, 342.5];
  final List<String> _days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

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
    final isOnline = widget.connectionStatus.toLowerCase() == 'online';
    final remainingDays = widget.billDueDate.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: Layout06Theme.background,
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
                      const SizedBox(height: 20),
                      _buildSpeedTestCard(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildUsageChart(),
                      const SizedBox(height: 24),
                      _buildPlanCard(remainingDays),
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
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: Layout06Theme.backgroundGradient,
              ),
            ),
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
                      Layout06Theme.primary.withOpacity(0.12),
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
                      Layout06Theme.tertiary.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: Layout06Theme.primaryGradient,
            boxShadow: Layout06Theme.primaryShadow(),
          ),
          child: const Icon(Icons.wifi_rounded, color: Colors.white, size: 26),
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
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        _buildHeaderBtn(Icons.headset_mic_rounded, () {
          widget.onNavigate('suporte');
        }),
        const SizedBox(width: 10),
        _buildHeaderBtn(Icons.notifications_outlined, () {
          widget.onNavigate('notificacoes');
        }, badge: 3),
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
            Icon(icon, color: Colors.white.withOpacity(0.8), size: 22),
            if (badge != null)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: Layout06Theme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: Layout06Theme.glowShadow(Layout06Theme.primary,
                        blur: 6),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
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
                                color: Layout06Theme.primary,
                                width: 2,
                              ),
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
                        boxShadow: Layout06Theme.glowShadow(
                          isOnline
                              ? Layout06Theme.primary
                              : Layout06Theme.error,
                        ),
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
                              blur: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOnline ? 'Conectado' : 'Desconectado',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isOnline
                          ? 'Fibra Óptica • ${widget.planName} • Latência: 3ms'
                          : 'Verifique seu roteador ou entre em contato',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onNavigate('configuracoes');
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpeedTestCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onNavigate('diagnostico');
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: Layout06Theme.speedTestCardDecoration(),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Teste de Velocidade',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Layout06Theme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.play_arrow_rounded,
                          color: Layout06Theme.primary, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Iniciar',
                        style: TextStyle(
                          color: Layout06Theme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: _buildSpeedMetric(
                        'Download',
                        '${widget.downloadMbps.toStringAsFixed(0)} Mbps',
                        Icons.arrow_downward_rounded,
                        Layout06Theme.primary)),
                Container(
                    width: 1,
                    height: 50,
                    color: Colors.white.withOpacity(0.08)),
                Expanded(
                    child: _buildSpeedMetric(
                        'Upload',
                        '${widget.uploadMbps.toStringAsFixed(0)} Mbps',
                        Icons.arrow_upward_rounded,
                        Layout06Theme.secondary)),
                Container(
                    width: 1,
                    height: 50,
                    color: Colors.white.withOpacity(0.08)),
                Expanded(
                    child: _buildSpeedMetric('Ping', '3 ms',
                        Icons.network_ping_rounded, Layout06Theme.warning)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedMetric(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.router_rounded,
        'label': 'Roteador',
        'color': Layout06Theme.tertiary,
        'route': 'wifi'
      },
      {
        'icon': Icons.receipt_long_rounded,
        'label': '2ª Via',
        'color': Layout06Theme.primary,
        'route': 'financeiro'
      },
      {
        'icon': Icons.rocket_launch_rounded,
        'label': 'Upgrade',
        'color': const Color(0xFFFF7043),
        'route': 'planos'
      },
      {
        'icon': Icons.support_agent_rounded,
        'label': 'Suporte',
        'color': Layout06Theme.warning,
        'route': 'suporte'
      },
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 6, right: 6),
            child: _buildActionButton(
              action['icon'] as IconData,
              action['label'] as String,
              action['color'] as Color,
              action['route'] as String,
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, Color color, String route) {
    return GestureDetector(
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
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageChart() {
    final maxUsage = _usageHistory.reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: Layout06Theme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Uso da Semana',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${widget.usedGb.toStringAsFixed(0)} GB / ${widget.totalGb.toStringAsFixed(0)} GB',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_usageHistory.length, (index) {
                final usage = _usageHistory[index];
                final height = (usage / maxUsage) * 80;
                final isToday = index == _usageHistory.length - 1;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: height,
                          decoration: BoxDecoration(
                            gradient: isToday
                                ? Layout06Theme.primaryGradient
                                : LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.2),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _days[index],
                          style: TextStyle(
                            color: isToday
                                ? Layout06Theme.primary
                                : Colors.white.withOpacity(0.5),
                            fontSize: 10,
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(int remainingDays) {
    final isLate = remainingDays < 0;
    final statusColor = isLate ? Layout06Theme.error : Layout06Theme.success;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: Layout06Theme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.planName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isLate ? 'Pendente' : 'Ativo',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Próxima fatura',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${widget.billAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onNavigate('financeiro');
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: Layout06Theme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: Layout06Theme.primaryShadow(),
                  ),
                  child: const Text(
                    'Ver Faturas',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.speed_rounded, 'label': 'Speed'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Faturas'},
      {'icon': Icons.person_rounded, 'label': 'Perfil'},
    ];

    return Positioned(
      left: 20,
      right: 20,
      bottom: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Layout06Theme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = _currentNavIndex == index;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _currentNavIndex = index);
                    if (index == 1) widget.onNavigate('diagnostico');
                    if (index == 2) widget.onNavigate('financeiro');
                    if (index == 3) widget.onNavigate('perfil');
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Layout06Theme.primary.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          color: isSelected
                              ? Layout06Theme.primary
                              : Colors.white.withOpacity(0.5),
                          size: 24,
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Text(
                            item['label'] as String,
                            style: const TextStyle(
                              color: Layout06Theme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
