import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/diagnostico_service.dart';
import '../../../core/models/diagnostico_state.dart';
import '../widgets/soft_card.dart';

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

  late AnimationController _gaugeController;
  DiagnosticoState _state = DiagnosticoState.initial();
  StreamSubscription? _subscription;

  final List<FlSpot> _spots = [];
  int _xCounter = 0;

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serviceInitialized) {
      final configProvider = ref.read(configurationProvider);
      final providerConfig = configProvider.providerConfig!;
      _service =
          DiagnosticoService(providerConfig: providerConfig, context: context);

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

      _spots.add(FlSpot(_xCounter.toDouble(), speed));
      _xCounter++;

      if (_spots.length > 50) {
        _spots.removeAt(0);
      }
    }
  }

  void _startTest() {
    HapticFeedback.mediumImpact();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final secondaryColor = theme.colorScheme.secondary;
    final surfaceColor = theme.cardColor;
    final bgColor = theme.scaffoldBackgroundColor;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? Colors.grey;

    final isRunning = _state.isTesting ||
        _state.testResultsDisplay['speedTestCustom']?['status'] ==
            TestStatus.running;

    final download = _state.customDownloadResultMbps;
    final upload = _state.customUploadResultMbps;
    double displaySpeed = 0.0;
    bool isUpload = false;

    if (isRunning) {
      if (upload > 1) {
        displaySpeed = upload;
        isUpload = true;
      } else {
        displaySpeed = download > 0 ? download : 0;
      }
    } else if (download > 0 || upload > 0) {
      _gaugeController.stop();
      displaySpeed = download;
    } else {
      _gaugeController.stop();
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Teste de Velocidade',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600, color: textPrimary),
        ),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        actions: [
          if (isRunning)
            IconButton(
              icon: Icon(Icons.stop_circle_outlined,
                  color: theme.colorScheme.error),
              tooltip: 'Cancelar Teste',
              onPressed: _stopTest,
            ),
          IconButton(
            icon: Icon(Icons.history_edu_rounded, color: textSecondary),
            tooltip: 'Histórico',
            onPressed: () => _showHistory(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Soft Gauge Circle
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 260,
                  width: 260,
                  child: AnimatedBuilder(
                    animation: _gaugeController,
                    builder: (context, child) {
                      final oscillation =
                          isRunning ? (_gaugeController.value * 0.08) : 0.0;
                      double fill = displaySpeed > 0
                          ? (displaySpeed / 500).clamp(0.0, 1.0)
                          : 0.0;

                      return CustomPaint(
                        painter: SoftGaugePainter(
                          progress: fill + oscillation,
                          primaryColor: primaryColor,
                          secondaryColor: secondaryColor,
                          bgColor: surfaceColor,
                        ),
                      );
                    },
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isRunning
                          ? (isUpload ? 'UPLOAD' : 'DOWNLOAD')
                          : (displaySpeed > 0 ? 'RESULTADO' : 'PRONTO'),
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displaySpeed.toStringAsFixed(1),
                      style: GoogleFonts.outfit(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Mbps',
                      style: TextStyle(color: textSecondary, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Real-time Graph
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
                        barWidth: 3,
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

            const SizedBox(height: 24),

            // Start Button
            if (!isRunning)
              GestureDetector(
                onTap: _startTest,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 56, vertical: 18),
                  decoration: BoxDecoration(
                    gradient:
                        LinearGradient(colors: [primaryColor, secondaryColor]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Text(
                    'INICIAR TESTE',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Results Row
            Row(
              children: [
                Expanded(
                  child: SoftCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.download_rounded,
                            color: primaryColor, size: 32),
                        const SizedBox(height: 12),
                        Text('Download',
                            style:
                                TextStyle(color: textSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '${download.toStringAsFixed(1)}',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text('Mbps',
                            style:
                                TextStyle(color: textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SoftCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.upload_rounded,
                            color: secondaryColor, size: 32),
                        const SizedBox(height: 12),
                        Text('Upload',
                            style:
                                TextStyle(color: textSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '${upload.toStringAsFixed(1)}',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text('Mbps',
                            style:
                                TextStyle(color: textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Ping Card
            SoftCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Icon(Icons.wifi_tethering_rounded,
                          color: primaryColor, size: 28),
                      const SizedBox(height: 8),
                      Text('Ping',
                          style: TextStyle(color: textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        '${_state.speedTestPingLatency?.toStringAsFixed(0) ?? '-'} ms',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                      width: 1,
                      height: 50,
                      color: Colors.grey.withValues(alpha: 0.2)),
                  Column(
                    children: [
                      Icon(Icons.signal_cellular_alt_rounded,
                          color: secondaryColor, size: 28),
                      const SizedBox(height: 8),
                      Text('Jitter',
                          style: TextStyle(color: textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        '- ms',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
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
    );
  }
}

// Soft Gauge Painter with warm aesthetics
class SoftGaugePainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final Color bgColor;

  SoftGaugePainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 15;
    const startAngle = 135 * (3.14159 / 180);
    const sweepAngle = 270 * (3.14159 / 180);

    // Track
    final trackPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Progress Gradient
    final gradient = LinearGradient(
      colors: [primaryColor, secondaryColor],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final progressPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    final currentSweep = sweepAngle * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      currentSweep,
      false,
      progressPaint,
    );

    // Soft Glow
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      currentSweep,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SoftGaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// History Sheet
class _SpeedHistorySheet extends ConsumerStatefulWidget {
  const _SpeedHistorySheet();

  @override
  ConsumerState<_SpeedHistorySheet> createState() => _SpeedHistorySheetState();
}

class _SpeedHistorySheetState extends ConsumerState<_SpeedHistorySheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(speedTestHistoryServiceProvider).loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyService = ref.watch(speedTestHistoryServiceProvider);
    final history = historyService.history;
    final surfaceColor = Theme.of(context).cardColor;
    final primaryColor = Theme.of(context).primaryColor;
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
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
          Text(
            'Histórico de Testes',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: historyService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : history.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum teste realizado',
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
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.speed_rounded,
                                  color: primaryColor),
                            ),
                            title: Text(
                              '${item.downloadSpeed.toStringAsFixed(1)} Mbps',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary),
                            ),
                            subtitle: Text(item.formattedDate),
                            trailing: Text(
                              '↑ ${item.uploadSpeed.toStringAsFixed(1)}',
                              style: const TextStyle(color: Colors.grey),
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
