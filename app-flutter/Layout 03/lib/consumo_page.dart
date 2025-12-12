import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/consumo_provider.dart';
import 'services/consumo_service.dart';
import 'configuration_provider.dart';
import 'utils.dart' show hexToColor;

class ConsumoPage extends StatelessWidget {
  final String cpfCnpj;
  final String senha;

  const ConsumoPage({
    super.key,
    required this.cpfCnpj,
    required this.senha,
  });

  @override
  Widget build(BuildContext context) {
    final configProvider =
        Provider.of<ConfigurationProvider>(context, listen: false);
    final providerConfig = configProvider.providerConfig;

    // Fallback seguro para parâmetros
    final apiUrl = providerConfig?.apiUrl ?? '';
    final sgpParams = {
      'token': providerConfig?.config.integrations.apiToken ?? '',
      'app': providerConfig?.config.integrations.appName ?? '',
      'sgpBaseUrl': providerConfig?.config.integrations.sgpBaseUrl ?? '',
    };
    // final sgpBaseUrl = providerConfig?.config.integrations.sgpBaseUrl ?? ''; // Unused

    final primaryColor = Theme.of(context).primaryColor;

    return ChangeNotifierProvider(
      create: (_) => ConsumoProvider(
        ConsumoService(
          apiUrl: apiUrl,
          sgpParams: sgpParams,
          cpfCnpj: cpfCnpj,
          senha: senha,
          // sgpBaseUrl: sgpBaseUrl, // REMOVED
        ),
      )..fetchConsumptionData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meu Consumo'),
          centerTitle: true,
        ),
        body: Consumer<ConsumoProvider>(
          builder: (context, provider, child) {
            if (provider.state == ConsumoState.loading ||
                provider.state == ConsumoState.idle) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.state == ConsumoState.error) {
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
                        provider.errorMessage ??
                            'Erro ao carregar dados de consumo',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: provider.fetchConsumptionData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = provider.consumptionData ?? {};
            if (data.isEmpty) {
              return const Center(
                  child: Text('Nenhum dado de consumo disponível'));
            }

            final double usedGb = (data['usedGb'] as num? ?? 0).toDouble();
            final double totalGb = (data['totalGb'] as num? ?? 100).toDouble();
            final String planName =
                data['planName'] as String? ?? 'Plano não informado';
            final String period = data['period'] as String? ?? 'N/A';
            final double percentage =
                totalGb > 0 ? (usedGb / totalGb).clamp(0.0, 1.0) : 0.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: 1,
                                  strokeWidth: 12,
                                  color: Colors.grey.shade200,
                                ),
                                CircularProgressIndicator(
                                  value: percentage,
                                  strokeWidth: 12,
                                  color: primaryColor,
                                ),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        usedGb.toStringAsFixed(1),
                                        style: GoogleFonts.inter(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text('GB usados',
                                          style: GoogleFonts.inter(
                                              color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${(percentage * 100).toStringAsFixed(0)}% utilizado',
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SEU PLANO',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            planName,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'FRANQUIA TOTAL',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${totalGb.toStringAsFixed(0)} GB',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'PERÍODO',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            period,
                            style: GoogleFonts.inter(
                                fontSize: 16, color: Colors.black87),
                          ),
                          if (percentage >= 0.8) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      color: Colors.orange),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Sua franquia está quase acabando.',
                                      style: GoogleFonts.inter(
                                          color: Colors.orange),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
