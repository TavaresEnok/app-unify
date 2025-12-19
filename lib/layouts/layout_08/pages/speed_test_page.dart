import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/diagnostico_service.dart';
import '../../../core/models/diagnostico_state.dart';
import '../theme.dart';

class Layout08SpeedTestPage extends ConsumerStatefulWidget {
  const Layout08SpeedTestPage({super.key});

  @override
  ConsumerState<Layout08SpeedTestPage> createState() =>
      _Layout08SpeedTestPageState();
}

class _Layout08SpeedTestPageState extends ConsumerState<Layout08SpeedTestPage>
    with SingleTickerProviderStateMixin {
  late final DiagnosticoService _service;
  bool _serviceInitialized = false;
  DiagnosticoState _state = DiagnosticoState.initial();
  StreamSubscription? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serviceInitialized) {
      final configProvider = ref.read(configurationProvider);
      final providerConfig = configProvider.providerConfig!;
      _service =
          DiagnosticoService(providerConfig: providerConfig, context: context);
      _subscription = _service.stateStream.listen((newState) {
        setState(() => _state = newState);
      });
      _serviceInitialized = true;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }

  void _startTest() {
    HapticFeedback.heavyImpact();
    _service.runSpeedTestsOnly();
  }

  void _stopTest() {
    _service.stopAllTests();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Layout08Theme.primary(ref.watch(themeProvider).config);
    final isRunning = _state.isTesting ||
        _state.testResultsDisplay['speedTestCustom']?['status'] ==
            TestStatus.running;

    final download = _state.customDownloadResultMbps;
    final upload = _state.customUploadResultMbps;

    return Scaffold(
      backgroundColor: Layout08Theme.background,
      appBar: AppBar(
        title: const Text('SPEED_TEST'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Área de Status Neubrutalista
            Container(
              width: double.infinity,
              decoration:
                  Layout08Theme.neubrutalismDecoration(color: Colors.black),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    isRunning ? 'TESTANDO...' : 'PRONTO',
                    style: const TextStyle(
                      color: Color(0xFFADFF2F),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        (upload > 1 ? upload : download).toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'MBPS',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Barras de Progresso "Rough Styles"
            _buildStatBar('DOWNLOAD', download, primaryColor),
            const SizedBox(height: 16),
            _buildStatBar('UPLOAD', upload, Layout08Theme.secondary(null)),
            const SizedBox(height: 48),
            // Botão de Controle
            GestureDetector(
              onTap: isRunning ? _stopTest : _startTest,
              child: Container(
                width: double.infinity,
                height: 72,
                decoration: Layout08Theme.neubrutalismDecoration(
                  color: isRunning
                      ? const Color(0xFFFF4B4B)
                      : const Color(0xFFADFF2F),
                ),
                child: Center(
                  child: Text(
                    isRunning ? 'PARAR TESTE' : 'INICIAR AGORA',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
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

  Widget _buildStatBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 32,
          decoration: Layout08Theme.neubrutalismDecoration(color: Colors.white),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (value / 500).clamp(0.02, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                border: const Border(
                    right: BorderSide(color: Colors.black, width: 3)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
