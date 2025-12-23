import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final List<Map<String, dynamic>>? menuItems;
  final Future<void> Function()? onRefresh;

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
    this.menuItems,
    this.onRefresh,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentNavIndex = 0;

  // Aurora Glass Color Palette
  static const Color _auroraPurple = Color(0xFF7B3FF2);
  static const Color _auroraBlue = Color(0xFF3F7BF2);
  static const Color _auroraPink = Color(0xFFF23FB7);
  static const Color _auroraGreen = Color(0xFF3FF27B);
  static const Color _glassWhite = Color(0x1AFFFFFF);
  static const Color _glassDark = Color(0xCC121220);
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _textSecondary = Color(0xFF6B6B8A);
  static const Color _textPrimaryDark = Color(0xFFFFFFFF);
  static const Color _textSecondaryDark = Color(0xFFB8B8D0);
  static const Color _success = Color(0xFF3FF27B);
  static const Color _warning = Color(0xFFFFB74D);
  static const Color _error = Color(0xFFFF6B6B);

  @override
  Widget build(BuildContext context) {
    final remainingDays = widget.billDueDate.difference(DateTime.now()).inDays;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121220) : Colors.white,
      body: Stack(
        children: [
          // Aurora Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _auroraPurple,
                    _auroraBlue,
                    _auroraPink,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      isDarkMode ? Colors.black.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Column(
            children: [
              // Main Scrollable Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    if (widget.onRefresh != null) {
                      HapticFeedback.mediumImpact();
                      await widget.onRefresh!();
                    }
                  },
                  color: _auroraPurple,
                  backgroundColor: Colors.white,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(context, isDarkMode),

                        const SizedBox(height: 32),

                        // Balance / Bill Card (Aurora Glass Style)
                        _buildBalanceCard(remainingDays, isDarkMode),

                        const SizedBox(height: 24),

                        // Quick Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQuickAction(Icons.receipt_long_rounded,
                                'Faturas', 'invoices', _auroraPurple, isDarkMode),
                            _buildQuickAction(Icons.speed_rounded, 'Velocidade',
                                'speed_test', _auroraBlue, isDarkMode),
                            _buildQuickAction(Icons.support_agent_rounded,
                                'Suporte', 'support', _auroraPink, isDarkMode),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Data Usage Card
                        _buildDataUsageCard(isDarkMode),

                        const SizedBox(height: 24),

                        // Speed Test Card
                        _buildSpeedTestCard(isDarkMode),

                        const SizedBox(height: 24),

                        // Services Section
                        _buildServicesSection(isDarkMode),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom Navigation
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: _buildBottomNav(isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, ${widget.customerName}',
              style: TextStyle(
                color: isDarkMode ? _textPrimaryDark : _textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.planName,
              style: TextStyle(
                color: isDarkMode ? _textSecondaryDark : _textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _glassWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: isDarkMode ? _textPrimaryDark : _textPrimary,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(int remainingDays, bool isDarkMode) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? _glassDark : _glassWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _auroraPurple.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FATURA ATUAL',
                      style: TextStyle(
                        color: isDarkMode ? _textSecondaryDark.withValues(alpha: 0.8) : _textSecondary.withValues(alpha: 0.8),
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _success.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        widget.connectionStatus.toUpperCase(),
                        style: TextStyle(
                          color: _success,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'R\$ ${widget.billAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isDarkMode ? _textPrimaryDark : _textPrimary,
                    fontSize: 42,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      remainingDays > 5 ? Icons.event_available : Icons.event_busy,
                      size: 16,
                      color: remainingDays > 5 ? _success : _warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Vence em $remainingDays dias',
                      style: TextStyle(
                        color: remainingDays > 5 ? _success : _warning,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, String route, Color color, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onNavigate(route);
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? _glassDark : _glassWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isDarkMode ? _textSecondaryDark : _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataUsageCard(bool isDarkMode) {
    final usagePercent = widget.usedGb / widget.totalGb;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? _glassDark : _glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Uso de Dados',
                style: TextStyle(
                  color: isDarkMode ? _textPrimaryDark : _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${widget.usedGb.toStringAsFixed(1)} GB',
                style: TextStyle(
                  color: usagePercent > 0.8 ? _error : _auroraBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: usagePercent,
              backgroundColor: (isDarkMode ? _textSecondaryDark : _textSecondary).withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                usagePercent > 0.8 ? _error : _auroraBlue,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(usagePercent * 100).toStringAsFixed(0)}% de ${widget.totalGb} GB usados',
            style: TextStyle(
              color: isDarkMode ? _textSecondaryDark : _textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedTestCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? _glassDark : _glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Velocidade da Conexão',
            style: TextStyle(
              color: isDarkMode ? _textPrimaryDark : _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSpeedItem(
                  Icons.download_rounded,
                  'Download',
                  '${widget.downloadMbps} Mbps',
                  _auroraGreen,
                  isDarkMode,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSpeedItem(
                  Icons.upload_rounded,
                  'Upload',
                  '${widget.uploadMbps} Mbps',
                  _auroraPink,
                  isDarkMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedItem(IconData icon, String label, String value, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? _textSecondaryDark : _textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isDarkMode ? _textPrimaryDark : _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Serviços',
          style: TextStyle(
            color: isDarkMode ? _textPrimaryDark : _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildServiceItem(
          Icons.wifi_tethering_rounded,
          'Rede Wi-Fi',
          'Gerenciar sua rede wireless',
          _auroraBlue,
          isDarkMode,
        ),
        const SizedBox(height: 12),
        _buildServiceItem(
          Icons.shield_rounded,
          'Segurança',
          'Proteção e firewall',
          _auroraPurple,
          isDarkMode,
        ),
        const SizedBox(height: 12),
        _buildServiceItem(
          Icons.analytics_rounded,
          'Relatórios',
          'Detalhes de uso e consumo',
          _auroraPink,
          isDarkMode,
        ),
      ],
    );
  }

  Widget _buildServiceItem(IconData icon, String title, String subtitle, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? _glassDark : _glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDarkMode ? _textPrimaryDark : _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDarkMode ? _textSecondaryDark : _textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: isDarkMode ? _textSecondaryDark : _textSecondary,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? _glassDark : _glassWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _auroraPurple.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Início', 0, isDarkMode),
              _buildNavItem(Icons.receipt_long_rounded, 'Faturas', 1, isDarkMode),
              _buildNavItem(Icons.speed_rounded, 'Velocidade', 2, isDarkMode),
              _buildNavItem(Icons.person_rounded, 'Perfil', 3, isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isDarkMode) {
    final isSelected = _currentNavIndex == index;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _currentNavIndex = index;
        });
        
        // Navigation logic
        switch (index) {
          case 0:
            // Home - already on dashboard
            break;
          case 1:
            widget.onNavigate('invoices');
            break;
          case 2:
            widget.onNavigate('speed_test');
            break;
          case 3:
            widget.onNavigate('profile');
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDarkMode ? _auroraPurple.withValues(alpha: 0.3) : _auroraPurple.withValues(alpha: 0.15))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? _auroraPurple 
                  : (isDarkMode ? _textSecondaryDark : _textSecondary),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? _auroraPurple 
                    : (isDarkMode ? _textSecondaryDark : _textSecondary),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}