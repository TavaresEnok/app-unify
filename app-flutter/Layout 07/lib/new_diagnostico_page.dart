import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'configuration_provider.dart';
import 'services/auth_service.dart';
import 'services/diagnostic_service.dart';
import 'services/sgp_diagnostic_service.dart';
import 'models/diagnostic_result.dart';
import 'models/diagnostic_category.dart';
import 'utils.dart' show hexToColor;

// Página de diagnóstico revolucionária - Fase 1
class NewDiagnosticoPage extends StatefulWidget {
  const NewDiagnosticoPage({super.key});

  @override
  State<NewDiagnosticoPage> createState() => _NewDiagnosticoPageState();
}

class _NewDiagnosticoPageState extends State<NewDiagnosticoPage> {
  DiagnosticResult? _result;
  bool _isRunning = false;
  late DiagnosticService _diagnosticService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Inicializar service com configuração SGP
    final config = context.read<ConfigurationProvider>().providerConfig;

    SGPDiagnosticService? sgpService;
    if (config != null) {
      final integrations = config.config.integrations;
      sgpService = SGPDiagnosticService(
        baseUrl: integrations.sgpBaseUrl,
        token: integrations.apiToken,
        appName: integrations.appName,
      );
    }

    _diagnosticService = DiagnosticService(sgpService: sgpService);
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isRunning = true;
      _result = null;
    });

    try {
      final authService = context.read<AuthService>();
      final user = authService.usuario;

      final result = await _diagnosticService.runFullDiagnostic(
        cpfCnpj: user?.cpfCnpj,
        contractId: user?.contratoId,
      );

      setState(() {
        _result = result;
        _isRunning = false;
      });
    } catch (e) {
      print('Erro no diagnóstico: $e');
      setState(() {
        _isRunning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao executar diagnóstico: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfigurationProvider>().providerConfig!;
    final primaryColor = hexToColor(config.config.themeColor);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico Avançado'),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botão de executar
            if (!_isRunning && _result == null) _buildStartCard(primaryColor),

            // Loading
            if (_isRunning) _buildLoadingCard(primaryColor),

            // Resultado
            if (_result != null) ...[
              _buildResultCard(primaryColor),
              const SizedBox(height: 16),
              _buildOnuSignalCard(),
              const SizedBox(height: 16),
              _buildLocalTestsCard(),
              const SizedBox(height: 16),
              _buildActionsCard(primaryColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStartCard(Color primaryColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.network_check, size: 64, color: primaryColor),
            const SizedBox(height: 16),
            const Text(
              'Diagnóstico Completo',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Vamos analisar sua conexão em detalhes, incluindo:'
              '\n• Sinal da fibra óptica (ONU)'
              '\n• Latência e velocidade'
              '\n• Status do DNS',
              style: TextStyle(fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _runDiagnostic,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar Diagnóstico'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(Color primaryColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 24),
            const Text(
              'Executando testes...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Isso pode levar alguns segundos',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Color primaryColor) {
    final category = _result!.category;
    final isGood = category == DiagnosticCategory.ALL_GOOD;

    return Card(
      elevation: 4,
      color: isGood ? Colors.green.shade50 : Colors.orange.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  category.icon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _result!.problem,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isGood
                              ? Colors.green.shade900
                              : Colors.orange.shade900,
                        ),
                      ),
                      Text(
                        category.displayName,
                        style: TextStyle(
                          color: isGood
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Confiança: ${_result!.confidencePercentage}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _result!.solution,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            if (_result!.estimatedTime != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Tempo estimado: ${_result!.estimatedTime}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOnuSignalCard() {
    final onuData = _result!.onuData;

    if (onuData == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[400]),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Dados do sinal ONU não disponíveis'),
              ),
            ],
          ),
        ),
      );
    }

    final color = onuData.isSignalHealthy
        ? Colors.green
        : onuData.isSignalDegraded
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.router, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Sinal Óptico (ONU)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // RX Signal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('RX (Recebido)', style: TextStyle(fontSize: 14)),
                Row(
                  children: [
                    Text(
                      '${onuData.signalRx.toStringAsFixed(1)} dBm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(onuData.signalQualityIcon,
                        style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: onuData.signalPercentage,
              backgroundColor: Colors.grey[200],
              color: color,
              minHeight: 8,
            ),
            const SizedBox(height: 4),
            Text(
              onuData.signalQuality,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 16),

            // TX Signal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TX (Transmitido)', style: TextStyle(fontSize: 14)),
                Text(
                  '${onuData.signalTx.toStringAsFixed(1)} dBm',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalTestsCard() {
    final tests = _result!.localTests;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.speed, size: 24),
                SizedBox(width: 8),
                Text(
                  'Testes de Conectividade',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTestItem(
              Icons.router_outlined,
              'Latência',
              tests.latency != null
                  ? '${tests.latency!.toStringAsFixed(0)} ms'
                  : 'N/A',
              tests.latencyIcon,
            ),
            const Divider(height: 24),
            _buildTestItem(
              Icons.download,
              'Download',
              tests.download != null
                  ? '${tests.download!.toStringAsFixed(1)} Mbps'
                  : 'N/A',
              tests.download != null && tests.download! > 10 ? '✅' : '⚠️',
            ),
            const Divider(height: 24),
            _buildTestItem(
              Icons.upload,
              'Upload',
              tests.upload != null
                  ? '${tests.upload!.toStringAsFixed(1)} Mbps'
                  : 'N/A',
              tests.upload != null && tests.upload! > 5 ? '✅' : '⚠️',
            ),
            const Divider(height: 24),
            _buildTestItem(
              Icons.dns,
              'DNS',
              tests.dnsStatus ? 'Funcionando' : 'Falha',
              tests.dnsStatus ? '✅' : '❌',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestItem(
      IconData icon, String label, String value, String emoji) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 15)),
        ),
        Text(value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Text(emoji, style: const TextStyle(fontSize: 18)),
      ],
    );
  }

  Widget _buildActionsCard(Color primaryColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ações Disponíveis',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _runDiagnostic,
                icon: const Icon(Icons.refresh),
                label: const Text('Executar Novamente'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_result!.needsTechnician) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Funcionalidade em desenvolvimento')),
                    );
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text('Abrir Chamado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
