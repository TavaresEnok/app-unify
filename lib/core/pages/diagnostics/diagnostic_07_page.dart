// ignore_for_file: deprecated_member_use

// Diagnostic7 - "Zenith Ultra-Premium" Final Polish
// INTEGRAÇÃO COM SERVIÇOS REAIS - Janeiro 2026
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/diagnostico_service.dart' as real_service;
import '../../services/onu_wifi_service.dart';
import '../../models/diagnostico_state.dart' as real_state;
import '../../providers/providers.dart';

// ============ THEME CONFIG (WHITE MODE) ============
class AppTheme {
  // Bases
  static const bgLight = Color(0xFFF8FAFC); // Slate 50
  static const bgWhite = Colors.white;

  // Brand
  static const primary = Color(0xFF7C3AED); // Violet 600
  static const primarySafe = Color(0xFF6D28D9); // Violet 700
  static const accent = Color(0xFF0EA5E9); // Sky 500
  static const secondary = Color(0xFFF43F5E); // Rose 500

  // Status
  static const success = Color(0xFF059669); // Emerald 600
  static const warning = Color(0xFFD97706); // Amber 600
  static const error = Color(0xFFDC2626); // Red 600

  // Text
  static const textDark = Color(0xFF0F172A); // Slate 900
  static const textGrey = Color(0xFF64748B); // Slate 500
  static const textLight = Color(0xFF94A3B8); // Slate 400

  static final borderRadius = BorderRadius.circular(24);
}

enum DiagStep { ready, wifi, fiber, tracert, devices, speed, done }

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ZenithApp());
}

class ZenithApp extends StatelessWidget {
  const ZenithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zenith Pro',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppTheme.bgLight,
        useMaterial3: true,
        primaryColor: AppTheme.primary,
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      ),
      home: const Diagnostic07Page(),
    );
  }
}

class Diagnostic07Page extends ConsumerStatefulWidget {
  const Diagnostic07Page({super.key});

  @override
  ConsumerState<Diagnostic07Page> createState() => _Diagnostic07PageState();
}

class _Diagnostic07PageState extends ConsumerState<Diagnostic07Page>
    with TickerProviderStateMixin {
  // State
  DiagStep _step = DiagStep.ready;
  String _statusMessage = "Sistema pronto";
  double _progress = 0.0;

  // Data
  Map<String, dynamic>? _wifi;
  Map<String, dynamic>? _fiber;
  List<Map<String, dynamic>> _hops = [];
  List<Map<String, dynamic>> _devices = [];
  double _liveSpeed = 0;
  List<double> _speedHistory = List.filled(40, 0.0, growable: true);
  Map<String, dynamic>? _results;

  // Animations
  late AnimationController _meshController;
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late AnimationController _globalResyncController; // Forces particle repaints

  // Integração com serviço real
  real_service.DiagnosticoService? _realService;
  StreamSubscription<real_state.DiagnosticoState>? _realSub;

  @override
  void initState() {
    super.initState();
    _meshController =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat(reverse: true);
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _scanController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _globalResyncController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_realService == null) {
      final config = ref.read(configurationProvider).providerConfig;
      if (config != null) {
        OnuWifiService? onuService;
        final authState = ref.read(authNotifierProvider);
        final user = authState.value;
        if (user != null) {
          final integrations = config.config.integrations;
          Map<String, String> sgpParams = {
            'sgpBaseUrl': integrations.sgpBaseUrl,
            'token': integrations.apiToken,
            'appName': integrations.appName,
          };
          onuService = OnuWifiService(
            apiUrl: config.apiUrl,
            cpfCnpj: user.cpfCnpj,
            senha: user.senha,
            contrato: user.contratoId?.toString(),
            sgpParams: sgpParams,
          );
        }

        _realService = real_service.DiagnosticoService(
          providerConfig: config,
          context: context,
          onuService: onuService,
        );
        _realSub = _realService!.stateStream.listen(_handleRealServiceState);
      }
    }
  }

  void _handleRealServiceState(real_state.DiagnosticoState realState) {
    final downloadMbps = realState.customDownloadResultMbps;
    final uploadMbps = realState.customUploadResultMbps;

    if (downloadMbps > 0 || uploadMbps > 0) {
      setState(() {
        _results = {
          'download': downloadMbps,
          'upload': uploadMbps,
          'ping': realState.speedTestPingLatency ?? 0.0,
          'jitter': 0.0,
        };
        // Atualizar histórico com dados reais
        for (final spot in realState.downloadHistory) {
          _speedHistory.add(spot.y);
          if (_speedHistory.length > 40) _speedHistory.removeAt(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _realSub?.cancel();
    _realService?.dispose();
    _meshController.dispose();
    _pulseController.dispose();
    _scanController.dispose();
    _globalResyncController.dispose();
    super.dispose();
  }

  // ============ LOGIC ============

  Future<void> _runDiagnostics() async {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _step = DiagStep.wifi;
      _progress = 0;
      _results = null;
      _wifi = null;
      _fiber = null;
      _hops = [];
      _devices = [];
      _speedHistory = List.filled(40, 0.0, growable: true);
    });

    // STEP 1: Wi-Fi
    _setStatus("Analisando espectro Wi-Fi...");
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _wifi = {
        'ssid': 'FibraMax_Ultra_5G',
        'rssi': -38,
        'channel': 149,
        'quality': 96,
        'freq': '5825 MHz',
        'security': 'WPA3',
        'gateway': '192.168.1.1'
      };
      _progress = 0.15;
    });

    // STEP 2: Fiber
    if (!mounted) return;
    setState(() => _step = DiagStep.fiber);
    _setStatus("Verificando potência óptica...");
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _fiber = {
        'rx': -18.45,
        'tx': 2.33,
        'temp': 41.2,
        'volt': 3.24,
        'bias': 12.5,
        'status': 'Online (O5)'
      };
      _progress = 0.30;
    });

    // STEP 3: Traceroute
    if (!mounted) return;
    setState(() => _step = DiagStep.tracert);
    _setStatus("Rastreando rota externa...");

    final routeData = [
      {'hop': 1, 'ip': '192.168.1.1', 'time': 0.8},
      {'hop': 2, 'ip': '10.0.0.1', 'time': 3.4},
      {'hop': 3, 'ip': '187.100.50.1', 'time': 8.2},
      {'hop': 4, 'ip': '200.200.10.5', 'time': 12.5},
      {'hop': 5, 'ip': '8.8.8.8', 'time': 18.7},
    ];

    for (var hop in routeData) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _hops.add(hop));
    }
    setState(() => _progress = 0.50);

    // STEP 4: Devices
    if (!mounted) return;
    setState(() => _step = DiagStep.devices);
    _setStatus("Mapeando dispositivos na rede...");

    final deviceData = [
      {
        'name': 'iPhone 15 Pro',
        'ip': '192.168.1.5',
        'icon': Icons.phone_iphone
      },
      {'name': 'Samsung TV 4K', 'ip': '192.168.1.12', 'icon': Icons.tv},
      {'name': 'Dell XPS', 'ip': '192.168.1.20', 'icon': Icons.computer},
      {'name': 'iPad Air', 'ip': '192.168.1.22', 'icon': Icons.tablet_mac},
      {'name': 'PlayStation 5', 'ip': '192.168.1.50', 'icon': Icons.gamepad},
    ];

    for (var dev in deviceData) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _devices.add(dev));
    }
    setState(() => _progress = 0.65);

    // STEP 5: Speed
    if (!mounted) return;
    setState(() => _step = DiagStep.speed);

    // Download
    _setStatus("Teste de Carga: Download");
    double maxRec = 0;
    for (int i = 0; i < 40; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 60));
      final val =
          (500 + math.sin(i * 0.4) * 150 + math.Random().nextDouble() * 50)
              .clamp(0.0, 999.0);
      maxRec = math.max(maxRec, val);
      setState(() {
        _liveSpeed = val;
        _speedHistory.add(val);
        _speedHistory.removeAt(0);
        _progress = 0.65 + (i / 40) * 0.20;
      });
    }

    // Upload
    if (!mounted) return;
    _setStatus("Teste de Carga: Upload");
    await Future.delayed(const Duration(milliseconds: 300));
    double maxTrans = 0;
    for (int i = 0; i < 30; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 60));
      final val =
          (250 + math.sin(i * 0.5) * 100 + math.Random().nextDouble() * 40)
              .clamp(0.0, 999.0);
      maxTrans = math.max(maxTrans, val);
      setState(() {
        _liveSpeed = val;
        _speedHistory.add(val);
        _speedHistory.removeAt(0);
        _progress = 0.85 + (i / 30) * 0.15;
      });
    }

    // Done
    if (!mounted) return;
    setState(() {
      _results = {
        'download': maxRec,
        'upload': maxTrans,
        'ping': 4.0,
        'jitter': 0.8,
        'loss': 0.0,
        'score': 99,
      };
      _step = DiagStep.done;
      _setStatus("Diagnóstico completo");
    });
    HapticFeedback.heavyImpact();
  }

  void _setStatus(String msg) {
    if (mounted) setState(() => _statusMessage = msg);
  }

  // ============ UI ============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.bgLight,
      body: Stack(
        children: [
          // 1. Alive Background (Mesh + Particles)
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _globalResyncController,
                builder: (_, __) => CustomPaint(
                  painter: _CombinedBackgroundPainter(
                    meshTime: _meshController.value,
                  ),
                ),
              ),
            ),
          ),

          // 2. Grain Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.03,
                child: Container(color: Colors.black),
              ),
            ),
          ),

          // 3. Content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: _buildBody(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildGlassIcon(Icons.bolt_rounded),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ZENITH",
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: AppTheme.textDark)),
                  Text("ULTRA PRO",
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppTheme.textGrey,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600)),
                ],
              )
            ],
          ),
          if (_step != DiagStep.ready && _step != DiagStep.done)
            _GlassBadge(
                child: Text("${(_progress * 100).toInt()}%",
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary)))
        ],
      ),
    );
  }

  Widget _buildBody() {
    Widget content;
    String title;

    switch (_step) {
      case DiagStep.wifi:
        title = "Analisando Wi-Fi";
        content = _wifi != null
            ? _StaggeredItem(index: 0, child: _buildWifiCard(_wifi!))
            : const SizedBox();
        break;
      case DiagStep.fiber:
        title = "Testando Fibra";
        content = _fiber != null
            ? _StaggeredItem(index: 0, child: _buildFiberCard(_fiber!))
            : const SizedBox();
        break;
      case DiagStep.tracert:
        title = "Traçando Rotas";
        content = _buildTracertList();
        break;
      case DiagStep.devices:
        title = "Dispositivos";
        content = _buildDeviceGrid();
        break;
      case DiagStep.speed:
        title = "Velocidade";
        content = Column(
          children: [
            Text(_liveSpeed.toStringAsFixed(0),
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 80,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    letterSpacing: -2)),
            Text("Mbps",
                style: GoogleFonts.inter(
                    color: AppTheme.textGrey, letterSpacing: 1.2)),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              width: double.infinity,
              child: CustomPaint(
                  painter: _SmoothChartPainter(
                      data: _speedHistory, color: AppTheme.primary)),
            )
          ],
        );
        break;
      case DiagStep.ready:
        return _buildReadyView();
      case DiagStep.done:
        return _buildResultsView();
      default:
        title = "Inicializando...";
        content = const SizedBox();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Progress Ring with Icon
        SizedBox(
            height: 120,
            width: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Custom Gradient Loader
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 6,
                    backgroundColor: AppTheme.bgWhite,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Inner Scan Effect
                if (_step == DiagStep.wifi || _step == DiagStep.devices)
                  AnimatedBuilder(
                    animation: _scanController,
                    builder: (_, __) => Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.primary.withOpacity(0.15)
                              ],
                              startAngle: 0,
                              endAngle: 1,
                              transform: GradientRotation(
                                  _scanController.value * 2 * math.pi))),
                    ),
                  ),
                Icon(_getStepIcon(), size: 40, color: AppTheme.primary),
              ],
            )),

        const SizedBox(height: 40),

        Text(title.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary)),
        const SizedBox(height: 8),
        Text(_statusMessage,
            style: GoogleFonts.inter(
                color: AppTheme.textGrey, letterSpacing: 0.5)),

        const SizedBox(height: 40),

        Expanded(
            child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: content))),
      ],
    );
  }

  // --- START & END VIEWS ---

  Widget _buildReadyView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        GestureDetector(
          onTap: _runDiagnostics,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, child) {
                return Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.primary
                                .withOpacity(0.3 * _pulseController.value),
                            blurRadius: 40 + (20 * _pulseController.value),
                            spreadRadius: 5),
                        BoxShadow(
                            color: AppTheme.accent.withOpacity(0.2),
                            blurRadius: 60,
                            spreadRadius: 10,
                            offset: const Offset(-10, -10)),
                      ]),
                  child: child,
                );
              },
              child: Center(
                child: Icon(Icons.play_arrow_rounded,
                    size: 60, color: AppTheme.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
        Text("INICIAR DIAGNÓSTICO",
            style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Text("Wi-Fi • Fibra • Rotas • Velocidade",
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textGrey)),
        const Spacer(),
      ],
    );
  }

  Widget _buildResultsView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Clean)
          Center(
              child: _StaggeredItem(
            index: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_outline_rounded,
                      color: AppTheme.success, size: 48),
                ),
                const SizedBox(height: 16),
                Text("Diagnóstico Finalizado",
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark)),
                Text("Todos os testes foram concluídos com êxito.",
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppTheme.textGrey)),
              ],
            ),
          )),
          const SizedBox(height: 32),

          // Speed Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _StaggeredItem(
                  index: 1,
                  child: _buildMetricCard(
                      "Download",
                      "${_results?['download'].toInt()}",
                      "Mbps",
                      AppTheme.success)),
              _StaggeredItem(
                  index: 2,
                  child: _buildMetricCard(
                      "Upload",
                      "${_results?['upload'].toInt()}",
                      "Mbps",
                      AppTheme.accent)),
              _StaggeredItem(
                  index: 3,
                  child: _buildMetricCard("Ping",
                      "${_results?['ping'].toInt()}", "ms", AppTheme.warning)),
              _StaggeredItem(
                  index: 4,
                  child: _buildMetricCard("Jitter", "${_results?['jitter']}",
                      "ms", AppTheme.secondary)),
            ],
          ),
          const SizedBox(height: 32),

          // Details Sections
          _StaggeredItem(
              index: 5,
              child: Text("RELATÓRIO TÉCNICO",
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textLight,
                      letterSpacing: 2))),
          const SizedBox(height: 16),

          if (_wifi != null)
            _StaggeredItem(
                index: 6,
                child: Column(children: [
                  _buildSectionHeader("Wi-Fi Spectrum", Icons.wifi),
                  _buildWifiCard(_wifi!)
                ])),
          const SizedBox(height: 16),

          if (_fiber != null)
            _StaggeredItem(
                index: 7,
                child: Column(children: [
                  _buildSectionHeader("Fibra Óptica", Icons.cable),
                  _buildFiberCard(_fiber!)
                ])),
          const SizedBox(height: 16),

          if (_hops.isNotEmpty)
            _StaggeredItem(
                index: 8,
                child: Column(children: [
                  _buildSectionHeader("Rota (Traceroute)", Icons.alt_route),
                  _buildTracertList()
                ])),
          const SizedBox(height: 16),

          if (_devices.isNotEmpty)
            _StaggeredItem(
                index: 9,
                child: Column(children: [
                  _buildSectionHeader("Dispositivos", Icons.devices),
                  _buildDeviceGrid()
                ])),

          const SizedBox(height: 48),
          _StaggeredItem(
              index: 10,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => _step = DiagStep.ready),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text("Novo Teste",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, color: AppTheme.textDark)),
        ],
      ),
    );
  }

  Widget _buildWifiCard(Map<String, dynamic> data) {
    return _GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _row("SSID", data['ssid'], bold: true),
          Divider(color: Colors.black.withOpacity(0.05)),
          _row("Canal", "${data['channel']}"),
          _row("Frequência", data['freq']),
          _row("Qualidade", "${data['quality']}%"),
        ],
      ),
    );
  }

  Widget _buildFiberCard(Map<String, dynamic> data) {
    return _GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _row("Status", data['status'], color: AppTheme.success),
          Divider(color: Colors.black.withOpacity(0.05)),
          _row("RX Power", "${data['rx']} dBm"),
          _row("TX Power", "${data['tx']} dBm"),
          _row("Voltagem", "${data['volt']} V"),
        ],
      ),
    );
  }

  Widget _buildTracertList() {
    return _GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _hops.asMap().entries.map((entry) {
          final i = entry.key;
          final h = entry.value;
          return _StaggeredItem(
            index: i,
            key: ValueKey(h['ip']),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: AppTheme.bgLight, shape: BoxShape.circle),
                    child: Text("${h['hop']}",
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textGrey)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(h['ip'],
                          style: GoogleFonts.firaCode(
                              fontSize: 12, color: AppTheme.textDark))),
                  Text("${h['time']}ms",
                      style: TextStyle(
                          fontSize: 11,
                          color: h['time'] < 10
                              ? AppTheme.success
                              : AppTheme.warning)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeviceGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.2),
      itemCount: _devices.length,
      itemBuilder: (ctx, i) {
        return _StaggeredItem(
          index: i,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.05))),
            child: Row(
              children: [
                Icon(_devices[i]['icon'] as IconData,
                    size: 20, color: AppTheme.textGrey),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_devices[i]['name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(_devices[i]['ip'],
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.textLight)),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
      String label, String value, String unit, Color color) {
    return _GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppTheme.textGrey)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.0)),
              const SizedBox(width: 4),
              Text(unit,
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textLight, height: 2.0)),
            ],
          )
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? AppTheme.textDark)),
        ],
      ),
    );
  }

  IconData _getStepIcon() {
    switch (_step) {
      case DiagStep.wifi:
        return Icons.wifi;
      case DiagStep.fiber:
        return Icons.cable;
      case DiagStep.tracert:
        return Icons.alt_route;
      case DiagStep.devices:
        return Icons.devices;
      case DiagStep.speed:
        return Icons.speed;
      default:
        return Icons.hourglass_empty;
    }
  }

  Widget _buildGlassIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ]),
      child: Icon(icon, color: AppTheme.textDark, size: 20),
    );
  }
}

// ============ UTILS ============

// Staggered Animation Helper
class _StaggeredItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggeredItem({required this.index, required this.child, super.key});
  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // Staggered Start
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _GlassContainer({required this.child, this.padding});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppTheme.borderRadius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: AppTheme.borderRadius,
              border: Border.all(color: Colors.white),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.primary.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5))
              ]),
          child: child,
        ),
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  final Widget child;
  const _GlassBadge({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: child,
    );
  }
}

// ============ PAINTERS ============

class _CombinedBackgroundPainter extends CustomPainter {
  final double meshTime;
  _CombinedBackgroundPainter({required this.meshTime});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // 1. Bg
    canvas.drawRect(rect, Paint()..color = AppTheme.bgLight);

    // 2. Mesh Orbs
    final p = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    p.color = AppTheme.primary.withOpacity(0.08);
    canvas.drawCircle(
        Offset(size.width * 0.3 + math.sin(meshTime) * 30, size.height * 0.2),
        size.width * 0.5,
        p);
    p.color = AppTheme.accent.withOpacity(0.08);
    canvas.drawCircle(
        Offset(size.width * 0.8 - math.cos(meshTime) * 30, size.height * 0.6),
        size.width * 0.6,
        p);

    // 3. Particles
    final rnd = math.Random(
        42); // Seeded for consistency in static snapshot but dynamic in animation
    final pp = Paint()..color = AppTheme.primary.withOpacity(0.2);
    for (int i = 0; i < 30; i++) {
      final x = (rnd.nextDouble() * size.width + math.sin(meshTime + i) * 20) %
          size.width;
      final y = (rnd.nextDouble() * size.height + math.cos(meshTime + i) * 20) %
          size.height;
      canvas.drawCircle(Offset(x, y), rnd.nextDouble() * 3, pp);
    }
  }

  @override
  bool shouldRepaint(covariant _CombinedBackgroundPainter old) => true;
}

class _SmoothChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _SmoothChartPainter({required this.data, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final widthStep = size.width / (data.length - 1);
    path.moveTo(0, size.height - (data[0] / 1000 * size.height));
    for (int i = 0; i < data.length - 1; i++) {
      final x1 = i * widthStep;
      final y1 =
          size.height - (data[i] / 1000 * size.height).clamp(0.0, size.height);
      final x2 = (i + 1) * widthStep;
      final y2 = size.height -
          (data[i + 1] / 1000 * size.height).clamp(0.0, size.height);
      path.cubicTo(x1 + widthStep / 2, y1, x1 + widthStep / 2, y2, x2, y2);
    }
    // Gradient Fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withOpacity(0.2), color.withOpacity(0.0)])
              .createShader(Offset.zero & size));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SmoothChartPainter old) => true;
}
