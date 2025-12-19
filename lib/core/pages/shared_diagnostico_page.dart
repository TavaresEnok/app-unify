import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../layouts/layout_03/theme.dart';
import '../../core/services/diagnostico_service.dart';
import '../../core/services/onu_wifi_service.dart';

import '../../core/models/diagnostico_state.dart';
import '../../core/widgets/dashboard_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/troubleshooter_card.dart';
import '../../core/utils/pdf_generator_service.dart';

class DiagnosticoPage extends ConsumerStatefulWidget {
  const DiagnosticoPage({super.key});

  @override
  ConsumerState<DiagnosticoPage> createState() => _DiagnosticoPageState();
}

class _DiagnosticoPageState extends ConsumerState<DiagnosticoPage> {
  late final DiagnosticoService _service;
  OnuWifiService? _onuWifiService;
  bool _serviceInitialized = false;

  // ONU State
  bool _loadingOnu = false;
  OnuData? _onuData;
  String? _onuError;

  // WiFi State
  bool _loadingWifi = false;
  List<WifiNetwork> _wifiNetworks = [];
  String? _wifiError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serviceInitialized) {
      final configProvider = ref.read(configurationProvider);
      final providerConfig = configProvider.providerConfig!;
      final authState = ref.read(authNotifierProvider);
      final usuario = authState.value;

      _service =
          DiagnosticoService(providerConfig: providerConfig, context: context);

      // Initialize ONU/WiFi service
      if (usuario != null) {
        _onuWifiService = OnuWifiService(
          apiUrl: providerConfig.apiUrl,
          cpfCnpj: usuario.cpfCnpj,
          senha: usuario.senha,
          contrato: usuario.contratoId?.toString(),
          sgpParams: {
            'token': providerConfig.config.integrations.apiToken,
            'app': providerConfig.config.integrations.appName,
            'sgpBaseUrl': providerConfig.config.integrations.sgpBaseUrl,
          },
        );
      }
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

        final configProvider = ref.watch(configurationProvider);
        final layoutType = configProvider.providerConfig?.layoutType;
        final isLayout05 = layoutType == 'layout_05';
        final isDarkLayout = layoutType == 'layout_06';

        final theme = Theme.of(context);

        Color backgroundColor;
        Color appBarColor;
        Color appBarTextColor;
        if (isDarkLayout) {
          backgroundColor = const Color(0xFF0A0A0A);
          appBarColor = const Color(0xFF0A0A0A);
          appBarTextColor = Colors.white;
        } else if (isLayout05) {
          backgroundColor = Layout03Theme.background;
          appBarColor = Layout03Theme.background;
          appBarTextColor = Layout03Theme.textDark;
        } else {
          backgroundColor = theme.scaffoldBackgroundColor;
          appBarColor = theme.primaryColor;
          appBarTextColor = Colors.white;
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text('Diagnóstico de Rede',
                style: TextStyle(color: appBarTextColor)),
            backgroundColor: appBarColor,
            iconTheme: IconThemeData(color: appBarTextColor),
            actions: [
              if (!state.isTesting && state.customDownloadResultMbps > 0)
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Compartilhar PDF',
                  onPressed: () {
                    final pdfService = PdfGeneratorService();
                    pdfService.stopAndSharePdf(state);
                  },
                ),
            ],
          ),
          body: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              color: state.isTesting
                  ? primaryColor.withAlpha(38)
                  : Colors.transparent,
              child: Text(state.geralStatusMessage,
                  style: textTheme.bodyLarge?.copyWith(
                      color: state.isTesting
                          ? primaryColor
                          : (isLayout05 ? Layout03Theme.textDark : null)),
                  textAlign: TextAlign.center),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _buildConnectionJourneyCard(context, state,
                      isLayout05: isLayout05, isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildOnuSignalCard(context,
                      isLayout05: isLayout05, isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildSpeedTestCard(context, state, isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildWifiManagementCard(context,
                      isLayout05: isLayout05, isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildWifiDetailsCard(context, state, isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildLanScanCard(context, state, isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildDeviceInfoCard(context, state, isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildBatteryInfoCard(context, state, isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 24),
                  TroubleshooterCard(
                    state: state,
                    onRetry: () {
                      if (!state.isTesting) _service.runAllTests();
                    },
                    isDarkLayout: isDarkLayout,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
              child: AppButton(
                icon: state.isTesting
                    ? Icons.stop_circle_outlined
                    : Icons.network_check_rounded,
                label: state.isTesting
                    ? "Parar Diagnóstico"
                    : "Iniciar Diagnóstico",
                onPressed: () {
                  if (state.isTesting) {
                    _service.stopAllTests();
                  } else {
                    _service.runAllTests();
                    _fetchOnuSignal();
                    _fetchWifiNetworks();
                  }
                },
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
      BuildContext context, DiagnosticoState state,
      {bool isLayout05 = false, bool isDarkLayout = false}) {
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

    return _buildAdaptiveCard(
        isLayout05: isLayout05,
        isDarkLayout: isDarkLayout,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Jornada da Conexão",
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: isDarkLayout ? Colors.white : null)),
          const SizedBox(height: 20),
          _buildJourneyStep(context,
              icon: Icons.wifi,
              title: "Você (Dispositivo)",
              status: wifiStatus,
              isDarkLayout: isDarkLayout,
              children: [
                _buildJourneyInfo(context, "Sinal:",
                    _parseResultLine(wifiResult, "Força do Sinal:"),
                    isDarkLayout: isDarkLayout),
                _buildJourneyInfo(
                    context, "SSID:", _parseResultLine(wifiResult, "SSID:"),
                    isDarkLayout: isDarkLayout)
              ]),
          _buildJourneyStep(context,
              icon: Icons.router,
              title: "Seu Roteador",
              status: gatewayStatus,
              isDarkLayout: isDarkLayout,
              children: [
                _buildJourneyInfo(context, "IP:",
                    _parseResultLine(wifiResult, "Gateway (Roteador):"),
                    isDarkLayout: isDarkLayout),
                _buildJourneyInfo(context, "Latência:",
                    _parseResultLine(gatewayResult, "Latência:"),
                    isDarkLayout: isDarkLayout),
                _buildJourneyInfo(context, "Jitter:",
                    _parseResultLine(gatewayResult, "Jitter:"),
                    isDarkLayout: isDarkLayout),
              ]),
          _buildJourneyStep(context,
              icon: Icons.cloud_queue,
              title: "Nossa Rede",
              status: ipStatus,
              isDarkLayout: isDarkLayout,
              children: [
                _buildJourneyInfo(
                    context, "IPv4:", _parseResultLine(ipResult, "IPv4:"),
                    isDarkLayout: isDarkLayout),
                _buildJourneyInfo(
                    context, "IPv6:", _parseResultLine(ipResult, "IPv6:"),
                    isLast: true, isDarkLayout: isDarkLayout)
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
              isDarkLayout: isDarkLayout,
              children: [
                _buildJourneyInfo(context, "Google:",
                    "${_parseResultLine(googleResult, "Latência:")} (${_parseResultLine(googleResult, "Perda:")})",
                    isDarkLayout: isDarkLayout),
                _buildJourneyInfo(context, "Cloudflare:",
                    "${_parseResultLine(cloudflareResult, "Latência:")} (${_parseResultLine(cloudflareResult, "Perda:")})",
                    isDarkLayout: isDarkLayout)
              ]),
        ]));
  }

  Widget _buildSpeedTestCard(
      BuildContext context, DiagnosticoState state, bool isLayout05,
      {bool isDarkLayout = false}) {
    // Determine state
    final customStatus = state.testResultsDisplay['speedTestCustom']?['status'];
    final fastStatus = state.testResultsDisplay['speedTestFast']?['status'];

    final isCustomRunning = customStatus == TestStatus.running;
    final isFastRunning = fastStatus == TestStatus.running;
    final isRunning = isCustomRunning || isFastRunning;
    final hasError =
        (customStatus == TestStatus.error || fastStatus == TestStatus.error) &&
            !isRunning;

    // Determine values
    double currentSpeed = 0.0;
    bool isDownload = true;
    double download = 0.0;
    double upload = 0.0;

    final textColor = isDarkLayout
        ? Colors.white
        : (isLayout05 ? Layout03Theme.textDark : null);
    final subTextColor = isDarkLayout
        ? Colors.white70
        : (isLayout05 ? Layout03Theme.textGrey : null);

    // Simplification for gauge
    if (isCustomRunning) {
      currentSpeed = state.customDownloadResultMbps > 0
          ? state.customDownloadResultMbps
          : 0;
      if (state.customUploadResultMbps > 1) {
        currentSpeed = state.customUploadResultMbps;
        isDownload = false;
      }
    } else if (isFastRunning) {
      currentSpeed = state.fastDownloadResultMbps;
      if (state.fastUploadResultMbps > 1) {
        currentSpeed = state.fastUploadResultMbps;
        isDownload = false;
      }
    } else if (hasError) {
      // Stop speed display on error
      currentSpeed = 0;
    }

    // Results to show
    download = state.customDownloadResultMbps > 0
        ? state.customDownloadResultMbps
        : state.fastDownloadResultMbps;
    upload = state.customUploadResultMbps > 0
        ? state.customUploadResultMbps
        : state.fastUploadResultMbps;

    final content = Column(
      children: [
        if (isRunning) ...[
          // GAUGE VIEW (Scaled down)
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(PieChartData(
                    startDegreeOffset: 135,
                    sectionsSpace: 0,
                    centerSpaceRadius: 80, // Smaller radius
                    sections: [
                      PieChartSectionData(
                        color: isLayout05 ? Colors.grey[300] : Colors.grey[200],
                        value: 75,
                        title: '',
                        radius: 12, // Smaller
                        showTitle: false,
                      ),
                      PieChartSectionData(
                          color: Colors.transparent,
                          value: 25,
                          title: '',
                          showTitle: false,
                          radius: 12),
                    ])),
                SizedBox(
                  width: 180,
                  height: 180,
                  child: RotationTransition(
                    turns: const AlwaysStoppedAnimation(225 / 360),
                    child: CircularProgressIndicator(
                      value: (currentSpeed / 100).clamp(0.0, 0.75),
                      strokeWidth: 12,
                      color: isDownload
                          ? (isLayout05 ? Colors.cyan : Colors.green)
                          : Colors.purple,
                      backgroundColor: Colors.transparent,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isDownload ? 'DOWNLOAD' : 'UPLOAD',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 10)),
                    Text(currentSpeed.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDarkLayout
                              ? Colors.white
                              : (isLayout05
                                  ? Layout03Theme.textDark
                                  : Theme.of(context).primaryColor),
                        )),
                    Text('Mbps',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          Text(isRunning ? "Testando sua conexão..." : "",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey))
        ] else if (hasError) ...[
          // ERROR VIEW
          Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Column(children: [
                Icon(Icons.error_outline,
                    size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text("Falha no Teste",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 8),
                Text(
                    state.testResultsDisplay['speedTestCustom']?['result'] ??
                        state.testResultsDisplay['speedTestFast']?['result'] ??
                        "Erro de conexão.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: () {
                      // Call service to retry only speed
                      _service.runSpeedTestsOnly();
                    },
                    child: const Text("Tentar Novamente"))
              ]))
        ] else ...[
          // RESULT VIEW (Mini Cards)
          Row(
            children: [
              Expanded(
                child: _buildMiniResultCard(
                    context,
                    "Download",
                    download.toStringAsFixed(1),
                    Icons.arrow_downward,
                    isLayout05 ? Colors.cyan : Colors.green,
                    isLayout05,
                    textColor: textColor,
                    subTextColor: subTextColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniResultCard(
                    context,
                    "Upload",
                    upload.toStringAsFixed(1),
                    Icons.arrow_upward,
                    isLayout05 ? Colors.purpleAccent : Colors.blue,
                    isLayout05,
                    textColor: textColor,
                    subTextColor: subTextColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniResultCard(
                    context,
                    "Ping",
                    "${state.speedTestPingLatency?.toStringAsFixed(0) ?? '-'} ms",
                    Icons.compare_arrows,
                    Colors.orange,
                    isLayout05,
                    textColor: textColor,
                    subTextColor: subTextColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                  onPressed: () {
                    // Retry
                    _service.runSpeedTestsOnly();
                  },
                  child: const Text("Refazer Teste"))
            ],
          )
        ] // end else
      ],
    );

    return _buildAdaptiveCard(
        isLayout05: isLayout05,
        isDarkLayout: isDarkLayout,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildTileHeader(context,
              label: "Velocidade de Internet",
              status: isRunning
                  ? TestStatus.running
                  : (hasError ? TestStatus.error : TestStatus.success),
              isDarkLayout: isDarkLayout),
          const SizedBox(height: 16),
          content,
        ]));
  }

  Widget _buildMiniResultCard(BuildContext context, String title, String value,
      IconData icon, Color color, bool isLayout05,
      {Color? textColor, Color? subTextColor}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: isLayout05
          ? BoxDecoration(
              color: Layout03Theme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)))
          : BoxDecoration(
              color: Colors.grey[100]
                  ?.withValues(alpha: textColor != null ? 0.1 : 1.0),
              borderRadius: BorderRadius.circular(8),
            ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: subTextColor)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
          ),
        ],
      ),
    );
  }

  // Unused method _buildSimpleStat removed

  Widget _buildWifiDetailsCard(
      BuildContext context, DiagnosticoState state, bool isLayout05,
      {bool isDarkLayout = false}) {
    final status =
        state.testResultsDisplay['wifiInfo']?['status'] as TestStatus? ??
            TestStatus.pending;
    final resultText =
        state.testResultsDisplay['wifiInfo']?['result'] as String?;

    return _buildAdaptiveCard(
      isLayout05: isLayout05,
      isDarkLayout: isDarkLayout,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildTileHeader(context,
            label: "Detalhes da Rede Wi-Fi",
            status: status,
            isDarkLayout: isDarkLayout),
        if (status == TestStatus.pending || status == TestStatus.running)
          _buildTileStatusText(context,
              status: status, result: resultText, isDarkLayout: isDarkLayout)
        else ...[
          const Divider(height: 24),
          _buildJourneyInfo(
              context, "BSSID:", _parseResultLine(resultText, "BSSID:"),
              isDarkLayout: isDarkLayout),
          _buildJourneyInfo(context, "IP Local:",
              _parseResultLine(resultText, "IP Dispositivo:"),
              isDarkLayout: isDarkLayout),
          _buildJourneyInfo(context, "Servidores DNS:",
              _parseResultBlock(resultText, "Servidores DNS:"),
              isDarkLayout: isDarkLayout),
        ]
      ]),
    );
  }

  Widget _buildDeviceInfoCard(
      BuildContext context, DiagnosticoState state, bool isLayout05,
      {bool isDarkLayout = false}) {
    final status =
        state.testResultsDisplay['deviceInfo']?['status'] as TestStatus? ??
            TestStatus.pending;
    final resultText =
        state.testResultsDisplay['deviceInfo']?['result'] as String?;

    return _buildAdaptiveCard(
      isLayout05: isLayout05,
      isDarkLayout: isDarkLayout,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildTileHeader(context,
            label: "Informações do Dispositivo",
            status: status,
            isDarkLayout: isDarkLayout),
        if (status == TestStatus.pending || status == TestStatus.running)
          _buildTileStatusText(context,
              status: status, result: resultText, isDarkLayout: isDarkLayout)
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
                      value: _parseResultLine(resultText, "Conexão:"),
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildDeviceInfoRow(context,
                      icon: Icons.android_outlined,
                      title: "Sistema",
                      value: _parseResultLine(resultText, "Versão OS:"),
                      isDarkLayout: isDarkLayout),
                ])),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _buildDeviceInfoRow(context,
                      icon: Icons.smartphone,
                      title: "Dispositivo",
                      value: _parseResultLine(resultText, "Dispositivo:"),
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildDeviceInfoRow(context,
                      icon: Icons.info_outline,
                      title: "Versão do App",
                      value: _parseResultLine(resultText, "Versão do App:"),
                      isDarkLayout: isDarkLayout),
                ])),
          ]),
        ]
      ]),
    );
  }

  Widget _buildBatteryInfoCard(
      BuildContext context, DiagnosticoState state, bool isLayout05,
      {bool isDarkLayout = false}) {
    final status =
        state.testResultsDisplay['batteryInfo']?['status'] as TestStatus? ??
            TestStatus.pending;
    final resultText =
        state.testResultsDisplay['batteryInfo']?['result'] as String?;

    return _buildAdaptiveCard(
      isLayout05: isLayout05,
      isDarkLayout: isDarkLayout,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildTileHeader(context,
            label: "Energia e Bateria",
            status: status,
            isDarkLayout: isDarkLayout),
        if (status == TestStatus.pending || status == TestStatus.running)
          _buildTileStatusText(context,
              status: status, result: resultText, isDarkLayout: isDarkLayout)
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
                      value: _parseResultLine(resultText, "Nível:"),
                      isDarkLayout: isDarkLayout),
                ])),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _buildDeviceInfoRow(context,
                      icon: Icons.power,
                      title: "Estado",
                      value: _parseResultLine(resultText, "Estado:"),
                      isDarkLayout: isDarkLayout),
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
                        resultText.split('\n').lastWhere(
                            (l) => l.contains("⚠️"),
                            orElse: () => "Aviso de energia"),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkLayout ? Colors.white : null)),
                  ),
                ],
              ),
            )
        ]
      ]),
    );
  }

  Widget _buildLanScanCard(
      BuildContext context, DiagnosticoState state, bool isLayout05,
      {bool isDarkLayout = false}) {
    final status =
        state.testResultsDisplay['lanScan']?['status'] as TestStatus? ??
            TestStatus.pending;
    final resultText =
        state.testResultsDisplay['lanScan']?['result'] as String?;

    final textColor = isDarkLayout
        ? Colors.white
        : (isLayout05 ? Layout03Theme.textDark : null);

    return _buildAdaptiveCard(
      isLayout05: isLayout05,
      isDarkLayout: isDarkLayout,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildTileHeader(context,
            label: "Dispositivos na Rede (LAN)",
            status: status,
            isDarkLayout: isDarkLayout),
        if (status == TestStatus.pending || status == TestStatus.running)
          _buildTileStatusText(context,
              status: status, result: resultText, isDarkLayout: isDarkLayout)
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
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: textColor)),
                  Text(
                      _parseResultLine(resultText, "Dispositivos encontrados:"),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: textColor)),
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
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: textColor),
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
      bool isLastStep = false,
      bool isDarkLayout = false}) {
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
                      color: isDarkLayout
                          ? Colors.grey[700]
                          : Theme.of(context).dividerColor,
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
      {bool isLast = false, bool isDarkLayout = false}) {
    final textTheme = Theme.of(context).textTheme;
    final textColor = isDarkLayout ? Colors.white : null;
    final subTextColor = isDarkLayout ? Colors.white70 : null;
    return Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$label ',
              style: textTheme.bodyMedium?.copyWith(color: subTextColor)),
          Expanded(
              child: Text(value,
                  style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500, color: textColor))),
        ]));
  }

  Widget _buildDeviceInfoRow(BuildContext context,
      {required IconData icon,
      required String title,
      required String value,
      bool isDarkLayout = false}) {
    final textTheme = Theme.of(context).textTheme;
    final textColor = isDarkLayout ? Colors.white : null;
    final subTextColor = isDarkLayout ? Colors.white70 : null;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(icon, size: 18, color: subTextColor)),
      const SizedBox(width: 12),
      Flexible(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: textTheme.bodyMedium?.copyWith(color: subTextColor)),
          const SizedBox(height: 4),
          Text(value,
              style: textTheme.titleMedium?.copyWith(color: textColor),
              softWrap: true),
        ]),
      ),
    ]);
  }

  // Unused method _buildSpeedTestTile removed
  // Fragments removed

  // Unused helpers removed

  Widget _buildTileHeader(BuildContext context,
      {required String label,
      required TestStatus status,
      bool isDarkLayout = false}) {
    final theme = Theme.of(context);
    Widget statusIconWidget;
    final color = _getColorForStatus(context, status);
    final textColor = isDarkLayout ? Colors.white : null;

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
              style: theme.textTheme.titleLarge?.copyWith(color: textColor)),
        ),
      ],
    );
  }

  Widget _buildTileStatusText(BuildContext context,
      {required TestStatus status, String? result, bool isDarkLayout = false}) {
    String text;
    Color color = _getColorForStatus(context, status);
    final textColor = isDarkLayout ? Colors.white70 : color;

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
              ?.copyWith(color: textColor, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ============== ONU SIGNAL CARD ==============
  Future<void> _fetchOnuSignal() async {
    if (_onuWifiService == null) return;
    setState(() {
      _loadingOnu = true;
      _onuError = null;
    });
    try {
      final data = await _onuWifiService!.fetchOnuSignal();
      setState(() {
        _onuData = data;
        _loadingOnu = false;
      });
    } catch (e) {
      setState(() {
        _onuError = e.toString().replaceAll('Exception: ', '');
        _loadingOnu = false;
      });
    }
  }

  Widget _buildOnuSignalCard(BuildContext context,
      {bool isLayout05 = false, bool isDarkLayout = false}) {
    final theme = Theme.of(context);
    final textColor = isDarkLayout ? Colors.white : null;
    final subTextColor = isDarkLayout ? Colors.white70 : Colors.grey;

    return _buildAdaptiveCard(
      isLayout05: isLayout05,
      isDarkLayout: isDarkLayout,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.router, color: theme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
              child: Text("Sinal da ONU (Fibra)",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor))),
          if (!_loadingOnu)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _fetchOnuSignal,
              tooltip: 'Buscar sinal',
            ),
        ]),
        const Divider(height: 24),
        if (_loadingOnu)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ))
        else if (_onuError != null)
          Center(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Icon(Icons.error_outline, color: Colors.red[300], size: 40),
              const SizedBox(height: 8),
              Text(_onuError!,
                  style: TextStyle(color: Colors.red[300]),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _fetchOnuSignal,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ]),
          ))
        else if (_onuData == null)
          Center(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Icon(Icons.signal_cellular_alt,
                  color: Colors.grey[400], size: 40),
              const SizedBox(height: 8),
              Text('Clique em atualizar para buscar o sinal da ONU',
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchOnuSignal,
                icon: const Icon(Icons.search),
                label: const Text('Buscar Sinal'),
              ),
            ]),
          ))
        else ...[
          // Status indicator at top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _onuData!.isOnline
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(
                _onuData!.isOnline ? Icons.check_circle : Icons.cancel,
                color: _onuData!.isOnline ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 12),
              Text(
                'Status: ${_onuData!.connectionStatus}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _onuData!.isOnline ? Colors.green : Colors.red,
                ),
              ),
              const Spacer(),
              if (_onuData!.lastUpdate != null)
                Text(
                  _onuData!.lastUpdate!,
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
            ]),
          ),
          const SizedBox(height: 16),

          // Signal Strength (only if online)
          Row(children: [
            Expanded(
                child: _buildOnuStatBox(
              context,
              label: 'Sinal RX',
              value: _onuData!.signalRxDisplay,
              icon: Icons.arrow_downward,
              isGood: _onuData!.isSignalGood,
              isLayout05: isLayout05,
              isDarkLayout: isDarkLayout,
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _buildOnuStatBox(
              context,
              label: 'Sinal TX',
              value: _onuData!.signalTxDisplay,
              icon: Icons.arrow_upward,
              isGood: _onuData!.signalTx != null,
              isLayout05: isLayout05,
              isDarkLayout: isDarkLayout,
            )),
          ]),
          const SizedBox(height: 16),

          // Quality indicator
          if (_onuData!.signalRx != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _onuData!.isSignalGood
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(
                  _onuData!.isSignalGood ? Icons.check_circle : Icons.warning,
                  color: _onuData!.isSignalGood ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Text(
                  'Qualidade: ${_onuData!.signalQuality}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        _onuData!.isSignalGood ? Colors.green : Colors.orange,
                  ),
                ),
              ]),
            ),

          // OLT Info
          if (_onuData!.oltName != null)
            _buildOnuInfoTile('OLT', _onuData!.oltName!, Icons.cell_tower,
                isDarkLayout: isDarkLayout),
          _buildOnuInfoTile(
              'Posição',
              'Slot ${_onuData!.slot} | PON ${_onuData!.pon} | ID ${_onuData!.onuId}',
              Icons.pin_drop,
              isDarkLayout: isDarkLayout),

          // Device info
          _buildOnuInfoTile('Modelo', _onuData!.model, Icons.router,
              isDarkLayout: isDarkLayout),
          if (_onuData!.serialNumber != null)
            _buildOnuInfoTile('Serial', _onuData!.serialNumber!, Icons.tag,
                isDarkLayout: isDarkLayout),
          if (_onuData!.mode != null)
            _buildOnuInfoTile('Modo', _onuData!.mode!, Icons.settings,
                isDarkLayout: isDarkLayout),

          // Network info
          if (_onuData!.vlan != null)
            _buildOnuInfoTile('VLAN', _onuData!.vlan.toString(), Icons.lan,
                isDarkLayout: isDarkLayout),
          if (_onuData!.cto != null)
            _buildOnuInfoTile('CTO', _onuData!.cto!, Icons.location_on,
                isDarkLayout: isDarkLayout),

          // Additional info
          Row(children: [
            if (_onuData!.temperature != null)
              Expanded(
                  child: _buildOnuInfoTile(
                      'Temp', '${_onuData!.temperature}°C', Icons.thermostat,
                      isDarkLayout: isDarkLayout)),
            if (_onuData!.voltage != null)
              Expanded(
                  child: _buildOnuInfoTile('Voltagem', '${_onuData!.voltage}V',
                      Icons.electrical_services,
                      isDarkLayout: isDarkLayout)),
          ]),
        ],
      ]),
    );
  }

  Widget _buildOnuStatBox(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required bool isGood,
    bool isLayout05 = false,
    bool isDarkLayout = false,
  }) {
    final textColor = isDarkLayout
        ? Colors.white
        : (isLayout05 ? Layout03Theme.textDark : null);
    final subTextColor = isDarkLayout
        ? Colors.white70
        : (isLayout05 ? Layout03Theme.textGrey : null);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: isLayout05
          ? BoxDecoration(
              color: Layout03Theme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isGood
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3)),
            )
          : BoxDecoration(
              color:
                  isDarkLayout ? Colors.grey[900] : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isGood
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3)),
            ),
      child: Column(children: [
        Icon(icon, color: isGood ? Colors.green : Colors.orange),
        const SizedBox(height: 8),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: subTextColor,
                )),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
      ]),
    );
  }

  Widget _buildOnuInfoTile(String label, String value, IconData icon,
      {bool isDarkLayout = false}) {
    // final textColor = isDarkLayout ? Colors.white : null;
    // final subTextColor = isDarkLayout ? Colors.white70 : Colors.grey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(color: Colors.grey)),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
    );
  }

  // ============== WIFI MANAGEMENT CARD ==============
  Future<void> _fetchWifiNetworks() async {
    if (_onuWifiService == null) return;
    setState(() {
      _loadingWifi = true;
      _wifiError = null;
    });
    try {
      final networks = await _onuWifiService!.fetchWifiNetworks();
      setState(() {
        _wifiNetworks = networks;
        _loadingWifi = false;
      });
    } catch (e) {
      setState(() {
        _wifiError = e.toString().replaceAll('Exception: ', '');
        _loadingWifi = false;
      });
    }
  }

  Widget _buildWifiManagementCard(BuildContext context,
      {bool isLayout05 = false, bool isDarkLayout = false}) {
    final theme = Theme.of(context);
    final textColor = isDarkLayout ? Colors.white : null;

    return _buildAdaptiveCard(
      isLayout05: isLayout05,
      isDarkLayout: isDarkLayout,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.wifi,
              color:
                  isDarkLayout ? const Color(0xFF00D9FF) : theme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
              child: Text("Gerenciar WiFi (TR-069)",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor))),
          if (!_loadingWifi)
            IconButton(
              icon:
                  Icon(Icons.refresh, color: isDarkLayout ? Colors.grey : null),
              onPressed: _fetchWifiNetworks,
              tooltip: 'Buscar redes',
            ),
        ]),
        const Divider(height: 24),
        if (_loadingWifi)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ))
        else if (_wifiError != null)
          Center(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Icon(Icons.error_outline, color: Colors.red[300], size: 40),
              const SizedBox(height: 8),
              Text(_wifiError!,
                  style: TextStyle(color: Colors.red[300]),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _fetchWifiNetworks,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ]),
          ))
        else if (_wifiNetworks.isEmpty)
          Center(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Icon(Icons.wifi_find, color: Colors.grey[400], size: 40),
              const SizedBox(height: 8),
              Text('Clique para buscar as redes WiFi do seu roteador',
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchWifiNetworks,
                icon: const Icon(Icons.search),
                label: const Text('Buscar Redes WiFi'),
              ),
            ]),
          ))
        else
          ..._wifiNetworks.map((network) =>
              _buildWifiNetworkTile(context, network, isLayout05: isLayout05)),
      ]),
    );
  }

  Widget _buildWifiNetworkTile(BuildContext context, WifiNetwork network,
      {bool isLayout05 = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: isLayout05
          ? BoxDecoration(
              color: Layout03Theme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white), // Subtle border
            )
          : BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
      child: Row(children: [
        Icon(
          network.frequency.contains('5') ? Icons.wifi : Icons.wifi_2_bar,
          color: network.enabled ? Colors.green : Colors.grey,
          size: 32,
        ),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(network.ssid,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isLayout05 ? Layout03Theme.textDark : null)),
          Text(network.frequency,
              style: TextStyle(
                  color: isLayout05 ? Layout03Theme.textGrey : Colors.grey[600],
                  fontSize: 13)),
        ])),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showEditWifiDialog(context, network),
          tooltip: 'Editar WiFi',
          color: isLayout05 ? Layout03Theme.primary : null,
        ),
      ]),
    );
  }

  void _showEditWifiDialog(BuildContext context, WifiNetwork network) {
    final ssidController = TextEditingController(text: network.ssid);
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar ${network.frequency}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: ssidController,
            decoration: const InputDecoration(
              labelText: 'Nome da Rede (SSID)',
              prefixIcon: Icon(Icons.wifi),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nova Senha',
              prefixIcon: Icon(Icons.lock),
              hintText: 'Deixe vazio para manter',
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _updateWifi(
                  network.id, ssidController.text, passwordController.text);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateWifi(String wifiId, String ssid, String password) async {
    if (_onuWifiService == null || ssid.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aplicando alterações no WiFi...')),
    );

    try {
      final success = await _onuWifiService!.updateWifi(
        wifiId: wifiId,
        ssid: ssid,
        password: password.isEmpty ? 'keep_current' : password,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'WiFi atualizado com sucesso!'
                : 'Falha ao atualizar WiFi'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _fetchWifiNetworks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildAdaptiveCard(
      {required Widget child,
      required bool isLayout05,
      bool isDarkLayout = false}) {
    if (isDarkLayout) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      );
    }
    if (isLayout05) {
      return Container(
        decoration: Layout03Theme.neumorphicDecoration,
        padding: const EdgeInsets.all(16),
        child: child,
      );
    }
    return DashboardCard(child: child);
  }
}
