import 'package:flutter/material.dart';
import '../theme.dart';

class QuickActions extends StatelessWidget {
  final Function(String)? onNavigate;

  const QuickActions({
    super.key,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Action buttons grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: Layout10Theme.spacingM,
          crossAxisSpacing: Layout10Theme.spacingM,
          childAspectRatio: 1.5,
          children: [
            _ActionButton(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              color: Layout10Theme.accentColor,
              onTap: () => onNavigate?.call('dashboard'),
            ),
            _ActionButton(
              icon: Icons.receipt_long_rounded,
              label: 'Ver Faturas',
              color: Layout10Theme.accentColor,
              onTap: () => onNavigate?.call('faturas'),
            ),
            _ActionButton(
              icon: Icons.speed_rounded,
              label: 'Teste de Velocidade',
              color: Layout10Theme.secondaryColor,
              onTap: () => onNavigate?.call('speed_test'),
            ),
            _ActionButton(
              icon: Icons.support_agent_rounded,
              label: 'Suporte',
              color: Layout10Theme.warningColor,
              onTap: () => onNavigate?.call('suporte'),
            ),
            _ActionButton(
              icon: Icons.settings_rounded,
              label: 'Configurações',
              color: Layout10Theme.primaryColor,
              onTap: () => onNavigate?.call('configuracoes'),
            ),
          ],
        ),
        
        const SizedBox(height: Layout10Theme.spacingL),
        
        // Emergency contact button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Layout10Theme.spacingM),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Layout10Theme.errorColor.withValues(alpha: 0.2),
                Layout10Theme.errorColor.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusL),
            border: Border.all(
              color: Layout10Theme.errorColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Layout10Theme.spacingS),
                decoration: BoxDecoration(
                  color: Layout10Theme.errorColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusM),
                ),
                child: Icon(
                  Icons.phone_in_talk_rounded,
                  color: Layout10Theme.errorColor,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: Layout10Theme.spacingM),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergência',
                      style: Layout10Theme.bodyMedium.copyWith(
                        color: Layout10Theme.primaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Ligue para suporte 24h',
                      style: Layout10Theme.caption.copyWith(
                        color: Layout10Theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Icon(Icons.arrow_forward_ios_rounded),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: Layout10Theme.surfaceColor.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusL),
              border: Border.all(
                color: widget.color.withValues(alpha: _glowAnimation.value),
                width: 2,
              ),
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
            ),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(Layout10Theme.spacingM),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusM),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: 28,
                    ),
                  ),
                  
                  const SizedBox(height: Layout10Theme.spacingM),
                  
                  Text(
                    widget.label,
                    style: Layout10Theme.bodyMedium.copyWith(
                      color: Layout10Theme.primaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class FloatingQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const FloatingQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Layout10Theme.spacingL,
          vertical: Layout10Theme.spacingM,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color,
              color.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusXXL),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Layout10Theme.primaryTextColor,
              size: 20,
            ),
            const SizedBox(width: Layout10Theme.spacingS),
            Text(
              label,
              style: Layout10Theme.bodyMedium.copyWith(
                color: Layout10Theme.primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
