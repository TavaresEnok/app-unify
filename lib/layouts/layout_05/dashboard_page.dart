// Layout 05 Dashboard - Cyber Neon Theme (Versão Completa)
// Design futurista com animações e todos os elementos premium

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
  int _selectedIndex = 0;
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
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildPlanCard(),
                      const SizedBox(height: 24),
                      _buildLiveStats(),
                      const SizedBox(height: 24),
                      _buildServiceStatus(),
                      const SizedBox(height: 24),
                      _buildDevices(),
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
                      Layout05Theme.primary.withValues(alpha: 0.08),
                      Colors.transparent
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
                      Layout05Theme.secondary.withValues(alpha: 0.06),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                  painter: _GridPatternPainter(_waveController.value)),
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
                        .withValues(alpha: 0.3 + _pulseController.value * 0.15),
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
                        letterSpacing: 0.5),
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
                            color: Layout05Theme.accent.withValues(alpha: 0.3),
                            blurRadius: 8)
                      ],
                    ),
                    child: const Text('ULTRA',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ),
                ],
              ),
              Text(
                'Fibra Óptica • ${widget.planName}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              ),
            ],
          ),
        ),
        _buildGlassBtn(
            Icons.support_agent_rounded, () => widget.onNavigate('suporte')),
        const SizedBox(width: 10),
        _buildGlassBtn(Icons.notifications_rounded,
            () => widget.onNavigate('notificacoes'),
            badge: 3),
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
                Icon(icon,
                    color: Colors.white.withValues(alpha: 0.9), size: 22),
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
                      child: Text('$badge',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
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
                  Stack(
                    alignment: Alignment.center,
                    children: [
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
                                    .withValues(alpha: (1 - progress) * 0.3),
                                width: 1.5),
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
                        child: const Icon(Icons.wifi_rounded,
                            color: Colors.white, size: 30),
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
                                boxShadow: Layout05Theme.glowShadow(isOnline
                                    ? Layout05Theme.success
                                    : Layout05Theme.error),
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
                            Text('Há 45 dias',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 11)),
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
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text('Última verificação: agora',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 4,
                  color: Colors.white.withValues(alpha: 0.1),
                  child: AnimatedBuilder(
                    animation: _dataFlowController,
                    builder: (context, _) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.3 + _dataFlowController.value * 0.7,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Layout05Theme.primary.withValues(alpha: 0),
                              Layout05Theme.primary
                            ]),
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

  Widget _buildQuickActions() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildAction('Roteador', Icons.router_rounded,
              Layout05Theme.secondary, 'wifi'),
          _buildAction('2ª Via', Icons.receipt_long_rounded,
              Layout05Theme.primary, 'financeiro'),
          _buildAction('Upgrade', Icons.rocket_launch_rounded,
              const Color(0xFFFF7043), 'planos'),
          _buildAction('Wi-Fi', Icons.wifi_password_rounded,
              Layout05Theme.success, 'wifi'),
          _buildAction('Suporte', Icons.support_agent_rounded,
              Layout05Theme.warning, 'suporte'),
        ],
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
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard() {
    final formattedDate =
        '${widget.billDueDate.day.toString().padLeft(2, '0')}/${widget.billDueDate.month.toString().padLeft(2, '0')}/${widget.billDueDate.year}';

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
              offset: const Offset(0, 12))
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
                  Text('Seu Plano',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(widget.planName.split(' ').first,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold)),
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
                    borderRadius: BorderRadius.circular(12)),
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
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Próxima Fatura',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                        'R\$ ${widget.billAmount.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    Text('Vencimento: $formattedDate',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11)),
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
                        borderRadius: BorderRadius.circular(14)),
                    child: const Text('Pagar',
                        style: TextStyle(
                            color: Color(0xFF7C4DFF),
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
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
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
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
                Layout05Theme.primary)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard(
                'Upload',
                '${widget.uploadMbps.toStringAsFixed(0)} Mbps',
                Icons.arrow_upward_rounded,
                Layout05Theme.success)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard('Ping', '3 ms', Icons.network_ping_rounded,
                Layout05Theme.warning)),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildServiceStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status dos Serviços',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildStatusCard('Internet', 'Operacional',
                    Icons.public_rounded, Layout05Theme.success, true)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatusCard('TV', 'Operacional', Icons.tv_rounded,
                    Layout05Theme.success, true)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatusCard('Telefone', 'Manutenção',
                    Icons.phone_rounded, Layout05Theme.warning, false)),
          ],
        ),
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
                borderRadius: BorderRadius.circular(6)),
            child: Text(status,
                style: TextStyle(
                    color: color, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDevices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Dispositivos',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Layout05Theme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('8 ativos',
                  style: TextStyle(
                      color: Layout05Theme.success,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 95,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildDevice('iPhone', Icons.phone_iphone_rounded, '12 MB/s'),
              _buildDevice('MacBook', Icons.laptop_mac_rounded, '45 MB/s'),
              _buildDevice('Smart TV', Icons.tv_rounded, '8 MB/s'),
              _buildDevice('PS5', Icons.gamepad_rounded, '25 MB/s'),
              _buildDevice('Alexa', Icons.speaker_rounded, '1 MB/s'),
              _buildDevice('iPad', Icons.tablet_mac_rounded, '5 MB/s'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDevice(String name, IconData icon, String speed) {
    return Container(
      width: 85,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Layout05Theme.primary, size: 26),
          const SizedBox(height: 8),
          Text(name,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(speed,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
        ],
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
              color: Layout05Theme.background.withValues(alpha: 0.92),
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
              ? Layout05Theme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected
                    ? Layout05Theme.primary
                    : Colors.white.withValues(alpha: 0.35),
                size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Layout05Theme.primary
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
              gradient: Layout05Theme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Layout05Theme.primary
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

class _GridPatternPainter extends CustomPainter {
  final double animation;
  _GridPatternPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    final offset = animation * spacing;

    for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = -spacing + offset;
        y < size.height + spacing;
        y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPatternPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
