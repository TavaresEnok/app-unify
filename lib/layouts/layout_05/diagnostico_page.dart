import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/configuration_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/diagnostico_service.dart';
import '../../core/services/onu_wifi_service.dart';
import '../../core/models/diagnostico_state.dart';
import 'theme.dart';

class DiagnosticoPage extends StatefulWidget {
  const DiagnosticoPage({super.key});

  @override
  State<DiagnosticoPage> createState() => _DiagnosticoPageState();
}

class _DiagnosticoPageState extends State<DiagnosticoPage> {
  late final DiagnosticoService _service;
  OnuWifiService?
      _onuWifiService; // Kept for consistency if needed direct access
  bool _serviceInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serviceInitialized) {
      final providerConfig =
          context.read<ConfigurationProvider>().providerConfig!;
      final authService = context.read<AuthService>();
      final usuario = authService.usuario;

      _service =
          DiagnosticoService(providerConfig: providerConfig, context: context);

      // Auto-start tests on load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _service.runAllTests();
      });

      _serviceInitialized = true;
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DiagnosticoState>(
      stream: _service.stateStream,
      initialData: DiagnosticoState.initial(),
      builder: (context, snapshot) {
        final state = snapshot.data!;

        return Scaffold(
          backgroundColor: Layout05Theme.background,
          appBar: AppBar(
            title:
                Text('Diagnóstico Inteligente', style: Layout05Theme.heading2),
            backgroundColor: Layout05Theme.background,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Layout05Theme.textDark),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderStatus(state),
                const SizedBox(height: 32),

                // Connection Journey
                Text('Jornada da Conexão', style: Layout05Theme.heading2),
                const SizedBox(height: 16),
                _buildJourneyStep(
                  icon: Icons.smartphone_rounded,
                  title: 'Seu Dispositivo',
                  status: _getStepStatus(state, 'wifiInfo'),
                  details: _getStepDetails(state, 'wifiInfo'),
                ),
                _buildConnector(),
                _buildJourneyStep(
                  icon: Icons.router_rounded,
                  title: 'Roteador (Gateway)',
                  status: _getStepStatus(state, 'pingGateway'),
                  details: _getStepDetails(state, 'pingGateway'),
                ),
                _buildConnector(),
                _buildJourneyStep(
                  icon: Icons.public_rounded,
                  title: 'Internet',
                  status: _getStepStatus(state, 'pingGoogle'),
                  details: _getStepDetails(state, 'pingGoogle'),
                ),

                const SizedBox(height: 32),

                // ONU Signal Section (If available)
                if (state.testResultsDisplay.containsKey('deviceInfo')) ...[
                  Text('Sinal da Fibra', style: Layout05Theme.heading2),
                  const SizedBox(height: 16),
                  _buildOnuSignalCard(state),
                  const SizedBox(height: 32),
                ],

                // Action Button
                ElevatedButton.icon(
                  onPressed: state.isTesting
                      ? _service.stopAllTests
                      : _service.runAllTests,
                  icon: Icon(state.isTesting
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded),
                  label: Text(state.isTesting
                      ? 'PARAR DIAGNÓSTICO'
                      : 'REFAZER DIAGNÓSTICO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isTesting
                        ? Layout05Theme.error
                        : Layout05Theme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderStatus(DiagnosticoState state) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: Layout05Theme.neumorphicCircleDecoration,
            child: Icon(
              state.isTesting
                  ? Icons.network_check_rounded
                  : Icons.check_circle_outline_rounded,
              size: 48,
              color: state.isTesting
                  ? Layout05Theme.primary
                  : Layout05Theme.success,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            state.geralStatusMessage,
            textAlign: TextAlign.center,
            style: Layout05Theme.bodyText.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyStep({
    required IconData icon,
    required String title,
    required TestStatus status,
    required String details,
  }) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Layout05Theme.neumorphicDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Layout05Theme.background,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                    color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                BoxShadow(
                    color: Color(0x11000000),
                    offset: Offset(2, 2),
                    blurRadius: 4),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Layout05Theme.label),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: Layout05Theme.bodyText.copyWith(
                    color: status == TestStatus.running
                        ? Layout05Theme.primary
                        : Layout05Theme.textDark,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (status == TestStatus.running)
            const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            Icon(
              status == TestStatus.success
                  ? Icons.check_circle_rounded
                  : status == TestStatus.error
                      ? Icons.cancel_rounded
                      : Icons.circle_outlined,
              color: color,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildConnector() {
    return Center(
      child: Container(
        height: 24,
        width: 2,
        color: Layout05Theme.textGrey.withOpacity(0.3),
      ),
    );
  }

  Widget _buildOnuSignalCard(DiagnosticoState state) {
    // Extract info using helper assuming text formatted like "Sinal: -20.0" etc
    // Layout06 parser logic simulation
    final result =
        state.testResultsDisplay['deviceInfo']?['result'] as String? ?? '';
    // Actually device info usually has signal if OnuService puts it there.
    // Wait, Layout06 has specific OnuSignalCard.
    // Here we can use simple display for now.

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: Layout05Theme.neumorphicDecoration,
      child: Text(
        result.isEmpty ? 'Aguardando dados da Fibra...' : result,
        style: Layout05Theme.bodyText,
      ),
    );
  }

  TestStatus _getStepStatus(DiagnosticoState state, String key) {
    return state.testResultsDisplay[key]?['status'] as TestStatus? ??
        TestStatus.pending;
  }

  String _getStepDetails(DiagnosticoState state, String key) {
    final result = state.testResultsDisplay[key]?['result'] as String?;
    final status = _getStepStatus(state, key);

    if (status == TestStatus.running) return 'Testando...';
    if (status == TestStatus.pending) return 'Aguardando...';
    if (result == null || result.isEmpty) return 'Sem dados';

    // Simple parser for one-line summary
    if (key == 'wifiInfo') {
      if (result.contains('SSID:'))
        return result.split('\n').firstWhere((l) => l.contains('SSID:')).trim();
      return 'Wi-Fi Conectado';
    }
    if (key == 'pingGateway') {
      if (result.contains('Latência:'))
        return result
            .split('\n')
            .firstWhere((l) => l.contains('Latência:'))
            .trim();
    }
    if (key == 'pingGoogle') {
      return 'Conexão validada';
    }

    return result.split('\n').first; // Default first line
  }

  Color _getStatusColor(TestStatus status) {
    switch (status) {
      case TestStatus.running:
        return Layout05Theme.primary;
      case TestStatus.success:
        return Layout05Theme.success;
      case TestStatus.error:
        return Layout05Theme.error;
      case TestStatus.pending:
        return Layout05Theme.textGrey;
    }
  }
}
