// LAYOUT 04 - AURORA - MAIN NAVIGATION WRAPPER
// Design: Clean bottom navigation with gradient background

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import 'aurora_theme.dart';
import 'dashboard_page.dart';
import 'financeiro_page.dart';
import 'suporte_page.dart';
import 'consumo_page.dart';
import 'diagnostico_page.dart';
import 'contrato_page.dart';
import 'faq_page.dart';
import 'my_ip_page.dart';
import 'speed_test_page.dart';

class AuroraMainPage extends StatefulWidget {
  final String initialPage;

  const AuroraMainPage({super.key, this.initialPage = 'dashboard'});

  @override
  State<AuroraMainPage> createState() => _AuroraMainPageState();
}

class _AuroraMainPageState extends State<AuroraMainPage> {
  late String _currentPage;
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
  }

  void _navigateTo(String pageId) {
    setState(() {
      _currentPage = pageId;
      // Update bottom nav index
      switch (pageId) {
        case 'dashboard':
          _bottomNavIndex = 0;
          break;
        case 'financeiro':
          _bottomNavIndex = 1;
          break;
        case 'diagnostico':
          _bottomNavIndex = 2;
          break;
        case 'suporte':
          _bottomNavIndex = 3;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuroraScaffold(
      body: _buildCurrentPage(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case 'dashboard':
        return const DashboardPage();
      case 'financeiro':
        return const FinanceiroPage();
      case 'suporte':
        return const SuportePage();
      case 'diagnostico':
        return const DiagnosticoPage();
      case 'consumo':
        return const ConsumoPage();
      case 'contrato':
        return const ContratoPage();
      case 'faq':
        return const FaqPage();
      case 'meu_ip':
        return const MyIpPage();
      case 'speed_test':
        return const SpeedTestPage();
      default:
        return const DashboardPage();
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AuroraColors.surface,
        border: Border(
          top: BorderSide(color: AuroraColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: _bottomNavIndex == 0,
                onTap: () => _navigateTo('dashboard'),
              ),
              _NavItem(
                icon: Icons.receipt_long_rounded,
                label: 'Faturas',
                isSelected: _bottomNavIndex == 1,
                onTap: () => _navigateTo('financeiro'),
              ),
              _NavItem(
                icon: Icons.router_rounded,
                label: 'ONU',
                isSelected: _bottomNavIndex == 2,
                onTap: () => _navigateTo('diagnostico'),
              ),
              _NavItem(
                icon: Icons.headset_mic_rounded,
                label: 'Suporte',
                isSelected: _bottomNavIndex == 3,
                onTap: () => _navigateTo('suporte'),
              ),
              _MoreButton(onNavigate: _navigateTo, onLogout: _handleLogout),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sair',
            style: TextStyle(color: AuroraColors.textPrimary)),
        content: const Text('Deseja realmente sair?',
            style: TextStyle(color: AuroraColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AuroraColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthService>().logout();
            },
            child:
                const Text('Sair', style: TextStyle(color: AuroraColors.error)),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AuroraColors.primary : AuroraColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final void Function(String) onNavigate;
  final VoidCallback onLogout;

  const _MoreButton({required this.onNavigate, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, -220),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AuroraColors.surface,
      onSelected: (value) {
        if (value == 'logout') {
          onLogout();
        } else {
          onNavigate(value);
        }
      },
      itemBuilder: (context) => [
        _buildMenuItem('consumo', Icons.data_usage_rounded, 'Consumo'),
        _buildMenuItem('speed_test', Icons.speed_rounded, 'Speed Test'),
        _buildMenuItem('meu_ip', Icons.public_rounded, 'Meu IP'),
        _buildMenuItem('faq', Icons.help_outline_rounded, 'FAQ'),
        _buildMenuItem('contrato', Icons.description_rounded, 'Contrato'),
        const PopupMenuDivider(),
        _buildMenuItem('logout', Icons.logout_rounded, 'Sair',
            isDestructive: true),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.more_horiz_rounded,
                color: AuroraColors.textMuted, size: 24),
            SizedBox(height: 4),
            Text(
              'Mais',
              style: TextStyle(color: AuroraColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
      String value, IconData icon, String label,
      {bool isDestructive = false}) {
    final color = isDestructive ? AuroraColors.error : AuroraColors.textPrimary;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
