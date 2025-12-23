import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../core/providers/providers.dart';
import '../../layouts/layout_03/theme.dart';
import '../../core/services/diagnostico_service.dart';
import '../../core/models/diagnostico_state.dart';

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
      _listenToStream();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = ref.watch(configurationProvider);
    final layoutType = config.providerConfig?.layoutType;
    final isLayout05 = layoutType == 'layout_05';
    final isDarkLayout = layoutType == 'layout_06';

    // Theme Colors
    Color backgroundColor;
    Color appBarTextColor;
    Color appBarColor;
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

    return StreamBuilder<DiagnosticoState>(
      stream: _service.stateStream,
      initialData: DiagnosticoState.initial(),
      builder: (context, snapshot) {
        final state = snapshot.data!;

        // Use custom speed test results for the gauge if running, or fast.com if running
        // Priority: Custom -> Fast
        final isCustomRunning = state.testResultsDisplay['speedTestCustom']
                ?['status'] ==
            TestStatus.running;
        final isFastRunning = state.testResultsDisplay['speedTestFast']
                ?['status'] ==
            TestStatus.running;
        final isRunning = isCustomRunning || isFastRunning || state.isTesting;

        // Current Speed Value (for Gauge)
        double currentSpeed = 0.0;
        bool isDownload = true;

        if (isCustomRunning) {
          final download = state.customDownloadResultMbps;
          final upload = state.customUploadResultMbps;

          currentSpeed = download > 0 ? download : 0;
          if (upload > 1) {
            currentSpeed = upload;
            isDownload = false;
          }
        }

        // Determine Mode
        Widget content;
        final hasResults = state.customDownloadResultMbps > 0 ||
            state.fastDownloadResultMbps > 0;
        final customStatus = state.testResultsDisplay['speedTestCustom']
            ?['status'] as TestStatus?;
        final fastStatus =
            state.testResultsDisplay['speedTestFast']?['status'] as TestStatus?;
        final hasError = (customStatus == TestStatus.error ||
                fastStatus == TestStatus.error) &&
            !isRunning;

        if (isRunning) {
          content = _buildGaugeView(
              context, state, isLayout05, currentSpeed, isDownload, false,
              isDarkLayout: isDarkLayout);
        } else if (hasError) {
          final errorMsg = state.testResultsDisplay['speedTestCustom']
                  ?['result'] ??
              state.testResultsDisplay['speedTestFast']?['result'] ??
              "Erro desconhecido ao conectar.";
          content = _buildErrorView(context, errorMsg, isLayout05);
        } else if (hasResults) {
          // Reuse Gauge View for Results, but with isFinished=true
          // Calculate final speed to show (likely download or upload based on what we want to emphasize, or maybe download by default)
          double finalSpeed = state.customDownloadResultMbps > 0
              ? state.customDownloadResultMbps
              : state.fastDownloadResultMbps;

          content = _buildGaugeView(
              context, state, isLayout05, finalSpeed, true, true,
              isDarkLayout: isDarkLayout);
        } else {
          content = _buildIdleView(context, isLayout05);
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text('Teste de Velocidade',
                style: TextStyle(color: appBarTextColor)),
            backgroundColor: appBarColor,
            iconTheme: IconThemeData(color: appBarTextColor),
            elevation: 0,
            centerTitle: true,
            actions: [
              if (!isRunning && hasResults)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    _startTest();
                  },
                )
            ],
          ),
          body: content,
        );
      },
    );
  }

  void _startTest() {
    _service.runSpeedTestsOnly();
  }

  void _stopTest() {
    _service.stopAllTests();
  }

  // --- VIEW: ERROR ---
  Widget _buildErrorView(
      BuildContext context, String? errorMessage, bool isLayout05) {
    final theme = Theme.of(context);
    final textColor =
        isLayout05 ? Layout03Theme.textDark : theme.textTheme.bodyLarge?.color;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.signal_wifi_connected_no_internet_4_rounded,
                size: 80,
                color:
                    isLayout05 ? Layout03Theme.error : theme.colorScheme.error),
            const SizedBox(height: 24),
            Text("Ops! Algo deu errado.",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 16),
            Text(
                errorMessage ??
                    "Não foi possível conectar ao servidor de teste.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _startTest,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text("Tentar Novamente",
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isLayout05 ? Layout03Theme.primary : theme.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30))),
            )
          ],
        ),
      ),
    );
  }

  // --- VIEW: IDLE (Start Button) ---
  Widget _buildIdleView(BuildContext context, bool isLayout05) {
    final theme = Theme.of(context);
    final primaryColor =
        isLayout05 ? Layout03Theme.primary : theme.primaryColor;
    final textColor =
        isLayout05 ? Layout03Theme.textDark : theme.textTheme.bodyLarge?.color;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Toque em INICIAR para testar a sua velocidade',
              style: TextStyle(
                  color: textColor?.withValues(alpha: 0.6), fontSize: 14)),
          const SizedBox(height: 60),

          // Start Button Hero
          GestureDetector(
            onTap: _startTest,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLayout05 ? Layout03Theme.background : Colors.white,
                boxShadow: isLayout05
                    ? [
                        const BoxShadow(
                            color: Colors.white,
                            offset: Offset(-8, -8),
                            blurRadius: 16),
                        BoxShadow(
                            color:
                                const Color(0xFFA3B1C6).withValues(alpha: 0.4),
                            offset: const Offset(8, 8),
                            blurRadius: 16),
                      ]
                    : [
                        BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5),
                        const BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5))
                      ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Inner Gradient Circle
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.8)
                            ]),
                        boxShadow: [
                          BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8))
                        ]),
                    child: const Icon(Icons.power_settings_new_rounded,
                        color: Colors.white, size: 48),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 48),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text('Conexão Segura',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(width: 24),
              const Icon(Icons.public, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text('Servidor Otimizado',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 100), // Added bottom padding for nav
        ],
      ),
    );
  }

  // --- VIEW: GAUGE (Active & Result) ---
  Widget _buildGaugeView(BuildContext context, DiagnosticoState state,
      bool isLayout05, double speedMbps, bool isDownload, bool isFinished,
      {bool isDarkLayout = false}) {
    final theme = Theme.of(context);
    final primaryColor =
        isLayout05 ? Layout03Theme.primary : theme.primaryColor;

    // Determine max speed for gauge
    double maxGauge = 100;
    if (speedMbps > 90) maxGauge = 500;
    if (speedMbps > 450) maxGauge = 1000;
    if (speedMbps > 950) maxGauge = 2000;

    return Column(
      children: [
        const SizedBox(height: 32),
        // Gauge Section
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 280,
                width: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background Arc
                    PieChart(PieChartData(
                        startDegreeOffset: 135,
                        sectionsSpace: 0,
                        centerSpaceRadius: 100,
                        sections: [
                          PieChartSectionData(
                            color: isLayout05
                                ? Colors.grey[300]
                                : Colors.grey[200]!.withValues(alpha: 0.5),
                            value: 75, // 270 degrees
                            title: '',
                            radius: 15,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                              color: Colors.transparent,
                              value: 25,
                              title: '',
                              showTitle: false,
                              radius: 15),
                        ])),
                    // Active Arc
                    SizedBox(
                      width: 230,
                      height: 230,
                      child: RotationTransition(
                        turns: const AlwaysStoppedAnimation(225 / 360),
                        child: CircularProgressIndicator(
                          value: (speedMbps / maxGauge).clamp(0.0, 0.75),
                          strokeWidth: 15,
                          // If finished, show a "complete" color mix or just the primary
                          color: isFinished
                              ? primaryColor
                              : (isDownload
                                  ? (isLayout05 ? Colors.cyan : Colors.green)
                                  : Colors.purple),
                          backgroundColor: Colors.transparent,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    ),

                    // Text in Center
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            isFinished
                                ? 'RESULTADO FINAL'
                                : (isDownload ? 'DOWNLOAD' : 'UPLOAD'),
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        Text(speedMbps.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: isDarkLayout
                                  ? Colors.white
                                  : (isLayout05
                                      ? Layout03Theme.textDark
                                      : theme.textTheme.bodyLarge?.color),
                            )),
                        Text('Mbps',
                            style: TextStyle(
                                color: isDarkLayout
                                    ? Colors.white70
                                    : Colors.grey[600],
                                fontSize: 16)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),

        // Stats & Controls
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Real-time Graph (Small)
                if (_downloadPoints.isNotEmpty || _uploadPoints.isNotEmpty)
                  Container(
                    height: 60,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          if (_downloadPoints.isNotEmpty)
                            LineChartBarData(
                              spots: _downloadPoints,
                              isCurved: true,
                              color: Colors.green,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.green.withValues(alpha: 0.1)),
                            ),
                          if (_uploadPoints.isNotEmpty)
                            LineChartBarData(
                              spots: _uploadPoints,
                              isCurved: true,
                              color: Colors.purple,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.purple.withValues(alpha: 0.1)),
                            ),
                        ],
                        lineTouchData: const LineTouchData(enabled: false),
                      ),
                    ),
                  ),

                Text(
                  isFinished
                      ? "Teste Concluído"
                      : (isDownload
                          ? "Testando Download..."
                          : "Testando Upload..."),
                  style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 20),

                // Mini Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat(
                        context,
                        'Ping',
                        '${state.speedTestPingLatency?.toStringAsFixed(0) ?? '-'} ms',
                        isLayout05,
                        isDarkLayout: isDarkLayout),
                    _buildMiniStat(
                        context,
                        'Download',
                        state.customDownloadResultMbps.toStringAsFixed(1),
                        isLayout05,
                        unit: 'Mbps',
                        isDarkLayout: isDarkLayout),
                    _buildMiniStat(
                        context,
                        'Upload',
                        state.customUploadResultMbps.toStringAsFixed(1),
                        isLayout05,
                        unit: 'Mbps',
                        isDarkLayout: isDarkLayout),
                  ],
                ),

                const Spacer(),

                // Action Button (Cancel or Restart)
                if (isFinished)
                  ElevatedButton.icon(
                    onPressed: _startTest,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text("Refazer Teste",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30))),
                  )
                else
                  TextButton.icon(
                    onPressed: _stopTest,
                    icon: const Icon(Icons.close, color: Colors.grey),
                    label: const Text('Cancelar Teste',
                        style: TextStyle(color: Colors.grey)),
                  ),

                // Extra Padding for Bottom Nav Overlap
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // State for Chart
  final List<FlSpot> _downloadPoints = [];
  final List<FlSpot> _uploadPoints = [];
  double _time = 0;
  // ignore: cancel_subscriptions
  StreamSubscription?
      _subscription; // Using cancel_subscriptions ignore because it is cancelled in dispose

  @override
  void initState() {
    super.initState();
    // Reset points on init
  }

  void _listenToStream() {
    _service.stateStream.listen((state) {
      if (state.testResultsDisplay['speedTestCustom']?['status'] ==
          TestStatus.running) {
        final down = state.customDownloadResultMbps;
        final up = state.customUploadResultMbps;
        if (down > 0 && up <= 1) {
          // Downloading
          if (mounted) {
            setState(() {
              _time += 1;
              _downloadPoints.add(FlSpot(_time, down));
              if (_downloadPoints.length > 50) _downloadPoints.removeAt(0);
            });
          }
        } else if (up > 1) {
          // Uploading
          if (mounted) {
            setState(() {
              _time += 1;
              _uploadPoints.add(FlSpot(_time, up));
              if (_uploadPoints.length > 50) _uploadPoints.removeAt(0);
            });
          }
        }
      } else if (state.testResultsDisplay['speedTestCustom']?['status'] ==
          TestStatus.pending) {
        // Reset on idle/pending start
        if (_time > 0 && mounted) {
          setState(() {
            _downloadPoints.clear();
            _uploadPoints.clear();
            _time = 0;
          });
        }
      }
    });
  }

  // To properly implement the listener, I need to call `_listenToStream` once service is ready.
  // But `_service` is lazy loaded in `didChangeDependencies`.

  Widget _buildMiniStat(
      BuildContext context, String title, String value, bool isLayout05,
      {String unit = '', bool isDarkLayout = false}) {
    return Column(
      children: [
        Text(title,
            style: TextStyle(
                color: isDarkLayout ? Colors.white70 : Colors.grey,
                fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isDarkLayout
                        ? Colors.white
                        : (isLayout05
                            ? Layout03Theme.textDark
                            : Colors.black87))),
            if (unit.isNotEmpty)
              Text(" $unit",
                  style: const TextStyle(fontSize: 10, color: Colors.grey))
          ],
        )
      ],
    );
  }
}
