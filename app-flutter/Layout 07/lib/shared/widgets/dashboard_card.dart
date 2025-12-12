import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DashboardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;

  const DashboardCard({
    super.key, 
    required this.child, 
    this.padding, 
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Variation A: Minimalist Sophisticated
    // Subtle borders, no heavy shadows, clean white background
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          // Optional: very subtle shadow for depth if needed, but Variation A prefers flat/border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
