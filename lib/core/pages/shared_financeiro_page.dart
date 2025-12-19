// Layout 02 - Financeiro Page (VERSÃO CLEAN)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../layouts/layout_04/widgets/skeleton_financeiro_page.dart';
import '../../layouts/layout_04/widgets/error_widget.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../../core/models/fatura.dart';
import '../../core/providers/financeiro_provider.dart';
import '../../core/providers/providers.dart';
import '../../layouts/layout_03/theme.dart';

class FinanceiroPage extends ConsumerStatefulWidget {
  const FinanceiroPage({super.key});

  @override
  ConsumerState<FinanceiroPage> createState() => _FinanceiroPageState();
}

class _FinanceiroPageState extends ConsumerState<FinanceiroPage> {
  bool _showAllOpenInvoices = false;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configurationProvider);
    final providerConfig = config.providerConfig;

    if (providerConfig == null) {
      return const Scaffold(
          body: Center(child: Text('Configuração não encontrada')));
    }

    final layoutType = providerConfig.layoutType;
    final isLayout05 = layoutType == 'layout_05';
    final isDarkLayout = layoutType == 'layout_06';

    final themeData = Theme.of(context);
    // Colors setup (condensed for brevity, keeping original logic)
    Color backgroundColor;
    Color appBarColor;
    Color appBarTextColor;

    if (isDarkLayout) {
      backgroundColor = const Color(0xFF0A0A0A);
      appBarColor = const Color(0xFF0A0A0A);
      appBarTextColor = Colors.white;
    } else if (isLayout05) {
      backgroundColor = Layout03Theme.background;
      appBarColor = Layout03Theme.background;
      appBarTextColor = Layout03Theme.textDark;
    } else {
      backgroundColor = Colors.grey[50]!;
      appBarColor = themeData.primaryColor;
      appBarTextColor = Colors.white;
    }

    final provider = ref.watch(financeiroViewModelProvider);

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text('Faturas', style: TextStyle(color: appBarTextColor)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: appBarColor,
          iconTheme: IconThemeData(color: appBarTextColor),
        ),
        body: Builder(builder: (context) {
          if (provider.state == FinanceiroState.loading) {
            return const SkeletonFinanceiroPage();
          }

          if (provider.state == FinanceiroState.error) {
            if (isDarkLayout) {
              return Layout06ErrorWidget(
                title: 'Erro ao carregar faturas',
                message: provider.errorMessage,
                onRetry: provider.fetchHistory,
              );
            }
            return _buildErrorState(context, provider);
          }

          if (provider.invoices.isEmpty) {
            return _buildEmptyState(context, provider);
          }

          // Segregate Invoices
          final openInvoices = provider.invoices
              .where((i) => !i.isPago)
              .toList()
            ..sort((a, b) => a.vencimento.compareTo(b.vencimento));

          final paidInvoices = provider.invoices.where((i) => i.isPago).toList()
            ..sort((a, b) =>
                b.vencimento.compareTo(a.vencimento)); // Newest paid first

          final displayedOpenInvoices = _showAllOpenInvoices
              ? openInvoices
              : (openInvoices.isNotEmpty ? [openInvoices.first] : []);

          final hiddenCount =
              openInvoices.length - displayedOpenInvoices.length;

          return RefreshIndicator(
            onRefresh: provider.fetchHistory,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                if (openInvoices.isNotEmpty) ...[
                  if (!_showAllOpenInvoices && openInvoices.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text("Próxima Fatura (Pagar Agora)",
                          style: TextStyle(
                              color: isDarkLayout
                                  ? Colors.white70
                                  : Colors.grey[700],
                              fontWeight: FontWeight.bold)),
                    ),
                  ...displayedOpenInvoices.map((i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildInvoiceCard(context, i, ref, isLayout05,
                            isDarkLayout: isDarkLayout),
                      )),
                  if (hiddenCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showAllOpenInvoices = true;
                            });
                          },
                          icon: Icon(Icons.add_circle_outline,
                              color: themeData.primaryColor),
                          label: Text("Ver mais $hiddenCount faturas pendentes",
                              style: TextStyle(color: themeData.primaryColor)),
                        ),
                      ),
                    ),
                  if (_showAllOpenInvoices && openInvoices.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _showAllOpenInvoices = false;
                            });
                          },
                          child: const Text("Mostrar menos faturas"),
                        ),
                      ),
                    ),
                ],
                if (paidInvoices.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("Histórico de Pagamentos",
                              style: TextStyle(
                                  color: isDarkLayout
                                      ? Colors.white54
                                      : Colors.grey)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),
                  ...paidInvoices.map((i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildInvoiceCard(context, i, ref, isLayout05,
                            isDarkLayout: isDarkLayout),
                      )),
                ]
              ],
            ),
          );
        }));
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

  Widget _buildInvoiceCard(
      BuildContext context, Fatura fatura, WidgetRef ref, bool isLayout05,
      {bool isDarkLayout = false}) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final primaryColor =
        isDarkLayout ? const Color(0xFF00D9FF) : Theme.of(context).primaryColor;

    // Status visual
    Color statusColor = Colors.orange;
    String statusText = 'Pendente';
    IconData statusIcon = Icons.schedule;

    if (fatura.isPago) {
      statusColor = isDarkLayout
          ? const Color(0xFF30D158)
          : (isLayout05 ? Layout03Theme.success : Colors.green);
      statusText = 'Pago';
      statusIcon = Icons.check_circle;
    } else if (fatura.isVencido) {
      statusColor = isDarkLayout
          ? const Color(0xFFFF453A)
          : (isLayout05 ? Layout03Theme.error : Colors.red);
      statusText = 'Vencido';
      statusIcon = Icons.error;
    }

    BoxDecoration decoration;
    if (isDarkLayout) {
      decoration = BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
      );
    } else if (isLayout05) {
      decoration = Layout03Theme.neumorphicDecoration;
    } else {
      decoration = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      );
    }

    // final textColor = isDarkLayout ? Colors.white : Colors.black87;
    // final subtitleColor =
    //    isDarkLayout ? const Color(0xFF8E8E93) : Colors.grey[600];

    return Container(
      decoration: decoration,
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
                        style: TextStyle(
                            color: fatura.isPago
                                ? (isDarkLayout
                                    ? Colors.white70
                                    : Colors.black87)
                                : Colors.grey[600],
                            fontSize: fatura.isPago ? 15 : 13,
                            fontWeight: fatura.isPago
                                ? FontWeight.bold
                                : FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
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
                      child: _buildTrustUnlockButton(context, fatura, ref),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrustUnlockButton(
      BuildContext context, Fatura fatura, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade600],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTrustUnlockDialog(context, fatura, ref),
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_open, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
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

  void _showTrustUnlockDialog(
      BuildContext context, Fatura fatura, WidgetRef ref) {
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
                color: Colors.orange.withValues(alpha: 0.1),
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
              _executeTrustUnlock(context, fatura, ref);
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

  void _executeTrustUnlock(
      BuildContext context, Fatura fatura, WidgetRef ref) async {
    final config = ref.read(configurationProvider);
    final authState = ref.read(authNotifierProvider);
    final providerConfig = config.providerConfig;
    final usuario = authState.value;

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

      if (!context.mounted) return;

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
      if (!context.mounted) return;
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
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick(); // Charm
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
