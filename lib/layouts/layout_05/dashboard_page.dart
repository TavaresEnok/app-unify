// Layout 05 Dashboard - Cyber Neon Dark Theme
// Design futurista com animações de grid, pulse e data flow

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
  late AnimationController _dataFlowController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _dataFlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _dataFlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = widget.connectionStatus.toLowerCase() == 'online';
    final remainingDays = widget.billDueDate.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: Layout05Theme.background,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                if (widget.onRefresh != null) {
                  HapticFeedback.mediumImpact();
                  await widget.onRefresh!();
                }
              },
              color: Layout05Theme.primary,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildHeroCard(isOnline),
                      const SizedBox(height: 20),
                      _buildLiveStats(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildBillCard(remainingDays),
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

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        return Stack(
          children: [
            Container(color: Layout05Theme.background),
            // Animated gradient orbs
            Positioned(
              top: -150 + math.sin(_waveController.value * math.pi * 2) * 20,
              right: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Layout05Theme.primary.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 300 + math.cos(_waveController.value * math.pi * 2) * 15,
              left: -100,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Layout05Theme.secondary.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Grid pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPatternPainter(_waveController.value),
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
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: Layout05Theme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: Layout05Theme.primary
                        .withOpacity(0.3 + _pulseController.value * 0.15),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child:
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
            );
          },
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
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: Layout05Theme.accentGradient,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Layout05Theme.accent.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Text(
                      'ULTRA',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Fibra Óptica • ${widget.planName}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        _buildGlassBtn(Icons.support_agent_rounded, () {
          widget.onNavigate('suporte');
        }),
        const SizedBox(width: 10),
        _buildGlassBtn(Icons.notifications_rounded, () {
          widget.onNavigate('notificacoes');
        }, badge: 3),
      ],
    );
  }

  Widget _buildGlassBtn(IconData icon, VoidCallback onTap, {int? badge}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: Layout05Theme.glassDecoration(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: Colors.white.withOpacity(0.9), size: 22),
                if (badge != null)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: Layout05Theme.errorGradient,
                        shape: BoxShape.circle,
                        boxShadow:
                            Layout05Theme.glowShadow(Layout05Theme.error),
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
        ),
      ),
    );
  }

  Widget _buildHeroCard(bool isOnline) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _dataFlowController]),
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: Layout05Theme.heroCardDecoration(_pulseController.value),
          child: Column(
            children: [
              Row(
                children: [
                  // Animated connection indicator
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Data flow rings
                      ...List.generate(3, (i) {
                        final delay = i * 0.3;
                        final progress =
                            ((_dataFlowController.value + delay) % 1.0);
                        return Container(
                          width: 55 + (progress * 25),
                          height: 55 + (progress * 25),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Layout05Theme.primary
                                  .withOpacity((1 - progress) * 0.3),
                              width: 1.5,
                            ),
                          ),
                        );
                      }),
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: Layout05Theme.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow:
                              Layout05Theme.glowShadow(Layout05Theme.primary),
                        ),
                        child: const Icon(
                          Icons.wifi_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
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
                                    ? Layout05Theme.success
                                    : Layout05Theme.error,
                                boxShadow: Layout05Theme.glowShadow(
                                  isOnline
                                      ? Layout05Theme.success
                                      : Layout05Theme.error,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                color: isOnline
                                    ? Layout05Theme.success
                                    : Layout05Theme.error,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Há 45 dias',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isOnline
                              ? 'Conexão estável e ultrarrápida'
                              : 'Verificando conexão...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Última verificação: agora',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Live data flow visualization
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: AnimatedBuilder(
                    animation: _dataFlowController,
                    builder: (context, _) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.3 + _dataFlowController.value * 0.7,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Layout05Theme.primary.withOpacity(0),
                                Layout05Theme.primary,
                              ],
                            ),
                            boxShadow:
                                Layout05Theme.glowShadow(Layout05Theme.primary),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Download',
            '${widget.downloadMbps.toStringAsFixed(0)} Mbps',
            Icons.arrow_downward_rounded,
            Layout05Theme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Upload',
            '${widget.uploadMbps.toStringAsFixed(0)} Mbps',
            Icons.arrow_upward_rounded,
            Layout05Theme.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Ping',
            '3 ms',
            Icons.network_ping_rounded,
            Layout05Theme.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
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
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.speed_rounded,
        'label': 'Speed Test',
        'route': 'diagnostico'
      },
      {
        'icon': Icons.receipt_long_rounded,
        'label': 'Faturas',
        'route': 'financeiro'
      },
      {'icon': Icons.wifi_password_rounded, 'label': 'Wi-Fi', 'route': 'wifi'},
      {
        'icon': Icons.support_agent_rounded,
        'label': 'Suporte',
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
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 6,
              right: index == actions.length - 1 ? 0 : 6,
            ),
            child: _buildActionButton(
              action['icon'] as IconData,
              action['label'] as String,
              action['route'] as String,
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, String route) {
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
              color: Layout05Theme.secondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Layout05Theme.secondary.withOpacity(0.2)),
            ),
            child: Icon(icon, color: Layout05Theme.secondary, size: 28),
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

  Widget _buildBillCard(int remainingDays) {
    final isLate = remainingDays < 0;
    final statusColor = isLate ? Layout05Theme.error : Layout05Theme.success;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: Layout05Theme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Próxima Fatura',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
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
                  isLate ? 'Atrasada' : 'Em dia',
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'R\$ ${widget.billAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Vence em ${remainingDays.abs()} dias',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
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
                    gradient: Layout05Theme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: Layout05Theme.neonShadow(Layout05Theme.primary),
                  ),
                  child: const Text(
                    'Pagar',
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

  Widget _buildPromoBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Layout05Theme.accent.withOpacity(0.15),
            Layout05Theme.accent.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Layout05Theme.accent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Layout05Theme.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: Layout05Theme.accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upgrade disponível!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Dobre sua velocidade por apenas +R\$ 20/mês',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Layout05Theme.accent,
            size: 18,
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
              color: Layout05Theme.surface.withOpacity(0.9),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Layout05Theme.primary.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          color: isSelected
                              ? Layout05Theme.primary
                              : Colors.white.withOpacity(0.5),
                          size: 24,
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Text(
                            item['label'] as String,
                            style: const TextStyle(
                              color: Layout05Theme.primary,
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

// Grid Pattern Painter
class _GridPatternPainter extends CustomPainter {
  final double animation;

  _GridPatternPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    final offset = animation * spacing;

    // Vertical lines
    for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = -spacing + offset;
        y < size.height + spacing;
        y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPatternPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
