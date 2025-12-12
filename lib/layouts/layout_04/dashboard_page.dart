import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import 'theme.dart';

class DashboardPage extends StatelessWidget {
  final Function(int) onNavigate;

  const DashboardPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final usuario = authService.usuario;

    return Scaffold(
      extendBody: true, // Allow body behind navbar
      body: Container(
        decoration: const BoxDecoration(
          gradient: Layout04Theme.auroraGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
                left: 20, right: 20, top: 20, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "Olá, ${usuario?.nome.split(' ').first ?? 'Cliente'}",
                            style: Layout04Theme.heading1),
                        const SizedBox(height: 4),
                        Text("Tudo certo com sua conexão",
                            style: Layout04Theme.bodyText
                                .copyWith(color: Layout04Theme.neonGreen)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Layout04Theme.neonCyan, width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: Layout04Theme.neonCyan.withOpacity(0.4),
                              blurRadius: 10),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        child: Text(
                          usuario?.nome.substring(0, 1) ?? "C",
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Status Card (Neon Pulse)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: Layout04Theme.glassDecoration.copyWith(
                      gradient: LinearGradient(
                    colors: [
                      Layout04Theme.neonPurple.withOpacity(0.2),
                      Layout04Theme.neonCyan.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Layout04Theme.neonGreen.withOpacity(0.2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Layout04Theme.neonGreen.withOpacity(0.4),
                                blurRadius: 16),
                          ],
                        ),
                        child: const Icon(Icons.wifi,
                            color: Layout04Theme.neonGreen, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Status da Rede", style: Layout04Theme.label),
                          const SizedBox(height: 4),
                          Text("ONLINE",
                              style: Layout04Theme.heading2
                                  .copyWith(color: Layout04Theme.neonGreen)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Text("Acesso Rápido", style: Layout04Theme.heading2),
                const SizedBox(height: 16),

                // Grid Shortcuts
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: [
                    _buildShortcutCard(
                      icon: Icons.receipt_long_rounded,
                      label: "Segunda Via",
                      color: Layout04Theme.neonCyan,
                      onTap: () => onNavigate(2), // Financeiro
                    ),
                    _buildShortcutCard(
                      icon: Icons.speed_rounded,
                      label: "Diagnóstico",
                      color: Layout04Theme.neonPurple,
                      onTap: () => Navigator.pushNamed(context, '/diagnostico'),
                    ),
                    _buildShortcutCard(
                      icon: Icons.wifi_tethering,
                      label: "Meu Wi-Fi",
                      color: Layout04Theme.neonPink,
                      onTap: () => onNavigate(1), // Wifi
                    ),
                    _buildShortcutCard(
                      icon: Icons.headset_mic_rounded,
                      label: "Suporte",
                      color: Colors.white,
                      onTap: () => onNavigate(3), // Suporte
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Banner / Promo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: Layout04Theme.glassDecoration.copyWith(
                    border: Border.all(
                        color: Layout04Theme.neonPurple.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded, color: Colors.amber, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Plano Premium",
                                style: Layout04Theme.label
                                    .copyWith(color: Colors.amber)),
                            Text("Upgrade disponível",
                                style: Layout04Theme.bodyText
                                    .copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          color: Colors.white54, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: Layout04Theme.glassDecoration,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(label,
                  style: Layout04Theme.bodyText
                      .copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
