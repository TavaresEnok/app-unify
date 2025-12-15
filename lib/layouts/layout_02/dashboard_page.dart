import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:intl/intl.dart';

typedef NavigateToPageCallback = void Function(String pageId);

class ProviderDashboardPage extends StatelessWidget {
  final String customerName, planName, connectionStatus;
  final double billAmount, usedGb, totalGb, downloadMbps, uploadMbps;
  final DateTime billDueDate;
  final NavigateToPageCallback onNavigate;
  final List<Map<String, dynamic>>? menuItems;

  // CORES PERSONALIZADAS
  final Color? customCardBg;
  final Color? customCardText;
  final Color? invoiceColor;
  final Color? actionColor;

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
  });

  @override
  Widget build(BuildContext context) {
    // Cores (roxo padrão recuperado ou customizado)
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = const Color(0xFF0EA5E9);

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          FadeInUp(
            child: _buildWelcomeSection(context, primaryColor, secondaryColor),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: _buildStatusCard(context, primaryColor),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _buildInvoiceSection(
                      context, primaryColor, secondaryColor),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: _buildServiceGrid(context, primaryColor),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: _buildDiagnosticoButton(context, primaryColor),
                ),
                const SizedBox(height: 180), // Footer spacer
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(
      BuildContext context, Color primaryColor, Color secondaryColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF673AB7), // Deep Purple
            const Color(0xFF512DA8), // Darker Purple
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        // Use SafeArea to respect StatusBar
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Menu and Notification
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu_rounded,
                        color: Colors.white, size: 28),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: Colors.white, size: 26),
                    onPressed: () => onNavigate('notifications'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Mensagem de boas vindas
              Text(
                'Bem-vindo(a),',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                customerName,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Badge do Plano
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      planName,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Remainder of _buildStatusCard and others remains similar but tweaked styles if needed)
  // Keeping logic identical but ensuring context usage works.

  Widget _buildStatusCard(BuildContext context, Color primaryColor) {
    final isConnected = connectionStatus.toLowerCase() == 'ativo' ||
        connectionStatus.toLowerCase() == 'conectado';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF673AB7).withOpacity(0.08), // Colored shadow
            blurRadius: 25,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? const Color(0xFF4CAF50).withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                      isConnected
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      color: isConnected ? const Color(0xFF4CAF50) : Colors.red,
                      size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isConnected ? 'Conectado' : 'Desconectado',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF1F2937)),
                    ),
                    Text(
                      isConnected ? 'Status Online' : 'Verifique sua rede',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF6B7280)),
                    )
                  ],
                )
              ],
            ),
            // No vertical divider, cleaner look
            Container(
              height: 40,
              width: 1,
              color: Colors.grey.shade100,
            ),
            InkWell(
              onTap: () => onNavigate('contract'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description_outlined,
                        color: Colors.grey[400], size: 22),
                    const SizedBox(height: 4),
                    Text(
                      'Contrato',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                          fontSize: 10),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceSection(
      BuildContext context, Color primaryColor, Color secondaryColor) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formattedValue = currencyFormat.format(billAmount);
    final formattedDate = DateFormat('dd/MM').format(billDueDate);

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            )
          ]),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fatura Atual',
                      style: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(formattedValue,
                      style: GoogleFonts.inter(
                          color: Colors.black87,
                          fontSize: 28,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('Vence em',
                        style: GoogleFonts.inter(
                            color: primaryColor.withOpacity(0.7),
                            fontSize: 10)),
                    Text(formattedDate,
                        style: GoogleFonts.inter(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onNavigate('invoices'),
                  icon: const Icon(Icons.pix, size: 18),
                  label: const Text('Pagar Pix'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onNavigate('invoices'),
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('Faturas'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(
                        color: primaryColor.withOpacity(0.2), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Keeping _buildActionButton for potential reuse or removal if unused.
  // Looks like it was used in previous layout, replaced by buttons inside InvoiceSection above.

  Widget _buildServiceGrid(BuildContext context, Color primaryColor) {
    return Column(
      children: [
        Row(
          children: [
            _buildServiceItem('speed_test', 'Velocidade', Icons.speed,
                Colors.purple.shade50, Colors.purple),
            const SizedBox(width: 12),
            _buildServiceItem('internet_usage', 'Consumo', Icons.data_usage,
                Colors.blue.shade50, Colors.blue),
            const SizedBox(width: 12),
            _buildServiceItem('support', 'Suporte', Icons.support_agent,
                Colors.orange.shade50, Colors.orange),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildServiceItem('my_ip', 'Meu IP', Icons.public,
                Colors.cyan.shade50, Colors.cyan),
            const SizedBox(width: 12),
            _buildServiceItem('faq', 'Dicas', Icons.lightbulb_outline,
                Colors.yellow.shade50, Colors.orangeAccent),
            const SizedBox(width: 12),
            _buildServiceItem('network_diagnostic', 'Conexão',
                Icons.wifi_tethering, Colors.green.shade50, Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceItem(String pageId, String label, IconData icon,
      Color bgColor, Color iconColor) {
    return Expanded(
      child: InkWell(
        onTap: () => onNavigate(pageId),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosticoButton(BuildContext context, Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => onNavigate('network_diagnostic'),
        icon: const Icon(Icons.build, size: 20),
        label: const Text('Rodar Diagnóstico Completo'),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: primaryColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: primaryColor.withOpacity(0.2)))),
      ),
    );
  }
}

class FadeInUp extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const FadeInUp({super.key, required this.child, this.delay = Duration.zero});

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _translate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _translate =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _translate,
        child: widget.child,
      ),
    );
  }
}
