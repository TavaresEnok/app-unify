import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'providers/consumo_provider.dart';
import 'services/consumo_service.dart';
import 'configuration_provider.dart';
import 'utils.dart' show hexToColor;
import 'widgets/glass_card.dart'; // NOVO
import 'widgets/section_header.dart'; // NOVO

class ConsumoPage extends StatelessWidget {
  final String cpfCnpj;
  final String senha;

  const ConsumoPage({super.key, required this.cpfCnpj, required this.senha});

  @override
  Widget build(BuildContext context) {
    final providerConfig =
        context.read<ConfigurationProvider>().providerConfig!;
    final primaryColor = hexToColor(providerConfig.config.themeColor);
    final apiUrl = '${providerConfig.apiUrl}/get-consumption-data';
    final sgpParams = {
      "token": providerConfig.config.integrations.apiToken,
      "app": providerConfig.config.integrations.appName,
      "sgpBaseUrl": providerConfig.config.integrations.sgpBaseUrl, // ADICIONADO
    };

    return ChangeNotifierProvider(
      create: (_) => ConsumoProvider(
        ConsumoService(
          apiUrl: apiUrl,
          sgpParams: sgpParams,
          cpfCnpj: cpfCnpj,
          senha: senha,
        ),
      )..fetchConsumptionData(),
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // Transparente para o gradiente funcionar
        appBar: AppBar(
          title: Text('Meu Consumo',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF050816), Color(0xFF111B2C), Color(0xFF1E2740)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Consumer<ConsumoProvider>(
                builder: (context, provider, child) {
                  switch (provider.state) {
                    case ConsumoState.loading:
                    case ConsumoState.idle:
                      return _buildShimmerLoading();

                    case ConsumoState.error:
                      return _buildErrorWidget(
                          context, provider.errorMessage!, primaryColor);

                    case ConsumoState.success:
                      final data = provider.consumptionData ?? {};
                      if (data.isEmpty) {
                        return _buildErrorWidget(
                            context,
                            'Não foi possível obter os dados de consumo.',
                            primaryColor);
                      }
                      final double usedGb =
                          (data['usedGb'] as num? ?? 0).toDouble();
                      final double totalGb =
                          (data['totalGb'] as num? ?? 1000).toDouble();
                      final String planName =
                          data['planName'] as String? ?? 'Plano não informado';
                      final String period = data['period'] as String? ?? 'N/A';
                      return _buildPageContent(
                          usedGb, totalGb, planName, period, primaryColor);
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(double usedGb, double totalGb, String planName,
      String period, Color primaryColor) {
    final double percentage =
        totalGb > 0 ? (usedGb / totalGb).clamp(0.0, 1.0) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: 'Consumo do ciclo',
              subtitle: 'Período: $period',
              icon: Icons.data_usage_rounded,
            ),
            const SizedBox(height: 24),
            Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                        vertical: 32, horizontal: 32),
                    child: Column(
                      children: [
                        _ConsumptionRing(
                          percentage: percentage,
                          usedGb: usedGb,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${(percentage * 100).toStringAsFixed(0)}% utilizado',
                          style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isWide)
                  const SizedBox(width: 24)
                else
                  const SizedBox(height: 24),
                Flexible(
                  fit: FlexFit.loose,
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SEU PLANO',
                            style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        Text(planName,
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 32),
                        Text('FRANQUIA TOTAL',
                            style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        Text('${totalGb.toStringAsFixed(0)} GB',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 32),
                        if (percentage >= 0.8)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: Colors.orange, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(
                                        "Sua franquia está quase acabando.",
                                        style: GoogleFonts.inter(
                                            color: Colors.orange,
                                            fontSize: 12))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorWidget(
      BuildContext context, String errorMessage, Color primaryColor) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 50),
            const SizedBox(height: 16),
            Text('Falha ao Carregar',
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text(errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white70)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              onPressed: () =>
                  context.read<ConsumoProvider>().fetchConsumptionData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1F2937),
      highlightColor: const Color(0xFF374151),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
              width: 150,
              height: 20,
              decoration: BoxDecoration(
                  color: Colors.black, borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 8),
          Container(
              width: 120,
              height: 24,
              decoration: BoxDecoration(
                  color: Colors.black, borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 40),
          const CircleAvatar(radius: 90, backgroundColor: Colors.black),
          const SizedBox(height: 40),
          Container(
              width: double.infinity,
              height: 90,
              decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16))),
        ],
      ),
    );
  }
}

class _ConsumptionRing extends StatelessWidget {
  final double percentage;
  final double usedGb;
  final Color primaryColor;

  const _ConsumptionRing(
      {required this.percentage,
      required this.usedGb,
      required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: percentage),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              const CircularProgressIndicator(
                value: 1,
                strokeWidth: 14,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white12),
              ),
              CircularProgressIndicator(
                value: value,
                strokeWidth: 14,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      usedGb.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold),
                    ),
                    Text('GB usados',
                        style: GoogleFonts.inter(
                            color: Colors.blueGrey[200], fontSize: 14)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
