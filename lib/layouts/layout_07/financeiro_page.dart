// Layout 02 - Financeiro Page (VERSÃO CLEAN)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

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
          body: Center(child: Text('Configuração não encontrada')));
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
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Faturas'),
          centerTitle: true,
          elevation: 0,
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
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: provider.invoices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _buildInvoiceCard(context, provider.invoices[index]),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(provider.errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: provider.fetchHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, FinanceiroProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green[400]),
          const SizedBox(height: 16),
          const Text('Nenhuma fatura encontrada',
              style: TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          TextButton.icon(
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
    final primaryColor = Theme.of(context).primaryColor;

    // Status visual
    Color statusColor = Colors.orange;
    String statusText = 'Pendente';
    IconData statusIcon = Icons.schedule;

    if (fatura.isPago) {
      statusColor = Colors.green;
      statusText = 'Pago';
      statusIcon = Icons.check_circle;
    } else if (fatura.isVencido) {
      statusColor = Colors.red;
      statusText = 'Vencido';
      statusIcon = Icons.error;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Valor
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currencyFormat.format(fatura.valor),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fatura.isPago
                            ? 'Pago em ${dateFormat.format(fatura.dataPagamento ?? fatura.vencimento)}'
                            : 'Vence ${dateFormat.format(fatura.vencimento)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusText,
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Ações de pagamento (apenas para não pagas)
          if (!fatura.isPago) ...[
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.grey[100],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // PIX - Botão principal
                  if (fatura.pixCopiaECola != null &&
                      fatura.pixCopiaECola!.isNotEmpty)
                    _buildActionButton(
                      context,
                      icon: Icons.pix,
                      label: 'Copiar código Pix',
                      color: const Color(0xFF32BCAD),
                      isPrimary: true,
                      onTap: () => _copyToClipboard(
                          context, fatura.pixCopiaECola!, 'Código Pix'),
                    ),

                  if (fatura.pixCopiaECola != null &&
                      fatura.pixCopiaECola!.isNotEmpty)
                    const SizedBox(height: 8),

                  // Linha digitável / Boleto
                  Row(
                    children: [
                      if (fatura.linhaDigitavel != null &&
                          fatura.linhaDigitavel!.isNotEmpty)
                        Expanded(
                          child: _buildActionButton(
                            context,
                            icon: Icons.content_copy,
                            label: 'Código de barras',
                            color: primaryColor,
                            isPrimary: false,
                            onTap: () => _copyToClipboard(context,
                                fatura.linhaDigitavel!, 'Código de barras'),
                          ),
                        ),
                      if (fatura.linhaDigitavel != null &&
                          fatura.urlBoleto != null)
                        const SizedBox(width: 8),
                      if (fatura.urlBoleto != null &&
                          fatura.urlBoleto!.isNotEmpty)
                        Expanded(
                          child: _buildActionButton(
                            context,
                            icon: Icons.open_in_new,
                            label: 'Ver boleto',
                            color: Colors.blue,
                            isPrimary: false,
                            onTap: () => _openUrl(fatura.urlBoleto!),
                          ),
                        ),
                    ],
                  ),

                  // Se não tem nenhuma opção de pagamento
                  if ((fatura.pixCopiaECola == null ||
                          fatura.pixCopiaECola!.isEmpty) &&
                      (fatura.linhaDigitavel == null ||
                          fatura.linhaDigitavel!.isEmpty) &&
                      (fatura.urlBoleto == null || fatura.urlBoleto!.isEmpty))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Dados de pagamento não disponíveis',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ),

                  // DESBLOQUEIO POR CONFIANÇA - Apenas para faturas vencidas
                  if (fatura.isVencido)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildTrustUnlockButton(context, fatura),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrustUnlockButton(BuildContext context, Fatura fatura) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade600],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTrustUnlockDialog(context, fatura),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_open, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Liberar por Confiança',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTrustUnlockDialog(BuildContext context, Fatura fatura) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_open, color: Colors.purple),
            SizedBox(width: 12),
            Text('Liberação por Confiança'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Libere sua internet por 24 horas enquanto aguarda a confirmação do pagamento.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Essa liberação é válida por apenas 24 horas.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeTrustUnlock(context, fatura);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Liberação'),
          ),
        ],
      ),
    );
  }

  void _executeTrustUnlock(BuildContext context, Fatura fatura) async {
    final configProvider = context.read<ConfigurationProvider>();
    final authService = context.read<AuthService>();
    final providerConfig = configProvider.providerConfig;
    final usuario = authService.usuario;

    if (providerConfig == null || usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Configuração não encontrada'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 16),
            Text('Processando liberação...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final response = await http.post(
        Uri.parse('${providerConfig.apiUrl}/unlock-trust'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cpfCnpj': usuario.cpfCnpj.replaceAll(RegExp(r'[^0-9]'), ''),
          'senha': usuario.senha,
          'faturaId': fatura.numero,
          'sgpParams': {
            'token': providerConfig.config.integrations.apiToken,
            'app': providerConfig.config.integrations.appName,
            'sgpBaseUrl': providerConfig.config.integrations.sgpBaseUrl,
          },
        }),
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Internet liberada por 24 horas!')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error']?['message'] ?? 'Erro ao liberar');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: color.withOpacity(0.4)),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
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
