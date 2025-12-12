import 'dart:ui';
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
      backgroundColor: Layout05Theme.background,
      body: Stack(
        children: [
          // Background Elements (Glows)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Layout05Theme.primary.withOpacity(0.2),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Layout05Theme.secondary.withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(name, plan),
                  const SizedBox(height: 32),

                  // Grid Layout (Standard Row/Col implementation)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildStatusCard(status)),
                      const SizedBox(width: 16),
                      Expanded(
                          flex: 3,
                          child: _buildBillCard(
                              widget.billAmount, widget.billDueDate)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildConnectionCard(widget.downloadMbps),

                  const SizedBox(height: 16),

                  // Shortcuts Grid using Wrap
                  LayoutBuilder(builder: (ctx, constraints) {
                    final width = (constraints.maxWidth - 16) / 2;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                            width: width,
                            child: _buildShortcut(Icons.wifi, 'Meu Wi-Fi',
                                'Gerenciar', () => widget.onNavigate('wifi'))),
                        SizedBox(
                            width: width,
                            child: _buildShortcut(
                                Icons.receipt_long,
                                'Faturas',
                                'Histórico',
                                () => widget.onNavigate('invoices'))),
                        SizedBox(
                            width: width,
                            child: _buildShortcut(
                                Icons.lock_open,
                                'Desbloqueio',
                                'Confiança',
                                () => widget.onNavigate('invoices'))),
                        SizedBox(
                            width: width,
                            child: _buildShortcut(
                                Icons.support_agent,
                                'Suporte',
                                'Ajuda 24h',
                                () => widget.onNavigate('support'))),
                      ],
                    );
                  }),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
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
            Text('Olá, ${name.split(' ').first}',
                style: Layout05Theme.heading1),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Layout05Theme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(plan.toUpperCase(),
                      style: const TextStyle(
                          color: Layout05Theme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Layout05Theme.primary, width: 2),
            color: Layout05Theme.surface,
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 30),
        ),
      ],
    );
  }

  Widget _buildStatusCard(String status) {
    final isOnline =
        status.toLowerCase() == 'ativo' || status.toLowerCase() == 'conectado';
    final color = isOnline ? Layout05Theme.secondary : Layout05Theme.accent;

    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: Layout05Theme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(isOnline ? Icons.wifi : Icons.wifi_off, color: color, size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status', style: Layout05Theme.label),
              const SizedBox(height: 4),
              Text(isOnline ? 'Online' : 'Offline',
                  style: Layout05Theme.heading2.copyWith(color: color)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBillCard(double amount, DateTime dueDate) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: Layout05Theme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Layout05Theme.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.receipt, color: Colors.white70),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Vence ${dueDate.day}/${dueDate.month}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fatura Atual',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildConnectionCard(double speed) {
    return GestureDetector(
      onTap: () => widget.onNavigate('network_diagnostic'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: Layout05Theme.glassDecoration,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.speed, color: Layout05Theme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Velocidade Contratada', style: Layout05Theme.label),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('${speed.toInt()}',
                          style: Layout05Theme.heading1.copyWith(fontSize: 24)),
                      const SizedBox(width: 4),
                      Text('MEGA',
                          style: Layout05Theme.label
                              .copyWith(color: Layout05Theme.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Layout05Theme.textGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcut(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(16),
        decoration: Layout05Theme.solidCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Layout05Theme.textWhite, size: 28),
            const Spacer(),
            Text(title,
                style: const TextStyle(
                    color: Layout05Theme.textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text(subtitle,
                style: const TextStyle(
                    color: Layout05Theme.textGrey, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
