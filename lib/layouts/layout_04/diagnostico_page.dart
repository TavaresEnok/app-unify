import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/diagnostico_service.dart';
import '../../core/models/diagnostico_state.dart';
import '../../core/providers/configuration_provider.dart';
import 'theme.dart';

class DiagnosticoPage extends StatefulWidget {
  const DiagnosticoPage({super.key});

  @override
  State<DiagnosticoPage> createState() => _DiagnosticoPageState();
}

class _DiagnosticoPageState extends State<DiagnosticoPage> {
  DiagnosticoService? _diagnosticoService;
  bool _isRebooting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initService();
    });
  }

  void _initService() {
    final configProvider = context.read<ConfigurationProvider>();
    if (configProvider.providerConfig != null) {
      setState(() {
        _diagnosticoService = DiagnosticoService(
          providerConfig: configProvider.providerConfig!,
          context: context,
        );
      });
    }
  }

  @override
  void dispose() {
    _diagnosticoService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout04Theme.background,
      appBar: AppBar(
        title: Text('Diagnóstico', style: Layout04Theme.heading3),
        backgroundColor: Layout04Theme.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: _diagnosticoService == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DiagnosticoState>(
              stream: _diagnosticoService!.stateStream,
              builder: (context, snapshot) {
                // Proper handling of initial state if snapshot is empty
                final state = snapshot.data;
                if (state == null)
                  return const Center(child: CircularProgressIndicator());

                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusCard(state: state),
                      const SizedBox(height: 24),
                      Text('Status dos Testes', style: Layout04Theme.heading3),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: [
                            _TestResultItem(
                                label: 'Internet (IPv4/IPv6)',
                                result: state.testResultsDisplay['publicIp']),
                            const SizedBox(height: 12),
                            _TestResultItem(
                                label: 'Conexão WiFi',
                                result: state.testResultsDisplay['wifiInfo']),
                            const SizedBox(height: 12),
                            _TestResultItem(
                                label: 'Latência (Google)',
                                result: state.testResultsDisplay['pingGoogle']),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: (_isRebooting || state.isTesting)
                              ? null
                              : _runDiagnostics,
                          style: Layout04Theme.outlineButtonStyle,
                          icon: (state.isTesting)
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : Icon(Icons.play_arrow_rounded,
                                  color: Layout04Theme.textPrimary),
                          label: Text(state.isTesting
                              ? 'Rodando Testes...'
                              : 'Iniciar Diagnóstico'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _runDiagnostics() async {
    if (_diagnosticoService != null) {
      _diagnosticoService!.runAllTests();
    }
  }
}

class _StatusCard extends StatelessWidget {
  final DiagnosticoState state;

  const _StatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String text;
    String subtext;

    if (state.isTesting) {
      icon = Icons.sync;
      color = Layout04Theme.primary;
      text = 'Diagnosticando...';
      subtext = state.geralStatusMessage;
    } else {
      // Simple logic based on completion
      // Check if any error exists
      bool hasError = state.testResultsDisplay.values
          .any((t) => t['status'] == TestStatus.error);
      if (hasError) {
        icon = Icons.warning_amber_rounded;
        color = Layout04Theme.warning; // Or error
        text = 'Atenção Necessária';
        subtext = 'Encontramos alguns problemas.';
      } else {
        icon = Icons.check_circle_outline;
        color = Layout04Theme.success;
        text = 'Diagnóstico Pronto';
        subtext = 'Toque para iniciar uma nova verificação.';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: Layout04Theme.cardDecoration,
      child: Column(
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 16),
          Text(text,
              style: Layout04Theme.heading2, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(subtext,
              style: Layout04Theme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _TestResultItem extends StatelessWidget {
  final String label;
  final Map<String, dynamic>? result;

  const _TestResultItem({required this.label, required this.result});

  @override
  Widget build(BuildContext context) {
    final status = result?['status'] as TestStatus? ?? TestStatus.pending;
    final resultText = result?['result'] as String? ?? '';

    IconData icon;
    Color color;

    switch (status) {
      case TestStatus.running:
        icon = Icons.sync;
        color = Layout04Theme.primary;
        break;
      case TestStatus.success:
        icon = Icons.check_circle;
        color = Layout04Theme.success;
        break;
      case TestStatus.error:
        icon = Icons.error;
        color = Layout04Theme.error;
        break;
      default:
        icon = Icons.circle_outlined;
        color = Layout04Theme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Layout04Theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Text(label, style: Layout04Theme.heading3.copyWith(fontSize: 16)),
            ],
          ),
          if (resultText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(resultText, style: Layout04Theme.bodySmall),
          ]
        ],
      ),
    );
  }
}
