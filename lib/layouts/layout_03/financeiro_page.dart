// Layout 02 - Financeiro Page
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

    // Constrói a URL de faturas a partir da URL base + endpoint
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
        appBar: AppBar(
          title: const Text('Faturas'),
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Consumer<FinanceiroProvider>(
          builder: (context, provider, child) {
            if (provider.state == FinanceiroState.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.state == FinanceiroState.error) {
              return _buildErrorState(context, provider);
            }

            if (provider.invoices.isEmpty) {
              return _buildEmptyState(context, provider);
            }

            return RefreshIndicator(
              onRefresh: provider.fetchHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.invoices.length,
                itemBuilder: (context, index) {
                  final fatura = provider.invoices[index];
                  return _buildInvoiceCard(context, fatura);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, FinanceiroProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: provider.fetchHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
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
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Nenhuma fatura encontrada'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: provider.fetchHistory,
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar'),
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

    if (fatura.isPago) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Pago';
    } else if (fatura.isVencido) {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
      statusText = 'Vencido';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      statusText = 'Pendente';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currencyFormat.format(fatura.valor),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusText,
                          style: TextStyle(
                              color: statusColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Vencimento: ${dateFormat.format(fatura.vencimento)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (!fatura.isPago) ...[
              const Divider(height: 24),
              Row(
                children: [
                  if (fatura.linhaDigitavel != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyToClipboard(context,
                            fatura.linhaDigitavel!, 'Código de barras'),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Código'),
                      ),
                    ),
                  if (fatura.linhaDigitavel != null &&
                      fatura.pixCopiaECola != null)
                    const SizedBox(width: 8),
                  if (fatura.pixCopiaECola != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyToClipboard(
                            context, fatura.pixCopiaECola!, 'Código Pix'),
                        icon: const Icon(Icons.qr_code, size: 18),
                        label: const Text('Pix'),
                      ),
                    ),
                  if ((fatura.linhaDigitavel != null ||
                          fatura.pixCopiaECola != null) &&
                      fatura.urlBoleto != null)
                    const SizedBox(width: 8),
                  if (fatura.urlBoleto != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openUrl(fatura.urlBoleto!),
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('Boleto'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copiado!')),
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
