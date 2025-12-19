import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dark Bottom Navigation with Glow Effect for Layout 10
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
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final surfaceColor = Theme.of(context).cardColor;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
              context, Icons.home_rounded, 0, primaryColor, textSecondary),
          _buildNavItem(
              context, Icons.wifi_rounded, 1, primaryColor, textSecondary),
          _buildCenterButton(context, primaryColor, secondaryColor),
          _buildNavItem(context, Icons.receipt_long_rounded, 2, primaryColor,
              textSecondary),
          _buildNavItem(
              context, Icons.person_rounded, 3, primaryColor, textSecondary),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    int index,
    Color primaryColor,
    Color textSecondary,
  ) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: isSelected
            ? BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ],
              )
            : null,
        child: Icon(
          icon,
          color: isSelected ? primaryColor : textSecondary,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildCenterButton(
      BuildContext context, Color primaryColor, Color secondaryColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap(4); // Speed test
      },
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, secondaryColor],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.speed_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
