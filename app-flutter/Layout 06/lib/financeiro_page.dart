import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:app_provedor/configuration_provider.dart';
import 'providers/financeiro_provider.dart';
import 'services/financeiro_service.dart';
import 'models/fatura.dart';
import 'widgets/glass_card.dart'; // NOVO
import 'widgets/section_header.dart'; // NOVO
import 'widgets/status_chip.dart'; // NOVO
import 'utils.dart';

class FinanceiroPage extends StatelessWidget {
  final String cpfCnpj;
  final String senha;
  final Map<String, dynamic> sgpParams;

  const FinanceiroPage({
    super.key,
    required this.cpfCnpj,
    required this.senha,
    required this.sgpParams,
  });

  @override
  Widget build(BuildContext context) {
    final providerConfig = context.read<ConfigurationProvider>().providerConfig!;
    final apiUrl = '${providerConfig.apiUrl}/get-invoices';
    final primaryColor = hexToColor(providerConfig.config.themeColor);

    return ChangeNotifierProvider(
      create: (_) => FinanceiroProvider(
        FinanceiroService(
          apiUrl: apiUrl,
          cpfCnpjUnformatted: cpfCnpj.replaceAll(RegExp(r'[^0-9]'), ''),
          senha: senha,
          sgpParams: sgpParams,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Faturas'),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF050816), Color(0xFF101A2E), Color(0xFF1C2845)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Consumer<FinanceiroProvider>(
              builder: (context, provider, child) {
                if (provider.state == FinanceiroState.loading || provider.state == FinanceiroState.idle) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                if (provider.state == FinanceiroState.error) {
                  return _buildErrorState(context, provider.errorMessage, primaryColor, provider);
                }

                if (provider.invoices.isEmpty) {
                  return _buildEmptyState(primaryColor, provider);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildUnlockCard(context, provider),
                      const SizedBox(height: 16),
                      _buildChartCard(context, provider.monthlyTotals, primaryColor),
                      const SizedBox(height: 32),
                      const SectionHeader(
                        title: 'Suas faturas',
                        subtitle: 'Visualize, copie códigos e baixe o PDF rapidamente',
                        icon: Icons.receipt_long_rounded,
                      ),
                      const SizedBox(height: 24),
                      ...provider.invoices.map((invoice) => _buildInvoiceCard(context, invoice, primaryColor)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message, Color primaryColor, FinanceiroProvider provider) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 56),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar faturas',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              onPressed: () => provider.fetchHistory(),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor, FinanceiroProvider provider) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 60, color: primaryColor),
            const SizedBox(height: 16),
            const Text('Nenhuma fatura encontrada.', style: TextStyle(fontSize: 16, color: Colors.white)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Verificar novamente'),
              onPressed: () => provider.fetchHistory(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockCard(BuildContext context, FinanceiroProvider provider) {
    final hasOverdue = provider.invoices.any((f) => 
        f.status == 'pendente' && 
        f.vencimento.isBefore(DateTime.now().subtract(const Duration(days: 1)))
    );

    if (!hasOverdue) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: GlassCard(
        borderColor: Colors.orange.shade900,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_clock, color: Colors.orange.shade400, size: 32),
                const SizedBox(width: 12),
                const Expanded(child: Text("Internet Bloqueada?", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Se você já pagou ou precisa de um prazo extra, libere sua conexão agora por 48h.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bolt),
                label: const Text("LIBERAR CONEXÃO AGORA"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => provider.solicitarDesbloqueio(context),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, Map<int, double> monthlyTotals, Color primaryColor) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final List<BarChartGroupData> barGroups = [];
    double maxY = 0;

    for (int i = 11; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthKey = monthDate.month;
      final total = monthlyTotals[monthKey] ?? 0.0;
      if (total > maxY) maxY = total;

      barGroups.add(BarChartGroupData(
        x: monthKey,
        barRods: [BarChartRodData(toY: total, color: primaryColor, width: 12, borderRadius: BorderRadius.circular(4))],
      ));
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pagamentos (Últimos 12 Meses)', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: BarChart(BarChartData(
              maxY: maxY == 0 ? 100 : maxY * 1.2,
              barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.grey.shade900.withOpacity(0.9),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final month = DateFormat.MMM('pt_BR').format(DateTime(0, group.x));
                  return BarTooltipItem(
                    '$month\n', 
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'R\$ ${rod.toY.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  );
                },
              )),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                  final month = DateFormat.MMM('pt_BR').format(DateTime(0, value.toInt()));
                  return SideTitleWidget(axisSide: meta.axisSide, child: Text(month, style: const TextStyle(color: Colors.white38, fontSize: 10)));
                }, reservedSize: 30)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 0.5)),
              barGroups: barGroups,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Fatura invoice, Color primaryColor) {
    final isPaid = invoice.status == 'pago';
    final isOverdue = invoice.status == 'pendente' && invoice.vencimento.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    
    final statusText = isPaid ? 'PAGO' : (isOverdue ? 'VENCIDA' : 'EM ABERTO');
    final statusColor = isPaid ? const Color(0xFF22C55E) : (isOverdue ? const Color(0xFFEF4444) : const Color(0xFFF97316));
    final icon = isPaid ? Icons.check_circle : (isOverdue ? Icons.warning_rounded : Icons.schedule);

    final valorFormatado = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(invoice.valor);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Vencimento: ${DateFormat('dd/MM/yyyy').format(invoice.vencimento)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                StatusChip(label: statusText, color: statusColor, icon: icon),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              valorFormatado,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: primaryColor),
            ),
            if (isPaid && invoice.dataPagamento != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Pago em: ${DateFormat('dd/MM/yyyy').format(invoice.dataPagamento!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
              ),
            const Divider(height: 32, color: Colors.white12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _actionButton(
                  context,
                  icon: FontAwesomeIcons.barcode,
                  label: 'Copiar\nCódigo',
                  onTap: isPaid ? null : () {
                    if (invoice.linhaDigitavel != null) {
                      Clipboard.setData(ClipboardData(text: invoice.linhaDigitavel!));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código de barras copiado!')));
                    }
                  },
                ),
                _actionButton(
                  context,
                  icon: FontAwesomeIcons.qrcode,
                  label: 'Copiar\nPIX',
                  onTap: (isPaid || invoice.pixCopiaECola == null) ? null : () {
                    Clipboard.setData(ClipboardData(text: invoice.pixCopiaECola!));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código PIX copiado!')));
                  },
                ),
                _actionButton(
                  context,
                  icon: FontAwesomeIcons.filePdf,
                  label: 'Baixar\nPDF',
                  onTap: () async {
                    if (invoice.urlBoleto != null) {
                      final uri = Uri.parse(invoice.urlBoleto!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback? onTap}) {
    final bool isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, color: isEnabled ? Colors.white : Colors.white24, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: isEnabled ? Colors.white : Colors.white24, fontSize: 11, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}
