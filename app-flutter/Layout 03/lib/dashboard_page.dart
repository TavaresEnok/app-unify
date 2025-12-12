import 'package:flutter/material.dart';
import 'package:layout01/shared/widgets/premium_invoice_card.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final Color?
      actionColor; // NOVO: Cor para botões de ação (Testar, Diagnóstico)

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
    final firstName = customerName.split(' ')[0];
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;

    final cardBg = customCardBg ?? textColor.withOpacity(0.08);
    final cardText = customCardText ?? textColor;
    // Se não tiver actionColor, usa preto como fallback para o botão "Testar"
    final buttonColor = actionColor ?? Colors.black;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        title: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Olá, $firstName',
                  style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: textColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(planName,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                  ),
                  const SizedBox(width: 8),
                  _SimpleStatusBadge(
                      status: connectionStatus, textColor: textColor),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24, top: 10),
            child: Container(
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => onNavigate('notifications'),
                icon: Icon(Icons.notifications_none_rounded, color: textColor),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
        children: [
          PremiumInvoiceCard(
            amount: billAmount,
            dueDate: billDueDate,
            onPay: () => onNavigate('invoices'),
            customColor: invoiceColor,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.speed_rounded,
                      color: Color(0xFF0EA5E9), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Minha Velocidade',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Text('${downloadMbps.toInt()} Mega',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => onNavigate('speed_test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        buttonColor, // <--- APLICANDO A COR DO BOTÃO AQUI
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Testar'),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Acesso Rápido',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
              const SizedBox(height: 16),
              _CleanActionsRow(
                onNavigate: onNavigate,
                textColor: textColor,
                menuItems: menuItems,
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () => onNavigate('network_diagnostic'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cardText.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      // Se tiver actionColor, usa ela no ícone, senão usa o cardText ou Amarelo padrão
                      Icon(Icons.build_circle_outlined,
                          color: actionColor ??
                              customCardText ??
                              const Color(0xFFFBBC05),
                          size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Problemas técnicos?',
                              style: GoogleFonts.inter(
                                  color: cardText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          Text('Iniciar auto-diagnóstico da rede.',
                              style: GoogleFonts.inter(
                                  color: cardText.withOpacity(0.7),
                                  fontSize: 12)),
                        ],
                      )),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: cardText.withOpacity(0.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimpleStatusBadge extends StatelessWidget {
  final String status;
  final Color textColor;
  const _SimpleStatusBadge({required this.status, required this.textColor});
  @override
  Widget build(BuildContext context) {
    final isConnected =
        status.toLowerCase() == 'ativo' || status.toLowerCase() == 'conectado';
    final bgColor = isConnected
        ? textColor.withOpacity(0.15)
        : Colors.red.withOpacity(0.15);
    final badgeColor = isConnected ? textColor : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isConnected ? Icons.wifi : Icons.wifi_off,
              color: badgeColor, size: 12),
          const SizedBox(width: 4),
          Text(status,
              style: GoogleFonts.inter(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

class _CleanActionsRow extends StatelessWidget {
  final NavigateToPageCallback onNavigate;
  final Color textColor;
  final List<Map<String, dynamic>>? menuItems;

  const _CleanActionsRow(
      {required this.onNavigate, required this.textColor, this.menuItems});

  @override
  Widget build(BuildContext context) {
    final actions = menuItems ??
        [
          {
            'id': 'invoices',
            'icon': Icons.receipt_long_rounded,
            'label': 'Faturas',
            'color': const Color(0xFF1E6FF8)
          },
          {
            'id': 'support',
            'icon': Icons.support_agent_rounded,
            'label': 'Suporte',
            'color': const Color(0xFF10B981)
          },
          {
            'id': 'contract',
            'icon': Icons.description_rounded,
            'label': 'Contrato',
            'color': const Color(0xFF8B5CF6)
          },
          {
            'id': 'my_ip',
            'icon': Icons.public_rounded,
            'label': 'Meu IP',
            'color': const Color(0xFFF97316)
          },
        ];

    return Wrap(
      spacing: 12,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      children: actions.map((item) {
        final color = item['color'] as Color? ?? Colors.blue;
        final icon = item['icon'] as IconData;
        final label = item['label'] as String;
        final id = item['id'] as String;

        return GestureDetector(
          onTap: () {
            print('Dashboard: Botão "$label" (ID: $id) clicado!'); // DEBUG LOG
            try {
              onNavigate(id);
            } catch (e) {
              print('Dashboard: Erro ao navegar para $id: $e');
            }
          },
          child: Container(
            width: 75,
            color: Colors.transparent, // Garante área de toque
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(height: 8),
                Text(label,
                    style: GoogleFonts.inter(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
