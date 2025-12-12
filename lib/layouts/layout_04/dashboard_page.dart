// LAYOUT 04 - AURORA - DASHBOARD PAGE
// Design: Futuristic glassmorphic dashboard with animated stats

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/configuration_provider.dart';
import 'aurora_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final configProvider = context.watch<ConfigurationProvider>();
    final usuario = authService.usuario;
    final config = configProvider.providerConfig;

    return AuroraBackground(
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(context, usuario?.nome ?? 'Cliente',
                    config?.name ?? 'Provedor'),
              ),

              // Stats Grid
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildAnimatedCard(
                        0,
                        NeonStatCard(
                          title: 'Seu Plano',
                          value: usuario?.plano ?? '100 Mega',
                          subtitle: '∞ Ilimitado',
                          icon: Icons.speed,
                          accentColor: AuroraColors.neonCyan,
                        )),
                    _buildAnimatedCard(
                        1,
                        NeonStatCard(
                          title: 'Conexão',
                          value: 'Online',
                          subtitle: 'Fibra Óptica',
                          icon: Icons.wifi,
                          accentColor: AuroraColors.success,
                        )),
                    _buildAnimatedCard(
                        2,
                        NeonStatCard(
                          title: 'Faturas',
                          value: 'Em dia',
                          subtitle: 'Nenhuma pendente',
                          icon: Icons.receipt_long,
                          accentColor: AuroraColors.neonPurple,
                        )),
                    _buildAnimatedCard(
                        3,
                        NeonStatCard(
                          title: 'Suporte',
                          value: '24/7',
                          subtitle: 'Atendimento',
                          icon: Icons.headset_mic,
                          accentColor: AuroraColors.neonPink,
                        )),
                  ]),
                ),
              ),

              // Quick Actions Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ações Rápidas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AuroraColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildQuickActionsRow(context),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Recent Activity
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atividade Recente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AuroraColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildActivityList(),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, String userName, String providerName) {
    final firstName = userName.split(' ').first;
    final hour = DateTime.now().hour;
    String greeting = 'Bom dia';
    if (hour >= 12 && hour < 18) greeting = 'Boa tarde';
    if (hour >= 18) greeting = 'Boa noite';

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: TextStyle(
                      fontSize: 16,
                      color: AuroraColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AuroraColors.primaryGradient.createShader(bounds),
                    child: Text(
                      firstName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              // Notification & Profile
              Row(
                children: [
                  _buildIconButton(Icons.notifications_outlined, () {}),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AuroraColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AuroraColors.neonCyan.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Speed Indicator Card
          GlassCard(
            padding: const EdgeInsets.all(20),
            glowColor: AuroraColors.neonCyan,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AuroraColors.success,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AuroraColors.success.withOpacity(0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Conexão Estável',
                            style: TextStyle(
                              color: AuroraColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildSpeedIndicator(
                              '↓', '98.5', 'Mbps', AuroraColors.neonCyan),
                          const SizedBox(width: 24),
                          _buildSpeedIndicator(
                              '↑', '98.2', 'Mbps', AuroraColors.neonPurple),
                          const SizedBox(width: 24),
                          _buildSpeedIndicator(
                              '◉', '12', 'ms', AuroraColors.success),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AuroraColors.neonCyan.withOpacity(0.3),
                        AuroraColors.neonCyan.withOpacity(0.0),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.signal_wifi_4_bar,
                    color: AuroraColors.neonCyan,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedIndicator(
      String arrow, String value, String unit, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          arrow,
          style: TextStyle(color: color, fontSize: 16),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AuroraColors.textPrimary,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                color: AuroraColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AuroraColors.glassWhite,
          shape: BoxShape.circle,
          border: Border.all(color: AuroraColors.glassBorder),
        ),
        child: Icon(icon, color: AuroraColors.textPrimary, size: 22),
      ),
    );
  }

  Widget _buildAnimatedCard(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, _) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _buildQuickAction(
                'Faturas', Icons.receipt_long, AuroraColors.neonPurple)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildQuickAction(
                'Suporte', Icons.headset_mic, AuroraColors.neonCyan)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildQuickAction(
                'Speed Test', Icons.speed, AuroraColors.neonPink)),
      ],
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        children: [
          NeonIconBadge(icon: icon, color: color, size: 48),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AuroraColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    final activities = [
      {
        'title': 'Fatura paga',
        'time': 'Há 2 dias',
        'icon': Icons.check_circle,
        'color': AuroraColors.success
      },
      {
        'title': 'Speed test realizado',
        'time': 'Há 5 dias',
        'icon': Icons.speed,
        'color': AuroraColors.neonCyan
      },
      {
        'title': 'Login no app',
        'time': 'Há 1 semana',
        'icon': Icons.login,
        'color': AuroraColors.neonPurple
      },
    ];

    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: activities.asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value;
          final isLast = index == activities.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (activity['color'] as Color).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        activity['icon'] as IconData,
                        color: activity['color'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AuroraColors.textPrimary,
                            ),
                          ),
                          Text(
                            activity['time'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: AuroraColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AuroraColors.textMuted,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: AuroraColors.glassBorder, indent: 72),
            ],
          );
        }).toList(),
      ),
    );
  }
}
