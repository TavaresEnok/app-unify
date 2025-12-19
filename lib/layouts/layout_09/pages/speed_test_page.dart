import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/diagnostico_service.dart';
import '../../../core/models/diagnostico_state.dart';
import '../theme.dart';
import '../widgets/bento_card.dart';

class Layout09SpeedTestPage extends ConsumerStatefulWidget {
  const Layout09SpeedTestPage({super.key});

  @override
  ConsumerState<Layout09SpeedTestPage> createState() =>
      _Layout09SpeedTestPageState();
}

class _Layout09SpeedTestPageState extends ConsumerState<Layout09SpeedTestPage>
    with SingleTickerProviderStateMixin {
  late final DiagnosticoService _service;
  bool _serviceInitialized = false;

  late AnimationController _ringController;
  DiagnosticoState _state = DiagnosticoState.initial();
  StreamSubscription? _subscription;

  final List<FlSpot> _spots = [];
  int _xCounter = 0;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
    _ringController.dispose();
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
    _ringController.repeat();
    setState(() {
      _spots.clear();
      _xCounter = 0;
    });
    _service.runSpeedTestsOnly();
  }

  void _stopTest() {
    _service.stopAllTests();
    _ringController.stop();
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
      _ringController.stop();
      displaySpeed = download;
    } else {
      _ringController.stop();
    }

    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Layout09Theme.pastelPink.withValues(alpha: 0.4),
                  Layout09Theme.pastelBlue.withValues(alpha: 0.3),
                  Layout09Theme.pastelPurple.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // App Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.arrow_back_rounded,
                                  color: textPrimary),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'Teste de Velocidade',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          if (isRunning)
                            GestureDetector(
                              onTap: _stopTest,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.stop_rounded,
                                    color: Colors.red, size: 20),
                              ),
                            ),
                          GestureDetector(
                            onTap: () => _showHistory(context),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(Icons.history_rounded,
                                      color: textSecondary),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Ring Progress Indicator
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 280,
                        width: 280,
                        child: AnimatedBuilder(
                          animation: _ringController,
                          builder: (context, child) {
                            final oscillation = isRunning
                                ? (_ringController.value * 0.05)
                                : 0.0;
                            double fill = displaySpeed > 0
                                ? (displaySpeed / 500).clamp(0.0, 1.0)
                                : 0.0;

                            return CustomPaint(
                              painter: RingProgressPainter(
                                progress: fill + oscillation,
                                primaryColor: primaryColor,
                                secondaryColor: secondaryColor,
                                isRunning: isRunning,
                              ),
                            );
                          },
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isRunning
                                      ? (isUpload ? 'UPLOAD' : 'DOWNLOAD')
                                      : (displaySpeed > 0
                                          ? 'RESULTADO'
                                          : 'PRONTO'),
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
                                  style: GoogleFonts.inter(
                                    fontSize: 52,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  'Mbps',
                                  style: TextStyle(
                                      color: textSecondary, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Real-time Graph
                  if (_spots.isNotEmpty)
                    Container(
                      height: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _spots,
                              isCurved: true,
                              gradient: LinearGradient(
                                colors: isUpload
                                    ? [
                                        secondaryColor,
                                        secondaryColor.withValues(alpha: 0.5)
                                      ]
                                    : [
                                        primaryColor,
                                        primaryColor.withValues(alpha: 0.5)
                                      ],
                              ),
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    (isUpload ? secondaryColor : primaryColor)
                                        .withValues(alpha: 0.2),
                                    Colors.transparent,
                                  ],
                                ),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 56, vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [primaryColor, secondaryColor]),
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
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Results Cards
                  Row(
                    children: [
                      Expanded(
                        child: BentoCard(
                          backgroundColor: Layout09Theme.pastelPurple,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(Icons.download_rounded,
                                  color: primaryColor, size: 32),
                              const SizedBox(height: 12),
                              Text('Download',
                                  style: TextStyle(
                                      color: textSecondary, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                '${download.toStringAsFixed(1)}',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              Text('Mbps',
                                  style: TextStyle(
                                      color: textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: BentoCard(
                          backgroundColor: Layout09Theme.pastelCyan,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(Icons.upload_rounded,
                                  color: secondaryColor, size: 32),
                              const SizedBox(height: 12),
                              Text('Upload',
                                  style: TextStyle(
                                      color: textSecondary, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                '${upload.toStringAsFixed(1)}',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              Text('Mbps',
                                  style: TextStyle(
                                      color: textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Ping Card
                  BentoCard(
                    useGlass: true,
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
                                style: TextStyle(
                                    color: textSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              '${_state.speedTestPingLatency?.toStringAsFixed(0) ?? '-'} ms',
                              style: GoogleFonts.inter(
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
                                style: TextStyle(
                                    color: textSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              '- ms',
                              style: GoogleFonts.inter(
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
          ),
        ],
      ),
    );
  }
}

// Ring Progress Painter
class RingProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isRunning;

  RingProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    const startAngle = -90 * (3.14159 / 180);
    const sweepAngle = 360 * (3.14159 / 180);

    // Track
    final trackPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [primaryColor, secondaryColor, primaryColor],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final progressPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final currentSweep = sweepAngle * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      currentSweep,
      false,
      progressPaint,
    );

    // Glow effect when running
    if (isRunning) {
      final glowPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        currentSweep,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RingProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isRunning != isRunning;
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
    final primaryColor = Theme.of(context).primaryColor;
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                style: GoogleFonts.inter(
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
        ),
      ),
    );
  }
}
