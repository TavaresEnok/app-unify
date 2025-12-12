// ARQUIVO: lib/financeiro.dart (MIGRADO PARA CONSUMO VIA PROVIDER)

import 'package:layout01/models/provider_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // Importar para TimeoutException
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart'; // <-- NOVO
import 'package:url_launcher/url_launcher.dart';
import 'utils.dart';
import 'services/financeiro_service.dart';
import 'configuration_provider.dart'; // <-- NOVO

class FinanceiroPage extends StatefulWidget {
  final String cpfCnpj; // Recebe o CPF/CNPJ formatado
  final String? senha;

  const FinanceiroPage({
    super.key,
    required this.cpfCnpj,
    this.senha,
  });

  @override
  State<FinanceiroPage> createState() => _FinanceiroPageState();
}

class _FinanceiroPageState extends State<FinanceiroPage> {
  Future<List<dynamic>>? _invoicesFuture;
  late final Color primaryColor;
  late final FinanceiroService _service;

  // Variável para armazenar a configuração localmente
  late final ProviderConfig _providerConfig;

  @override
  void initState() {
    super.initState();

    // Acessa a configuração do provedor (ConfigurationProvider)
    _providerConfig = Provider.of<ConfigurationProvider>(context, listen: false)
        .providerConfig!;

    primaryColor = hexToColor(_providerConfig.config.themeColor);

    // --- Configuração do Serviço ---
    // 1. Pega a apiUrl centralizada
    final String baseUrl = _providerConfig.apiUrl;
    final String apiUrl = '$baseUrl/get-invoices';

    // 2. Pega os parâmetros SGP
    final sgpParams = {
      "token": _providerConfig.config.integrations.apiToken,
      "app": _providerConfig.config.integrations.appName,
      "sgpBaseUrl": _providerConfig.config.integrations.sgpBaseUrl
    };

    // 3. Pega o CPF não formatado
    final cpfCnpjUnformatted = widget.cpfCnpj.replaceAll(RegExp(r'[^0-9]'), '');

    // 4. Inicializa o serviço
    _service = FinanceiroService(
      apiUrl: apiUrl,
      sgpParams: sgpParams,
      cpfCnpjUnformatted: cpfCnpjUnformatted,
      senha: widget.senha,
    );

    // 5. Chama o método do serviço
    _invoicesFuture = _service.fetchInvoices();
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Ok'),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  void _openUrl(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Link indisponível.')));
      return;
    }
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Não foi possível abrir o link: $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Faturas'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _invoicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: primaryColor));
          }

          if (snapshot.hasError) {
            String errorMessage =
                'Ocorreu um erro inesperado ao carregar as faturas.';
            if (snapshot.error is TimeoutException) {
              errorMessage =
                  'O servidor demorou muito para responder.\\nVerifique sua conexão e tente novamente.';
            } else if (snapshot.error is Exception) {
              errorMessage =
                  snapshot.error.toString().replaceFirst('Exception: ', '');
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 50),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao Carregar Faturas',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar Novamente'),
                      onPressed: () {
                        setState(() {
                          // Chama o serviço novamente
                          _invoicesFuture = _service.fetchInvoices();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('Nenhuma fatura encontrada.',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.refresh,
                      size: 18,
                    ),
                    label: const Text('Verificar novamente'),
                    onPressed: () {
                      setState(() {
                        // Chama o serviço novamente
                        _invoicesFuture = _service.fetchInvoices();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      foregroundColor: primaryColor,
                      elevation: 0,
                    ),
                  )
                ],
              ),
            );
          }

          final invoices = snapshot.data!;
          // Ordena as faturas (lógica de ordenação mantida)
          invoices.sort((a, b) {
            bool aPago = a['pago'] ?? false;
            bool bPago = b['pago'] ?? false;
            if (aPago != bPago) {
              return aPago ? 1 : -1;
            }
            if (!aPago) {
              try {
                DateTime? dateA = DateTime.tryParse(a['dataVencimento'] ?? '');
                DateTime? dateB = DateTime.tryParse(b['dataVencimento'] ?? '');
                if (dateA != null && dateB != null) {
                  return dateA.compareTo(dateB);
                }
              } catch (_) {}
              return (a['dataVencimento'] ?? '')
                  .compareTo(b['dataVencimento'] ?? '');
            } else {
              try {
                DateTime? dateA = DateTime.tryParse(a['dataPagamento'] ?? '');

                DateTime? dateB = DateTime.tryParse(b['dataPagamento'] ?? '');
                if (dateA != null && dateB != null) {
                  return dateB.compareTo(dateA);
                }
              } catch (_) {}
              return (b['dataPagamento'] ?? '')
                  .compareTo(a['dataPagamento'] ?? '');
            }
          });
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: invoices.length,
            itemBuilder: (context, index) => _buildInvoiceCard(invoices[index]),
          );
        },
      ),
    );
  }

  // _buildInvoiceCard e _actionButton permanecem inalterados
  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final bool isPaid = invoice['pago'] as bool? ?? false;
    final statusText = isPaid ? "PAGO" : "EM ABERTO";
    final statusColor = isPaid ? Colors.green.shade600 : Colors.orange.shade800;
    final valorString =
        (invoice['valor'] ?? '0.00').toString().replaceAll(',', '.');
    final valorFormatado =
        'R\$ ${double.tryParse(valorString)?.toStringAsFixed(2).replaceAll('.', ',') ?? '0,00'}';
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Vencimento: ${invoice['dataVencimento'] ?? 'N/A'}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(statusText,
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(valorFormatado,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: primaryColor)),
            if (isPaid &&
                invoice['dataPagamento'] != null &&
                invoice['dataPagamento'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Pago em: ${invoice['dataPagamento']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _actionButton(
                    icon: FontAwesomeIcons.barcode,
                    label: 'Copiar\\nCódigo',
                    onTap: isPaid
                        ? null
                        : () {
                            Clipboard.setData(ClipboardData(
                                text: invoice['linhaDigitavel'] ?? ''));
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Código de barras copiado!'),
                                    duration: Duration(seconds: 1)));
                          }),
                _actionButton(
                    icon: FontAwesomeIcons.qrcode,
                    label: 'Copiar\\nPIX',
                    onTap: (isPaid ||
                            (invoice['codigoPix'] == null ||
                                invoice['codigoPix'].isEmpty))
                        ? null
                        : () {
                            Clipboard.setData(ClipboardData(
                                text: invoice['codigoPix'] ?? ''));
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Código PIX copiado!'),
                                    duration: Duration(seconds: 1)));
                          }),
                _actionButton(
                    icon: FontAwesomeIcons.download,
                    label: 'Baixar\\nPDF',
                    onTap: () => _openUrl(invoice['link'] as String?)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
      {required IconData icon,
      required String label,
      required VoidCallback? onTap}) {
    final bool isEnabled = onTap != null;
    final Color color = isEnabled ? primaryColor : Colors.grey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 11, height: 1.1),
            ),
          ],
        ),
      ),
    );
  }
}
