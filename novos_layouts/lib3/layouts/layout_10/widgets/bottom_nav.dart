import 'package:flutter/material.dart';
import '../theme.dart';

class Layout10BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const Layout10BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(Layout10Theme.spacingL),
      padding: const EdgeInsets.symmetric(
        horizontal: Layout10Theme.spacingM,
        vertical: Layout10Theme.spacingS,
      ),
      decoration: BoxDecoration(
        color: Layout10Theme.surfaceColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusXXL),
        border: Border.all(
          color: Layout10Theme.accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Layout10Theme.accentColor.withValues(alpha: 0.2),
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
          _NavItem(
            icon: Icons.dashboard_rounded,
            label: 'Início',
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.receipt_long_rounded,
            label: 'Faturas',
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.support_agent_rounded,
            label: 'Suporte',
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: 'Perfil',
            isSelected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
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
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isSelected) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(_NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Layout10Theme.spacingM,
              vertical: Layout10Theme.spacingS,
            ),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? Layout10Theme.accentColor.withValues(alpha: _glowAnimation.value)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusM),
              border: widget.isSelected
                  ? Border.all(
                      color: Layout10Theme.accentColor.withValues(alpha: 0.8),
                      width: 1,
                    )
                  : null,
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: Layout10Theme.accentColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Icon(
                    widget.icon,
                    size: 24,
                    color: widget.isSelected
                        ? Layout10Theme.primaryTextColor
                        : Layout10Theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: Layout10Theme.spacingXS),
                Text(
                  widget.label,
                  style: Layout10Theme.caption.copyWith(
                    color: widget.isSelected
                        ? Layout10Theme.primaryTextColor
                        : Layout10Theme.secondaryTextColor,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FloatingNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FloatingNavButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(Layout10Theme.spacingM),
        decoration: BoxDecoration(
          gradient: isSelected
              ? Layout10Theme.accentGradient
              : LinearGradient(
                  colors: [
                    Layout10Theme.surfaceColor,
                    Layout10Theme.surfaceColor.withValues(alpha: 0.8),
                  ],
                ),
          borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusL),
          border: Border.all(
            color: isSelected
                ? Layout10Theme.accentColor
                : Layout10Theme.secondaryTextColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? Layout10Theme.buttonShadow
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected
                  ? Layout10Theme.primaryTextColor
                  : Layout10Theme.secondaryTextColor,
            ),
            const SizedBox(height: Layout10Theme.spacingXS),
            Text(
              label,
              style: Layout10Theme.caption.copyWith(
                color: isSelected
                    ? Layout10Theme.primaryTextColor
                    : Layout10Theme.secondaryTextColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
