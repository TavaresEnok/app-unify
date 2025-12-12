import 'dart:convert';
import 'dart:ui';
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
import 'theme.dart';

class FinanceiroPage extends StatelessWidget {
  const FinanceiroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final configProvider = context.read<ConfigurationProvider>();
    final authService = context.read<AuthService>();
    final providerConfig = configProvider.providerConfig;
    final usuario = authService.usuario;

    if (providerConfig == null) {
      return Scaffold(
        backgroundColor: Layout04Theme.background,
        body: Center(
          child: Text(
            'Configuração não encontrada',
            style: Layout04Theme.bodyMedium,
          ),
        ),
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
        backgroundColor: Layout04Theme.background,
        body: Container(
          decoration: const BoxDecoration(
            gradient: Layout04Theme.backgroundGradient,
          ),
          child: Consumer<FinanceiroProvider>(
            builder: (context, provider, child) {
              if (provider.state == FinanceiroState.loading) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Layout04Theme.primaryCyan,
                    ),
                  ),
                );
              }

              if (provider.state == FinanceiroState.error) {
                return _buildErrorState(context, provider);
              }

              if (provider.invoices.isEmpty) {
                return _buildEmptyState(context, provider);
              }

              return RefreshIndicator(
                onRefresh: provider.fetchHistory,
                color: Layout04Theme.primaryCyan,
                backgroundColor: Layout04Theme.backgroundLight,
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: Layout04Theme.secondaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              provider.errorMessage,
              textAlign: TextAlign.center,
              style: Layout04Theme.bodyLarge,
            ),
            const SizedBox(height: 32),
            _NeonButton(
              label: 'TENTAR NOVAMENTE',
              onPressed: provider.fetchHistory,
              icon: Icons.refresh_rounded,
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: Layout04Theme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text('Nenhuma fatura encontrada', style: Layout04Theme.heading3),
          const SizedBox(height: 32),
          _NeonButton(
            label: 'ATUALIZAR',
            onPressed: provider.fetchHistory,
            icon: Icons.refresh_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Fatura fatura) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    // Status visual
    Color statusColor = Layout04Theme.warning;
    String statusText = 'Pendente';
    IconData statusIcon = Icons.schedule_rounded;

    if (fatura.isPago) {
      statusColor = Layout04Theme.success;
      statusText = 'Pago';
      statusIcon = Icons.check_circle_rounded;
    } else if (fatura.isVencido) {
      statusColor = Layout04Theme.error;
      statusText = 'Vencido';
      statusIcon = Icons.error_rounded;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: Layout04Theme.glassCard(),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Valor
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => Layout04Theme
                                .accentGradient
                                .createShader(bounds),
                            child: Text(
                              currencyFormat.format(fatura.valor),
                              style: Layout04Theme.heading2.copyWith(
                                color: Colors.white,
                                fontSize: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fatura.isPago
                                ? 'Pago em ${dateFormat.format(fatura.dataPagamento ?? fatura.vencimento)}'
                                : 'Vence ${dateFormat.format(fatura.vencimento)}',
                            style: Layout04Theme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: Layout04Theme.statusBadge(statusColor),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: Layout04Theme.bodySmall.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Ações de pagamento (apenas para não pagas)
              if (!fatura.isPago) ...[
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Layout04Theme.glassBorder,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // PIX - Botão principal
                      if (fatura.pixCopiaECola != null &&
                          fatura.pixCopiaECola!.isNotEmpty)
                        _NeonButton(
                          label: 'COPIAR PIX',
                          icon: Icons.pix,
                          onPressed: () => _copyToClipboard(
                            context,
                            fatura.pixCopiaECola!,
                            'Código Pix',
                          ),
                        ),

                      if (fatura.pixCopiaECola != null &&
                          fatura.pixCopiaECola!.isNotEmpty)
                        const SizedBox(height: 12),

                      // Linha digitável / Boleto
                      Row(
                        children: [
                          if (fatura.linhaDigitavel != null &&
                              fatura.linhaDigitavel!.isNotEmpty)
                            Expanded(
                              child: _GlassButton(
                                icon: Icons.content_copy_rounded,
                                label: 'Código',
                                onPressed: () => _copyToClipboard(
                                  context,
                                  fatura.linhaDigitavel!,
                                  'Código de barras',
                                ),
                              ),
                            ),
                          if (fatura.linhaDigitavel != null &&
                              fatura.urlBoleto != null)
                            const SizedBox(width: 8),
                          if (fatura.urlBoleto != null &&
                              fatura.urlBoleto!.isNotEmpty)
                            Expanded(
                              child: _GlassButton(
                                icon: Icons.open_in_new_rounded,
                                label: 'Boleto',
                                onPressed: () => _openUrl(fatura.urlBoleto!),
                              ),
                            ),
                        ],
                      ),

                      // Se não tem nenhuma opção de pagamento
                      if ((fatura.pixCopiaECola == null ||
                              fatura.pixCopiaECola!.isEmpty) &&
                          (fatura.linhaDigitavel == null ||
                              fatura.linhaDigitavel!.isEmpty) &&
                          (fatura.urlBoleto == null ||
                              fatura.urlBoleto!.isEmpty))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Dados de pagamento não disponíveis',
                            style: Layout04Theme.bodySmall,
                          ),
                        ),

                      // DESBLOQUEIO POR CONFIANÇA
                      if (fatura.isVencido)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _TrustUnlockButton(fatura: fatura),
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

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Layout04Theme.success),
            const SizedBox(width: 12),
            Text('$label copiado!'),
          ],
        ),
        backgroundColor: Layout04Theme.backgroundLight,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Layout04Theme.glassBorder),
        ),
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

// === NEON BUTTON ===

class _NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const _NeonButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Container(
        decoration: Layout04Theme.neonButton(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(label, style: Layout04Theme.buttonText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// === GLASS BUTTON ===

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Layout04Theme.glassWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Layout04Theme.glassBorder),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Layout04Theme.primaryCyan, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: Layout04Theme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Layout04Theme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// === TRUST UNLOCK BUTTON ===

class _TrustUnlockButton extends StatelessWidget {
  final Fatura fatura;

  const _TrustUnlockButton({required this.fatura});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: Layout04Theme.secondaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Layout04Theme.neonGlow(Layout04Theme.primaryPurple),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTrustUnlockDialog(context, fatura),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_open_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'LIBERAR POR CONFIANÇA',
                style: Layout04Theme.buttonText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrustUnlockDialog(BuildContext context, Fatura fatura) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Layout04Theme.backgroundLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Layout04Theme.glassBorder, width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: Layout04Theme.secondaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_open_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text('Liberação por Confiança', style: Layout04Theme.heading3),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Libere sua internet por 24 horas enquanto aguarda a confirmação do pagamento.',
                style: Layout04Theme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Layout04Theme.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Layout04Theme.warning.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Layout04Theme.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Essa liberação é válida por apenas 24 horas.',
                        style: Layout04Theme.bodySmall.copyWith(
                          color: Layout04Theme.warning,
                        ),
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
              child: Text(
                'CANCELAR',
                style: Layout04Theme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              height: 42,
              decoration: Layout04Theme.neonButton(
                gradient: Layout04Theme.secondaryGradient,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _executeTrustUnlock(context, fatura);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        'CONFIRMAR',
                        style: Layout04Theme.buttonText.copyWith(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
        SnackBar(
          content: const Text('Erro: Configuração não encontrada'),
          backgroundColor: Layout04Theme.error,
        ),
      );
      return;
    }

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Layout04Theme.primaryCyan,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text('Processando liberação...'),
          ],
        ),
        backgroundColor: Layout04Theme.backgroundLight,
        duration: const Duration(seconds: 30),
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
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Layout04Theme.success,
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Internet liberada por 24 horas!')),
              ],
            ),
            backgroundColor: Layout04Theme.backgroundLight,
            duration: const Duration(seconds: 4),
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
          content: Text(
            'Erro: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Layout04Theme.error,
        ),
      );
    }
  }
}
