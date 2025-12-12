// LAYOUT 04 - AURORA - CONSUMO PAGE
// Design: Unlimited plan display with infinity animation

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import 'aurora_theme.dart';

class ConsumoPage extends StatefulWidget {
  const ConsumoPage({super.key});

  @override
  State<ConsumoPage> createState() => _ConsumoPageState();
}

class _ConsumoPageState extends State<ConsumoPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final usuario = authService.usuario;

    // Extract speed from plan name
    String speedValue = '100';
    String planName = usuario?.plano ?? 'Plano Fibra';
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(planName);
    if (match != null) speedValue = match.group(1)!;

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: ShaderMask(
            shaderCallback: (bounds) =>
                AuroraColors.primaryGradient.createShader(bounds),
            child: const Text('Consumo',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: RefreshIndicator(
          color: AuroraColors.neonCyan,
          backgroundColor: AuroraColors.surface,
          onRefresh: () async =>
              await Future.delayed(const Duration(milliseconds: 500)),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Infinity Card
              _buildInfinityCard(planName),

              const SizedBox(height: 24),

              // Speed Cards
              Row(
                children: [
                  Expanded(
                      child: _buildSpeedCard('Download', speedValue,
                          Icons.arrow_downward, AuroraColors.neonCyan)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildSpeedCard('Upload', speedValue,
                          Icons.arrow_upward, AuroraColors.neonPurple)),
                ],
              ),

              const SizedBox(height: 24),

              // Features List
              _buildFeaturesCard(),

              const SizedBox(height: 24),

              // Connection Quality
              _buildConnectionQuality(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfinityCard(String planName) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      glowColor: AuroraColors.neonCyan,
      child: Column(
        children: [
          // Animated Infinity Symbol
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring
                        Transform.rotate(
                          angle: _rotateController.value * 2 * 3.14159,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  AuroraColors.neonCyan.withOpacity(0),
                                  AuroraColors.neonCyan.withOpacity(0.5),
                                  AuroraColors.neonPurple.withOpacity(0.5),
                                  AuroraColors.neonPink.withOpacity(0.5),
                                  AuroraColors.neonCyan.withOpacity(0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Inner circle
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AuroraColors.neonCyan.withOpacity(0.3),
                                AuroraColors.neonPurple.withOpacity(0.3),
                              ],
                            ),
                            border: Border.all(
                              color: AuroraColors.neonCyan.withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AuroraColors.neonCyan.withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.all_inclusive,
                            size: 70,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 32),

          // Title
          ShaderMask(
            shaderCallback: (bounds) =>
                AuroraColors.primaryGradient.createShader(bounds),
            child: const Text(
              'ILIMITADO',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 8,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Navegue sem limites!',
            style: TextStyle(
              fontSize: 16,
              color: AuroraColors.textSecondary,
            ),
          ),

          const SizedBox(height: 20),

          // Plan Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AuroraColors.neonCyan.withOpacity(0.2),
                  AuroraColors.neonPurple.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AuroraColors.glassBorder),
            ),
            child: Text(
              planName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AuroraColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedCard(
      String label, String speed, IconData icon, Color color) {
    return GlassCard(
      glowColor: color,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: -2),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                speed,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AuroraColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Mbps',
                style: TextStyle(
                  fontSize: 16,
                  color: AuroraColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AuroraColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard() {
    final features = [
      {
        'icon': Icons.all_inclusive,
        'text': 'Internet ilimitada',
        'color': AuroraColors.neonCyan
      },
      {
        'icon': Icons.bolt,
        'text': 'Velocidade garantida',
        'color': AuroraColors.warning
      },
      {
        'icon': Icons.router,
        'text': 'Wi-Fi de alta qualidade',
        'color': AuroraColors.neonPurple
      },
      {
        'icon': Icons.security,
        'text': 'Conexão segura',
        'color': AuroraColors.success
      },
    ];

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.star, color: AuroraColors.warning),
                const SizedBox(width: 12),
                const Text(
                  'Benefícios do Plano',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AuroraColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...features.map((f) => _buildFeatureItem(
                f['icon'] as IconData,
                f['text'] as String,
                f['color'] as Color,
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AuroraColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionQuality() {
    return GlassCard(
      glowColor: AuroraColors.success,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AuroraColors.success.withOpacity(0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AuroraColors.success.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: -2),
              ],
            ),
            child: const Icon(Icons.signal_wifi_4_bar,
                color: AuroraColors.success, size: 32),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conexão Excelente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AuroraColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Fibra Óptica • Sem fidelidade',
                  style: TextStyle(
                    fontSize: 14,
                    color: AuroraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
