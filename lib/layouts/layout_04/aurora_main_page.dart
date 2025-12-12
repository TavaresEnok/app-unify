// LAYOUT 04 - AURORA - MAIN NAVIGATION WRAPPER
// Provides bottom navigation for Aurora layout pages

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

  final List<Map<String, dynamic>> _bottomNavItems = [
    {'id': 'dashboard', 'icon': Icons.home_rounded, 'label': 'Home'},
    {
      'id': 'financeiro',
      'icon': Icons.receipt_long_rounded,
      'label': 'Faturas'
    },
    {'id': 'diagnostico', 'icon': Icons.router_rounded, 'label': 'ONU'},
    {'id': 'suporte', 'icon': Icons.headset_mic_rounded, 'label': 'Suporte'},
    {'id': 'more', 'icon': Icons.menu_rounded, 'label': 'Mais'},
  ];

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
  }

  void _navigateTo(String pageId) {
    setState(() {
      _currentPage = pageId;
      // Update bottom nav index if it's a main page
      final idx = _bottomNavItems.indexWhere((item) => item['id'] == pageId);
      if (idx >= 0 && idx < 4) {
        _bottomNavIndex = idx;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuroraColors.background,
      body: _buildCurrentPage(),
      bottomNavigationBar: _buildBottomNavBar(),
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

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AuroraColors.surface,
        border: Border(
          top: BorderSide(color: AuroraColors.glassBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_bottomNavItems.length, (index) {
              final item = _bottomNavItems[index];
              final isSelected = _bottomNavIndex == index;

              if (item['id'] == 'more') {
                return _buildMoreButton();
              }

              return _buildNavItem(
                icon: item['icon'],
                label: item['label'],
                isSelected: isSelected,
                onTap: () {
                  setState(() => _bottomNavIndex = index);
                  _navigateTo(item['id']);
                },
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? AuroraColors.neonCyan : AuroraColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AuroraColors.neonCyan.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
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

  Widget _buildMoreButton() {
    return PopupMenuButton<String>(
      offset: const Offset(0, -200),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AuroraColors.surface,
      onSelected: (value) {
        if (value == 'logout') {
          _handleLogout();
        } else {
          _navigateTo(value);
        }
      },
      itemBuilder: (context) => [
        _buildPopupItem('consumo', Icons.data_usage_rounded, 'Consumo'),
        _buildPopupItem('speed_test', Icons.speed_rounded, 'Speed Test'),
        _buildPopupItem('meu_ip', Icons.language_rounded, 'Meu IP'),
        _buildPopupItem('faq', Icons.help_outline_rounded, 'FAQ'),
        _buildPopupItem('contrato', Icons.description_rounded, 'Contrato'),
        const PopupMenuDivider(),
        _buildPopupItem('logout', Icons.logout_rounded, 'Sair',
            isDestructive: true),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_rounded, color: AuroraColors.textMuted, size: 24),
            const SizedBox(height: 4),
            Text(
              'Mais',
              style: TextStyle(
                color: AuroraColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
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

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sair',
            style: TextStyle(color: AuroraColors.textPrimary)),
        content: const Text('Deseja realmente sair?',
            style: TextStyle(color: AuroraColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: AuroraColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthService>().logout();
            },
            child: Text('Sair', style: TextStyle(color: AuroraColors.error)),
          ),
        ],
      ),
    );
  }
}
