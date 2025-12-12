import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Para Clipboard
import 'package:url_launcher/url_launcher.dart'; // Para abrir PDF
import 'configuration_provider.dart';
import 'providers/financeiro_provider.dart';
import 'services/financeiro_service.dart';
import 'models/fatura.dart';
import 'utils.dart' show hexToColor;

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
    final providerConfig =
        context.read<ConfigurationProvider>().providerConfig!;
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
        appBar: AppBar(
          title: const Text('Minhas Faturas'),
          centerTitle: true,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Consumer<FinanceiroProvider>(
          builder: (context, provider, child) {
            if (provider.state == FinanceiroState.loading ||
                provider.state == FinanceiroState.idle) {
              return Center(
                  child: CircularProgressIndicator(color: primaryColor));
            }

            if (provider.state == FinanceiroState.error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        provider.errorMessage ?? 'Erro ao carregar faturas',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: provider.fetchHistory,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar Novamente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final faturas = provider.invoices;
            if (faturas.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Nenhuma fatura encontrada',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => provider.fetchHistory(),
              color: primaryColor,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: faturas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final fatura = faturas[index];
                  return _InvoiceCard(
                      fatura: fatura, primaryColor: primaryColor);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Fatura fatura;
  final Color primaryColor;

  const _InvoiceCard({required this.fatura, required this.primaryColor});

  bool get isPaid => fatura.status.toLowerCase() == 'pago';
  bool get isOverdue => !isPaid && fatura.vencimento.isBefore(DateTime.now());

  Color get statusColor {
    if (isPaid) return Colors.green;
    if (isOverdue) return Colors.red;
    return Colors.orange;
  }

  String get statusText {
    if (isPaid) return 'PAGO';
    if (isOverdue) return 'VENCIDO';
    return 'ABERTO';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(fatura.vencimento),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                  .format(fatura.valor),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vencimento',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            if (!isPaid) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyBarcode(context),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Cód. Barras'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyPix(context),
                      icon: const Icon(Icons.pix, size: 18),
                      label: const Text('Copia e Cola'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openPdf(context),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Visualizar PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _copyBarcode(BuildContext context) {
    if (fatura.linhaDigitavel != null && fatura.linhaDigitavel!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: fatura.linhaDigitavel!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código de barras copiado!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código de barras indisponível')),
      );
    }
  }

  void _copyPix(BuildContext context) {
    if (fatura.pixCopiaECola != null && fatura.pixCopiaECola!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: fatura.pixCopiaECola!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pix Copia e Cola copiado!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pix indisponível para esta fatura')),
      );
    }
  }

  void _openPdf(BuildContext context) async {
    if (fatura.urlBoleto != null && fatura.urlBoleto!.isNotEmpty) {
      final uri = Uri.parse(fatura.urlBoleto!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o PDF')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF indisponível')),
      );
    }
  }
}
