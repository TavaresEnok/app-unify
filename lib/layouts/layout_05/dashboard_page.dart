import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/configuration_provider.dart';
import 'theme.dart';

class DashboardPage extends StatefulWidget {
  final String customerName;
  final String planName;
  final String connectionStatus;
  final double billAmount;
  final DateTime billDueDate;
  final double usedGb;
  final double totalGb;
  final double downloadMbps;
  final double uploadMbps;
  final Function(String) onNavigate;

  const DashboardPage({
    super.key,
    required this.customerName,
    required this.planName,
    required this.connectionStatus,
    required this.billAmount,
    required this.billDueDate,
    required this.usedGb,
    required this.totalGb,
    required this.downloadMbps,
    required this.uploadMbps,
    required this.onNavigate,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.usuario;

    final name = user?.nome ?? widget.customerName;
    final plan = user?.plano ?? widget.planName;
    final status = user?.status ?? widget.connectionStatus;

    return Scaffold(
      backgroundColor: Layout05Theme.background, // Soft Grey
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(name, plan),
              const SizedBox(height: 40),

              // Status & Bill Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connection Status - Neumorphic Card
                  Expanded(flex: 1, child: _buildNeumorphicStatus(status)),
                  const SizedBox(width: 20),
                  // Bill Card - Neumorphic but highlighted
                  Expanded(
                      flex: 1,
                      child: _buildNeumorphicBill(
                          widget.billAmount, widget.billDueDate)),
                ],
              ),

              const SizedBox(height: 24),

              // Connection Speed - Clickable
              GestureDetector(
                onTap: () => widget.onNavigate('speed_test'),
                child: _buildSpeedCard(widget.downloadMbps),
              ),

              const SizedBox(height: 32),

              Text('Ações Rápidas', style: Layout05Theme.label),
              const SizedBox(height: 16),

              // Shortcuts Grid
              LayoutBuilder(builder: (ctx, constraints) {
                final width = (constraints.maxWidth - 20) / 2;
                return Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    SizedBox(
                        width: width,
                        child: _buildNeuShortcut(Icons.wifi_rounded,
                            'Meu Wi-Fi', () => widget.onNavigate('wifi'))),
                    SizedBox(
                        width: width,
                        child: _buildNeuShortcut(Icons.receipt_long_rounded,
                            'Faturas', () => widget.onNavigate('invoices'))),
                    SizedBox(
                        width: width,
                        child: _buildNeuShortcut(
                            Icons.speed_rounded, // Changed Icon
                            'Diagnóstico', // Changed Title
                            () => widget.onNavigate(
                                'network_diagnostic'))), // Changed Route
                    SizedBox(
                        width: width,
                        child: _buildNeuShortcut(Icons.support_agent_rounded,
                            'Suporte', () => widget.onNavigate('support'))),
                  ],
                );
              }),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String plan) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá,',
                style: Layout05Theme.heading2.copyWith(
                    color: Layout05Theme.textGrey,
                    fontWeight: FontWeight.normal)),
            Text(name.split(' ').first,
                style: Layout05Theme.heading1
                    .copyWith(color: Layout05Theme.textDark)),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Layout05Theme.background,
            boxShadow: [
              const BoxShadow(
                  color: Colors.white, offset: Offset(-5, -5), blurRadius: 10),
              BoxShadow(
                  color: const Color(0xFFA3B1C6).withOpacity(0.4),
                  offset: const Offset(5, 5),
                  blurRadius: 10),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Layout05Theme.primary, // Pop of color
            ),
            child:
                const Icon(Icons.person_rounded, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildNeumorphicStatus(String status) {
    final isOnline =
        status.toLowerCase() == 'ativo' || status.toLowerCase() == 'conectado';
    final color = isOnline ? Layout05Theme.success : Layout05Theme.error;

    return Container(
      height: 150,
      padding: const EdgeInsets.all(20),
      decoration: Layout05Theme.neumorphicDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Layout05Theme.background,
              boxShadow: const [
                BoxShadow(
                    color: Colors.white, offset: Offset(-2, -2), blurRadius: 4),
                BoxShadow(
                    color: Color(0x22A3B1C6),
                    offset: Offset(2, 2),
                    blurRadius: 4),
              ],
            ),
            child: Icon(isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status', style: Layout05Theme.label),
              const SizedBox(height: 4),
              Text(isOnline ? 'Online' : 'Offline',
                  style: Layout05Theme.heading2
                      .copyWith(fontSize: 18, color: color)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildNeumorphicBill(double amount, DateTime dueDate) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(20),
      decoration: Layout05Theme.neumorphicDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Text('Vence ${dueDate.day}/${dueDate.month}',
                style: Layout05Theme.label
                    .copyWith(fontSize: 11, color: Layout05Theme.primary)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fatura', style: Layout05Theme.label),
              const SizedBox(height: 4),
              Text('R\$ ${amount.toStringAsFixed(0)}',
                  style: Layout05Theme.heading2
                      .copyWith(color: Layout05Theme.textDark, fontSize: 22)),
              Text(',${amount.toStringAsFixed(2).split('.')[1]}',
                  style: Layout05Theme.heading2
                      .copyWith(color: Layout05Theme.textGrey, fontSize: 16)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSpeedCard(double speed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: Layout05Theme.neumorphicDecoration,
      child: Row(
        children: [
          Icon(Icons.speed_rounded, color: Layout05Theme.primary, size: 36),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sua Velocidade', style: Layout05Theme.label),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${speed.toInt()}',
                        style: Layout05Theme.heading1
                            .copyWith(color: Layout05Theme.textDark)),
                    const SizedBox(width: 4),
                    Text('MEGA',
                        style: Layout05Theme.label
                            .copyWith(color: Layout05Theme.primary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeuShortcut(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration:
            Layout05Theme.flatDecoration, // Slightly flatter for buttons
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Layout05Theme.textGrey, size: 28),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                    color: Layout05Theme.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
