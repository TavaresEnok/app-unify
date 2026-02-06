import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiagnosticoActionButton extends StatelessWidget {
  final bool isTesting;
  final Color primaryColor;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const DiagnosticoActionButton({
    super.key,
    required this.isTesting,
    required this.primaryColor,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        icon: Icon(isTesting ? Icons.stop_circle_outlined : Icons.network_check),
        label: Text(isTesting ? "Parar Diagnóstico" : "Iniciar Diagnóstico"),
        style: ElevatedButton.styleFrom(
          backgroundColor: isTesting ? Colors.redAccent : primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          minimumSize: const Size(double.infinity, 56),
          elevation: 5,
        ),
        onPressed: () {
          HapticFeedback.heavyImpact();
          if (isTesting) {
            onStop();
          } else {
            onStart();
          }
        },
      ),
    );
  }
}
