import 'package:flutter/material.dart';
import 'dart:async';

import '../../core/services/meu_ip_service.dart';
import '../../core/widgets/dashboard_card.dart';

class MeuIpPage extends StatefulWidget {
  const MeuIpPage({super.key});

  @override
  State<MeuIpPage> createState() => _MeuIpPageState();
}

class _MeuIpPageState extends State<MeuIpPage> {
  late Future<Map<String, dynamic>> _ipFuture;
  final MeuIpService _service = MeuIpService();

  @override
  void initState() {
    super.initState();
    _ipFuture = _service.fetchIpInfo();
  }

  void _retry() {
    setState(() {
      _ipFuture = _service.fetchIpInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Endereço IP'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _ipFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 64, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      _formatErrorMessage(snapshot.error),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasData) {
            return _buildIpInfoCard(context, snapshot.data!);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _formatErrorMessage(Object? error) {
    if (error is TimeoutException) {
      return 'O servidor demorou muito para responder. Por favor, tente novamente.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  Widget _buildIpInfoCard(BuildContext context, Map<String, dynamic> ipData) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: DashboardCard(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language, size: 48, color: primaryColor),
              const SizedBox(height: 16),
              Text("Seu IP Público é:", style: textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(
                ipData['ip'] ?? 'Não encontrado',
                style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const Divider(height: 40),
              _buildInfoRow(context,
                  icon: Icons.location_city,
                  title: "Localização",
                  value:
                      "${ipData['city'] ?? 'N/A'}, ${ipData['region'] ?? 'N/A'}"),
              const SizedBox(height: 12),
              _buildInfoRow(context,
                  icon: Icons.public,
                  title: "País",
                  value: ipData['country'] ?? 'N/A'),
              const SizedBox(height: 12),
              _buildInfoRow(context,
                  icon: Icons.router,
                  title: "Provedor",
                  value: ipData['org'] ?? 'Não encontrado'),
              const SizedBox(height: 12),
              _buildInfoRow(context,
                  icon: Icons.access_time,
                  title: "Fuso Horário",
                  value: ipData['timezone'] ?? 'N/A'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon, required String title, required String value}) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, color: textTheme.bodySmall?.color, size: 20),
        const SizedBox(width: 16),
        Text("$title:",
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(value,
                textAlign: TextAlign.end, style: textTheme.bodyMedium)),
      ],
    );
  }
}
