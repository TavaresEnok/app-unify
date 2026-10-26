// Test Mode Selector Widget
// Allows user to select personalized test mode before starting diagnostic

import 'package:flutter/material.dart';
import '../models/test_mode.dart';

class TestModeSelector extends StatelessWidget {
  final TestMode selectedMode;
  final ValueChanged<TestMode> onModeSelected;

  const TestModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Modo de Teste',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: TestMode.values.map((mode) {
              final isSelected = selectedMode == mode;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _buildModeCard(mode, isSelected),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildModeCard(TestMode mode, bool isSelected) {
    final colors = _getModeColors(mode);

    return GestureDetector(
      onTap: () => onModeSelected(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  mode.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              mode.displayName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mode.description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getModeColors(TestMode mode) {
    switch (mode) {
      case TestMode.quick:
        return [const Color(0xFF00F5FF), const Color(0xFF0EA5E9)];
      case TestMode.gaming:
        return [const Color(0xFF8B5CF6), const Color(0xFFC026D3)];
      case TestMode.streaming:
        return [const Color(0xFFEC4899), const Color(0xFFF43F5E)];
      case TestMode.complete:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
    }
  }
}

// Compact Test Mode Selector (for limited space)
class CompactTestModeSelector extends StatelessWidget {
  final TestMode selectedMode;
  final ValueChanged<TestMode> onModeSelected;

  const CompactTestModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TestMode>(
          value: selectedMode,
          dropdownColor: const Color(0xFF1a1a2e),
          icon: const Icon(Icons.expand_more, color: Colors.white, size: 20),
          items: TestMode.values.map((mode) {
            return DropdownMenuItem(
              value: mode,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(mode.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    mode.displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (mode) {
            if (mode != null) onModeSelected(mode);
          },
        ),
      ),
    );
  }
}
