import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/premium_invoice_card.dart';

typedef NavigateToPageCallback = void Function(String pageId);

class ProviderDashboardPage extends StatefulWidget {
  final String customerName, planName, connectionStatus;
  final double billAmount, usedGb, totalGb, downloadMbps, uploadMbps;
  final DateTime billDueDate;
  final NavigateToPageCallback onNavigate;
  final List<Map<String, dynamic>>? menuItems;
  final Future<void> Function()? onRefresh;

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
    this.onRefresh,
  });

  @override
  State<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends State<ProviderDashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.customerName.split(' ')[0];
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;

    final cardBg = widget.customCardBg ?? textColor.withValues(alpha: 0.08);
    final cardText = widget.customCardText ?? textColor;
    final buttonColor = widget.actionColor ?? Colors.black;

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
                        color: textColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(widget.planName,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                  ),
                  const SizedBox(width: 8),
                  _SimpleStatusBadge(
                      status: widget.connectionStatus, textColor: textColor),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24, top: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onNavigate('notifications');
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_none_rounded,
                    color: textColor, size: 24),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (widget.onRefresh != null) {
            HapticFeedback.mediumImpact();
            await widget.onRefresh!();
          }
        },
        color: buttonColor,
        backgroundColor: Colors.white,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
            children: [
              // Invoice Card with subtle animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: PremiumInvoiceCard(
                  amount: widget.billAmount,
                  dueDate: widget.billDueDate,
                  onPay: () {
                    HapticFeedback.lightImpact();
                    widget.onNavigate('invoices');
                  },
                  customColor: widget.invoiceColor,
                ),
              ),
              const SizedBox(height: 24),

              // Speed Card
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: buttonColor.withValues(alpha: 0.08),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFF0F9FF),
                              const Color(0xFFE0F2FE),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.speed_rounded,
                            color: Color(0xFF0EA5E9), size: 28),
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
                            const SizedBox(height: 2),
                            Text('${widget.downloadMbps.toInt()} Mega',
                                style: GoogleFonts.inter(
                                    color: const Color(0xFF0F172A),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          widget.onNavigate('speed_test');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Testar',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Quick Actions Section
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Acesso Rápido',
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor)),
                    const SizedBox(height: 16),
                    _CleanActionsRow(
                      onNavigate: widget.onNavigate,
                      textColor: textColor,
                      menuItems: widget.menuItems,
                    ),
                    const SizedBox(height: 24),

                    // Diagnostic Card
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onNavigate('network_diagnostic');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: cardText.withValues(alpha: 0.15)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (widget.actionColor ??
                                        const Color(0xFFFBBC05))
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.build_circle_outlined,
                                  color: widget.actionColor ??
                                      widget.customCardText ??
                                      const Color(0xFFFBBC05),
                                  size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Problemas técnicos?',
                                    style: GoogleFonts.inter(
                                        color: cardText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                const SizedBox(height: 2),
                                Text('Iniciar auto-diagnóstico da rede.',
                                    style: GoogleFonts.inter(
                                        color: cardText.withValues(alpha: 0.7),
                                        fontSize: 12)),
                              ],
                            )),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: cardText.withValues(alpha: 0.5)),
                          ],
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
        ? const Color(0xFF10B981).withValues(alpha: 0.15)
        : Colors.red.withValues(alpha: 0.15);
    final badgeColor = isConnected ? const Color(0xFF10B981) : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(status,
              style: GoogleFonts.inter(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11)),
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
          {
            'id': 'trace_route',
            'icon': Icons.alt_route_rounded,
            'label': 'Rota',
            'color': const Color(0xFF7C3AED)
          },
          {
            'id': 'wifi',
            'icon': Icons.wifi_rounded,
            'label': 'Wi-Fi',
            'color': const Color(0xFF0891B2)
          },
          {
            'id': 'internet_usage',
            'icon': Icons.data_usage_rounded,
            'label': 'Consumo',
            'color': const Color(0xFF059669)
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
            HapticFeedback.lightImpact();
            onNavigate(id);
          },
          child: Container(
            width: 75,
            color: Colors.transparent,
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(height: 10),
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
