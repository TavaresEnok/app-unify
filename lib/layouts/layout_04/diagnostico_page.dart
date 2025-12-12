import 'package:flutter/material.dart';
import 'dart:ui'; // For moving blur
import 'package:provider/provider.dart';

import '../../core/services/diagnostico_service.dart';
import '../../core/models/diagnostico_state.dart';
import '../../core/providers/configuration_provider.dart';
import 'theme.dart';

class DiagnosticoPage extends StatefulWidget {
  const DiagnosticoPage({super.key});

  @override
  State<DiagnosticoPage> createState() => _DiagnosticoPageState();
}

class _DiagnosticoPageState extends State<DiagnosticoPage>
    with SingleTickerProviderStateMixin {
  DiagnosticoService? _diagnosticoService;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initService();
    });
  }

  void _initService() {
    final configProvider = context.read<ConfigurationProvider>();
    final providerConfig = configProvider.providerConfig;

    if (providerConfig != null) {
      _diagnosticoService = DiagnosticoService(
        providerConfig: providerConfig,
        context: context,
      );
      _diagnosticoService?.runAllTests();
      setState(() {});
    }
  }

  Future<void> _rebootOnu() async {
    // Show confirmation dialog with Cyber theme
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Layout04Theme.backgroundLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Layout04Theme.primaryCyan),
          ),
          title: Text('Reiniciar ONU', style: Layout04Theme.heading3),
          content: Text(
            'Deseja realmente reiniciar seu equipamento? A conexão cairá por alguns instantes.',
            style: Layout04Theme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'CANCELAR',
                style: Layout04Theme.bodyMedium,
              ),
            ),
            Container(
              height: 40,
              decoration: Layout04Theme.neonButton(
                gradient: Layout04Theme.secondaryGradient,
                borderRadius: 12,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(ctx, true),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        'REINICIAR',
                        style: Layout04Theme.buttonText.copyWith(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enviando comando de reinicialização...'),
          backgroundColor: Layout04Theme.info,
        ),
      );
      // Here you would call _diagnosticoService.rebootOnu(...)
      // For now, let's just simulate
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Comando enviado com sucesso!'),
            backgroundColor: Layout04Theme.success,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _diagnosticoService?.stopAllTests();
    _diagnosticoService?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout04Theme.background,
      appBar: AppBar(
        title: Text('Diagnóstico de Rede', style: Layout04Theme.heading3),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: Layout04Theme.backgroundGradient,
        ),
        child: SafeArea(
          child: _diagnosticoService == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<DiagnosticoState>(
                  stream: _diagnosticoService!.stateStream,
                  builder: (context, snapshot) {
                    final state = snapshot.data;
                    if (state == null || state.isTesting) {
                      return _buildScanningAnimation(state?.geralStatusMessage);
                    }
                    return _buildDiagnosticResult(state);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildScanningAnimation(String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Rotating rings
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Layout04Theme.primaryCyan.withOpacity(0.3),
                  ),
                  strokeWidth: 2,
                ),
              ),
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Layout04Theme.primaryPurple.withOpacity(0.5),
                  ),
                  strokeWidth: 4,
                ),
              ),
              // Pulsing Core
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow:
                        Layout04Theme.neonGlow(Layout04Theme.primaryCyan),
                    gradient: Layout04Theme.primaryGradient,
                  ),
                  child: const Icon(
                    Icons.radar_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            'ESCANEANDO REDE...',
            style: Layout04Theme.heading3.copyWith(
              letterSpacing: 2,
              color: Layout04Theme.primaryCyan,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message ?? 'Iniciando testes...',
              textAlign: TextAlign.center,
              style: Layout04Theme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticResult(DiagnosticoState state) {
    // Determine overall status based on failures
    bool hasError = state.testResultsDisplay.values
        .any((result) => result['status'] == TestStatus.error);

    final statusColor = hasError ? Layout04Theme.error : Layout04Theme.success;

    // Extract Latency from Ping Test (Google or Cloudflare)
    final pingResult = state.testResultsDisplay['pingGoogle']?['result'] ?? '';
    final latency = _extractLatency(pingResult);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Main Status Card
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: Layout04Theme.glassCard(borderRadius: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withOpacity(0.1),
                        border: Border.all(
                          color: statusColor.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: Layout04Theme.neonGlow(statusColor),
                      ),
                      child: Icon(
                        hasError
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 64,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      hasError ? 'ATENÇÃO NECESSÁRIA' : 'TUDO ONLINE',
                      style: Layout04Theme.heading2.copyWith(
                        color: statusColor,
                        shadows: [
                          Shadow(
                            color: statusColor.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasError
                          ? 'Alguns testes falharam. Verifique os detalhes abaixo.'
                          : 'Sua conexão está estável e operando normalmente.',
                      textAlign: TextAlign.center,
                      style: Layout04Theme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildMetricCard(
                'Download',
                '${state.fastDownloadResultMbps.toStringAsFixed(0)} Mbps',
                Icons.download_rounded,
                Layout04Theme.primaryCyan,
              ),
              _buildMetricCard(
                'Upload',
                '${state.fastUploadResultMbps.toStringAsFixed(0)} Mbps',
                Icons.upload_rounded,
                Layout04Theme.primaryPink,
              ),
              _buildMetricCard(
                'Latência',
                latency,
                Icons.speed_rounded,
                Layout04Theme.neonGreen,
              ),
              _buildMetricCard(
                'Wi-Fi',
                _isWifiOk(state) ? 'Forte' : 'Verificar',
                Icons.wifi_rounded,
                Layout04Theme.neonYellow,
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Actions
          _NeonButton(
            label: 'REINICIAR EQUIPAMENTO',
            icon: Icons.restart_alt_rounded,
            onPressed: _rebootOnu,
            gradient: Layout04Theme.secondaryGradient,
          ),
          const SizedBox(height: 16),
          _NeonButton(
            label: 'REFAZER TESTES',
            icon: Icons.refresh_rounded,
            onPressed: () => _diagnosticoService?.runAllTests(),
            gradient: Layout04Theme.secondaryGradient,
          ),
        ],
      ),
    );
  }

  String _extractLatency(String result) {
    if (result.contains('Latência:')) {
      final parts = result.split('\n');
      for (var part in parts) {
        if (part.contains('Latência:')) {
          return part.replaceAll('Latência:', '').trim();
        }
      }
    }
    return '-- ms';
  }

  bool _isWifiOk(DiagnosticoState state) {
    return state.testResultsDisplay['wifiInfo']?['status'] ==
        TestStatus.success;
  }

  Widget _buildMetricCard(
      dynamic title, dynamic value, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: Layout04Theme.glassCard(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                value.toString(),
                style: Layout04Theme.heading3.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                title.toString(),
                style: Layout04Theme.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusing NeonButton from theme/dashboard
class _NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Gradient? gradient;

  const _NeonButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: Layout04Theme.neonButton(gradient: gradient),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                ],
                Text(label, style: Layout04Theme.buttonText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
