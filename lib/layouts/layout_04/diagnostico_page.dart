import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/configuration_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/diagnostico_service.dart';
import '../../core/models/diagnostico_state.dart';
import 'theme.dart';

class DiagnosticoPage extends StatefulWidget {
  const DiagnosticoPage({super.key});

  @override
  State<DiagnosticoPage> createState() => _DiagnosticoPageState();
}

class _DiagnosticoPageState extends State<DiagnosticoPage> {
  late final DiagnosticoService _service;
  bool _serviceInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serviceInitialized) {
      final providerConfig =
          context.read<ConfigurationProvider>().providerConfig!;
      _service =
          DiagnosticoService(providerConfig: providerConfig, context: context);

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
          backgroundColor: Layout04Theme.backgroundBlack,
          appBar: AppBar(
            title: Text('Auto Diagnóstico', style: Layout04Theme.heading2),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: const BoxDecoration(
              gradient: Layout04Theme.auroraGradient,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderStatus(state),
                    const SizedBox(height: 48),
                    Text('Checklist de Conexão', style: Layout04Theme.heading2),
                    const SizedBox(height: 24),
                    _buildGlassStep(
                      icon: Icons.smartphone_rounded,
                      title: 'Dispositivo',
                      status: _getStepStatus(state, 'wifiInfo'),
                      details: _getStepDetails(state, 'wifiInfo'),
                    ),
                    _buildNeonConnector(),
                    _buildGlassStep(
                      icon: Icons.router_rounded,
                      title: 'Gateway',
                      status: _getStepStatus(state, 'pingGateway'),
                      details: _getStepDetails(state, 'pingGateway'),
                    ),
                    _buildNeonConnector(),
                    _buildGlassStep(
                      icon: Icons.cloud_done_rounded,
                      title: 'Internet',
                      status: _getStepStatus(state, 'pingGoogle'),
                      details: _getStepDetails(state, 'pingGoogle'),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      decoration: BoxDecoration(boxShadow: [
                        BoxShadow(
                            color: Layout04Theme.neonCyan.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10))
                      ]),
                      child: ElevatedButton(
                        onPressed: state.isTesting
                            ? _service.stopAllTests
                            : _service.runAllTests,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, // Glass button
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                  color: state.isTesting
                                      ? Layout04Theme.neonPink
                                      : Layout04Theme.neonCyan)),
                        ).copyWith(
                            backgroundColor: MaterialStateProperty.all(
                                Colors.white.withOpacity(0.1))),
                        child: Text(
                            state.isTesting ? 'PARAR' : 'VERIFICAR NOVAMENTE',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderStatus(DiagnosticoState state) {
    Color statusColor =
        state.isTesting ? Layout04Theme.neonCyan : Layout04Theme.neonGreen;
    if (state.geralStatusMessage.contains("Erro") ||
        state.geralStatusMessage.contains("Falha")) {
      statusColor = Layout04Theme.neonPink;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(
                    color: statusColor.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 5)
              ]),
          child: Icon(
            state.isTesting ? Icons.network_check : Icons.check_circle_outline,
            size: 64,
            color: statusColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          state.geralStatusMessage,
          textAlign: TextAlign.center,
          style: Layout04Theme.heading1
              .copyWith(shadows: [Shadow(color: statusColor, blurRadius: 10)]),
        ),
      ],
    );
  }

  Widget _buildGlassStep({
    required IconData icon,
    required String title,
    required TestStatus status,
    required String details,
  }) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: Layout04Theme.glassDecoration.copyWith(
          border:
              Border.all(color: color.withOpacity(0.3)) // Dynamic border color
          ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Layout04Theme.label),
                const SizedBox(height: 4),
                Text(details,
                    style:
                        Layout04Theme.bodyText.copyWith(color: Colors.white)),
              ],
            ),
          ),
          if (status == TestStatus.running)
            SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: color, strokeWidth: 2))
          else
            Icon(status == TestStatus.success ? Icons.check : Icons.close,
                color: color)
        ],
      ),
    );
  }

  Widget _buildNeonConnector() {
    return Center(
      child: Container(
        height: 20,
        width: 2,
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.1),
        ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
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

    if (status == TestStatus.running) return 'Analisando...';
    if (status == TestStatus.pending) return 'Aguardando...';
    if (result == null || result.isEmpty) return '---';

    return result.split('\n').first; // Concise
  }

  Color _getStatusColor(TestStatus status) {
    switch (status) {
      case TestStatus.running:
        return Layout04Theme.neonCyan;
      case TestStatus.success:
        return Layout04Theme.neonGreen;
      case TestStatus.error:
        return Layout04Theme.neonPink;
      case TestStatus.pending:
        return Colors.white30;
    }
  }
}
