// Layout 02 - Financeiro Page (VERSÃO MELHORADA)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/fatura.dart';
import '../../core/providers/financeiro_provider.dart';
import '../../core/services/financeiro_service.dart';
import '../../core/providers/configuration_provider.dart';
import '../../core/services/auth_service.dart';

class FinanceiroPage extends StatelessWidget {
  const FinanceiroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final configProvider = context.read<ConfigurationProvider>();
    final authService = context.read<AuthService>();
    final providerConfig = configProvider.providerConfig;
    final usuario = authService.usuario;

    if (providerConfig == null) {
      return const Scaffold(
        body: Center(child: Text('Configuração não encontrada')),
      );
    }

    final apiUrl = '${providerConfig.apiUrl}/get-invoices';
    final cpfCnpj = usuario?.cpfCnpj ?? '';

    return ChangeNotifierProvider(
      create: (_) => FinanceiroProvider(
        FinanceiroService(
          apiUrl: apiUrl,
          cpfCnpjUnformatted: cpfCnpj.replaceAll(RegExp(r'[^0-9]'), ''),
          senha: usuario?.senha,
          sgpParams: {
            'token': providerConfig.config.integrations.apiToken,
            'app': providerConfig.config.integrations.appName,
            'sgpBaseUrl': providerConfig.config.integrations.sgpBaseUrl,
          },
        ),
      )..fetchHistory(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Minhas Faturas',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Consumer<FinanceiroProvider>(
          builder: (context, provider, child) {
            if (provider.state == FinanceiroState.loading) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Carregando faturas...',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            if (provider.state == FinanceiroState.error) {
              return _buildErrorState(context, provider);
            }

            if (provider.invoices.isEmpty) {
              return _buildEmptyState(context, provider);
            }

            // Separa faturas pendentes e pagas
            final pendentes =
                provider.invoices.where((f) => !f.isPago).toList();
            final pagas = provider.invoices.where((f) => f.isPago).toList();

            return RefreshIndicator(
              onRefresh: provider.fetchHistory,
              color: Theme.of(context).primaryColor,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Resumo
                  if (pendentes.isNotEmpty) ...[
                    _buildSummaryCard(context, pendentes),
                    const SizedBox(height: 24),
                  ],

                  // Faturas Pendentes
                  if (pendentes.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Faturas Pendentes',
                        Icons.warning_amber_rounded, Colors.orange),
                    const SizedBox(height: 12),
                    ...pendentes.map((f) => _buildInvoiceCard(context, f)),
                    const SizedBox(height: 24),
                  ],

                  // Faturas Pagas
                  if (pagas.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Faturas Pagas',
                        Icons.check_circle_outline, Colors.green),
                    const SizedBox(height: 12),
                    ...pagas.take(6).map((f) => _buildInvoiceCard(context, f)),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<Fatura> pendentes) {
    final total = pendentes.fold<double>(0, (sum, f) => sum + f.valor);
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final vencidas = pendentes.where((f) => f.isVencido).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withBlue(255),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long,
                    color: Colors.white, size: 28),
              ),
              const Spacer(),
              if (vencidas > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$vencidas vencida${vencidas > 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Total em Aberto',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(total),
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${pendentes.length} fatura${pendentes.length > 1 ? 's' : ''} pendente${pendentes.length > 1 ? 's' : ''}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800]),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, FinanceiroProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
            ),
            const SizedBox(height: 24),
            const Text('Ops! Algo deu errado',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: provider.fetchHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, FinanceiroProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
          ),
          const SizedBox(height: 24),
          const Text('Tudo certo!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Você não tem faturas pendentes',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: provider.fetchHistory,
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Fatura fatura) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final Color statusColor;
    final IconData statusIcon;
    final String statusText;
    final Color cardBorderColor;

    if (fatura.isPago) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Pago';
      cardBorderColor = Colors.green.withOpacity(0.3);
    } else if (fatura.isVencido) {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
      statusText = 'Vencido';
      cardBorderColor = Colors.red.withOpacity(0.5);
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = 'Pendente';
      cardBorderColor = Colors.orange.withOpacity(0.3);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap:
              fatura.isPago ? null : () => _showPaymentOptions(context, fatura),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Valor e Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currencyFormat.format(fatura.valor),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color:
                                  fatura.isPago ? Colors.grey : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                fatura.isPago && fatura.dataPagamento != null
                                    ? 'Pago em ${dateFormat.format(fatura.dataPagamento!)}'
                                    : 'Vence em ${dateFormat.format(fatura.vencimento)}',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Botões de Pagamento (apenas para não pagas)
                if (!fatura.isPago) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Botão Principal: Pix (se disponível)
                  if (fatura.pixCopiaECola != null &&
                      fatura.pixCopiaECola!.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _copyToClipboard(
                            context, fatura.pixCopiaECola!, 'Código Pix'),
                        icon: const Icon(Icons.qr_code_2, size: 20),
                        label: const Text('COPIAR CÓDIGO PIX'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF32BCAD),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Linha secundária: Código de Barras e Boleto
                  Row(
                    children: [
                      if (fatura.linhaDigitavel != null &&
                          fatura.linhaDigitavel!.isNotEmpty)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _copyToClipboard(context,
                                fatura.linhaDigitavel!, 'Código de barras'),
                            icon: Icon(Icons.content_copy,
                                size: 18,
                                color: Theme.of(context).primaryColor),
                            label: Text('Código',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              side: BorderSide(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.5)),
                            ),
                          ),
                        ),
                      if (fatura.linhaDigitavel != null &&
                          fatura.urlBoleto != null)
                        const SizedBox(width: 10),
                      if (fatura.urlBoleto != null &&
                          fatura.urlBoleto!.isNotEmpty)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openUrl(fatura.urlBoleto!),
                            icon: const Icon(Icons.picture_as_pdf,
                                size: 18, color: Colors.red),
                            label: const Text('Ver Boleto',
                                style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentOptions(BuildContext context, Fatura fatura) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Pagar Fatura',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '${currencyFormat.format(fatura.valor)} • Vence ${dateFormat.format(fatura.vencimento)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Opção PIX
            if (fatura.pixCopiaECola != null &&
                fatura.pixCopiaECola!.isNotEmpty)
              _buildPaymentOption(
                context,
                icon: Icons.qr_code_2,
                title: 'Pagar com Pix',
                subtitle: 'Copie o código e pague no app do seu banco',
                color: const Color(0xFF32BCAD),
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(
                      context, fatura.pixCopiaECola!, 'Código Pix');
                },
              ),

            // Opção Código de Barras
            if (fatura.linhaDigitavel != null &&
                fatura.linhaDigitavel!.isNotEmpty)
              _buildPaymentOption(
                context,
                icon: Icons.qr_code,
                title: 'Código de Barras',
                subtitle: 'Copie para pagar via boleto',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(
                      context, fatura.linhaDigitavel!, 'Código de barras');
                },
              ),

            // Opção Boleto PDF
            if (fatura.urlBoleto != null && fatura.urlBoleto!.isNotEmpty)
              _buildPaymentOption(
                context,
                icon: Icons.picture_as_pdf,
                title: 'Ver Boleto em PDF',
                subtitle: 'Abrir boleto para impressão',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _openUrl(fatura.urlBoleto!);
                },
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('$label copiado!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
