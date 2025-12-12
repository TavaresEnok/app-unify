import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/configuration_provider.dart';
import '../../core/services/financeiro_service.dart';
import '../../core/services/auth_service.dart';
import 'theme.dart';

class FinanceiroPage extends StatefulWidget {
  const FinanceiroPage({super.key});

  @override
  State<FinanceiroPage> createState() => _FinanceiroPageState();
}

class _FinanceiroPageState extends State<FinanceiroPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _invoices = [];
  String? _errorMessage;
  FinanceiroService? _financeiroService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServiceAndFetch();
    });
  }

  Future<void> _initServiceAndFetch() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final configProvider =
        Provider.of<ConfigurationProvider>(context, listen: false);
    final user = authService.usuario;
    final config = configProvider.providerConfig;

    if (user == null || config == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro de autenticação ou configuração.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      _financeiroService = FinanceiroService(
        apiUrl: '${config.apiUrl}/get-invoices', // Correct usage of API URL
        cpfCnpjUnformatted: user.cpfCnpj,
        senha: user.senha,
        sgpParams: {
          'token': config.config.integrations.apiToken,
          'app': config.config.integrations.appName,
          'sgpBaseUrl': config.config.integrations.sgpBaseUrl,
        },
      );

      await _fetchInvoices();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao inicializar financeiro: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchInvoices() async {
    if (_financeiroService == null) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final invoices = await _financeiroService!.fetchInvoices();
      if (mounted) {
        setState(() {
          _invoices = List<Map<String, dynamic>>.from(invoices);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao buscar faturas: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard(String content, String message) {
    Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message), backgroundColor: Layout05Theme.secondary),
      );
    }
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Não foi possível abrir o PDF'),
              backgroundColor: Layout05Theme.error),
        );
      }
    }
  }

  void _requestTrustUnlock() async {
    if (_financeiroService == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Desbloqueio de Confiança', style: Layout05Theme.heading2),
        content: const Text(
            'Deseja solicitar o desbloqueio provisório da sua conexão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR',
                style: TextStyle(color: Layout05Theme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Layout05Theme.primary),
            child:
                const Text('CONFIRMAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Solicitando desbloqueio...'),
            backgroundColor: Layout05Theme.primary),
      );

      try {
        await _financeiroService!.solicitarDesbloqueioConfianca();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Desbloqueio solicitado com sucesso! Aguarde alguns instantes.'),
                backgroundColor: Layout05Theme.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erro: $e'),
                backgroundColor: Layout05Theme.accent),
          );
        }
      }
    }
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
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Layout05Theme.error)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Unlock Card
                      Container(
                        margin: const EdgeInsets.only(bottom: 32),
                        padding: const EdgeInsets.all(24),
                        decoration: Layout05Theme.neumorphicDecoration,
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
                                      style: Layout05Theme.heading2.copyWith(
                                          fontSize: 16,
                                          color: Layout05Theme.textDark)),
                                  const Text(
                                      'Solicite o desbloqueio em confiança.',
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
                                elevation: 5,
                                shadowColor:
                                    Layout05Theme.primary.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('LIBERAR',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
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
      margin: const EdgeInsets.only(bottom: 24),
      decoration: Layout05Theme.neumorphicDecoration,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Layout05Theme.background,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.white,
                            offset: Offset(-2, -2),
                            blurRadius: 4),
                        BoxShadow(
                            color: Color(0x19000000),
                            offset: Offset(2, 2),
                            blurRadius: 4),
                      ]),
                  child: Icon(
                    isOpen
                        ? Icons.receipt_long_rounded
                        : Icons.check_circle_rounded,
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
                  'R\$ ${(fatura['valor'] ?? 0).toStringAsFixed(2).replaceAll('.', ',')}',
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
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.pix_rounded,
                    label: 'PIX',
                    onTap: () => _copyToClipboard(
                        fatura['pixCode'] ?? '', 'Código Pix copiado!'),
                  ),
                  _ActionButton(
                    icon: Icons.qr_code_rounded,
                    label: 'CÓDIGO',
                    onTap: () => _copyToClipboard(
                        fatura['barCode'] ?? '', 'Código de barras copiado!'),
                  ),
                  _ActionButton(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'PDF',
                    onTap: () => _openPdf(fatura['pdfUrl'] ?? ''),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: Layout05Theme.flatDecoration,
        child: Column(
          children: [
            Icon(icon, color: Layout05Theme.textDark, size: 24),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Layout05Theme.textGrey)),
          ],
        ),
      ),
    );
  }
}
