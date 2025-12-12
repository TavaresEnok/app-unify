import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/configuration_provider.dart';
// import '../../core/services/financeiro_service.dart'; // TODO: Uncomment when using real service
import 'theme.dart';

class FinanceiroPage extends StatefulWidget {
  const FinanceiroPage({super.key});

  @override
  State<FinanceiroPage> createState() => _FinanceiroPageState();
}

class _FinanceiroPageState extends State<FinanceiroPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _invoices = [];

  @override
  void initState() {
    super.initState();
    // Simulate fetching data
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _invoices = [
            {
              'id': '1001',
              'status': 'open',
              'valor': 99.90,
              'vencimento': '10/12/2023',
              'pixCode':
                  '00020126360014BR.GOV.BCB.PIX0114+5511999999999520400005303986540510.005802BR5913Empresa Teste6008Sao Paulo62070503***63041D3D',
              'barCode':
                  '34191.79001 01043.510047 91020.150008 1 89870000009990',
              'pdfUrl':
                  'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'
            },
            {
              'id': '1002',
              'status': 'paid',
              'valor': 99.90,
              'vencimento': '10/11/2023',
            },
          ];
        });
      }
    });
  }

  void _copyToClipboard(String content, String message) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message), backgroundColor: Layout05Theme.secondary),
    );
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível abrir o PDF'),
            backgroundColor: Layout05Theme.error),
      );
    }
  }

  void _requestTrustUnlock() {
    // Call service to unlock
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Desbloqueio de Confiança', style: Layout05Theme.heading2),
        content: const Text(
            'Deseja solicitar o desbloqueio provisório da sua conexão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR',
                style: TextStyle(color: Layout05Theme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Call real service here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Desbloqueio solicitado com sucesso!'),
                    backgroundColor: Layout05Theme.success),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Layout05Theme.primary),
            child:
                const Text('CONFIRMAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout05Theme.background,
      appBar: AppBar(
        title: Text('Minhas Faturas', style: Layout05Theme.heading2),
        backgroundColor: Layout05Theme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Layout05Theme.textDark),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Layout05Theme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Unlock Card
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Layout05Theme.primary.withOpacity(0.05),
                      borderRadius: Layout05Theme.radiusL,
                      border: Border.all(
                          color: Layout05Theme.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_open_rounded,
                            color: Layout05Theme.primary, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Conexão Bloqueada?',
                                  style: Layout05Theme.heading2
                                      .copyWith(fontSize: 16)),
                              const Text('Solicite o desbloqueio em confiança.',
                                  style: TextStyle(
                                      color: Layout05Theme.textGrey,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _requestTrustUnlock,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Layout05Theme.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('DESBLOQUEAR',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                  // Invoices List
                  ..._invoices
                      .map((fatura) => _buildInvoiceCard(fatura))
                      .toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> fatura) {
    final isOpen = fatura['status'] == 'open';
    final color = isOpen ? Layout05Theme.warning : Layout05Theme.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: Layout05Theme.cardDecoration,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOpen ? Icons.receipt_long : Icons.check_circle,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOpen ? 'Fatura em Aberto' : 'Fatura Paga',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Layout05Theme.textDark,
                            fontSize: 16),
                      ),
                      Text(
                        'Vence em: ${fatura['vencimento']}',
                        style: const TextStyle(
                            color: Layout05Theme.textGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  'R\$ ${fatura['valor'].toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Layout05Theme.textDark),
                ),
              ],
            ),
          ),
          if (isOpen)
            Container(
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: Colors.grey.withOpacity(0.1))),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.pix,
                    label: 'PIX',
                    onTap: () => _copyToClipboard(
                        fatura['pixCode'], 'Código Pix copiado!'),
                  ),
                  _ActionButton(
                    icon: Icons.qr_code,
                    label: 'CÓDIGO',
                    onTap: () => _copyToClipboard(
                        fatura['barCode'], 'Código de barras copiado!'),
                  ),
                  _ActionButton(
                    icon: Icons.picture_as_pdf,
                    label: 'PDF',
                    onTap: () => _openPdf(fatura['pdfUrl']),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: Layout05Theme.primary, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Layout05Theme.primary)),
          ],
        ),
      ),
    );
  }
}
