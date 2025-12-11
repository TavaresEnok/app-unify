import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../core/providers/configuration_provider.dart';
import '../../core/services/diagnostico_service.dart';
import '../../core/models/diagnostico_state.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/troubleshooter_card.dart';

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
            title: const Text('Diagnóstico de Rede'),
          ),
          body: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              color: state.isTesting
                  ? primaryColor.withAlpha(38)
                  : Colors.transparent,
              child: Text(state.geralStatusMessage,
                  style: textTheme.bodyLarge
                      ?.copyWith(color: state.isTesting ? primaryColor : null),
                  textAlign: TextAlign.center),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _buildConnectionJourneyCard(context, state),
                  const SizedBox(height: 16),
                  _buildSpeedTestCard(context, state),
                  const SizedBox(height: 16),
                  _buildWifiDetailsCard(context, state),
                  const SizedBox(height: 16),
                  _buildLanScanCard(context, state),
                  const SizedBox(height: 16),
                  _buildDeviceInfoCard(context, state),
                  const SizedBox(height: 16),
                  _buildBatteryInfoCard(context, state),
                  const SizedBox(height: 24),
                  TroubleshooterCard(
                    state: state,
                    onRetry: () {
                      if (!state.isTesting) _service.runAllTests();
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: AppButton(
                icon: state.isTesting
                    ? Icons.stop_circle_outlined
                    : Icons.network_check_rounded,
                label: state.isTesting
                    ? "Parar Diagnóstico"
                    : "Iniciar Diagnóstico",
                onPressed: () => state.isTesting
                    ? _service.stopAllTests()
                    : _service.runAllTests(),
              ),
            ),
          ]),
        );
      },
    );
  }

  String _parseResultLine(String? resultText, String key) {
    if (resultText == null || resultText.isEmpty) return "---";
    try {
      final line = resultText
          .split('\n')
          .firstWhere((l) => l.startsWith(key), orElse: () => '');
      if (line.isEmpty) return "---";
      return line.split(':').sublist(1).join(':').trim();
    } catch (e) {
      return "---";
    }
  }

  String _parseResultBlock(String? resultText, String key) {
    if (resultText == null || resultText.isEmpty) return "---";
    try {
      final lines = resultText.split('\n');
      final startIndex = lines.indexWhere((l) => l.startsWith(key));
      if (startIndex == -1) return "---";
      final block = lines
          .sublist(startIndex + 1)
          .takeWhile((l) => l.isNotEmpty && !l.contains(':'))
          .map((l) => l.trim())
          .join('\n');
      return block.isEmpty ? "---" : block;
    } catch (e) {
      return "---";
    }
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

  Widget _buildConnectionJourneyCard(
      BuildContext context, DiagnosticoState state) {
    final wifiStatus =
        state.testResultsDisplay['wifiInfo']?['status'] as TestStatus? ??
            TestStatus.pending;
    final wifiResult =
        state.testResultsDisplay['wifiInfo']?['result'] as String?;
    final gatewayStatus =
        state.testResultsDisplay['pingGateway']?['status'] as TestStatus? ??
            TestStatus.pending;
    final gatewayResult =
        state.testResultsDisplay['pingGateway']?['result'] as String?;
    final ipStatus =
        state.testResultsDisplay['publicIp']?['status'] as TestStatus? ??
            TestStatus.pending;
    final ipResult = state.testResultsDisplay['publicIp']?['result'] as String?;
    final googleStatus =
        state.testResultsDisplay['pingGoogle']?['status'] as TestStatus? ??
            TestStatus.pending;
    final googleResult =
        state.testResultsDisplay['pingGoogle']?['result'] as String?;
    final cloudflareStatus =
        state.testResultsDisplay['pingCloudflare']?['status'] as TestStatus? ??
            TestStatus.pending;
    final cloudflareResult =
        state.testResultsDisplay['pingCloudflare']?['result'] as String?;

    return DashboardCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Jornada da Conexão",
          style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 20),
      _buildJourneyStep(context,
          icon: Icons.wifi,
          title: "Você (Dispositivo)",
          status: wifiStatus,
          children: [
            _buildJourneyInfo(context, "Sinal:",
                _parseResultLine(wifiResult, "Força do Sinal:")),
            _buildJourneyInfo(
                context, "SSID:", _parseResultLine(wifiResult, "SSID:"))
          ]),
      _buildJourneyStep(context,
          icon: Icons.router,
          title: "Seu Roteador",
          status: gatewayStatus,
          children: [
            _buildJourneyInfo(context, "IP:",
                _parseResultLine(wifiResult, "Gateway (Roteador):")),
            _buildJourneyInfo(context, "Latência:",
                _parseResultLine(gatewayResult, "Latência:")),
            _buildJourneyInfo(
                context, "Jitter:", _parseResultLine(gatewayResult, "Jitter:")),
          ]),
      _buildJourneyStep(context,
          icon: Icons.cloud_queue,
          title: "Nossa Rede",
          status: ipStatus,
          children: [
            _buildJourneyInfo(
                context, "IPv4:", _parseResultLine(ipResult, "IPv4:")),
            _buildJourneyInfo(
                context, "IPv6:", _parseResultLine(ipResult, "IPv6:"),
                isLast: true)
          ]),
      _buildJourneyStep(context,
          icon: Icons.dns_rounded,
          title: "Internet (DNS)",
          isLastStep: true,
          status: (googleStatus == TestStatus.success ||
                  cloudflareStatus == TestStatus.success)
              ? TestStatus.success
              : (googleStatus == TestStatus.running ||
                      cloudflareStatus == TestStatus.running)
                  ? TestStatus.running
                  : TestStatus.error,
          children: [
            _buildJourneyInfo(context, "Google:",
                "${_parseResultLine(googleResult, "Latência:")} (${_parseResultLine(googleResult, "Perda:")})"),
            _buildJourneyInfo(context, "Cloudflare:",
                "${_parseResultLine(cloudflareResult, "Latência:")} (${_parseResultLine(cloudflareResult, "Perda:")})")
          ]),
    ]));
  }

  Widget _buildSpeedTestCard(BuildContext context, DiagnosticoState state) {
    return DashboardCard(
        child: Column(children: [
      _buildSpeedTestTile(context,
          label: "Velocidade (Seu Servidor)",
          status: state.testResultsDisplay['speedTestCustom']?['status']
                  as TestStatus? ??
              TestStatus.pending,
          resultText:
              state.testResultsDisplay['speedTestCustom']?['result'] as String?,
          downloadMbps: state.customDownloadResultMbps,
          uploadMbps: state.customUploadResultMbps,
          latency: state.speedTestPingLatency,
          downloadHistory: state.downloadHistory,
          uploadHistory: state.uploadHistory),
      Divider(height: 32, color: Theme.of(context).dividerColor),
      _buildSpeedTestTile(context,
          label: "Velocidade (Referência)",
          status: state.testResultsDisplay['speedTestFast']?['status']
                  as TestStatus? ??
              TestStatus.pending,
          resultText:
              state.testResultsDisplay['speedTestFast']?['result'] as String?,
          downloadMbps: state.fastDownloadResultMbps,
          uploadMbps: state.fastUploadResultMbps,
          downloadHistory: state.fastDownloadHistory,
          uploadHistory: state.fastUploadHistory,
          isReference: true),
    ]));
  }

  Widget _buildWifiDetailsCard(BuildContext context, DiagnosticoState state) {
    final status =
        state.testResultsDisplay['wifiInfo']?['status'] as TestStatus? ??
            TestStatus.pending;
    final resultText =
        state.testResultsDisplay['wifiInfo']?['result'] as String?;

    return DashboardCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildTileHeader(context,
            label: "Detalhes da Rede Wi-Fi", status: status),
        if (status == TestStatus.pending || status == TestStatus.running)
          _buildTileStatusText(context, status: status, result: resultText)
        else ...[
          const Divider(height: 24),
          _buildJourneyInfo(
              context, "BSSID:", _parseResultLine(resultText, "BSSID:")),
          _buildJourneyInfo(context, "IP Local:",
              _parseResultLine(resultText, "IP Dispositivo:")),
          _buildJourneyInfo(context, "Servidores DNS:",
              _parseResultBlock(resultText, "Servidores DNS:")),
        ]
      ]),
    );
  }

  Widget _buildDeviceInfoCard(BuildContext context, DiagnosticoState state) {
    final status =
        state.testResultsDisplay['deviceInfo']?['status'] as TestStatus? ??
            TestStatus.pending;
    final resultText =
        state.testResultsDisplay['deviceInfo']?['result'] as String?;

    return DashboardCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildTileHeader(context,
            label: "Informações do Dispositivo", status: status),
        if (status == TestStatus.pending || status == TestStatus.running)
          _buildTileStatusText(context, status: status, result: resultText)
        else ...[
          const Divider(height: 24),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _buildDeviceInfoRow(context,
                      icon: Icons.wifi,
                      title: "Conexão",
                      value: _parseResultLine(resultText, "Conexão:")),
                  const SizedBox(height: 16),
                  _buildDeviceInfoRow(context,
                      icon: Icons.android_outlined,
                      title: "Sistema",
                      value: _parseResultLine(resultText, "Versão OS:")),
                ])),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _buildDeviceInfoRow(context,
                      icon: Icons.smartphone,
                      title: "Dispositivo",
                      value: _parseResultLine(resultText, "Dispositivo:")),
                  const SizedBox(height: 16),
                  _buildDeviceInfoRow(context,
                      icon: Icons.info_outline,
                      title: "Versão do App",
                      value: _parseResultLine(resultText, "Versão do App:")),
                ])),
          ]),
        ]
      ]),
    );
  }

  Widget _buildBatteryInfoCard(BuildContext context, DiagnosticoState state) {
    final status =
        state.testResultsDisplay['batteryInfo']?['status'] as TestStatus? ??
            TestStatus.pending;
    final resultText =
        state.testResultsDisplay['batteryInfo']?['result'] as String?;

    return DashboardCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildTileHeader(context, label: "Energia e Bateria", status: status),
        if (status == TestStatus.pending || status == TestStatus.running)
          _buildTileStatusText(context, status: status, result: resultText)
        else ...[
          const Divider(height: 24),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _buildDeviceInfoRow(context,
                      icon: Icons.battery_std,
                      title: "Nível",
                      value: _parseResultLine(resultText, "Nível:")),
                ])),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _buildDeviceInfoRow(context,
                      icon: Icons.power,
                      title: "Estado",
                      value: _parseResultLine(resultText, "Estado:")),
                ])),
          ]),
          if (resultText != null && resultText.contains("⚠️"))
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.amberAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      resultText.split('\n').lastWhere((l) => l.contains("⚠️"),
                          orElse: () => "Aviso de energia"),
                      style: const TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
        ]
      ]),
    );
  }

  Widget _buildLanScanCard(BuildContext context, DiagnosticoState state) {
    final status =
        state.testResultsDisplay['lanScan']?['status'] as TestStatus? ??
            TestStatus.pending;
    final resultText =
        state.testResultsDisplay['lanScan']?['result'] as String?;

    return DashboardCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildTileHeader(context,
            label: "Dispositivos na Rede (LAN)", status: status),
        if (status == TestStatus.pending || status == TestStatus.running)
          _buildTileStatusText(context, status: status, result: resultText)
        else ...[
          const Divider(height: 24),
          Row(children: [
            Icon(Icons.devices_other,
                size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text("Total Encontrado",
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                      _parseResultLine(resultText, "Dispositivos encontrados:"),
                      style: Theme.of(context).textTheme.headlineMedium),
                  if (resultText != null && resultText.contains("sub-rede"))
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        resultText
                            .split('\n')
                            .lastWhere((l) => l.contains("sub-rede"),
                                orElse: () => "")
                            .replaceAll("(", "")
                            .replaceAll(")", ""),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ]))
          ])
        ]
      ]),
    );
  }

  Widget _buildJourneyStep(BuildContext context,
      {required IconData icon,
      required String title,
      required TestStatus status,
      required List<Widget> children,
      bool isLastStep = false}) {
    Color statusColor = _getColorForStatus(context, status);
    return IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
          width: 32,
          child: Column(children: [
            Icon(icon, size: 24, color: statusColor),
            if (!isLastStep)
              Expanded(
                  child: Container(
                      width: 2,
                      color: Theme.of(context).dividerColor,
                      margin: const EdgeInsets.symmetric(vertical: 8.0)))
          ])),
      const SizedBox(width: 16),
      Expanded(
          child: Padding(
              padding: EdgeInsets.only(bottom: isLastStep ? 0 : 24.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: statusColor)),
                    const SizedBox(height: 6),
                    ...children
                  ]))),
    ]));
  }

  Widget _buildJourneyInfo(BuildContext context, String label, String value,
      {bool isLast = false}) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$label ', style: textTheme.bodyMedium),
          Expanded(
              child: Text(value,
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500))),
        ]));
  }

  Widget _buildDeviceInfoRow(BuildContext context,
      {required IconData icon, required String title, required String value}) {
    final textTheme = Theme.of(context).textTheme;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(icon, size: 18, color: textTheme.bodySmall?.color)),
      const SizedBox(width: 12),
      Flexible(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(value, style: textTheme.titleMedium, softWrap: true),
        ]),
      ),
    ]);
  }

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
            unit == "ms" ? value.toStringAsFixed(0) : value.toStringAsFixed(1),
            style:
                textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
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
                end: Alignment.bottomCenter,
              ),
            )
          : BarAreaData(show: false),
    );
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
              style: theme.textTheme.titleLarge?.copyWith(color: color)),
        ),
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
        text = "Pendente";
        break;
      default:
        return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Center(
        child: Text(
          text.replaceAll("Exception: ", ""),
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: color, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
