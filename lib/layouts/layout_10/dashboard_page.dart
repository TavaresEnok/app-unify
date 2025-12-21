import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Layout10DashboardPage extends StatefulWidget {
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

  const Layout10DashboardPage({
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
  State<Layout10DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<Layout10DashboardPage> {
  int _currentNavIndex = 0;

  // Cyberpunk Color Palette
  static const Color _bgDark = Color(0xFF050A14);
  static const Color _cardBg = Color(0xFF131B2C);
  static const Color _neonCyan = Color(0xFF00F3FF);
  static const Color _neonPink = Color(0xFFBC13FE);
  static const Color _textWhite = Colors.white;
  static const Color _textGray = Color(0xFF8A9BB8);

  @override
  Widget build(BuildContext context) {
    final remainingDays = widget.billDueDate.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          // Background Grid Effect (Optional)
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(),
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
                  backgroundColor: _cardBg,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(context),

                        const SizedBox(height: 32),

                        // Balance / Bill Card (Cyberpunk Style)
                        _buildBalanceCard(remainingDays),

                        const SizedBox(height: 24),

                        // Quick Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQuickAction(Icons.receipt_long_rounded,
                                'Faturas', 'invoices', _neonCyan),
                            _buildQuickAction(Icons.speed_rounded, 'Velocidade',
                                'speed_test', _neonPink),
                            _buildQuickAction(Icons.support_agent_rounded,
                                'Suporte', 'support', _neonCyan),
                            _buildQuickAction(
                                Icons.wifi_rounded, 'Wi-Fi', 'wifi', _neonPink),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Plan Details (Holo Card)
                        _buildPlanCard(),

                        const SizedBox(height: 32),

                        // Services Title
                        const Text(
                          'DIAGNÓSTICO & SERVIÇOS',
                          style: TextStyle(
                            color: _textGray,
                            fontSize: 12,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Services List
                        _buildServiceItem(
                            Icons.analytics_rounded,
                            'Diagnóstico Rede',
                            'Verificar stauts da conexão',
                            'network_diagnostic'),
                        _buildServiceItem(Icons.route_rounded, 'Traceroute',
                            'Rastrear rota de pacotes', 'trace_route',
                            color: _neonPink),
                        _buildServiceItem(Icons.data_usage_rounded, 'Consumo',
                            'Histórico de uso de dados', 'internet_usage'),
                        _buildServiceItem(Icons.public_rounded, 'Meu IP',
                            'Visualizar endereço IP', 'my_ip',
                            color: _neonPink),
                        _buildServiceItem(Icons.description_rounded, 'Contrato',
                            'Termos de serviço', 'contract'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom Nav
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _neonCyan.withOpacity(0.3)),
                ),
                child: const Icon(Icons.menu_rounded, color: _neonCyan),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BEM-VINDO,',
                  style: TextStyle(
                    color: _textGray,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.customerName.split(' ').first.toUpperCase(),
                  style: const TextStyle(
                    color: _textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(2), // Gradient border trick
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_neonCyan, _neonPink]),
            shape: BoxShape.circle,
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: _bgDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: _textWhite, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(int remainingDays) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _neonPink.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: _neonPink.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.bolt_rounded,
              size: 150,
              color: _neonPink.withOpacity(0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'FATURA ATUAL',
                      style: TextStyle(
                        color: _textGray,
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _neonCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _neonCyan.withOpacity(0.5)),
                      ),
                      child: Text(
                        widget.connectionStatus.toUpperCase(),
                        style: const TextStyle(
                          color: _neonCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'R\$ ${widget.billAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _textWhite,
                    fontSize: 42,
                    fontFamily: 'Roboto', // Or relevant monospace
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    shadows: [
                      Shadow(
                        color: _neonPink,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 14, color: _textGray),
                    const SizedBox(width: 8),
                    Text(
                      remainingDays >= 0
                          ? 'Vence em $remainingDays dias'
                          : 'Vencida há ${remainingDays.abs()} dias',
                      style: TextStyle(
                        color: remainingDays < 0 ? _neonPink : _textGray,
                        fontSize: 14,
                        fontWeight: remainingDays < 0
                            ? FontWeight.bold
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _bgDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accentColor.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.15),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: _textGray,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard() {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [_neonCyan, Colors.transparent, _neonPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg.withOpacity(0.95),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _neonCyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.router_outlined, color: _neonCyan),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.planName,
                    style: const TextStyle(
                      color: _textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.download_rounded, size: 14, color: _textGray),
                      Text('${widget.downloadMbps.toInt()} Mb',
                          style:
                              const TextStyle(color: _textGray, fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.upload_rounded, size: 14, color: _textGray),
                      Text('${widget.uploadMbps.toInt()} Mb',
                          style:
                              const TextStyle(color: _textGray, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _neonPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('PRO',
                  style: TextStyle(
                      color: _neonPink,
                      fontWeight: FontWeight.bold,
                      fontSize: 10)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(
      IconData icon, String title, String subtitle, String route,
      {Color color = _neonCyan}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onNavigate(route);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color.withOpacity(0.8), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _textWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _textGray.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _textGray),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: _bgDark.withOpacity(0.9),
        border: Border(top: BorderSide(color: _neonCyan.withOpacity(0.2))),
        boxShadow: const [
          BoxShadow(
              color: Colors.black54, blurRadius: 20, offset: Offset(0, -5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_filled, 0),
          _buildNavItem(Icons.wifi, 1),
          _buildNavItem(Icons.receipt_long, 2),
          _buildNavItem(Icons.headset_mic, 3),
          _buildNavItem(Icons.person, 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
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
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: isSelected
            ? BoxDecoration(
                color: _neonCyan.withOpacity(0.1),
                shape: BoxShape.circle,
              )
            : null,
        child: Icon(
          icon,
          color: isSelected ? _neonCyan : _textGray,
          size: 26,
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    const spacing = 40.0;

    for (var i = 0.0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (var i = 0.0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
