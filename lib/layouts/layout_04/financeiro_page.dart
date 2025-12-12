// LAYOUT 04 - AURORA - FINANCEIRO PAGE
// Design: Premium invoice list with glassmorphic cards

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
import 'aurora_theme.dart';

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
      child: AuroraBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: ShaderMask(
              shaderCallback: (bounds) =>
                  AuroraColors.primaryGradient.createShader(bounds),
              child: const Text('Faturas',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            centerTitle: true,
            elevation: 0,
          ),
          body: Consumer<FinanceiroProvider>(
            builder: (context, provider, child) {
              if (provider.state == FinanceiroState.loading) {
                return _buildLoadingState();
              }

              if (provider.state == FinanceiroState.error) {
                return _buildErrorState(context, provider);
              }

              if (provider.invoices.isEmpty) {
                return _buildEmptyState(context, provider);
              }

              return RefreshIndicator(
                color: AuroraColors.neonCyan,
                backgroundColor: AuroraColors.surface,
                onRefresh: provider.fetchHistory,
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: provider.invoices.length,
                  itemBuilder: (context, index) => _buildInvoiceCard(
                      context, provider.invoices[index], index),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AuroraColors.neonCyan),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Carregando faturas...',
            style: TextStyle(color: AuroraColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, FinanceiroProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeonIconBadge(
                  icon: Icons.error_outline,
                  color: AuroraColors.error,
                  size: 64),
              const SizedBox(height: 20),
              Text(
                'Erro ao carregar',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AuroraColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage.isNotEmpty
                    ? provider.errorMessage
                    : 'Tente novamente',
                style: TextStyle(color: AuroraColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              NeonButton(
                text: 'Tentar Novamente',
                icon: Icons.refresh,
                onPressed: provider.fetchHistory,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, FinanceiroProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          glowColor: AuroraColors.success,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeonIconBadge(
                  icon: Icons.check_circle,
                  color: AuroraColors.success,
                  size: 64),
              const SizedBox(height: 20),
              Text(
                'Tudo em dia!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AuroraColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Não há faturas pendentes',
                style: TextStyle(color: AuroraColors.textSecondary),
              ),
              const SizedBox(height: 24),
              NeonButton(
                text: 'Atualizar',
                icon: Icons.refresh,
                isOutlined: true,
                onPressed: provider.fetchHistory,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Fatura fatura, int index) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    Color statusColor = AuroraColors.warning;
    String statusText = 'Pendente';
    IconData statusIcon = Icons.schedule;

    if (fatura.isPago) {
      statusColor = AuroraColors.success;
      statusText = 'Pago';
      statusIcon = Icons.check_circle;
    } else if (fatura.isVencido) {
      statusColor = AuroraColors.error;
      statusText = 'Vencido';
      statusIcon = Icons.error;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GlassCard(
          glowColor: statusColor.withOpacity(0.5),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => AuroraColors
                                .primaryGradient
                                .createShader(bounds),
                            child: Text(
                              currencyFormat.format(fatura.valor),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fatura.isPago
                                ? 'Pago em ${dateFormat.format(fatura.dataPagamento ?? fatura.vencimento)}'
                                : 'Vence ${dateFormat.format(fatura.vencimento)}',
                            style: TextStyle(color: AuroraColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 6),
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
              ),

              // Actions
              if (!fatura.isPago) ...[
                Container(
                  width: double.infinity,
                  height: 1,
                  color: AuroraColors.glassBorder,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (fatura.pixCopiaECola != null &&
                          fatura.pixCopiaECola!.isNotEmpty)
                        _buildPaymentButton(
                          context,
                          icon: Icons.pix,
                          label: 'Copiar código Pix',
                          colors: [
                            const Color(0xFF32BCAD),
                            const Color(0xFF00D9A5)
                          ],
                          onTap: () => _copyToClipboard(
                              context, fatura.pixCopiaECola!, 'Código Pix'),
                        ),
                      if (fatura.pixCopiaECola != null &&
                          fatura.pixCopiaECola!.isNotEmpty)
                        const SizedBox(height: 12),
                      Row(
                        children: [
                          if (fatura.linhaDigitavel != null &&
                              fatura.linhaDigitavel!.isNotEmpty)
                            Expanded(
                              child: _buildSmallButton(
                                icon: Icons.content_copy,
                                label: 'Código de barras',
                                onTap: () => _copyToClipboard(context,
                                    fatura.linhaDigitavel!, 'Código de barras'),
                              ),
                            ),
                          if (fatura.linhaDigitavel != null &&
                              fatura.urlBoleto != null)
                            const SizedBox(width: 12),
                          if (fatura.urlBoleto != null &&
                              fatura.urlBoleto!.isNotEmpty)
                            Expanded(
                              child: _buildSmallButton(
                                icon: Icons.open_in_new,
                                label: 'Ver boleto',
                                onTap: () => _openUrl(fatura.urlBoleto!),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: colors.first.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AuroraColors.glassWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AuroraColors.glassBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AuroraColors.neonCyan, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                  color: AuroraColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ],
        ),
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
        backgroundColor: AuroraColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
