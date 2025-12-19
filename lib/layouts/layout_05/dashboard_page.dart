import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

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

class _ProviderDashboardPageState extends State<ProviderDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.actionColor ?? Layout09Theme.primary(null);
    const bgColor = Layout09Theme.background;

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: widget.onRefresh ?? () async {},
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header Orgânico (Blob)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 240,
                child: Stack(
                  children: [
                    // Fundo curvo (Blob)
                    Positioned(
                      top: -100,
                      left: -50,
                      right: -50,
                      child: Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.elliptical(300, 100),
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Bem-vindo,',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 16),
                                    ),
                                    Text(
                                      widget.customerName.split(' ').first,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                        Icons.notifications_none_rounded,
                                        color: Colors.white),
                                    onPressed: () =>
                                        widget.onNavigate('notifications'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Card de Fatura Flutuante
                    Positioned(
                      bottom: 0,
                      left: 24,
                      right: 24,
                      child: Container(
                        decoration: Layout09Theme.organicDecoration(
                          color: widget.invoiceColor ?? Colors.white,
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Próxima Fatura',
                                    style: TextStyle(
                                      color: (widget.invoiceColor != null)
                                          ? Colors.white70
                                          : Colors.blueGrey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'R\$ ${widget.billAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: (widget.invoiceColor != null)
                                          ? Colors.white
                                          : const Color(0xFF2C3E50),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => widget.onNavigate('invoices'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (widget.invoiceColor != null)
                                    ? Colors.white
                                    : primaryColor,
                                foregroundColor: (widget.invoiceColor != null)
                                    ? primaryColor
                                    : Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('PAGAR'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Ações Rápidas (Pills)
                  const Text(
                    'SERVIÇOS RÁPIDOS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildPillAction(Icons.speed_rounded, 'Teste',
                            'speed_test', primaryColor),
                        _buildPillAction(Icons.wifi_rounded, 'Wi-Fi', 'wifi',
                            const Color(0xFF8E44AD)),
                        _buildPillAction(Icons.support_agent_rounded, 'Suporte',
                            'support', const Color(0xFFE67E22)),
                        _buildPillAction(Icons.history_rounded, 'Histórico',
                            'invoices', const Color(0xFF1ABC9C)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Status de Conexão (Organic Card)
                  Container(
                    decoration: Layout09Theme.organicDecoration(
                      color: primaryColor.withValues(alpha: 0.05),
                      showShadow: false,
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: primaryColor.withValues(alpha: 0.1)),
                              ),
                              child: Icon(Icons.check_circle_rounded,
                                  color: primaryColor),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Conexão Ativa',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                  Text(
                                    widget.planName,
                                    style: const TextStyle(
                                        color: Colors.blueGrey, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Uso de Dados
                        LinearProgressIndicator(
                          value: widget.usedGb /
                              (widget.totalGb > 0 ? widget.totalGb : 1),
                          backgroundColor: Colors.white,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(primaryColor),
                          borderRadius: BorderRadius.circular(10),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                '${widget.usedGb.toStringAsFixed(1)} GB usados',
                                style: const TextStyle(fontSize: 12)),
                            Text(
                                'Limite: ${widget.totalGb.toStringAsFixed(0)} GB',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Lista de Atalhos
                  _buildOrganicTile(Icons.analytics_outlined,
                      'Diagnóstico de Rede', 'network_diagnostic'),
                  _buildOrganicTile(
                      Icons.description_outlined, 'Meu Contrato', 'contract'),
                  _buildOrganicTile(
                      Icons.help_outline_rounded, 'Dúvidas Frequentes', 'faq'),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildOrganicNavBar(primaryColor),
    );
  }

  Widget _buildPillAction(
      IconData icon, String label, String route, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onNavigate(route);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganicTile(IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () => widget.onNavigate(route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Layout09Theme.background,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF2C3E50), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.blueGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganicNavBar(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.grid_view_rounded, primaryColor),
          _buildNavItem(1, Icons.wifi_rounded, primaryColor),
          _buildNavItem(2, Icons.receipt_long_rounded, primaryColor),
          _buildNavItem(3, Icons.person_rounded, primaryColor),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, Color primaryColor) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedIndex = index);
        // Implement navigation logic same as other layouts
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.blueGrey,
        ),
      ),
    );
  }
}
