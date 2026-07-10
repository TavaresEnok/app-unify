import 'package:flutter/material.dart';
import '../../models/diagnostic_enums.dart';
import 'diagnostic_theme.dart';
import 'holo_card.dart';

class StepProgressBar extends StatelessWidget {
  final DiagStep currentStep;
  final Set<DiagStep> completedSteps;
  final bool isRunning;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.completedSteps,
    required this.isRunning,
  });

  static const steps = [
    (DiagStep.device, Icons.smartphone, 'Device'),
    (DiagStep.wifi, Icons.wifi, 'Wi-Fi'),
    (DiagStep.onu, Icons.router, 'ONU'),
    (DiagStep.lan, Icons.devices, 'LAN'),
    (DiagStep.connectivity, Icons.public, 'Rede'),
    (DiagStep.speed, Icons.speed, 'Speed'),
    (DiagStep.tracert, Icons.route, 'Rota'),
  ];

  @override
  Widget build(BuildContext context) {
    return HoloCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: steps.map((s) {
          final isCompleted = completedSteps.contains(s.$1);
          final isCurrent = currentStep == s.$1 && isRunning;
          final color = isCompleted
              ? DiagnosticTheme.green
              : isCurrent
                  ? DiagnosticTheme.cyan
                  : Colors.white.withAlpha(40);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: isCompleted || isCurrent
                      ? RadialGradient(
                          colors: [color.withAlpha(80), color.withAlpha(15)],
                        )
                      : null,
                  color: !isCompleted && !isCurrent
                      ? Colors.white.withAlpha(8)
                      : null,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                  boxShadow: isCurrent
                      ? [BoxShadow(color: color.withAlpha(100), blurRadius: 10)]
                      : null,
                ),
                child: Icon(
                  isCompleted ? Icons.check_rounded : s.$2,
                  color: color,
                  size: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(s.$3, style: TextStyle(color: color, fontSize: 8)),
            ],
          );
        }).toList(),
      ),
    );
  }
}
