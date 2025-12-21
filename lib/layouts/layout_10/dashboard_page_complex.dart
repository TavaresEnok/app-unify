import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../theme.dart';
import 'widgets/glass_card.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/stats_card.dart';
import 'widgets/usage_chart.dart';
import 'widgets/quick_actions.dart';

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

class _Layout10DashboardPageState extends ConsumerState<Layout10DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;
  late AnimationController _cardController;
  late List<Animation<double>> _cardAnimations;
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
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _cardAnimations = List.generate(6, (index) {
      return Tween<double>(
        begin: 0,
        end: 1,
      ).animate(CurvedAnimation(
        parent: _cardController,
        curve: Interval(
          index * 0.1,
          0.5 + index * 0.1,
          curve: Curves.easeOutBack,
        ),
      ));
    });
    
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _cardController.forward();
      }
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardController.dispose();
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
        break;
      case 2: // Suporte
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
      backgroundColor: Layout10Theme.backgroundColor,
      body: Stack(
        children: [
          // Background pattern
          CustomPaint(
            size: Size.infinite,
            painter: DashboardBackgroundPainter(),
          ),
          
          // Main content
          RefreshIndicator(
            onRefresh: widget.onRefresh ?? () async {},
            color: Layout10Theme.accentColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + Layout10Theme.spacingL,
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
                  
                  const SizedBox(height: Layout10Theme.spacingXL),
                  
                  // Stats Cards Grid
                  _buildStatsGrid(),
                  
                  const SizedBox(height: Layout10Theme.spacingXL),
                  
                  // Usage Chart
                  _buildUsageSection(),
                  
                  const SizedBox(height: Layout10Theme.spacingXL),
                  
                  // Quick Actions
                  _buildQuickActions(),
                  
                  const SizedBox(height: Layout10Theme.spacingXXL),
                ],
              ),
            ),
          ),
          
          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Layout10BottomNav(
              currentIndex: _selectedNavIndex,
              onTap: _handleNavTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final cliente = widget.cliente ?? {};
    final plano = widget.plano ?? {};
    final status = widget.conexaoStatus ?? 'offline';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Layout10Theme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          Text(
            'Olá, ${cliente['nome'] ?? 'Usuário'}!',
            style: Layout10Theme.heading1,
          ),
          
          const SizedBox(height: Layout10Theme.spacingS),
          
          // Plan and status
          Row(
            children: [
              Expanded(
                child: GradientCard(
                  padding: const EdgeInsets.all(Layout10Theme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plano Atual',
                        style: Layout10Theme.caption.copyWith(
                          color: Layout10Theme.primaryTextColor.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: Layout10Theme.spacingXS),
                      Text(
                        plano['nome'] ?? 'Plano Básico',
                        style: Layout10Theme.heading3.copyWith(
                          color: Layout10Theme.primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: Layout10Theme.spacingM),
              
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Layout10Theme.spacingM,
                  vertical: Layout10Theme.spacingS,
                ),
                decoration: BoxDecoration(
                  color: status == 'online' 
                      ? Layout10Theme.successColor.withValues(alpha: 0.2)
                      : Layout10Theme.warningColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusXXL),
                  border: Border.all(
                    color: status == 'online' 
                        ? Layout10Theme.successColor.withValues(alpha: 0.5)
                        : Layout10Theme.warningColor.withValues(alpha: 0.5),
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
                            ? Layout10Theme.successColor
                            : Layout10Theme.warningColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: Layout10Theme.spacingS),
                    Text(
                      status == 'online' ? 'Online' : 'Offline',
                      style: Layout10Theme.bodyMedium.copyWith(
                        color: status == 'online' 
                            ? Layout10Theme.successColor
                            : Layout10Theme.warningColor,
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
      padding: const EdgeInsets.symmetric(horizontal: Layout10Theme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo',
            style: Layout10Theme.heading2,
          ),
          
          const SizedBox(height: Layout10Theme.spacingL),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: Layout10Theme.spacingM,
            crossAxisSpacing: Layout10Theme.spacingM,
            childAspectRatio: 1.4,
            children: [
              // Download Speed
              AnimatedBuilder(
                animation: _cardAnimations[0],
                builder: (context, child) {
                  return Transform.scale(
                    scale: _cardAnimations[0].value,
                    child: FadeTransition(
                      opacity: _cardAnimations[0],
                      child: StatsCard(
                        title: 'Download',
                        value: '${widget.velocidades?['download'] ?? '0'} Mbps',
                        icon: Icons.download_rounded,
                        color: Layout10Theme.accentColor,
                        trend: '+12%',
                      ),
                    ),
                  );
                },
              ),
              
              // Upload Speed
              AnimatedBuilder(
                animation: _cardAnimations[1],
                builder: (context, child) {
                  return Transform.scale(
                    scale: _cardAnimations[1].value,
                    child: FadeTransition(
                      opacity: _cardAnimations[1],
                      child: StatsCard(
                        title: 'Upload',
                        value: '${widget.velocidades?['upload'] ?? '0'} Mbps',
                        icon: Icons.upload_rounded,
                        color: Layout10Theme.secondaryColor,
                        trend: '+8%',
                      ),
                    ),
                  );
                },
              ),
              
              // Data Usage
              AnimatedBuilder(
                animation: _cardAnimations[2],
                builder: (context, child) {
                  return Transform.scale(
                    scale: _cardAnimations[2].value,
                    child: FadeTransition(
                      opacity: _cardAnimations[2],
                      child: StatsCard(
                        title: 'Dados Usados',
                        value: '${widget.dadosUso?['usados'] ?? '0'} GB',
                        subtitle: 'de ${widget.dadosUso?['limite'] ?? '100'} GB',
                        icon: Icons.data_usage_rounded,
                        color: Layout10Theme.warningColor,
                        trend: '+25%',
                      ),
                    ),
                  );
                },
              ),
              
              // Next Bill
              AnimatedBuilder(
                animation: _cardAnimations[3],
                builder: (context, child) {
                  return Transform.scale(
                    scale: _cardAnimations[3].value,
                    child: FadeTransition(
                      opacity: _cardAnimations[3],
                      child: StatsCard(
                        title: 'Próxima Fatura',
                        value: 'R\$ ${widget.fatura?['valor'] ?? '0,00'}',
                        subtitle: 'Vence em ${widget.fatura?['vencimento'] ?? '10'} dias',
                        icon: Icons.receipt_long_rounded,
                        color: Layout10Theme.successColor,
                        trend: '0%',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Layout10Theme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uso de Dados',
            style: Layout10Theme.heading2,
          ),
          
          const SizedBox(height: Layout10Theme.spacingL),
          
          AnimatedBuilder(
            animation: _cardAnimations[4],
            builder: (context, child) {
              return Transform.scale(
                scale: _cardAnimations[4].value,
                child: FadeTransition(
                  opacity: _cardAnimations[4],
                  child: UsageChart(
                    dadosUso: widget.dadosUso ?? {},
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Layout10Theme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ações Rápidas',
            style: Layout10Theme.heading2,
          ),
          
          const SizedBox(height: Layout10Theme.spacingL),
          
          AnimatedBuilder(
            animation: _cardAnimations[5],
            builder: (context, child) {
              return Transform.scale(
                scale: _cardAnimations[5].value,
                child: FadeTransition(
                  opacity: _cardAnimations[5],
                  child: QuickActions(
                    onNavigate: widget.onNavigate,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DashboardBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Layout10Theme.accentColor.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;
    
    // Create geometric pattern
    final path = Path();
    final spacing = 100.0;
    
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        path.addOval(
          Rect.fromCircle(
            center: Offset(x + spacing / 2, y + spacing / 2),
            radius: 30,
          ),
        );
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Add gradient overlay
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Layout10Theme.backgroundColor.withValues(alpha: 0.9),
          Layout10Theme.backgroundColor,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      gradientPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
