import 'package:flutter/material.dart';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:app_provedor/shared/widgets/app_page.dart';
import 'package:app_provedor/shared/widgets/dashboard_card.dart';
import 'package:app_provedor/core/locator.dart'; // NOVO
import 'services/meu_ip_service.dart';

class MeuIpPage extends StatefulWidget {
  const MeuIpPage({super.key});

  @override
  State<MeuIpPage> createState() => _MeuIpPageState();
}

class _MeuIpPageState extends State<MeuIpPage> {
  late Future<Map<String, dynamic>> _ipFuture;
  final MeuIpService _service = locator<MeuIpService>(); // CORRIGIDO

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
    return FutureBuilder<Map<String, dynamic>>(
      future: _ipFuture,
      builder: (context, snapshot) {
        return AppPage(
          title: 'Meu Endereço IP',
          isLoading: snapshot.connectionState == ConnectionState.waiting,
          error: snapshot.hasError ? _formatErrorMessage(snapshot.error) : null,
          onRetry: _retry,
          body: snapshot.hasData
              ? _buildIpInfoCard(context, snapshot.data!)
              : const SizedBox.shrink(),
        );
      },
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
              FaIcon(FontAwesomeIcons.networkWired, size: 32, color: textTheme.bodySmall?.color),
              const SizedBox(height: 16),
              Text("Seu IP Público é:", style: textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(
                ipData['ip'] ?? 'Não encontrado',
                style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const Divider(height: 40),
              _buildInfoRow(context, icon: Icons.location_city, title: "Localização", value: "${ipData['city'] ?? 'N/A'}, ${ipData['region'] ?? 'N/A'}"),
              const SizedBox(height: 12),
              _buildInfoRow(context, icon: Icons.router, title: "Provedor", value: ipData['org'] ?? 'Não encontrado'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String title, required String value}) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, color: textTheme.bodySmall?.color, size: 20),
        const SizedBox(width: 16),
        Text("$title:", style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, textAlign: TextAlign.end, style: textTheme.bodyMedium)),
      ],
    );
  }
}
