// LAYOUT 04 - AURORA - FINANCEIRO PAGE

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../core/providers/financeiro_provider.dart';
import '../../core/models/fatura.dart';
import 'aurora_theme.dart';

class FinanceiroPage extends StatefulWidget {
  const FinanceiroPage({super.key});

  @override
  State<FinanceiroPage> createState() => _FinanceiroPageState();
}

class _FinanceiroPageState extends State<FinanceiroPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceiroProvider>().fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          pinned: true,
          expandedHeight: 100,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'Faturas',
                    style: TextStyle(
                      color: AuroraColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: Consumer<FinanceiroProvider>(
            builder: (context, provider, _) {
              if (provider.state == FinanceiroState.loading) {
                return const SliverFillRemaining(
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AuroraColors.primary),
                  ),
                );
              }

              if (provider.state == FinanceiroState.error) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AuroraColors.error, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          provider.errorMessage,
                          style: const TextStyle(
                              color: AuroraColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        AuroraButton(
                          label: 'Tentar novamente',
                          onPressed: () => provider.fetchHistory(),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (provider.invoices.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            color: AuroraColors.textMuted, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'Nenhuma fatura encontrada',
                          style: TextStyle(
                              color: AuroraColors.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final fatura = provider.invoices[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FaturaCard(fatura: fatura),
                    );
                  },
                  childCount: provider.invoices.length,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FaturaCard extends StatelessWidget {
  final Fatura fatura;

  const _FaturaCard({required this.fatura});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (fatura.isPago) {
      statusColor = AuroraColors.success;
      statusText = 'Pago';
      statusIcon = Icons.check_circle;
    } else if (fatura.isVencido) {
      statusColor = AuroraColors.error;
      statusText = 'Vencida';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = AuroraColors.warning;
      statusText = 'Pendente';
      statusIcon = Icons.schedule;
    }

    final formattedAmount =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
            .format(fatura.valor);
    final formattedDate = DateFormat('dd/MM/yyyy').format(fatura.vencimento);

    return AuroraCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const AuroraIconBox(
                  icon: Icons.receipt_long_rounded,
                  color: AuroraColors.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedAmount,
                      style: const TextStyle(
                        color: AuroraColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vencimento: $formattedDate',
                      style: const TextStyle(
                          color: AuroraColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              AuroraStatusBadge(
                  text: statusText, color: statusColor, icon: statusIcon),
            ],
          ),
          if (!fatura.isPago) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (fatura.pixCopiaECola != null &&
                    fatura.pixCopiaECola!.isNotEmpty)
                  Expanded(
                    child: AuroraButton(
                      label: 'PIX',
                      icon: Icons.qr_code_rounded,
                      onPressed: () =>
                          _showPixDialog(context, fatura.pixCopiaECola!),
                    ),
                  ),
                if (fatura.pixCopiaECola != null &&
                    fatura.pixCopiaECola!.isNotEmpty &&
                    fatura.urlBoleto != null)
                  const SizedBox(width: 12),
                if (fatura.urlBoleto != null && fatura.urlBoleto!.isNotEmpty)
                  Expanded(
                    child: AuroraButton(
                      label: 'Boleto',
                      icon: Icons.receipt_outlined,
                      onPressed: () => _openBoleto(fatura.urlBoleto!),
                      isOutlined: true,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showPixDialog(BuildContext context, String pixCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Código PIX',
            style: TextStyle(color: AuroraColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AuroraColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                pixCode,
                style: const TextStyle(
                    color: AuroraColors.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AuroraButton(
                label: 'Copiar Código',
                icon: Icons.copy,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: pixCode));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código PIX copiado!')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openBoleto(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
