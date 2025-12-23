import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Simple theme constants for Layout 10
class _Layout10Colors {
  static const Color backgroundColor = Color(0xFF0A0F1C);
  static const Color surfaceColor = Color(0xFF0D1B2A);
  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color secondaryColor = Color(0xFF2E7D32);
  static const Color accentColor = Color(0xFF00BCD4);
  static const Color primaryTextColor = Color(0xFFFFFFFF);
  static const Color secondaryTextColor = Color(0xFFB0BEC5);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE91E63);
}

class _Layout10Spacing {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class _Layout10BorderRadius {
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
}

class _Layout10TextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: _Layout10Colors.primaryTextColor,
    letterSpacing: -0.5,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: _Layout10Colors.primaryTextColor,
    letterSpacing: -0.25,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: _Layout10Colors.primaryTextColor,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: _Layout10Colors.primaryTextColor,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _Layout10Colors.secondaryTextColor,
    height: 1.4,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: _Layout10Colors.secondaryTextColor,
  );
}

class Layout10DashboardPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? cliente;
  final Map<String, dynamic>? plano;
  final String? conexaoStatus;
  final Map<String, dynamic>? fatura;
  final Map<String, dynamic>? dadosUso;
  final Map<String, dynamic>? velocidades;
  final Function(String)? onNavigate;
  final Future<void> Function()? onRefresh;

  const Layout10DashboardPage({
    super.key,
    this.cliente,
    this.plano,
    this.conexaoStatus,
    this.fatura,
    this.dadosUso,
    this.velocidades,
    this.onNavigate,
    this.onRefresh,
  });

  @override
  ConsumerState<Layout10DashboardPage> createState() => _Layout10DashboardPageState();
}

class _Layout10DashboardPageState extends ConsumerState<Layout10DashboardPage> {
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _headerAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutBack,
    ));
    
    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  void _handleNavTap(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
    
    switch (index) {
      case 0: // Dashboard
        // Already on dashboard
        break;
      case 1: // Faturas
        widget.onNavigate?.call('faturas');
        break.
break;
 . . .       case inate (2): // Suporte
        widget.onNavigate?.call('suporte');
        break;
      case 3: // Perfil
        widget.onNavigate?.call('perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Layout10Colors.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _Layout10Colors.backgroundColor,
              _Layout10Colors.primaryColor.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: widget.onRefresh ?? () async {},
          color: _Layout10Colors.accentColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + _Layout10Spacing.l,
              bottom: 120, // Space for bottom nav
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                AnimatedBuilder(
                  animation: _headerAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - _headerAnimation.value)),
                      child: FadeTransition(
                        opacity: _headerAnimation,
                        child: _buildHeader(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: _Layout10Spacing.xl),
                
                // Stats Cards Grid
                _buildStatsGrid(),
                
                const SizedBox(height: _Layout10Spacing.xl),
                
                // Usage Chart
                _buildUsageSection(),
                
                const SizedBox(height: _Layout10Spacing.xl),
                
                // Quick Actions
                _buildQuickActions(),
                
                const SizedBox(height: _Layout10Spacing.xxl),
              ],
            ),
          ),
        ),
      ),
      
      // Bottom Navigation
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    final cliente = widget.cliente ?? {};
    final plano = widget.plano ?? {};
    final status = widget.conexaoStatus ?? 'offline';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _Layout10Spacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          Text(
            'Olá, ${cliente['nome'] ?? 'Usuário'}!',
            style: _Layout10TextStyles.heading1,
          ),
          
          const SizedBox(height: _Layout10Spacing.s),
          
          // Plan and status
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(_Layout10Spacing.m),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        _Layout10Colors.primaryColor,
                        _Layout10Colors.secondaryColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(_Layout10BorderRadius.l),
                    boxShadow: [
                      BoxShadow(
                        color: _Layout10Colors.accentColor.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plano Atual',
                        style: _Layout10TextStyles.caption.copyWith(
                          color: _Layout10Colors.primaryTextColor.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: _Layout10Spacing.xs),
                      Text(
                        plano['nome'] ?? 'Plano Básico',
                        style: _Layout10TextStyles.heading3.copyWith(
                          color: _Layout10Colors.primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: _Layout10Spacing.m),
              
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _Layout10Spacing.m,
                  vertical: _Layout10Spacing.s,
                ),
                decoration: BoxDecoration(
                  color: status == 'online' 
                      ? _Layout10Colors.successColor.withValues(alpha: 0.2)
                      : _Layout10Colors.warningColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(_Layout10BorderRadius.xxl),
                  border: Border.all(
                    color: status == 'online' 
                        ? _Layout10Colors.successColor.withValues(alpha: 0.5)
                        : _Layout10Colors.warningColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: status == 'online' 
                            ? _Layout10Colors.successColor
                            : _Layout10Colors.warningColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: _Layout10Spacing.s),
                    Text(
                      status == 'online' ? 'Online' : 'Offline',
                      style: _Layout10TextStyles.bodyMedium.copyWith(
                        color: status == 'online' 
                            ? _Layout10Colors.successColor
                            : _Layout10Colors.warningColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _Layout10Spacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo',
            style: _Layout10TextStyles.heading2,
          ),
          
          const SizedBox(height: _Layout10Spacing.l),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: _Layout10Spacing.m,
            crossAxisSpacing: _Layout10Spacing.m,
            childAspectRatio: 1.4,
            children: [
              // Download Speed
              _buildStatsCard(
                title: 'Download',
                value: '${widget.velocidades?['download'] ?? '0'} Mbps',
                icon: Icons.download_rounded,
                color: _Layout10Colors.accentColor,
                trend: '+12%',
              ),
              
              // Upload Speed
              _buildStatsCard(
                title: 'Upload',
                value: '${widget.velocidades?['upload'] ?? '0'} Mbps',
                icon: Icons.upload_rounded,
                color: _Layout10Colors.secondaryColor,
                trend: '+8%',
              ),
              
              // Data Usage
              _buildStatsCard(
                title: 'Dados Usados',
                value: '${widget.dadosUso?['usados'] ?? '0'} GB',
                subtitle: 'de ${widget.dadosUso?['limite'] ?? '100'} GB',
                icon: Icons.data_usage_rounded,
                color: _Layout10Colors.warningColor,
                trend: '+25%',
              ),
              
              // Next Bill
              _buildStatsCard(
                title: 'Próxima Fatura',
                value: 'R\$ ${widget.fatura?['valor'] ?? '0,00'}',
                subtitle: 'Vence em ${widget.fatura?['vencimento'] ?? '10'} dias',
                icon: Icons.receipt_long_rounded,
                color: _Layout10Colors.successColor,
                trend: '0%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    final isPositive = trend.startsWith('+');
    final trendColor = isPositive ? _Layout10Colors.successColor : _Layout10Colors.errorColor;
    
    return Container(
      padding: const EdgeInsets.all(_Layout10Spacing.m),
      decoration: BoxDecoration(
        color: _Layout10Colors.surfaceColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(_Layout10BorderRadius.l),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and trend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(_Layout10Spacing.s),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(_Layout10BorderRadius.m),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              
              // Trend indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _Layout10Spacing.s,
                  vertical: _Layout10Spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(_Layout10BorderRadius.xxl),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 14,
                      color: trendColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: _Layout10TextStyles.caption.copyWith(
                        color: trendColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: _Layout10Spacing.m),
          
          // Main value
          Text(
            value,
            style: _Layout10TextStyles.heading3.copyWith(
              color: _Layout10Colors.primaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          
          if (subtitle != null) ...[
            const SizedBox(height: _Layout10Spacing.xs),
            Text(
              subtitle!,
              style: _Layout10TextStyles.caption.copyWith(
                color: _Layout10Colors.secondaryTextColor.withValues(alpha: 0.8),
              ),
            ),
          ],
          
          const SizedBox(height: _Layout10Spacing.s),
          
          // Title
          Text(
            title,
            style: _Layout10TextStyles.caption.copyWith(
              color: _Layout10Colors.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageSection() {
    final used = double.tryParse(widget.dadosUso?['usados']?.toString() ?? '0') ?? 0.0;
    final limit = double.tryParse(widget.dadosUso?['limite']?.toString() ?? '100') ?? 100.0;
    final percentage = limit > 0 ? (used / limit) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _Layout10Spacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uso de Dados',
            style: _Layout10TextStyles.heading2,
          ),
          
          const SizedBox(height: _Layout10Spacing.l),
          
          Container(
            padding: const EdgeInsets.all(_Layout10Spacing.l),
            decoration: BoxDecoration(
              color: _Layout10Colors.surfaceColor.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(_Layout10BorderRadius.l),
              border: Border.all(
                color: _getUsageColor(percentage).withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getUsageColor(percentage).withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Consumo Mensal',
                      style: _Layout10TextStyles.heading3.copyWith(
                        color: _Layout10Colors.primaryTextColor,
                      ),
                    ),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _Layout10Spacing.m,
                        vertical: _Layout10Spacing.s,
                      ),
                      decoration: BoxDecoration(
                        color: _getUsageColor(percentage).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(_Layout10BorderRadius.xxl),
                      ),
                      child: Text(
                        '${(percentage * 100).toStringAsFixed(1)}%',
                        style: _Layout10TextStyles.bodyMedium.copyWith(
                          color: _getUsageColor(percentage),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: _Layout10Spacing.l),
                
                // Progress bar
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: _Layout10Colors.surfaceColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(_Layout10BorderRadius.xxl),
                  ),
                  child: Stack(
                    children: [
                      // Background gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _Layout10Colors.surfaceColor,
                              _Layout10Colors.surfaceColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(_Layout10BorderRadius.xxl),
                        ),
                      ),
                      
                      // Progress
                      FractionallySizedBox(
                        widthFactor: percentage.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getUsageColor(percentage),
                                _getUsageColor(percentage).withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(_Layout10BorderRadius.xxl),
                            boxShadow: [
                              BoxShadow(
                                color: _getUsageColor(percentage).withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: _Layout10Spacing.l),
                
                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Usados',
                          style: _Layout10TextStyles.caption.copyWith(
                            color: _Layout10Colors.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: _Layout10Spacing.xs),
                        Text(
                          '${used.toStringAsFixed(1)} GB',
                          style: _Layout10TextStyles.bodyLarge.copyWith(
                            color: _Layout10Colors.primaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Limite',
                          style: _Layout10TextStyles.caption.copyWith(
                            color: _Layout10Colors.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: _Layout10Spacing.xs),
                        Text(
                          '${limit.toStringAsFixed(1)} GB',
                          style: _Layout10TextStyles.bodyLarge.copyWith(
                            color: _Layout10Colors.primaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getUsageColor(double percentage) {
    if (percentage < 0.5) return _Layout10Colors.successColor;
    if (percentage < 0.8) return _Layout10Colors.warningColor;
    return _Layout10Colors.errorColor;
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _Layout10Spacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ações Rápidas',
            style: _Layout10TextStyles.heading2,
          ),
          
          const SizedBox(height: _Layout10Spacing.l),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: _Layout10Spacing.m,
            crossAxisSpacing: _Layout10Spacing.m,
            childAspectRatio: 1.5,
            children: [
              _buildActionButton(
                icon: Icons.receipt_long_rounded,
                label: 'Ver Faturas',
                color: _Layout10Colors.accentColor,
                onTap: () => widget.onNavigate?.call('faturas'),
              ),
              _buildActionButton(
                icon: Icons.speed_rounded,
                label: 'Teste de Velocidade',
                color: _Layout10Colors.secondaryColor,
                onTap: () => widget.onNavigate?.call('speed_test'),
              ),
              _buildActionButton(
                icon: Icons.support_agent_rounded,
                label: 'Suporte',
                color: _Layout10Colors.warningColor,
                onTap: () => widget.onNavigate?.call('suporte'),
              ),
              _buildActionButton(
                icon: Icons.settings_rounded,
                label: 'Configurações',
                color: _Layout10Colors.primaryColor,
                onTap: () => widget.onNavigate?.call('configuracoes'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _Layout10Colors.surfaceColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(_Layout10BorderRadius.l),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(_Layout10Spacing.m),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(_Layout10BorderRadius.m),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            
            const SizedBox(height: _Layout10Spacing.m),
            
            Text(
              label,
              style: _Layout10TextStyles.bodyMedium.copyWith(
                color: _Layout10Colors.primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.all(_Layout10Spacing.l),
      padding: const EdgeInsets.symmetric(
        horizontal: _Layout10Spacing.m,
        vertical: _Layout10Spacing.s,
      ),
      decoration: BoxDecoration(
        color: _Layout10Colors.surfaceColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(_Layout10BorderRadius.xxl),
        border: Border.all(
          color: _Layout10Colors.accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _Layout10Colors.accentColor.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.dashboard_rounded,
            label: 'Início',
            isSelected: _selectedNavIndex == 0,
            onTap: () => _handleNavTap(0),
          ),
          _buildNavItem(
            icon: Icons.receipt_long_rounded,
            label: 'Faturas',
            isSelected: _selectedNavIndex == 1,
            onTap: () => _handleNavTap(1),
          ),
          _buildNavItem(
            icon: Icons.support_agent_rounded,
            label: 'Suporte',
            isSelected: _selectedNavIndex == 2,
            onTap: () => _handleNavTap(2),
          ),
          _buildNavItem(
            icon: Icons.person_rounded,
            label: 'Perfil',
            isSelected: _selectedNavIndex == 3,
            onTap: () => _handleNavTap(3),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: _Layout10Spacing.m,
          vertical: _Layout10Spacing.s,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? _Layout10Colors.accentColor.withValues(alpha: 0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(_Layout10BorderRadius.m),
          border: isSelected
              ? Border.all(
                  color: _Layout10Colors.accentColor.withValues(alpha: 0.8),
                  width: 1,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _Layout10Colors.accentColor.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? _Layout10Colors.primaryTextColor
                  : _Layout10Colors.secondaryTextColor,
            ),
            const SizedBox(height: _Layout10Spacing.xs),
            Text(
              label,
              style: _Layout10TextStyles.caption.copyWith(
                color: isSelected
                    ? _Layout10Colors.primaryTextColor
                    : _Layout10Colors.secondaryTextColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
