// LAYOUT 04 - AURORA - CONTRATO PAGE

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/configuration_provider.dart';
import 'aurora_theme.dart';

class ContratoPage extends StatelessWidget {
  const ContratoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthService>().usuario;
    final config = context.watch<ConfigurationProvider>().providerConfig;

    return CustomScrollView(
      slivers: [
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
                    'Meu Contrato',
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
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Status Card
              AuroraCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AuroraColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.verified_rounded,
                          color: AuroraColors.success, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contrato Ativo',
                            style: TextStyle(
                              color: AuroraColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            config?.name ?? 'Provedor',
                            style: const TextStyle(
                                color: AuroraColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Info Card
              AuroraCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dados Pessoais',
                      style: TextStyle(
                        color: AuroraColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Nome', value: usuario?.nome ?? '-'),
                    _InfoRow(label: 'CPF/CNPJ', value: usuario?.cpfCnpj ?? '-'),
                    _InfoRow(
                        label: 'Email',
                        value: usuario?.email ?? '-',
                        isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Plan Card
              AuroraCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seu Plano',
                      style: TextStyle(
                        color: AuroraColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Plano', value: usuario?.plano ?? '-'),
                    _InfoRow(label: 'Status', value: usuario?.status ?? '-'),
                    _InfoRow(
                        label: 'Vencimento',
                        value: 'Dia ${usuario?.vencimentoFatura ?? '-'}',
                        isLast: true),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow(
      {required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(color: AuroraColors.textSecondary)),
              Text(value,
                  style: const TextStyle(
                      color: AuroraColors.textPrimary,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        if (!isLast) Divider(color: AuroraColors.border, height: 1),
      ],
    );
  }
}
