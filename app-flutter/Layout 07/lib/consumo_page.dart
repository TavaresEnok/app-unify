import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'configuration_provider.dart';
import 'providers/consumo_provider.dart';
import 'services/consumo_service.dart';
import 'utils.dart' show hexToColor;
import 'models/provider_config.dart'; // Importante para checagem de tipo

class ConsumoPage extends StatelessWidget {
  final String cpfCnpj;
  final String senha;

  const ConsumoPage({super.key, required this.cpfCnpj, required this.senha});

  @override
  Widget build(BuildContext context) {
    // Buscar config dinamicamente
    final configProvider = context.read<ConfigurationProvider>();
    final dynamic config = configProvider.providerConfig;

    if (config == null) {
      return const Scaffold(
        body: Center(child: Text('Configuração não disponível')),
      );
    }

    String? apiToken;
    String? appName;
    String sgpBaseUrl = 'https://vibetelecom.sgp.net.br';
    String themeColor = '#4A90E2';
    String apiUrl = '';

    // Extração Robusta
    if (config is ProviderConfig) {
      // Caso 1: ProviderConfig (Tipado)
      final integrations = config.config.integrations;
      apiToken = integrations.apiToken;
      appName = integrations.appName;
      sgpBaseUrl = integrations.sgpBaseUrl; // Removido ?? sgpBaseUrl
      themeColor = config.config.themeColor;
      apiUrl = config.apiUrl;
    } else if (config is Map) {
      // Caso 2: Map (Dinâmico)
      final configMap = config;

      // Tentar pegar de config.integrations
      final configSection = configMap['config'] as Map<String, dynamic>?;
      final integrations =
          configSection?['integrations'] as Map<String, dynamic>?;

      apiToken = integrations?['apiToken'] as String?;
      appName = integrations?['appName'] as String?;
      sgpBaseUrl = integrations?['sgpBaseUrl'] as String? ?? sgpBaseUrl;
      themeColor = configSection?['themeColor'] as String? ?? themeColor;
      apiUrl = configMap['apiUrl'] as String? ?? '';

      // Fallback para details se necessário
      if ((apiToken == null || apiToken.isEmpty) &&
          configMap.containsKey('details')) {
        final details = configMap['details'] as Map<String, dynamic>?;
        apiToken = details?['apiToken'] as String?;
        appName = details?['appName'] as String?;
        sgpBaseUrl = details?['sgpBaseUrl'] as String? ??
            details?['url'] as String? ??
            sgpBaseUrl;
      }
    }

    final primaryColor = hexToColor(themeColor);
    final fullApiUrl = '$apiUrl/get-consumption-data';

    // CORREÇÃO: Adicionado sgpBaseUrl aos parâmetros
    final sgpParams = {
      "token": apiToken ?? '',
      "app": appName ?? '',
      "sgpBaseUrl": sgpBaseUrl,
    };

    return ChangeNotifierProvider(
      create: (_) => ConsumoProvider(
        ConsumoService(
          apiUrl: fullApiUrl,
          sgpParams: sgpParams,
          cpfCnpj: cpfCnpj,
          senha: senha,
        ),
      )..fetchConsumptionData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meu Consumo'),
          centerTitle: true,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Consumer<ConsumoProvider>(
          builder: (context, provider, child) {
            if (provider.state == ConsumoState.loading ||
                provider.state == ConsumoState.idle) {
              return Center(
                  child: CircularProgressIndicator(color: primaryColor));
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
                        style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white),
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
            final double totalGb = (data['totalGb'] as num? ?? 0).toDouble();
            final String planName = data['planName'] as String? ?? 'Plano';
            final String period = data['period'] as String? ?? '';
            final double downloadSpeed =
                (data['downloadSpeed'] as num? ?? 0).toDouble();
            final double uploadSpeed =
                (data['uploadSpeed'] as num? ?? 0).toDouble();

            final double percentage =
                totalGb > 0 ? (usedGb / totalGb).clamp(0.0, 1.0) : 0.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            planName,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            period,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 32),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: CircularProgressIndicator(
                                  value: percentage,
                                  strokeWidth: 15,
                                  backgroundColor: Colors.grey[200],
                                  color: primaryColor,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(percentage * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const Text('Utilizado'),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildInfoItem(
                                  'Usado',
                                  '${usedGb.toStringAsFixed(1)} GB',
                                  primaryColor),
                              _buildInfoItem(
                                  'Total',
                                  '${totalGb.toStringAsFixed(0)} GB',
                                  Colors.grey),
                            ],
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
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSpeedItem(Icons.arrow_downward, 'Download',
                              '$downloadSpeed Mbps', Colors.green),
                          Container(
                              height: 40, width: 1, color: Colors.grey[300]),
                          _buildSpeedItem(Icons.arrow_upward, 'Upload',
                              '$uploadSpeed Mbps', Colors.blue),
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

  Widget _buildInfoItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSpeedItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
