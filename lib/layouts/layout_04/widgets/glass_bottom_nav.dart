import 'package:flutter/material.dart';
import '../theme.dart';

class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      height: 70, // Fixed height for the bar
      decoration: Layout04Theme.glassDecoration
          .copyWith(borderRadius: BorderRadius.circular(35), boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        )
      ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.grid_view_rounded, 0),
          _buildNavItem(Icons.wifi_tethering, 1),
          _buildNavItem(Icons.receipt_long_rounded, 2),
          _buildNavItem(Icons.headset_mic_rounded, 3),
          _buildNavItem(Icons.menu_rounded, 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 50,
        width: 50,
        decoration: isSelected
            ? BoxDecoration(
                color: Layout04Theme.neonCyan.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                    BoxShadow(
                        color: Layout04Theme.neonCyan.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 2)
                  ])
            : null,
        child: Icon(
          icon,
          color: isSelected ? Layout04Theme.neonCyan : Colors.white60,
          size: 24,
        ),
      ),
    );
  }
}
