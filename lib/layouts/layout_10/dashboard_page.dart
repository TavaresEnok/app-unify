import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'login_page.dart'; // To reuse MeshGradientPainter

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
  late AnimationController _meshController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _meshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _meshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.actionColor ?? Layout10Theme.primary(null);
    final secondaryColor = Layout10Theme.secondary(null);
    final bgColor = Layout10Theme.backgroundColor(null);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Mesh
          AnimatedBuilder(
            animation: _meshController,
            builder: (context, child) {
              return CustomPaint(
                painter: MeshGradientPainter(
                  animation: _meshController.value,
                  primary: primaryColor,
                  secondary: secondaryColor,
                ),
                size: Size.infinite,
              );
            },
          ),

          RefreshIndicator(
            onRefresh: widget.onRefresh ?? () async {},
            backgroundColor: Colors.white,
            color: primaryColor,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    centerTitle: false,
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, ${widget.customerName.split(' ').first}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded,
                          color: Colors.white),
                      onPressed: () => widget.onNavigate('notifications'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Glass Invoice Card
                      Layout10Theme.glassCard(
                        opacity: 0.15,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'FATURA EM ABERTO',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Pendente',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'R\$ ${widget.billAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => widget.onNavigate('invoices'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primaryColor,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text('VISUALIZAR FATURA'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Quick Actions Grid (Glass Icons)
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _buildGlassAction(
                              Icons.speed_rounded, 'Teste', 'speed_test'),
                          _buildGlassAction(
                              Icons.wifi_rounded, 'Wi-Fi', 'wifi'),
                          _buildGlassAction(
                              Icons.support_agent_rounded, 'Ajuda', 'support'),
                          _buildGlassAction(
                              Icons.receipt_long_rounded, 'Conta', 'invoices'),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Connection Status (Premium Glass)
                      Layout10Theme.glassCard(
                        opacity: 0.08,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.bolt_rounded,
                                      color: primaryColor, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.planName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Text(
                                        'Seu plano está ativo',
                                        style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatusInfo('Download',
                                    '${widget.downloadMbps.toStringAsFixed(0)}Mb'),
                                Container(
                                    width: 1,
                                    height: 20,
                                    color: Colors.white12),
                                _buildStatusInfo('Upload',
                                    '${widget.uploadMbps.toStringAsFixed(0)}Mb'),
                                Container(
                                    width: 1,
                                    height: 20,
                                    color: Colors.white12),
                                _buildStatusInfo('Status', 'Online'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Bottom Options
                      _buildGlassTile(Icons.shield_outlined,
                          'Segurança da Rede', 'security'),
                      _buildGlassTile(Icons.devices_other_rounded,
                          'Dispositivos Conectados', 'devices'),
                      _buildGlassTile(Icons.star_outline_rounded,
                          'Benefícios do Cliente', 'benefits'),

                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // Floating Bottom Navigation (Glass)
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Layout10Theme.glassCard(
              blur: 15,
              opacity: 0.15,
              padding: const EdgeInsets.symmetric(vertical: 8),
              borderRadius: BorderRadius.circular(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.dashboard_rounded),
                  _buildNavItem(1, Icons.wifi_password_rounded),
                  _buildNavItem(2, Icons.wallet_rounded),
                  _buildNavItem(3, Icons.person_outline_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassAction(IconData icon, String label, String route) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onNavigate(route);
          },
          child: Layout10Theme.glassCard(
            blur: 10,
            opacity: 0.1,
            padding: const EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(16),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
              color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStatusInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildGlassTile(IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () => widget.onNavigate(route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Layout10Theme.glassCard(
          opacity: 0.05,
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    final primaryColor = widget.actionColor ?? Layout10Theme.primary(null);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          color: isSelected ? primaryColor : Colors.white38,
          size: 26,
        ),
      ),
    );
  }
}
