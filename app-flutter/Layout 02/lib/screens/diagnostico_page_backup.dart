import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diagnostic_core/diagnostic_core.dart';
import '../configuration_provider.dart';
import '../services/auth_service.dart';

class DiagnosticoPage extends StatefulWidget {
  const DiagnosticoPage({Key? key}) : super(key: key);

  @override
  State<DiagnosticoPage> createState() => _DiagnosticoPageState();
}

class _DiagnosticoPageState extends State<DiagnosticoPage>
    with SingleTickerProviderStateMixin {
  DiagnosticService? _diagnosticService;
  DiagnosticResult? _result;
  bool _isRunning = false;
  double _progress = 0.0;
  String _currentStep = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _runDiagnostic() async {
    final configProvider =
        Provider.of<ConfigurationProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.usuario == null) {
      _showError('Usuário não autenticado');
      return;
    }

    setState(() {
      _isRunning = true;
      _progress = 0.0;
      _result = null;
    });

    try {
      // Inicializar serviço
      _diagnosticService = DiagnosticService(
        proxyBaseUrl: 'http://45.176.56.70:3000',
      );

      // Passo 1: Preparando
      _updateProgress(0.1, '🚀 Iniciando diagnóstico...');
      await Future.delayed(const Duration(milliseconds: 500));

      // Passo 2: Testes locais
      _updateProgress(0.3, '📱 Testando conexão local...');
      await Future.delayed(const Duration(milliseconds: 800));

      _updateProgress(0.5, '⚡ Medindo velocidade...');
      await Future.delayed(const Duration(milliseconds: 800));

      // Passo 3: Consultando SGP
      _updateProgress(0.7, '🌐 Consultando servidor...');
      await Future.delayed(const Duration(milliseconds: 600));

      // Executar diagnóstico real
      final result = await _diagnosticService!.runFullDiagnostic(
        cpfCnpj: authService.usuario!.cpfCnpj,
        senha: authService.usuario!.senha,
        contractId: authService.usuario!.contratoId,
        sgpParams: {
          'token': configProvider.providerConfig.config.integrations.apiToken,
          'app': configProvider.providerConfig.config.integrations.appName ??
              'app_diagnostico',
        },
        sgpBaseUrl:
            configProvider.providerConfig.config.integrations.sgpBaseUrl,
      );

      // Passo 4: Analisando
      _updateProgress(0.9, '🤖 Analisando resultados...');
      await Future.delayed(const Duration(milliseconds: 500));

      _updateProgress(1.0, '✅ Diagnóstico concluído!');
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _result = result;
        _isRunning = false;
      });
    } catch (e) {
      debugPrint('❌ Erro no diagnóstico: $e');
      setState(() {
        _isRunning = false;
      });
      _showError('Erro ao executar diagnóstico: ${e.toString()}');
    }
  }

  void _updateProgress(double progress, String step) {
    if (mounted) {
      setState(() {
        _progress = progress;
        _currentStep = step;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openTicket() async {
    if (_result == null) return;

    final configProvider =
        Provider.of<ConfigurationProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final ticketInfo = await _diagnosticService!.openTicket(
        cpfCnpj: authService.usuario!.cpfCnpj,
        senha: authService.usuario!.senha,
        contractId: authService.usuario!.contratoId,
        diagnostic: _result!,
        sgpParams: {
          'token': configProvider.providerConfig.config.integrations.apiToken,
          'app': configProvider.providerConfig.config.integrations.appName ??
              'app_diagnostico',
        },
        sgpBaseUrl:
            configProvider.providerConfig.config.integrations.sgpBaseUrl,
      );

      Navigator.pop(context); // Fechar loading

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text('Chamado Aberto!'),
            ],
          ),
          content: Text(
            'Protocolo: ${ticketInfo['protocol']}\n\n'
            'Um técnico entrará em contato em breve.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Fechar loading
      _showError('Erro ao abrir chamado: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigurationProvider>(context);
    final themeColor = configProvider.themeColor;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Diagnóstico Completo'),
        backgroundColor: themeColor,
        elevation: 0,
      ),
      body: _buildBody(themeColor),
    );
  }

  Widget _buildBody(Color themeColor) {
    if (_isRunning) {
      return _buildRunningView(themeColor);
    } else if (_result != null) {
      return _buildResultView(themeColor);
    } else {
      return _buildInitialView(themeColor);
    }
  }

  Widget _buildInitialView(Color themeColor) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone animado
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_animationController.value * 0.1),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.network_check,
                      size: 80,
                      color: themeColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),

            // Título
            Text(
              'Diagnóstico Automático',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Descrição
            Text(
              'Detectamos e identificamos problemas na sua conexão automaticamente',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Features
            _buildFeatureItem(
              icon: Icons.speed,
              title: 'Teste de Velocidade',
              subtitle: 'Download e Upload',
              color: themeColor,
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              icon: Icons.wifi,
              title: 'Análise WiFi',
              subtitle: 'Sinal e Qualidade',
              color: themeColor,
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              icon: Icons.router,
              title: 'Sinal Fibra Óptica',
              subtitle: 'Potência RX/TX',
              color: themeColor,
            ),
            const SizedBox(height: 40),

            // Botão Iniciar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _runDiagnostic,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Iniciar Diagnóstico',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green[400]),
        ],
      ),
    );
  }

  Widget _buildRunningView(Color themeColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animação de loading
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  ),
                ),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Status atual
            Text(
              _currentStep,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Mensagem de aguarde
            Text(
              'Isso pode levar alguns segundos...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView(Color themeColor) {
    final result = _result!;
    final isHealthy = result.category == DiagnosticCategory.HEALTHY;
    final isCritical = result.isCritical;

    final statusColor = isHealthy
        ? Colors.green
        : isCritical
            ? Colors.red
            : Colors.orange;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card de Resultado Principal
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.1),
                  statusColor.withOpacity(0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isHealthy ? Icons.check_circle : Icons.warning,
                        color: statusColor,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.problem,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.verified,
                                  size: 16, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                'Confiança: ${(result.confidence * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // Solução
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Solução:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.solution,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tempo Estimado
                Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Tempo estimado: ${result.estimatedTime}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Detalhes Técnicos
          const Text(
            'Detalhes Técnicos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Link Óptico
          _buildDetailCard(
            title: '📡 Link Óptico (SGP)',
            items: [
              _DetailItem(
                icon: Icons.graphic_eq,
                label: 'Sinal RX',
                value: '${result.sgpData.signalRx} dBm',
                status: result.sgpData.signalQuality,
                statusColor: result.sgpData.isSignalHealthy
                    ? Colors.green
                    : result.sgpData.isSignalDegraded
                        ? Colors.orange
                        : Colors.red,
              ),
              _DetailItem(
                icon: Icons.send,
                label: 'Sinal TX',
                value: '${result.sgpData.signalTx} dBm',
              ),
              if (result.sgpData.temperature != null)
                _DetailItem(
                  icon: Icons.thermostat,
                  label: 'Temperatura',
                  value: '${result.sgpData.temperature}°C',
                ),
              _DetailItem(
                icon: Icons.router,
                label: 'OLT',
                value: 'ID ${result.sgpData.oltId} - PON ${result.sgpData.pon}',
              ),
            ],
            themeColor: themeColor,
          ),
          const SizedBox(height: 12),

          // Testes Locais
          _buildDetailCard(
            title: '📱 Testes Locais',
            items: [
              _DetailItem(
                icon: Icons.speed,
                label: 'Latência',
                value: '${result.localTests.latency.toStringAsFixed(1)} ms',
                statusColor: result.localTests.latency < 50
                    ? Colors.green
                    : result.localTests.latency < 100
                        ? Colors.orange
                        : Colors.red,
              ),
              _DetailItem(
                icon: Icons.download,
                label: 'Download',
                value: '${result.localTests.download.toStringAsFixed(1)} Mbps',
              ),
              _DetailItem(
                icon: Icons.upload,
                label: 'Upload',
                value: '${result.localTests.upload.toStringAsFixed(1)} Mbps',
              ),
              if (result.localTests.wifiSignal != null)
                _DetailItem(
                  icon: Icons.wifi,
                  label: 'WiFi',
                  value:
                      '${result.localTests.wifiSignal} dBm (Canal ${result.localTests.wifiChannel ?? "?"})',
                ),
            ],
            themeColor: themeColor,
          ),
          const SizedBox(height: 24),

          // Botões de Ação
          if (!isHealthy) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _openTicket,
                icon: const Icon(Icons.support_agent),
                label: const Text(
                  'Abrir Chamado Técnico',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _result = null;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Fazer Novo Diagnóstico',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: themeColor,
                side: BorderSide(color: themeColor, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required List<_DetailItem> items,
    required Color themeColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...items.map((item) => _buildDetailItem(item, themeColor)).toList(),
        ],
      ),
    );
  }

  Widget _buildDetailItem(_DetailItem item, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(item.icon, size: 20, color: themeColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (item.status != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: item.statusColor?.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.statusColor ?? Colors.grey,
                  width: 1,
                ),
              ),
              child: Text(
                item.status!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: item.statusColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  final String? status;
  final Color? statusColor;

  _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.status,
    this.statusColor,
  });
}
