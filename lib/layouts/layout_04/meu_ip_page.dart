import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import '../../core/services/meu_ip_service.dart';
import 'theme.dart';

class MeuIpPage extends StatefulWidget {
  const MeuIpPage({super.key});

  @override
  State<MeuIpPage> createState() => _MeuIpPageState();
}

class _MeuIpPageState extends State<MeuIpPage>
    with SingleTickerProviderStateMixin {
  late MeuIpService _meuIpService;
  bool _isLoading = true;
  Map<String, dynamic>? _ipData;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initService();
    });
  }

  void _initService() {
    _meuIpService = MeuIpService();
    _fetchIpData();
  }

  Future<void> _fetchIpData() async {
    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(seconds: 1)); // Cyber effect used
      final data = await _meuIpService.fetchIpInfo();
      setState(() {
        _ipData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _ipData = {'ip': 'Erro', 'city': 'N/A', 'region': 'N/A', 'org': 'N/A'};
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout04Theme.background,
      appBar: AppBar(
        title: Text('Meu IP', style: Layout04Theme.heading3),
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
          child: _isLoading ? _buildLoading() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Layout04Theme.primaryCyan),
      ),
    );
  }

  Widget _buildContent() {
    final ip = _ipData?['ip'] ?? 'Indisponível';
    final isp = _ipData?['isp'] ?? 'Provedor';
    // final city = _ipData?['city'] ?? ''; // Assuming API might simulate location

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // IP Glass Card
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: Layout04Theme.glassCard(borderRadius: 32),
                  child: Column(
                    children: [
                      FadeTransition(
                        opacity:
                            _pulseController.drive(Tween(begin: 0.6, end: 1.0)),
                        child: Icon(
                          Icons.public_rounded,
                          size: 64,
                          color: Layout04Theme.primaryCyan,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'SEU IP PÚBLICO',
                        style:
                            Layout04Theme.bodySmall.copyWith(letterSpacing: 2),
                      ),
                      const SizedBox(height: 8),
                      // Text with Shader Mask for gradient
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            Layout04Theme.accentGradient.createShader(bounds),
                        child: Text(
                          ip,
                          style: Layout04Theme.heading1.copyWith(
                            fontSize: 36,
                            color: Colors.white, // Color needed for shader mask
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Layout04Theme.primaryPurple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isp,
                          style: Layout04Theme.bodyMedium.copyWith(
                            color: Layout04Theme.primaryPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _NeonButton(
                        label: 'COPIAR IP',
                        icon: Icons.copy_all_rounded,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: ip));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('IP copiado!'),
                              backgroundColor: Layout04Theme.success,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Info text
            Text(
              'Este é o endereço IP que identifica sua conexão na internet.',
              textAlign: TextAlign.center,
              style: Layout04Theme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const _NeonButton({required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: Layout04Theme.neonButton(),
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
