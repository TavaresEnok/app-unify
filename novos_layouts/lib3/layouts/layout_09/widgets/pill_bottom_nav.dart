import 'package:flutter/material.dart';

class PillBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PillBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surface = Theme.of(context).cardColor;

    final inactive = scheme.onSurface.withValues(alpha: 0.55);
    final active = scheme.primary;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 26,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _item(
                context: context,
                icon: Icons.home_rounded,
                index: 0,
                active: active,
                inactive: inactive,
              ),
              _item(
                context: context,
                icon: Icons.wifi_rounded,
                index: 1,
                active: active,
                inactive: inactive,
              ),
              _item(
                context: context,
                icon: Icons.receipt_long_rounded,
                index: 2,
                active: active,
                inactive: inactive,
              ),
              _item(
                context: context,
                icon: Icons.support_agent_rounded,
                index: 3,
                active: active,
                inactive: inactive,
              ),
              _item(
                context: context,
                icon: Icons.menu_rounded,
                index: 4,
                active: active,
                inactive: inactive,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item({
    required BuildContext context,
    required IconData icon,
    required int index,
    required Color active,
    required Color inactive,
  }) {
    final selected = currentIndex == index;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? active.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(
            icon,
            size: 24,
            color: selected ? active : inactive,
          ),
        ),
      ),
    );
  }
}
