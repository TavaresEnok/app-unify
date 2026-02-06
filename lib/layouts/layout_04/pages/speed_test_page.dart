import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/diagnostico_service.dart';
import '../../../core/models/diagnostico_state.dart';
import '../widgets/glass_card.dart';

class Layout06SpeedTestPage extends ConsumerStatefulWidget {
  const Layout06SpeedTestPage({super.key});

  @override
  ConsumerState<Layout06SpeedTestPage> createState() =>
      _Layout06SpeedTestPageState();
}

class _Layout06SpeedTestPageState extends ConsumerState<Layout06SpeedTestPage>
    with SingleTickerProviderStateMixin {
  late final DiagnosticoService _service;
  bool _serviceInitialized = false;

  late AnimationController _gaugeController;
  DiagnosticoState _state = DiagnosticoState.initial();
  StreamSubscription? _subscription;

  // Chart Data
  final List<FlSpot> _spots = [];
  int _xCounter = 0;

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serviceInitialized) {
      final configProvider = ref.read(configurationProvider);
      final providerConfig = configProvider.providerConfig!;
      _service =
          DiagnosticoService(providerConfig: providerConfig, context: context);

      // Listen to stream manually to accumulate chart points
      _subscription = _service.stateStream.listen((newState) {
        setState(() {
          _state = newState;
          _updateChart(newState);
        });
      });

      _serviceInitialized = true;
    }
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }

  void _updateChart(DiagnosticoState state) {
    if (state.isTesting ||
        state.testResultsDisplay['speedTestCustom']?['status'] ==
            TestStatus.running) {
      double speed = 0;
      if (state.customUploadResultMbps > 1) {
        speed = state.customUploadResultMbps;
      } else {
        speed = state.customDownloadResultMbps > 0
            ? state.customDownloadResultMbps
            : 0;
      }

      // Add spot (limit to last 50 points for performance)
      _spots.add(FlSpot(_xCounter.toDouble(), speed));
      _xCounter++;

      if (_spots.length > 50) {
        _spots.removeAt(0);
      }
    }
  }

  void _startTest() {
    HapticFeedback.mediumImpact();
    // Reset gauge and chart
    _gaugeController.repeat(reverse: true);
    setState(() {
      _spots.clear();
      _xCounter = 0;
    });
    _service.runSpeedTestsOnly();
  }

  void _stopTest() {
    _service.stopAllTests();
    _gaugeController.stop();
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SpeedHistorySheet(),
    );
  }

  String _extractJitter(DiagnosticoState state) {
    String? result = state.testResultsDisplay['pingGoogle']?['result'];
    // Try Google first, then Cloudflare
    if (result == null || !result.contains('Jitter')) {
      result = state.testResultsDisplay['pingCloudflare']?['result'];
    }

    if (result != null && result.contains('Jitter:')) {
      try {
        final jitterPart =
            result.split('\n').firstWhere((l) => l.contains('Jitter:'));
        // "Jitter: 12.5ms" -> "12.5ms"
        return jitterPart.split(':')[1].trim();
      } catch (_) {}
    }
    return '- ms';
  }

  @override
  Widget build(BuildContext context) {
    // Theme data from context (dynamic)
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final secondaryColor = theme.colorScheme.secondary;

    final isRunning = _state.isTesting ||
        _state.testResultsDisplay['speedTestCustom']?['status'] ==
            TestStatus.running;

    // Determine current values
    final download = _state.customDownloadResultMbps;
    final upload = _state.customUploadResultMbps;
    double displaySpeed = 0.0;
    double progress = 0.0; // 0.0-1.0 for Download, 1.0-2.0 for Upload
    bool isUpload = false;

    if (isRunning) {
      // Logic to determine what to show
      if (upload > 1) {
        displaySpeed = upload;
        progress = 1.5; // Arbitrary "Upload Phase" for gauge
        isUpload = true;
      } else {
        displaySpeed = download > 0 ? download : 0;
        progress = 0.5; // Arbitrary "Download Phase"
      }
    } else if (download > 0 || upload > 0) {
      // Finished
      _gaugeController.stop();
      displaySpeed = download; // Show download by default on finish
      progress = 2.0; // Finished
    } else {
      _gaugeController.stop();
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (isRunning) {
          _stopTest();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent, // Handled by Layout 06 background
        appBar: AppBar(
          title: Text(
            'Teste de Velocidade',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            if (isRunning)
              IconButton(
                icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                tooltip: 'Cancelar Teste',
                onPressed: _stopTest,
              ),
            IconButton(
              icon: const Icon(Icons.history_edu_rounded),
              tooltip: 'Histórico de Testes',
              onPressed: () => _showHistory(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Gauge Section
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 250,
                    width: 250,
                    child: AnimatedBuilder(
                        animation: _gaugeController,
                        builder: (context, child) {
                          // If running, oscillate the gauge a bit for effect + real value
                          final oscillation =
                              isRunning ? (_gaugeController.value * 0.1) : 0.0;

                          // Combine progress (phase) with fill
                          double fill = 0.0;
                          if (progress >= 2.0) {
                            fill = 1.0;
                          } else if (displaySpeed > 0) {
                            fill = (displaySpeed / 500).clamp(0.0, 1.0);
                          }

                          return CustomPaint(
                            painter: SpeedGaugePainter(
                              progress:
                                  fill + oscillation, // Use fill for visual
                              primaryColor: primaryColor,
                              secondaryColor: secondaryColor,
                              trackColor: theme.colorScheme.surface,
                            ),
                          );
                        }),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isRunning
                            ? (isUpload ? 'UPLOAD' : 'DOWNLOAD')
                            : (displaySpeed > 0 ? 'PRONTO' : 'PARADO'),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displaySpeed.toStringAsFixed(1),
                        style: GoogleFonts.outfit(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Mbps',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // [NEW] Real-time Graph
              if (_spots.isNotEmpty)
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _spots,
                          isCurved: true,
                          color: isUpload ? secondaryColor : primaryColor,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: (isUpload ? secondaryColor : primaryColor)
                                .withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                      lineTouchData: const LineTouchData(enabled: false),
                    ),
                  ),
                ),

              const SizedBox(height: 20), // Adjusted spacing

              // Start Button
              if (!isRunning)
                GestureDetector(
                  onTap: _startTest,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      'INICIAR TESTE',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Contrast on bright gradient
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // Results Grid
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.download, color: primaryColor, size: 28),
                          const SizedBox(height: 8),
                          Text('Download',
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7))),
                          const SizedBox(height: 4),
                          Text(
                            '${download.toStringAsFixed(1)} Mbps',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.upload, color: secondaryColor, size: 28),
                          const SizedBox(height: 8),
                          Text('Upload',
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7))),
                          const SizedBox(height: 4),
                          Text(
                            '${upload.toStringAsFixed(1)} Mbps',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.wifi_tethering,
                            color: theme.colorScheme.tertiary, size: 28),
                        const SizedBox(height: 8),
                        Text('Ping',
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7))),
                        const SizedBox(height: 4),
                        Text(
                          '${_state.speedTestPingLatency?.toStringAsFixed(0) ?? '-'} ms',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.computer,
                            color: theme.colorScheme.tertiary, size: 28),
                        const SizedBox(height: 8),
                        Text('Jitter',
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7))),
                        const SizedBox(height: 4),
                        Text(
                          _extractJitter(_state),
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SpeedGaugePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color primaryColor;
  final Color secondaryColor;
  final Color trackColor;

  SpeedGaugePainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const startAngle = 135 * (3.14159 / 180);
    const sweepAngle = 270 * (3.14159 / 180);

    // Track Paint
    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Progress Paint (Gradient)
    final gradient = LinearGradient(
      colors: [primaryColor, secondaryColor],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final progressPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    final currentSweep = sweepAngle * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      currentSweep,
      false,
      progressPaint,
    );

    // Glow Effect
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      currentSweep,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SpeedGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor;
  }
}

class _SpeedHistorySheet extends ConsumerStatefulWidget {
  const _SpeedHistorySheet();

  @override
  ConsumerState<_SpeedHistorySheet> createState() => _SpeedHistorySheetState();
}

class _SpeedHistorySheetState extends ConsumerState<_SpeedHistorySheet> {
  @override
  void initState() {
    super.initState();
    // Load history when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(speedTestHistoryServiceProvider).loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyService = ref.watch(speedTestHistoryServiceProvider);
    final history = historyService.history;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Text(
            'Histórico de Resultados',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // List
          Expanded(
            child: historyService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : history.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum teste realizado ainda',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = history[index];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.speed_rounded,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            title: Text(
                              '${item.downloadSpeed.toStringAsFixed(1)} Mbps',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(item.formattedDate),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.arrow_upward,
                                        size: 14, color: Colors.grey),
                                    Text(
                                      ' ${item.uploadSpeed.toStringAsFixed(1)}',
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
