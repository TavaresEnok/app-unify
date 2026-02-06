// Layout 05 Speed Test Page - Redireciona para página de diagnóstico compartilhada
import 'package:flutter/material.dart';
import '../../../core/pages/shared_diagnostico_page.dart';

class SpeedTestPage extends StatelessWidget {
  const SpeedTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Usa a página de diagnóstico compartilhada do core
    return const DiagnosticoPage();
  }
}
