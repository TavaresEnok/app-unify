// LAYOUT 04 - AURORA - DIAGNOSTICO PAGE

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/onu_wifi_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/configuration_provider.dart';
import 'aurora_theme.dart';

class DiagnosticoPage extends StatefulWidget {
  const DiagnosticoPage({super.key});

  @override
  State<DiagnosticoPage> createState() => _DiagnosticoPageState();
}

class _DiagnosticoPageState extends State<DiagnosticoPage> {
  bool _isLoading = true;
  String? _error;
  OnuData? _onuData;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final configProvider = context.read<ConfigurationProvider>();

      final usuario = authService.usuario;
      final config = configProvider.providerConfig;

      if (usuario == null || config == null) {
        throw Exception('Configuração não disponível');
      }

      final service = OnuWifiService(
        apiUrl: config.apiUrl,
        cpfCnpj: usuario.cpfCnpj,
        sgpParams: {
          'token': config.config.integrations.apiToken,
          'app': config.config.integrations.appName,
          'sgpBaseUrl': config.config.integrations.sgpBaseUrl,
        },
      );

      final data = await service.fetchOnuSignal();
      setState(() {
        _onuData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

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
                    'Diagnóstico ONU',
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
              if (_isLoading)
                const _LoadingState()
              else if (_error != null)
                _ErrorState(error: _error!, onRetry: _fetchData)
              else if (_onuData != null)
                _OnuInfo(onu: _onuData!, onRefresh: _fetchData)
              else
                const _EmptyState(),
            ]),
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(color: AuroraColors.primary),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.error_outline, color: AuroraColors.error, size: 48),
        const SizedBox(height: 16),
        const Text(
          'Erro ao carregar dados',
          style: TextStyle(
              color: AuroraColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          style: const TextStyle(color: AuroraColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AuroraButton(label: 'Tentar novamente', onPressed: onRetry),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SizedBox(height: 40),
        Icon(Icons.router_outlined, color: AuroraColors.textMuted, size: 64),
        SizedBox(height: 16),
        Text(
          'Nenhum dado de ONU disponível',
          style: TextStyle(color: AuroraColors.textSecondary, fontSize: 16),
        ),
      ],
    );
  }
}

class _OnuInfo extends StatelessWidget {
  final OnuData onu;
  final VoidCallback onRefresh;

  const _OnuInfo({required this.onu, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final signalValue = onu.signalRx ?? 0;
    final isGoodSignal = signalValue > -25 && signalValue < 0;

    return Column(
      children: [
        // Status Card
        AuroraCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (isGoodSignal
                          ? AuroraColors.success
                          : AuroraColors.warning)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  onu.isOnline
                      ? Icons.check_circle_rounded
                      : Icons.warning_rounded,
                  color: onu.isOnline
                      ? AuroraColors.success
                      : AuroraColors.warning,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      onu.isOnline ? 'ONU Online' : 'ONU Offline',
                      style: const TextStyle(
                        color: AuroraColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isGoodSignal
                          ? 'Sinal dentro do esperado'
                          : 'Sinal fora do ideal',
                      style: const TextStyle(
                          color: AuroraColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Signal Details
        AuroraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detalhes do Sinal',
                style: TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _InfoRow(
                  label: 'Sinal RX',
                  value: '${onu.signalRx?.toStringAsFixed(2) ?? '-'} dBm',
                  icon: Icons.signal_cellular_alt),
              _InfoRow(
                  label: 'Sinal TX',
                  value: '${onu.signalTx?.toStringAsFixed(2) ?? '-'} dBm',
                  icon: Icons.signal_cellular_alt),
              _InfoRow(label: 'Modelo', value: onu.model, icon: Icons.router),
              _InfoRow(
                  label: 'Status',
                  value: onu.connectionStatus,
                  icon: Icons.power),
              _InfoRow(
                  label: 'OLT',
                  value: onu.oltName ?? 'OLT ${onu.oltId}',
                  icon: Icons.hub,
                  isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Refresh Button
        SizedBox(
          width: double.infinity,
          child: AuroraButton(
            label: 'Atualizar Dados',
            icon: Icons.refresh_rounded,
            onPressed: onRefresh,
            isOutlined: true,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AuroraColors.textMuted, size: 20),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(color: AuroraColors.textSecondary)),
              const Spacer(),
              Flexible(
                child: Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                      color: AuroraColors.textPrimary,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: AuroraColors.border, height: 1),
      ],
    );
  }
}
