import 'package:flutter/material.dart';
import '../theme.dart';

class NeumorphicBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NeumorphicBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Obtém o padding inferior do sistema (safe area)
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      // Adiciona o padding do sistema e um extra para garantir que fique acima dos botões do Android
      padding: EdgeInsets.only(bottom: 30 + bottomPadding, left: 24, right: 24),
      color: Colors.transparent, // Background allows Scaffold color to show
      child: Container(
        height: 70, // Reduzido levemente para 70 para ficar mais compacto
        decoration: BoxDecoration(
          color: Layout05Theme.background,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.white,
              offset: const Offset(-4, -4), // Sombras mais suaves
              blurRadius: 10,
            ),
            BoxShadow(
              color: const Color(0xFFA3B1C6).withOpacity(0.3),
              offset: const Offset(4, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Início'),
            _buildNavItem(1, Icons.wifi_rounded, 'Wi-Fi'),
            _buildNavItem(2, Icons.receipt_long_rounded, 'Finan.'),
            _buildNavItem(3, Icons.headset_mic_rounded, 'Suporte'),
            _buildNavItem(4, Icons.menu_rounded, 'Menu'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    final color = isSelected ? Layout05Theme.primary : Layout05Theme.textGrey;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: Layout05Theme.background,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA3B1C6).withValues(alpha: 0.2),
                      offset: const Offset(4, 4),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: Colors.white,
                      offset: const Offset(-4, -4),
                      blurRadius: 8,
                    ),
                  ]) // Pressed/Concave Simulation
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
