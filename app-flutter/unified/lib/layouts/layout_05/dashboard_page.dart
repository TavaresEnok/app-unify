// Layout 05 Dashboard - Cyber Neon Theme
// Design futurista com Speed Test Gauge, Network Map, e animações

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'theme.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/network_state_provider.dart';
import '../../core/services/diagnostico_service.dart';
import '../../core/models/diagnostico_state.dart';

class DashboardPage extends ConsumerStatefulWidget {
  final String customerName;
  final String planName;
  final String connectionStatus;
  final double billAmount;
  final DateTime billDueDate;
  final double usedGb;
  final double totalGb;
  final double downloadMbps;
  final double uploadMbps;
  final Function(String) onNavigate;
  final List<Map<String, dynamic>>? menuItems;
  final Future<void> Function()? onRefresh;

  const DashboardPage({
    super.key,
    required this.customerName,
    required this.planName,
    required this.connectionStatus,
    required this.billAmount,
    required this.billDueDate,
    required this.usedGb,
    required this.totalGb,
    required this.downloadMbps,
    required this.uploadMbps,
    required this.onNavigate,
    this.menuItems,
    this.onRefresh,
  });

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _dataFlowController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Speed Test State
  DiagnosticoService? _speedTestService;
  StreamSubscription? _speedTestSubscription;
  bool _isSpeedTesting = false;
  bool _speedTestCompleted = false;
  double _downloadSpeed = 0.0;
  double _uploadSpeed = 0.0;
  int _pingMs = 0;
  String _speedTestPhase = 'idle'; // idle, ping, download, upload, done

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _dataFlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _dataFlowController.dispose();
    _speedTestSubscription?.cancel();
    _speedTestService?.dispose();
    super.dispose();
  }

  void _initSpeedTestService() {
    if (_speedTestService != null) return;

    final configProvider = ref.read(configurationProvider);
    final providerConfig = configProvider.providerConfig;
    if (providerConfig == null) return;

    _speedTestService = DiagnosticoService(
      providerConfig: providerConfig,
      context: context,
    );

    _speedTestSubscription = _speedTestService!.stateStream.listen((state) {
      if (!mounted) return;

      final customStatus =
          state.testResultsDisplay['speedTestCustom']?['status'];
      final isRunning = customStatus == TestStatus.running;
      final isDone = customStatus == TestStatus.success;
      final isError = customStatus == TestStatus.error;

      setState(() {
        _isSpeedTesting = isRunning;
        _speedTestCompleted = isDone || isError;

        if (state.customDownloadResultMbps > 0) {
          _downloadSpeed = state.customDownloadResultMbps;
        }
        if (state.customUploadResultMbps > 0) {
          _uploadSpeed = state.customUploadResultMbps;
        }
        if (state.speedTestPingLatency != null) {
          _pingMs = state.speedTestPingLatency!.toInt();
        }

        // Update phase
        if (isRunning) {
          if (state.customUploadResultMbps > 1) {
            _speedTestPhase = 'upload';
          } else if (state.customDownloadResultMbps > 0) {
            _speedTestPhase = 'download';
          } else {
            _speedTestPhase = 'ping';
          }
        } else if (isDone) {
          _speedTestPhase = 'done';
        } else if (isError) {
          _speedTestPhase = 'error';
        }
      });
    });
  }

  void _startSpeedTest() {
    _initSpeedTestService();
    if (_speedTestService == null) return;

    setState(() {
      _isSpeedTesting = true;
      _speedTestCompleted = false;
      _downloadSpeed = 0.0;
      _uploadSpeed = 0.0;
      _pingMs = 0;
      _speedTestPhase = 'ping';
    });

    _speedTestService!.runSpeedTestsOnly();
  }

  void _stopSpeedTest() {
    _speedTestService?.stopAllTests();
    setState(() {
      _isSpeedTesting = false;
      _speedTestPhase = 'idle';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = widget.connectionStatus.toLowerCase() == 'online' ||
        widget.connectionStatus.toLowerCase() == 'ativo';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Layout05Theme.background,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                if (widget.onRefresh != null) {
                  HapticFeedback.mediumImpact();
                  await widget.onRefresh!();
                }
              },
              color: Layout05Theme.primary,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: _buildHeader(),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildHeroCard(isOnline),
                    ),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildPromoBanner(),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSpeedTestCard(),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildNetworkMap(),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        return Stack(
          children: [
            Container(color: Layout05Theme.background),
            Positioned(
              top: -150 + math.sin(_waveController.value * math.pi * 2) * 20,
              right: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Layout05Theme.primary.withValues(alpha: 0.08),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 300 + math.cos(_waveController.value * math.pi * 2) * 15,
              left: -100,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Layout05Theme.secondary.withValues(alpha: 0.06),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                  painter: _GridPatternPainter(_waveController.value)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _scaffoldKey.currentState?.openDrawer();
          },
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: Layout05Theme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Layout05Theme.primary.withValues(
                          alpha: 0.3 + _pulseController.value * 0.15),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.menu_rounded,
                    color: Colors.white, size: 26),
              );
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.customerName.split(' ').first,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: Layout05Theme.accentGradient,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('ULTRA',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Fibra Óptica • ${widget.planName}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _buildGlassBtn(
            Icons.support_agent_rounded, () => widget.onNavigate('suporte')),
        const SizedBox(width: 10),
        _buildGlassBtn(Icons.notifications_rounded,
            () => widget.onNavigate('notificacoes'),
            badge: 3),
      ],
    );
  }

  Widget _buildGlassBtn(IconData icon, VoidCallback onTap, {int? badge}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: Layout05Theme.glassDecoration(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon,
                    color: Colors.white.withValues(alpha: 0.9), size: 22),
                if (badge != null)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: Layout05Theme.errorGradient,
                        shape: BoxShape.circle,
                        boxShadow:
                            Layout05Theme.glowShadow(Layout05Theme.error),
                      ),
                      child: Text('$badge',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(bool isOnline) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _dataFlowController]),
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: Layout05Theme.heroCardDecoration(_pulseController.value),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ...List.generate(3, (i) {
                          final delay = i * 0.3;
                          final progress =
                              ((_dataFlowController.value + delay) % 1.0);
                          return Opacity(
                            opacity: (1 - progress) * 0.4,
                            child: Container(
                              width: 50 + (progress * 18),
                              height: 50 + (progress * 18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Layout05Theme.primary, width: 1.5),
                              ),
                            ),
                          );
                        }),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: Layout05Theme.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow:
                                Layout05Theme.glowShadow(Layout05Theme.primary),
                          ),
                          child: const Icon(Icons.wifi_rounded,
                              color: Colors.white, size: 26),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOnline
                                    ? Layout05Theme.success
                                    : Layout05Theme.error,
                                boxShadow: Layout05Theme.glowShadow(isOnline
                                    ? Layout05Theme.success
                                    : Layout05Theme.error),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                color: isOnline
                                    ? Layout05Theme.success
                                    : Layout05Theme.error,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text('Há 45 dias',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isOnline
                              ? 'Conexão estável e ultrarrápida'
                              : 'Verificando conexão...',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text('Última verificação: agora',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 4,
                  color: Colors.white.withValues(alpha: 0.1),
                  child: AnimatedBuilder(
                    animation: _dataFlowController,
                    builder: (context, _) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.3 + _dataFlowController.value * 0.7,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Layout05Theme.primary.withValues(alpha: 0),
                              Layout05Theme.primary
                            ]),
                            boxShadow:
                                Layout05Theme.glowShadow(Layout05Theme.primary),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpeedTestCard() {
    // Determine status badge content
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (_isSpeedTesting) {
      statusText = _speedTestPhase == 'ping'
          ? 'Testando ping...'
          : _speedTestPhase == 'download'
              ? 'Download...'
              : _speedTestPhase == 'upload'
                  ? 'Upload...'
                  : 'Testando...';
      statusColor = Layout05Theme.warning;
      statusIcon = Icons.speed_rounded;
    } else if (_speedTestCompleted && _speedTestPhase == 'done') {
      statusText = 'Concluído';
      statusColor = Layout05Theme.success;
      statusIcon = Icons.check_circle_rounded;
    } else if (_speedTestPhase == 'error') {
      statusText = 'Erro';
      statusColor = Layout05Theme.error;
      statusIcon = Icons.error_rounded;
    } else {
      statusText = 'Não testado';
      statusColor = Colors.white.withValues(alpha: 0.5);
      statusIcon = Icons.info_outline_rounded;
    }

    // Calculate gauge progress based on current phase
    double gaugeProgress = 0.0;
    if (_isSpeedTesting) {
      if (_speedTestPhase == 'download') {
        gaugeProgress = (_downloadSpeed / 500).clamp(0.0, 1.0);
      } else if (_speedTestPhase == 'upload') {
        gaugeProgress = (_uploadSpeed / 500).clamp(0.0, 1.0);
      } else {
        gaugeProgress = 0.1;
      }
    } else if (_speedTestCompleted) {
      gaugeProgress = (_downloadSpeed / 500).clamp(0.0, 1.0);
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        if (_isSpeedTesting) {
          _stopSpeedTest();
        } else {
          _startSpeedTest();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
              colors: [Color(0xFF0D1117), Color(0xFF161B22)]),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Speed Test',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isSpeedTesting)
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: statusColor,
                          ),
                        )
                      else
                        Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(statusText,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) {
                return SizedBox(
                  width: 200,
                  height: 200,
                  child: CustomPaint(
                    painter: _SpeedGaugePainter(
                        gaugeProgress, _waveController.value),
                    child: Center(
                      child: _isSpeedTesting
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _speedTestPhase == 'download'
                                      ? _downloadSpeed.toStringAsFixed(1)
                                      : _speedTestPhase == 'upload'
                                          ? _uploadSpeed.toStringAsFixed(1)
                                          : '...',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Mbps',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _speedTestCompleted
                                    ? LinearGradient(colors: [
                                        Layout05Theme.success,
                                        Layout05Theme.success
                                            .withValues(alpha: 0.8)
                                      ])
                                    : Layout05Theme.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_speedTestCompleted
                                            ? Layout05Theme.success
                                            : Layout05Theme.primary)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 25,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _speedTestCompleted
                                    ? Icons.refresh_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              _isSpeedTesting
                  ? (_speedTestPhase == 'download'
                      ? 'Testando Download...'
                      : _speedTestPhase == 'upload'
                          ? 'Testando Upload...'
                          : 'Iniciando teste...')
                  : _speedTestCompleted
                      ? 'Toque para testar novamente'
                      : 'Toque para iniciar',
              style: TextStyle(
                color: (_isSpeedTesting
                        ? Layout05Theme.warning
                        : Layout05Theme.primary)
                    .withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: _buildTestResult(
                        'Ping',
                        _pingMs > 0 ? '${_pingMs}ms' : '—',
                        _pingMs > 0
                            ? Layout05Theme.secondary
                            : Colors.white.withValues(alpha: 0.3))),
                Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.08)),
                Expanded(
                    child: _buildTestResult(
                        'Download',
                        _downloadSpeed > 0
                            ? _downloadSpeed.toStringAsFixed(1)
                            : '—',
                        _downloadSpeed > 0
                            ? Layout05Theme.success
                            : Colors.white.withValues(alpha: 0.3))),
                Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.08)),
                Expanded(
                    child: _buildTestResult(
                        'Upload',
                        _uploadSpeed > 0
                            ? _uploadSpeed.toStringAsFixed(1)
                            : '—',
                        _uploadSpeed > 0
                            ? Layout05Theme.primary
                            : Colors.white.withValues(alpha: 0.3))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResult(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'label': 'Faturas',
        'icon': Icons.receipt_long_rounded,
        'color': Layout05Theme.primary,
        'subtitle':
            'R\$ ${widget.billAmount.toStringAsFixed(2).replaceAll(".", ",")}',
        'route': 'invoices'
      },
      {
        'label': 'Suporte\n24h',
        'icon': Icons.headset_mic_rounded,
        'color': Layout05Theme.warning,
        'subtitle': 'Online',
        'route': 'support'
      },
      {
        'label': 'Diagnóstico\nRede',
        'icon': Icons.healing_rounded,
        'color': const Color(0xFF00ACC1),
        'subtitle': 'Testar',
        'route': 'network_diagnostic'
      },
      {
        'label': 'Meu\nRoteador',
        'icon': Icons.router_rounded,
        'color': Layout05Theme.secondary,
        'subtitle': '2 devices',
        'route': 'wifi'
      },
      {
        'label': 'Consumo\nDados',
        'icon': Icons.data_usage_rounded,
        'color': const Color(0xFF9C27B0),
        'subtitle': '${widget.usedGb.toStringAsFixed(0)} GB',
        'route': 'internet_usage'
      },
      {
        'label': 'Contrato\nDigital',
        'icon': Icons.description_rounded,
        'color': const Color(0xFF607D8B),
        'subtitle': 'Ver PDF',
        'route': 'contract'
      },
      {
        'label': 'FAQ\nAjuda',
        'icon': Icons.help_outline_rounded,
        'color': const Color(0xFF795548),
        'subtitle': 'Dúvidas',
        'route': 'faq'
      },
      {
        'label': 'Senha\nWi-Fi',
        'icon': Icons.wifi_password_rounded,
        'color': Layout05Theme.success,
        'subtitle': 'Copiar',
        'route': 'wifi'
      },
      {
        'label': 'Traceroute\nRota',
        'icon': Icons.route_rounded,
        'color': const Color(0xFF5C6BC0),
        'subtitle': 'Mapear',
        'route': 'trace_route'
      },
      {
        'label': 'Meu IP\nPúblico',
        'icon': Icons.public_rounded,
        'color': const Color(0xFF26A69A),
        'subtitle': 'Ver',
        'route': 'my_ip'
      },
      {
        'label': 'Alertas\nAvisos',
        'icon': Icons.notifications_rounded,
        'color': const Color(0xFFEF5350),
        'subtitle': 'Novos',
        'route': 'notifications'
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ações Rápidas',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showActionsGrid(context, actions);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Layout05Theme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Ver mais',
                          style: TextStyle(
                              color: Layout05Theme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.grid_view_rounded,
                          color: Layout05Theme.primary, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 105,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: actions
                  .take(5)
                  .map((a) => _buildActionCard(
                        a['label'] as String,
                        a['icon'] as IconData,
                        a['color'] as Color,
                        a['subtitle'] as String,
                        a['route'] as String,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionsGrid(
      BuildContext context, List<Map<String, dynamic>> actions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Layout05Theme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Todas as Ações',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final a = actions[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    HapticFeedback.lightImpact();
                    widget.onNavigate(a['route'] as String);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (a['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: (a['color'] as Color).withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(a['icon'] as IconData,
                            color: a['color'] as Color, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          (a['label'] as String).replaceAll('\n', ' '),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          a['subtitle'] as String,
                          style: TextStyle(
                              color:
                                  (a['color'] as Color).withValues(alpha: 0.8),
                              fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
      String label, IconData icon, Color color, String subtitle, String route) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onNavigate(route);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const Spacer(),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.2)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(
                      color: color.withValues(alpha: 0.8), fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkMap() {
    return Consumer(
      builder: (context, ref, child) {
        final networkState = ref.watch(networkStateProvider);
        final configProvider = ref.watch(configurationProvider);
        final providerName = configProvider.providerConfig?.name;

        // Determina status de cada nó
        final bool internetActive = networkState.isConnectedToInternet;
        final bool routerActive = networkState.isWifi ||
            networkState.status == NetworkConnectionStatus.ethernet;
        final bool deviceActive = internetActive && routerActive;

        // Determina mensagem de status
        String statusMessage;
        Color statusColor;
        IconData statusIcon;

        if (!networkState.isConnectedToInternet) {
          statusMessage = 'Sem Conexão';
          statusColor = Layout05Theme.error;
          statusIcon = Icons.error_outline;
        } else if (networkState.isMobileData) {
          statusMessage = 'Dados Móveis';
          statusColor = Layout05Theme.accent;
          statusIcon = Icons.signal_cellular_alt;
        } else if (networkState.isExternalWifi(providerName)) {
          statusMessage = 'Wi-Fi Externo';
          statusColor = Layout05Theme.accent;
          statusIcon = Icons.wifi;
        } else if (networkState.isWifi) {
          statusMessage = 'Tudo OK';
          statusColor = Layout05Theme.success;
          statusIcon = Icons.check_circle;
        } else {
          statusMessage = 'Verificando...';
          statusColor = Colors.grey;
          statusIcon = Icons.sync;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mapa da Rede',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(statusMessage,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            // Mostra SSID se conectado a Wi-Fi
            if (networkState.isWifi && networkState.wifiName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Rede: ${networkState.wifiName}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: AnimatedBuilder(
                animation: _dataFlowController,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNetworkNode(
                          'Internet',
                          Icons.public_rounded,
                          internetActive ? Layout05Theme.primary : Colors.grey,
                          internetActive),
                      _buildNetworkLine(active: internetActive && routerActive),
                      _buildNetworkNode(
                          'Roteador',
                          Icons.router_rounded,
                          routerActive ? Layout05Theme.secondary : Colors.grey,
                          routerActive),
                      _buildNetworkLine(active: deviceActive),
                      _buildNetworkNode(
                          'Você',
                          Icons.phone_iphone_rounded,
                          deviceActive ? Layout05Theme.success : Colors.grey,
                          deviceActive),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNetworkNode(
      String label, IconData icon, Color color, bool isActive) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(
                    color: color.withValues(
                        alpha: 0.3 + _pulseController.value * 0.2),
                    width: 2),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 15)
                ],
              ),
              child: Icon(icon, color: color, size: 26),
            );
          },
        ),
        const SizedBox(height: 10),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildNetworkLine({bool active = true}) {
    final lineColor = active ? Layout05Theme.primary : Colors.grey;
    return AnimatedBuilder(
      animation: _dataFlowController,
      builder: (context, _) {
        return SizedBox(
          width: 50,
          height: 3,
          child: CustomPaint(
              painter: _DataFlowPainter(
                  active ? _dataFlowController.value : 0, lineColor)),
        );
      },
    );
  }

  Widget _buildPromoBanner() {
    final promos = [
      {
        'title': '🚀 Upgrade Disponível',
        'subtitle': 'Dobre sua velocidade por +R\$ 20/mês',
        'gradient': const [Color(0xFF7C4DFF), Color(0xFF536DFE)]
      },
      {
        'title': '🎁 Indique e Ganhe',
        'subtitle': '1 mês grátis para cada amigo',
        'gradient': [Layout05Theme.success, const Color(0xFF00C853)]
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Promoções',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: PageView.builder(
            itemCount: promos.length,
            controller: PageController(viewportFraction: 0.95),
            itemBuilder: (context, index) {
              final promo = promos[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                        colors: promo['gradient'] as List<Color>),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(promo['title'] as String,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(promo['subtitle'] as String,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white.withValues(alpha: 0.6), size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    final menuItems = [
      {
        'icon': Icons.home_rounded,
        'label': 'Início',
        'route': 'dashboard',
        'color': Layout05Theme.primary
      },
      {
        'icon': Icons.speed_rounded,
        'label': 'Velocidade',
        'route': 'speed_test',
        'color': Layout05Theme.success
      },
      {
        'icon': Icons.receipt_long_rounded,
        'label': 'Faturas',
        'route': 'invoices',
        'color': const Color(0xFFFF7043)
      },
      {
        'icon': Icons.router_rounded,
        'label': 'Wi-Fi / Roteador',
        'route': 'wifi',
        'color': Layout05Theme.secondary
      },
      {
        'icon': Icons.data_usage_rounded,
        'label': 'Consumo',
        'route': 'internet_usage',
        'color': const Color(0xFF9C27B0)
      },
      {
        'icon': Icons.support_agent_rounded,
        'label': 'Suporte',
        'route': 'support',
        'color': Layout05Theme.warning
      },
      {
        'icon': Icons.healing_rounded,
        'label': 'Diagnóstico',
        'route': 'network_diagnostic',
        'color': const Color(0xFF00ACC1)
      },
      {
        'icon': Icons.route_rounded,
        'label': 'Traceroute',
        'route': 'trace_route',
        'color': const Color(0xFF5C6BC0)
      },
      {
        'icon': Icons.public_rounded,
        'label': 'Meu IP',
        'route': 'my_ip',
        'color': const Color(0xFF26A69A)
      },
      {
        'icon': Icons.description_rounded,
        'label': 'Contrato',
        'route': 'contract',
        'color': const Color(0xFF607D8B)
      },
      {
        'icon': Icons.help_outline_rounded,
        'label': 'FAQ',
        'route': 'faq',
        'color': const Color(0xFF795548)
      },
      {
        'icon': Icons.notifications_rounded,
        'label': 'Notificações',
        'route': 'notifications',
        'color': const Color(0xFFEF5350)
      },
    ];

    return Drawer(
      backgroundColor: Layout05Theme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration:
                  const BoxDecoration(gradient: Layout05Theme.primaryGradient),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.customerName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(widget.planName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children:
                    menuItems.map((item) => _buildDrawerItem(item)).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  widget.onNavigate('logout');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Layout05Theme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Layout05Theme.error.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded,
                          color: Layout05Theme.error, size: 20),
                      SizedBox(width: 8),
                      Text('Sair',
                          style: TextStyle(
                              color: Layout05Theme.error,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          widget.onNavigate(item['route'] as String);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: (item['color'] as Color).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: (item['color'] as Color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(item['icon'] as IconData,
                    color: item['color'] as Color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(item['label'] as String,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500))),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.3), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            decoration: BoxDecoration(
              color: Layout05Theme.background.withValues(alpha: 0.92),
              border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_rounded, 'Início', 0),
                  _buildNavItem(Icons.speed_rounded, 'Velocidade', 1),
                  _buildCenterNav(),
                  _buildNavItem(Icons.receipt_long_rounded, 'Faturas', 2),
                  _buildNavItem(Icons.headset_mic_rounded, 'Suporte', 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedIndex = index);
        if (index == 1) widget.onNavigate('diagnostico');
        if (index == 2) widget.onNavigate('financeiro');
        if (index == 3) widget.onNavigate('perfil');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Layout05Theme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected
                    ? Layout05Theme.primary
                    : Colors.white.withValues(alpha: 0.35),
                size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Layout05Theme.primary
                    : Colors.white.withValues(alpha: 0.35),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNav() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onNavigate('diagnostico');
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          return Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: Layout05Theme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Layout05Theme.primary
                      .withValues(alpha: 0.35 + _pulseController.value * 0.1),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child:
                const Icon(Icons.speed_rounded, color: Colors.white, size: 28),
          );
        },
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  final double animation;
  _GridPatternPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    final offset = animation * spacing;

    for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = -spacing + offset;
        y < size.height + spacing;
        y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPatternPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class _SpeedGaugePainter extends CustomPainter {
  final double progress;
  final double animation;
  _SpeedGaugePainter(this.progress, this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Background circles
    for (int i = 0; i < 3; i++) {
      final r = radius - (i * 12);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.03 + i * 0.01)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, r, paint);
    }

    // Speed markers
    final markerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 2;
    for (int i = 0; i < 12; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / 12);
      final start = Offset(
        center.dx + (radius - 5) * math.cos(angle),
        center.dy + (radius - 5) * math.sin(angle),
      );
      final end = Offset(
        center.dx + (radius - 15) * math.cos(angle),
        center.dy + (radius - 15) * math.sin(angle),
      );
      canvas.drawLine(start, end, markerPaint);
    }

    // Progress arc (only if progress > 0)
    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          colors: const [
            Color(0xFF00E5FF),
            Color(0xFF00E676),
            Color(0xFF00E5FF)
          ],
          transform: GradientRotation(animation * 2 * math.pi),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );

      // Glow
      final glowPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        glowPaint,
      );
    }

    // Outer ring glow (subtle, always visible)
    final ringGlow = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius, ringGlow);
  }

  @override
  bool shouldRepaint(covariant _SpeedGaugePainter oldDelegate) =>
      progress != oldDelegate.progress || animation != oldDelegate.animation;
}

class _DataFlowPainter extends CustomPainter {
  final double animation;
  final Color color;
  _DataFlowPainter(this.animation, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);

    // Animated dot
    final dotPaint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final dotX = animation * size.width;
    canvas.drawCircle(Offset(dotX, size.height / 2), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _DataFlowPainter oldDelegate) =>
      animation != oldDelegate.animation;
}
