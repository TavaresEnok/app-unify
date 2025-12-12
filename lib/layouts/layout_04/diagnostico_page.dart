// LAYOUT 04 - AURORA - DIAGNOSTICO PAGE (FIXED)
// Design: Network diagnostics with neon indicators (simplified)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/configuration_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/onu_wifi_service.dart';
import 'aurora_theme.dart';

class DiagnosticoPage extends StatefulWidget {
  const DiagnosticoPage({super.key});

  @override
  State<DiagnosticoPage> createState() => _DiagnosticoPageState();
}

class _DiagnosticoPageState extends State<DiagnosticoPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  OnuWifiService? _onuWifiService;
  OnuData? _onuData;
  bool _isLoadingOnu = false;
  String? _onuError;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initService();
  }

  void _initService() {
    final configProvider = context.read<ConfigurationProvider>();
    final authService = context.read<AuthService>();
    final config = configProvider.providerConfig;
    final usuario = authService.usuario;

    if (config != null && usuario != null && _onuWifiService == null) {
      _onuWifiService = OnuWifiService(
        apiUrl: config.apiUrl,
        cpfCnpj: usuario.cpfCnpj.replaceAll(RegExp(r'[^0-9]'), ''),
        senha: usuario.senha ?? '',
        sgpParams: {
          'token': config.config.integrations.apiToken,
          'app': config.config.integrations.appName,
          'sgpBaseUrl': config.config.integrations.sgpBaseUrl,
        },
      );
      _loadOnuData();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadOnuData() async {
    if (_onuWifiService == null) return;

    setState(() {
      _isLoadingOnu = true;
      _onuError = null;
    });

    try {
      final data = await _onuWifiService!.fetchOnuSignal();
      setState(() => _onuData = data);
    } catch (e) {
      setState(() => _onuError = e.toString());
    } finally {
      setState(() => _isLoadingOnu = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: ShaderMask(
            shaderCallback: (bounds) =>
                AuroraColors.primaryGradient.createShader(bounds),
            child: const Text('Diagnóstico',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          color: AuroraColors.neonCyan,
          backgroundColor: AuroraColors.surface,
          onRefresh: _loadOnuData,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ONU Card
              _buildOnuCard(),

              const SizedBox(height: 20),

              // Quick Info Cards
              _buildQuickInfoGrid(),

              const SizedBox(height: 20),

              // Speed Test Button
              GlassCard(
                glowColor: AuroraColors.neonCyan,
                child: Column(
                  children: [
                    NeonIconBadge(
                        icon: Icons.speed,
                        color: AuroraColors.neonCyan,
                        size: 56),
                    const SizedBox(height: 16),
                    const Text(
                      'Teste de Velocidade',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AuroraColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Verifique a velocidade da sua conexão',
                      style: TextStyle(color: AuroraColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    NeonButton(
                      text: 'Iniciar Speed Test',
                      icon: Icons.play_arrow,
                      onPressed: () {
                        // Navigate to speed test page
                        Navigator.of(context).pushNamed('/speed-test');
                      },
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

  Widget _buildOnuCard() {
    if (_isLoadingOnu) {
      return GlassCard(
        child: Center(
          child: Column(
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AuroraColors.neonCyan),
                ),
              ),
              const SizedBox(height: 16),
              Text('Carregando ONU...',
                  style: TextStyle(color: AuroraColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (_onuError != null || _onuData == null) {
      return GlassCard(
        child: Column(
          children: [
            NeonIconBadge(
                icon: Icons.router, color: AuroraColors.textMuted, size: 56),
            const SizedBox(height: 16),
            Text('ONU não encontrada',
                style: TextStyle(color: AuroraColors.textSecondary)),
            const SizedBox(height: 16),
            NeonButton(
                text: 'Tentar novamente',
                icon: Icons.refresh,
                isOutlined: true,
                onPressed: _loadOnuData),
          ],
        ),
      );
    }

    final signalColor =
        _onuData!.isSignalGood ? AuroraColors.success : AuroraColors.error;
    final statusColor =
        _onuData!.isOnline ? AuroraColors.success : AuroraColors.error;

    return GlassCard(
      glowColor: statusColor,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor
                                .withOpacity(0.3 + 0.2 * _controller.value),
                            blurRadius: 20,
                            spreadRadius: _onuData!.isOnline ? 2 : 0,
                          ),
                        ],
                      ),
                      child: Icon(Icons.router, color: statusColor, size: 28),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ONU ${_onuData!.model}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AuroraColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(_onuData!.connectionStatus,
                              style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: signalColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: signalColor.withOpacity(0.5)),
                  ),
                  child: Text(_onuData!.signalQuality,
                      style: TextStyle(
                          color: signalColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              ],
            ),
          ),

          Container(height: 1, color: AuroraColors.glassBorder),

          // Signal Values
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                    child: _buildSignalIndicator('RX',
                        _onuData!.signalRxDisplay, AuroraColors.neonCyan)),
                Container(
                    width: 1, height: 50, color: AuroraColors.glassBorder),
                Expanded(
                    child: _buildSignalIndicator('TX',
                        _onuData!.signalTxDisplay, AuroraColors.neonPurple)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(color: AuroraColors.textMuted, fontSize: 12)),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildQuickInfoGrid() {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                NeonIconBadge(
                    icon: Icons.wifi, color: AuroraColors.success, size: 40),
                const SizedBox(height: 12),
                const Text('Wi-Fi',
                    style: TextStyle(
                        color: AuroraColors.textPrimary,
                        fontWeight: FontWeight.bold)),
                Text('Conectado',
                    style:
                        TextStyle(fontSize: 12, color: AuroraColors.success)),
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
                NeonIconBadge(
                    icon: Icons.timer,
                    color: AuroraColors.neonPurple,
                    size: 40),
                const SizedBox(height: 12),
                const Text('Latência',
                    style: TextStyle(
                        color: AuroraColors.textPrimary,
                        fontWeight: FontWeight.bold)),
                Text('< 20ms',
                    style: TextStyle(
                        fontSize: 12, color: AuroraColors.neonPurple)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
