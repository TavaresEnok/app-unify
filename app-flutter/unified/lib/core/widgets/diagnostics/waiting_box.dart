import 'package:flutter/material.dart';
import 'diagnostic_theme.dart';
import 'holo_card.dart';

class WaitingBox extends StatelessWidget {
  const WaitingBox({super.key});

  @override
  Widget build(BuildContext context) {
    return const HoloCard(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            color: Color(0x66FFFFFF), // Colors.white.withAlpha(40)
            size: 20,
          ),
          SizedBox(width: 10),
          Text(
            'Aguardando diagnóstico...',
            style: TextStyle(color: DiagnosticTheme.textDim, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
