import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/services/diagnostico_service.dart';
import '../../core/models/diagnostico_state.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/app_button.dart';

class SharedSpeedTestPage extends ConsumerStatefulWidget {
  const SharedSpeedTestPage({super.key});

  @override
  ConsumerState<SharedSpeedTestPage> createState() =>
      _SharedSpeedTestPageState();
}

class _SharedSpeedTestPageState extends ConsumerState<SharedSpeedTestPage> {
  late final DiagnosticoService _service;
  bool _serviceInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serviceInitialized) {
      final configProvider = ref.read(configurationProvider);
      final providerConfig = configProvider.providerConfig!;
      _service =
          DiagnosticoService(providerConfig: providerConfig, context: context);
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
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    return StreamBuilder<DiagnosticoState>(
      stream: _service.stateStream,
      initialData: DiagnosticoState.initial(),
      builder: (context, snapshot) {
        final state = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Teste de Velocidade'),
          ),
          body: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              color: state.isTesting
                  ? primaryColor.withAlpha(38)
                  : Colors.transparent,
              child: Text(
                state.isTesting
                    ? "Testando velocidade..."
                    : "Pronto para iniciar",
                style: textTheme.bodyLarge
                    ?.copyWith(color: state.isTesting ? primaryColor : null),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DashboardCard(
                    child: Column(children: [
                      // SEU SERVIDOR (CUSTOM)
                      _buildSpeedTestTile(context,
                          label: "Velocidade (Seu Servidor)",
                          status: state.testResultsDisplay['speedTestCustom']
                                  ?['status'] as TestStatus? ??
                              TestStatus.pending,
                          resultText:
                              state.testResultsDisplay['speedTestCustom']
                                  ?['result'] as String?,
                          downloadMbps: state.customDownloadResultMbps,
                          uploadMbps: state.customUploadResultMbps,
                          latency: state.speedTestPingLatency,
                          downloadHistory: state.downloadHistory,
                          uploadHistory: state.uploadHistory),

                      const Divider(height: 32),

                      // FAST.COM (REFERENCE)
                      _buildSpeedTestTile(context,
                          label: "Velocidade (Referência Fast.com)",
                          status: state.testResultsDisplay['speedTestFast']
                                  ?['status'] as TestStatus? ??
                              TestStatus.pending,
                          resultText: state.testResultsDisplay['speedTestFast']
                              ?['result'] as String?,
                          downloadMbps: state.fastDownloadResultMbps,
                          uploadMbps: state.fastUploadResultMbps,
                          downloadHistory: state.fastDownloadHistory,
                          uploadHistory: state.fastUploadHistory,
                          isReference: true),
                    ]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
              child: AppButton(
                icon:
                    state.isTesting ? Icons.stop_circle_outlined : Icons.speed,
                label: state.isTesting
                    ? "Parar Teste"
                    : "Iniciar Teste de Velocidade",
                onPressed: () {
                  if (state.isTesting) {
                    _service.stopAllTests();
                  } else {
                    // Executa APENAS os testes de velocidade
                    _service.runSpeedTestsOnly();
                  }
                },
              ),
            ),
          ]),
        );
      },
    );
  }

  // --- WIDGETS AUXILIARES (Copiados de DiagnosticoPage para isolamento) ---

  Widget _buildSpeedTestTile(BuildContext context,
      {required String label,
      required TestStatus status,
      required double downloadMbps,
      required double uploadMbps,
      double? latency,
      required List<FlSpot> downloadHistory,
      required List<FlSpot> uploadHistory,
      String? resultText,
      bool isReference = false}) {
    final theme = Theme.of(context);
    final showData = status == TestStatus.success ||
        status == TestStatus.running ||
        status == TestStatus.error;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildTileHeader(context, label: label, status: status),
      if (status == TestStatus.pending ||
          (status == TestStatus.running && !showData))
        _buildTileStatusText(context, status: status, result: resultText)
      else if (showData) ...[
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
              child: _buildSpeedStatBox(context,
                  title: "Download",
                  mbps: downloadMbps,
                  icon: Icons.arrow_downward_rounded)),
          Container(width: 1, height: 50, color: theme.dividerColor),
          Expanded(
              child: _buildSpeedStatBox(context,
                  title: "Upload",
                  mbps: uploadMbps,
                  icon: Icons.arrow_upward_rounded)),
          if (!isReference)
            Container(width: 1, height: 50, color: theme.dividerColor),
          if (!isReference)
            Expanded(
                child: _buildSpeedStatBox(context,
                    title: "Latência",
                    mbps: latency,
                    icon: Icons.timer_outlined,
                    unit: "ms")),
        ]),
        if (status == TestStatus.running)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Center(
                child: Text(resultText?.split('\n').last ?? "Iniciando...",
                    style: theme.textTheme.bodySmall)),
          ),
        if (downloadHistory.isNotEmpty || uploadHistory.isNotEmpty)
          _buildSparkLineChart(
              context,
              downloadHistory,
              uploadHistory,
              isReference ? Colors.cyan : theme.primaryColor,
              isReference ? Colors.purpleAccent : Colors.cyanAccent),
        if (status == TestStatus.error)
          _buildTileStatusText(context, status: status, result: resultText),
      ]
    ]);
  }

  Widget _buildTileHeader(BuildContext context,
      {required String label, required TestStatus status}) {
    final theme = Theme.of(context);
    Widget statusIconWidget;
    final color = _getColorForStatus(context, status);

    switch (status) {
      case TestStatus.running:
        statusIconWidget = SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 3, color: color));
        break;
      case TestStatus.success:
        statusIconWidget = Icon(Icons.check_circle, color: color, size: 28);
        break;
      case TestStatus.error:
        statusIconWidget = Icon(Icons.error, color: color, size: 28);
        break;
      case TestStatus.pending:
        statusIconWidget = Icon(Icons.hourglass_empty, color: color, size: 24);
        break;
    }
    return Row(
      children: [
        statusIconWidget,
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                style: theme.textTheme.titleLarge?.copyWith(color: color))),
      ],
    );
  }

  Widget _buildTileStatusText(BuildContext context,
      {required TestStatus status, String? result}) {
    String text;
    Color color = _getColorForStatus(context, status);

    switch (status) {
      case TestStatus.running:
        text =
            result != null && result.isNotEmpty && !result.contains("Iniciando")
                ? result.split('\n').last.trim()
                : "Executando...";
        break;
      case TestStatus.error:
        text = result ?? "Ocorreu um erro desconhecido.";
        break;
      case TestStatus.pending:
        text = "Toque em iniciar para testar";
        break;
      default:
        return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Center(
        child: Text(text.replaceAll("Exception: ", ""),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: color, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center),
      ),
    );
  }

  Color _getColorForStatus(BuildContext context, TestStatus status) {
    final theme = Theme.of(context);
    switch (status) {
      case TestStatus.running:
        return theme.primaryColor;
      case TestStatus.success:
        return Colors.green;
      case TestStatus.error:
        return theme.colorScheme.error;
      case TestStatus.pending:
        return Colors.grey;
    }
  }

  Widget _buildSpeedStatBox(BuildContext context,
      {required String title,
      double? mbps,
      required IconData icon,
      String unit = "Mbps"}) {
    final textTheme = Theme.of(context).textTheme;
    final value = mbps ?? 0.0;
    return Column(children: [
      Icon(icon, color: textTheme.bodySmall?.color, size: 22),
      const SizedBox(height: 8),
      Text(title, style: textTheme.bodyMedium),
      const SizedBox(height: 4),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
              unit == "ms"
                  ? value.toStringAsFixed(0)
                  : value.toStringAsFixed(1),
              style: textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 2),
          Text(unit, style: textTheme.bodySmall),
        ],
      ),
    ]);
  }

  Widget _buildSparkLineChart(BuildContext context, List<FlSpot> downloadData,
      List<FlSpot> uploadData, Color downloadColor, Color uploadColor) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 8.0, right: 8.0),
      child: SizedBox(
        height: 60,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: [
              _getLineChartBarData(downloadData, downloadColor),
              if (uploadData.isNotEmpty)
                _getLineChartBarData(uploadData, uploadColor, showBelow: false),
            ],
          ),
        ),
      ),
    );
  }

  LineChartBarData _getLineChartBarData(List<FlSpot> spots, Color color,
      {bool showBelow = true}) {
    return LineChartBarData(
      spots:
          spots.length > 1 ? spots : [const FlSpot(0, 0), const FlSpot(1, 0)],
      isCurved: true,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: showBelow
          ? BarAreaData(
              show: true,
              gradient: LinearGradient(
                  colors: [color.withAlpha(77), color.withAlpha(0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter))
          : BarAreaData(show: false),
    );
  }
}
