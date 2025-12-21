import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get colors from context
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceColor = Theme.of(context).cardColor;
    final textSecondaryColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
              context, Icons.home_rounded, 0, primaryColor, textSecondaryColor),
          _buildNavItem(context, Icons.receipt_long_rounded, 1, primaryColor,
              textSecondaryColor),
          _buildNavItem(context, Icons.speed_rounded, 2, primaryColor,
              textSecondaryColor),
          _buildNavItem(context, Icons.person_rounded, 3, primaryColor,
              textSecondaryColor),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, int index,
      Color primaryColor, Color secondaryColor) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: isSelected
            ? BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Icon(
          icon,
          color: isSelected ? primaryColor : secondaryColor,
          size: 24,
        ),
      ),
    );
  }
}
