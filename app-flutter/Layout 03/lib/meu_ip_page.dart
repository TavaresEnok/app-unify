import 'package:flutter/material.dart';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layout01/core/locator.dart';
import 'package:layout01/shared/theme/app_colors.dart';
import 'services/meu_ip_service.dart';

class MeuIpPage extends StatefulWidget {
  const MeuIpPage({super.key});

  @override
  State<MeuIpPage> createState() => _MeuIpPageState();
}

class _MeuIpPageState extends State<MeuIpPage> {
  late Future<Map<String, dynamic>> _ipFuture;
  final MeuIpService _service = locator<MeuIpService>();

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Meu IP', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _ipFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error.withOpacity(0.8)),
                    const SizedBox(height: 16),
                    Text("Erro ao carregar IP", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(_formatErrorMessage(snapshot.error), textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textSecondary)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Tentar Novamente"),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                    )
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
      return 'O servidor demorou muito para responder.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  Widget _buildIpInfoCard(BuildContext context, Map<String, dynamic> ipData) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                child: const FaIcon(FontAwesomeIcons.globe, size: 40, color: AppColors.primaryBlue),
              ),
              const SizedBox(height: 24),
              Text("Seu IP Público", style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                ipData['ip'] ?? 'Não encontrado',
                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Divider(),
              ),
              _buildInfoRow(icon: Icons.location_on_outlined, title: "Cidade", value: "${ipData['city'] ?? 'N/A'}"),
              const SizedBox(height: 16),
              _buildInfoRow(icon: Icons.map_outlined, title: "Estado", value: "${ipData['region'] ?? 'N/A'}"),
              const SizedBox(height: 16),
              _buildInfoRow(icon: Icons.business_outlined, title: "Provedor", value: ipData['org'] ?? 'Desconhecido'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String title, required String value}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
