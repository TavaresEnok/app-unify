// LAYOUT 04 - AURORA - CONTRATO PAGE (FIXED)
// Design: Contract info with glassmorphic cards

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/configuration_provider.dart';
import 'aurora_theme.dart';

class ContratoPage extends StatelessWidget {
  const ContratoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final configProvider = context.watch<ConfigurationProvider>();
    final usuario = authService.usuario;
    final config = configProvider.providerConfig;

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: ShaderMask(
            shaderCallback: (bounds) =>
                AuroraColors.primaryGradient.createShader(bounds),
            child: const Text('Contrato',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Contract Status
            GlassCard(
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
                            blurRadius: 20),
                      ],
                    ),
                    child: const Icon(Icons.verified,
                        color: AuroraColors.success, size: 32),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contrato Ativo',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AuroraColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${usuario?.status ?? "---"}',
                          style: TextStyle(color: AuroraColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Personal Info
            _buildSectionTitle('Dados Pessoais'),
            const SizedBox(height: 12),

            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildInfoRow(Icons.person, 'Nome', usuario?.nome ?? '---'),
                  _buildDivider(),
                  _buildInfoRow(
                      Icons.badge, 'CPF/CNPJ', usuario?.cpfCnpj ?? '---'),
                  _buildDivider(),
                  _buildInfoRow(Icons.email, 'E-mail', usuario?.email ?? '---'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Plan Info
            _buildSectionTitle('Plano Contratado'),
            const SizedBox(height: 12),

            GlassCard(
              glowColor: AuroraColors.neonPurple,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        NeonIconBadge(
                            icon: Icons.speed,
                            color: AuroraColors.neonPurple,
                            size: 56),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => AuroraColors
                                    .primaryGradient
                                    .createShader(bounds),
                                child: Text(
                                  usuario?.plano ?? 'Plano Fibra',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.all_inclusive,
                                      color: AuroraColors.neonCyan, size: 16),
                                  const SizedBox(width: 4),
                                  const Text('Ilimitado',
                                      style: TextStyle(
                                          color: AuroraColors.neonCyan,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDivider(),
                  _buildInfoRow(Icons.cable, 'Tecnologia', 'Fibra Óptica'),
                  _buildDivider(),
                  _buildInfoRow(
                      Icons.lock_open, 'Fidelidade', 'Sem fidelidade'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Provider Info
            _buildSectionTitle('Provedor'),
            const SizedBox(height: 12),

            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildInfoRow(
                      Icons.business, 'Empresa', config?.name ?? '---'),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AuroraColors.textPrimary),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: AuroraColors.neonCyan, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(color: AuroraColors.textMuted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: AuroraColors.textPrimary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: AuroraColors.glassBorder);
  }
}
