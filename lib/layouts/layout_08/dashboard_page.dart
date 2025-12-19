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
  @override
  Widget build(BuildContext context) {
    final remainingDays = widget.billDueDate.difference(DateTime.now()).inDays;
    final primaryColor = widget.actionColor ?? Layout08Theme.primary(null);
    final secondaryColor = Layout08Theme.secondary(null);

    return Scaffold(
      backgroundColor: Layout08Theme.background,
      body: RefreshIndicator(
        onRefresh: widget.onRefresh ?? () async {},
        child: CustomScrollView(
          slivers: [
            // AppBar Neubrutalista
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 120,
              backgroundColor: Layout08Theme.background,
              elevation: 0,
              shape: const Border(
                  bottom: BorderSide(color: Colors.black, width: 3)),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'OLÁ, ${widget.customerName.split(' ').first.toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_active_outlined,
                      color: Colors.black),
                  onPressed: () => widget.onNavigate('notifications'),
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Card de Fatura - Neubrutalismo Puro
                  Container(
                    decoration: Layout08Theme.neubrutalismDecoration(
                      color: widget.invoiceColor ?? primaryColor,
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VALOR_DA_FATURA',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'R\$ ${widget.billAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                          ),
                          child: Text(
                            remainingDays >= 0
                                ? 'VENCE EM $remainingDays DIAS'
                                : 'VENCIDA HÁ ${remainingDays.abs()} DIAS',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Grid de Ações Rápidas
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          Icons.receipt_long,
                          'FATURAS',
                          'invoices',
                          secondaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildQuickAction(
                          Icons.speed,
                          'TESTAR',
                          'speed_test',
                          const Color(0xFFADFF2F), // Lime
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          Icons.support_agent,
                          'SUPORTE',
                          'support',
                          const Color(0xFF00FFFF), // Cyan
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildQuickAction(
                          Icons.wifi,
                          'WI-FI',
                          'wifi',
                          const Color(0xFFFFA500), // Orange
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Status de Conexão Estilo Terminal
                  Container(
                    decoration: Layout08Theme.neubrutalismDecoration(
                      color: Colors.black,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.circle,
                                color: Color(0xFFADFF2F), size: 12),
                            SizedBox(width: 8),
                            Text(
                              'SISTEMA_ATIVO',
                              style: TextStyle(
                                color: Color(0xFFADFF2F),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'PLANO: ${widget.planName.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Lista de Outros Serviços
                  const Text(
                    'MAIS_OPÇÕES',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  _buildServiceItem('diagnóstico', 'network_diagnostic'),
                  _buildServiceItem('consumo', 'internet_usage'),
                  _buildServiceItem('contrato', 'contract'),
                  _buildServiceItem('faq', 'faq'),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
      IconData icon, String label, String route, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        widget.onNavigate(route);
      },
      child: Container(
        height: 120,
        decoration: Layout08Theme.neubrutalismDecoration(color: color),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(String label, String route) {
    return GestureDetector(
      onTap: () => widget.onNavigate(route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: Layout08Theme.neubrutalismDecoration(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const Icon(Icons.arrow_forward, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
