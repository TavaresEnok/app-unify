import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    // Cores do tema (adaptadas para parecer com o backup mas usando o tema atual)
    final primaryColor = invoiceColor ?? const Color(0xFF673AB7);
    final secondaryColor = actionColor ?? const Color(0xFF9575CD);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF), // Cor de fundo do backup
      body: Stack(
        children: [
          _buildHeader(context, primaryColor, secondaryColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 160.0, 16.0, 0),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildStatusCard(context, primaryColor),
                const SizedBox(height: 16),
                _buildInvoiceSection(context, primaryColor, secondaryColor),
                const SizedBox(height: 16),
                _buildServiceGrid(context, primaryColor),
                const SizedBox(height: 16),
                // Botão de Diagnóstico (Restaurado do backup)
                _buildDiagnosticoButton(context, primaryColor),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, Color primaryColor, Color secondaryColor) {
    return Container(
      // height: 200, // Removendo altura fixa para evitar overflow
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  // Espaço para notificações se necessário
                ],
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, ${customerName.toUpperCase()}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        planName,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildStatusCard(BuildContext context, Color primaryColor) {
    final isConnected = connectionStatus.toLowerCase() == 'ativo' ||
        connectionStatus.toLowerCase() == 'conectado';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? primaryColor.withOpacity(0.15)
                        : Colors.red.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                      isConnected ? Icons.check : Icons.warning_amber_rounded,
                      color: isConnected ? primaryColor : Colors.red,
                      size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isConnected ? 'Tudo certo' : 'Atenção',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937)),
                    ),
                    Text(
                      isConnected ? 'com seu plano!' : 'Verifique sua conexão',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFF6B7280)),
                    )
                  ],
                )
              ],
            ),
            const VerticalDivider(color: Color(0xFFE0E0E0), thickness: 1),
            InkWell(
              onTap: () => onNavigate('contract'),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined,
                      color: Colors.grey, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Contrato\nAtivo',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        height: 1.2,
                        fontSize: 12),
                  )
                ],
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onNavigate('invoices'),
            child: Container(
              padding: const EdgeInsets.all(16),
              height: 124,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06), blurRadius: 15)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Última fatura',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                            fontSize: 12),
                      ),
                      Text(
                        'Vence em $formattedDate',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: const Color(0xFF9CA3AF)),
                      )
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedValue,
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1F2937)),
                      ),
                      Text(
                        'Ver faturas',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                            fontSize: 12),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _buildActionButton(
                label: 'Pagar\nfatura',
                icon: Icons.credit_card,
                color: primaryColor,
                onTap: () => onNavigate('invoices'),
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                label: 'Prometer\npagamento',
                icon: FontAwesomeIcons.lockOpen,
                color: secondaryColor,
                onTap: () => onNavigate('promessa_pagamento'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    fontSize: 12),
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceGrid(BuildContext context, Color primaryColor) {
    // Itens padrão se não vierem do menuItems
    final defaultItems = [
      {'id': 'speed_test', 'label': 'Velocidade', 'icon': Icons.speed_rounded},
      {
        'id': 'internet_usage',
        'label': 'Consumo',
        'icon': Icons.data_usage_rounded
      },
      {
        'id': 'support',
        'label': 'Suporte',
        'icon': Icons.support_agent_rounded
      },
      {'id': 'my_ip', 'label': 'Meu IP', 'icon': Icons.public},
      {'id': 'dicas', 'label': 'Dicas', 'icon': Icons.lightbulb_outline},
      {'id': 'status_servicos', 'label': 'Status', 'icon': Icons.network_check},
    ];

    final itemsToDisplay = menuItems ?? defaultItems;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: itemsToDisplay.length,
      itemBuilder: (context, index) {
        final item = itemsToDisplay[index];
        return _buildServiceItem(
          label: item['label'] ?? '',
          icon: item['icon'] ?? Icons.circle,
          iconColor: primaryColor,
          onTap: () => onNavigate(item['id'] ?? ''),
        );
      },
    );
  }

  Widget _buildServiceItem({
    required String label,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFF4B5563),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosticoButton(BuildContext context, Color primaryColor) {
    return Material(
      color: primaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onNavigate('network_diagnostic'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.build_circle_outlined, color: primaryColor, size: 22),
              const SizedBox(width: 12),
              Text(
                'Diagnóstico de Rede',
                style: GoogleFonts.inter(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
