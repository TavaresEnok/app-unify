import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

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

  // Cyberpunk-Neon Color Palette
  static const Color _deepSpace = Color(0xFF0A0A0F);
  static const Color _voidBlack = Color(0xFF050508);
  static const Color _darkPurple = Color(0xFF1A0A2E);
  
  static const Color _neonCyan = Color(0xFF00FFFF);
  static const Color _neonMagenta = Color(0xFFFF00FF);
  static const Color _neonYellow = Color(0xFFFFFF00);
  static const Color _neonGreen = Color(0xFF00FF00);
  
  static const Color _glassCyan = Color(0x1A00FFFF);
  static const Color _glassMagenta = Color(0x1AFF00FF);
  static const Color _glassSurface = Color(0x0DFFFFFF);
  
  static const Color _textPrimary = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFFB0B0C0);
  static const Color _textNeon = Color(0xFF00FFFF);

  @override
  Widget build(BuildContext context) {
    final remainingDays = widget.billDueDate.difference(DateTime.now()).inDays;
    final isOverdue = remainingDays < 0;

    return Scaffold(
      backgroundColor: _deepSpace,
      body: Stack(
        children: [
          // Animated Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: CyberGridPainter(),
            ),
          ),

          // Scan Lines Effect
          Positioned.fill(
            child: CustomPaint(
              painter: ScanLinesPainter(),
            ),
          ),

          Column(
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
                  color: _neonCyan,
                  backgroundColor: _voidBlack,
                  displacement: 40,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 50, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with Glass Effect
                        _buildHeader(context),

                        const SizedBox(height: 24),

                        // Cyber Balance Card
                        _buildBalanceCard(remainingDays, isOverdue),

                        const SizedBox(height: 20),

                        // Quick Actions Grid
                        _buildQuickActionsGrid(),

                        const SizedBox(height: 24),

                        // Plan Details Card
                        _buildPlanCard(),

                        const SizedBox(height: 24),

                        // Services Section
                        _buildServicesSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _neonCyan.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _neonCyan.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _voidBlack,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _neonCyan, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: _neonCyan.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.menu_rounded, color: _neonCyan, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BEM-VINDO,',
                      style: TextStyle(
                        color: _textSecondary.withOpacity(0.8),
                        fontSize: 10,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.customerName.split(' ').first.toUpperCase(),
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_neonCyan, _neonMagenta],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _neonCyan.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: _voidBlack,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  children: [
                    const Icon(Icons.notifications_none_rounded,
                        color: _textPrimary, size: 18),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _neonMagenta,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _neonMagenta.withOpacity(0.8),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(int remainingDays, bool isOverdue) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverdue ? _neonMagenta : _neonCyan,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isOverdue ? _neonMagenta : _neonCyan).withOpacity(0.3),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Stack(
          children: [
            // Holographic Effect
            Positioned(
              right: -30,
              top: -30,
              child: Icon(
                Icons.bolt_rounded,
                size: 120,
                color: (isOverdue ? _neonMagenta : _neonCyan).withOpacity(0.08),
              ),
            ),
            // Scan Line Overlay
            Positioned.fill(
              child: CustomPaint(
                painter: HologramLinesPainter(
                  color: (isOverdue ? _neonMagenta : _neonCyan).withOpacity(0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _voidBlack,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _textSecondary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'FATURA ATUAL',
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 10,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: (isOverdue ? _neonMagenta : _neonCyan).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (isOverdue ? _neonMagenta : _neonCyan),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isOverdue ? _neonMagenta : _neonCyan).withOpacity(0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          widget.connectionStatus.toUpperCase(),
                          style: TextStyle(
                            color: isOverdue ? _neonMagenta : _neonCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        'R\$',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.billAmount.toStringAsFixed(2),
                        style: TextStyle(
                          color: isOverdue ? _neonMagenta : _textPrimary,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'JetBrains Mono',
                          letterSpacing: -1,
                          shadows: [
                            Shadow(
                              color: (isOverdue ? _neonMagenta : _neonCyan).withOpacity(0.6),
                              blurRadius: 12,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: isOverdue ? _neonMagenta : _textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        remainingDays >= 0
                            ? 'Vence em $remainingDays dias'
                            : 'Vencida há ${remainingDays.abs()} dias',
                        style: TextStyle(
                          color: isOverdue ? _neonMagenta : _textSecondary,
                          fontSize: 14,
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.w500,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _neonMagenta.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ATENÇÃO',
                            style: TextStyle(
                              color: _neonMagenta,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildQuickAction(
          Icons.receipt_long_rounded,
          'Faturas',
          'invoices',
          _neonCyan,
        ),
        _buildQuickAction(
          Icons.speed_rounded,
          'Velocidade',
          'speed_test',
          _neonMagenta,
        ),
        _buildQuickAction(
          Icons.support_agent_rounded,
          'Suporte',
          'support',
          _neonCyan,
        ),
        _buildQuickAction(
          Icons.wifi_rounded,
          'Wi-Fi',
          'wifi',
          _neonMagenta,
        ),
      ],
    );
  }

  Widget _buildQuickAction(
      IconData icon, String label, String route, Color accentColor) {
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
              color: _voidBlack,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 26,
              shadows: [
                Shadow(
                  color: accentColor.withOpacity(0.8),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [_neonCyan, _neonMagenta],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: _neonCyan.withOpacity(0.3),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _glassSurface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _glassCyan, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _glassCyan,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _neonCyan.withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.router_outlined, color: _neonCyan, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.planName,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.download_rounded, size: 14, color: _neonCyan),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.downloadMbps.toInt()} Mb',
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Icon(Icons.upload_rounded, size: 14, color: _neonMagenta),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.uploadMbps.toInt()} Mb',
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _neonMagenta.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _neonMagenta, width: 1),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(
                  color: _neonMagenta,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  fontFamily: 'JetBrains Mono',
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _voidBlack,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _textSecondary.withOpacity(0.2), width: 1),
          ),
          child: const Text(
            'DIAGNÓSTICO & SERVIÇOS',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 11,
              letterSpacing: 2.5,
              fontWeight: FontWeight.bold,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildServiceItem(
          Icons.analytics_rounded,
          'Diagnóstico Rede',
          'Verificar status da conexão',
          'network_diagnostic',
          _neonCyan,
        ),
        _buildServiceItem(
          Icons.route_rounded,
          'Traceroute',
          'Rastrear rota de pacotes',
          'trace_route',
          _neonMagenta,
        ),
        _buildServiceItem(
          Icons.data_usage_rounded,
          'Consumo',
          'Histórico de uso de dados',
          'internet_usage',
          _neonCyan,
        ),
        _buildServiceItem(
          Icons.public_rounded,
          'Meu IP',
          'Visualizar endereço IP',
          'my_ip',
          _neonMagenta,
        ),
        _buildServiceItem(
          Icons.description_rounded,
          'Contrato',
          'Termos de serviço',
          'contract',
          _neonCyan,
        ),
      ],
    );
  }

  Widget _buildServiceItem(
      IconData icon, String title, String subtitle, String route, Color accentColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onNavigate(route);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: accentColor, width: 3),
            right: BorderSide(color: _textSecondary.withValues(alpha: 0.1), width: 1),
            top: BorderSide(color: _textSecondary.withValues(alpha: 0.1), width: 1),
            bottom: BorderSide(color: _textSecondary.withValues(alpha: 0.1), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _textSecondary.withOpacity(0.7),
                      fontSize: 11,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: accentColor.withOpacity(0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: _voidBlack.withOpacity(0.95),
        border: Border(top: BorderSide(color: _neonCyan.withOpacity(0.3), width: 1)),
        boxShadow: [
          BoxShadow(
            color: _neonCyan.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_filled, 0, _neonCyan),
            _buildNavItem(Icons.wifi, 1, _neonMagenta),
            _buildNavItem(Icons.receipt_long, 2, _neonCyan),
            _buildNavItem(Icons.headset_mic, 3, _neonMagenta),
            _buildNavItem(Icons.person, 4, _neonCyan),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, Color accentColor) {
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
            widget.onNavigate('support');
            break;
          case 4:
            Scaffold.of(context).openDrawer();
            break;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: isSelected
            ? BoxDecoration(
                color: accentColor.withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(color: accentColor, width: 1.5),
              )
            : null,
        child: Icon(
          icon,
          color: isSelected ? accentColor : _textSecondary,
          size: isSelected ? 28 : 24,
          shadows: isSelected
              ? [
                  Shadow(
                    color: accentColor.withOpacity(0.8),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

// Cyber Grid Background Painter
class CyberGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.03)
      ..strokeWidth = 1;

    const spacing = 40.0;

    // Vertical lines
    for (var i = 0.0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Horizontal lines
    for (var i = 0.0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Diagonal lines (subtle)
    final diagPaint = Paint()
      ..color = const Color(0xFFFF00FF).withOpacity(0.02)
      ..strokeWidth = 0.5;

    for (var i = -size.height; i < size.width; i += spacing * 2) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), diagPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Scan Lines Painter
class ScanLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.02)
      ..strokeWidth = 1;

    const spacing = 4.0;

    for (var i = 0.0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Hologram Lines Painter
class HologramLinesPainter extends CustomPainter {
  final Color color;

  HologramLinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const spacing = 8.0;

    for (var i = 0.0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant HologramLinesPainter oldDelegate) => oldDelegate.color != color;
}