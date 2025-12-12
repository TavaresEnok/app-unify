// LAYOUT 04 - AURORA - CONSUMO PAGE
// Design: Clean usage display

import 'package:flutter/material.dart';
import 'aurora_theme.dart';

class ConsumoPage extends StatelessWidget {
  const ConsumoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          pinned: true,
          expandedHeight: 100,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'Consumo',
                    style: TextStyle(
                      color: AuroraColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Unlimited Plan Card
              AuroraCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AuroraColors.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.all_inclusive_rounded,
                        color: AuroraColors.primary,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Plano Ilimitado',
                      style: TextStyle(
                        color: AuroraColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Você possui um plano com dados ilimitados.\nAproveite sua internet sem preocupações!',
                      style: TextStyle(
                        color: AuroraColors.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: AuroraStatCard(
                      title: 'Download',
                      value: '100 Mbps',
                      subtitle: 'Velocidade contratada',
                      icon: Icons.download_rounded,
                      accentColor: AuroraColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AuroraStatCard(
                      title: 'Upload',
                      value: '50 Mbps',
                      subtitle: 'Velocidade contratada',
                      icon: Icons.upload_rounded,
                      accentColor: AuroraColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tips Card
              AuroraCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Dicas de Uso',
                      style: TextStyle(
                        color: AuroraColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _TipItem(
                      icon: Icons.speed_rounded,
                      text: 'Faça um teste de velocidade regularmente',
                    ),
                    _TipItem(
                      icon: Icons.router_rounded,
                      text: 'Mantenha seu roteador em local arejado',
                    ),
                    _TipItem(
                      icon: Icons.wifi_rounded,
                      text: 'Use cabo de rede para maior estabilidade',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AuroraColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: AuroraColors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
