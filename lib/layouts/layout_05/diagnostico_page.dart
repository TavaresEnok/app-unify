import 'package:flutter/material.dart';
import 'theme.dart';

class DiagnosticoPage extends StatelessWidget {
  const DiagnosticoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout05Theme.background,
      appBar: AppBar(
        title: Text('Diagnóstico', style: Layout05Theme.heading2),
        backgroundColor: Layout05Theme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Layout05Theme.textDark),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: Layout05Theme.softShadow,
              ),
              child: const CircularProgressIndicator(
                color: Layout05Theme.primary,
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 32),
            Text('Verificando conexão...', style: Layout05Theme.heading2),
            const SizedBox(height: 12),
            const Text(
              'Aguarde enquanto analisamos sua rede.',
              style: TextStyle(color: Layout05Theme.textGrey),
            ),
          ],
        ),
      ),
    );
  }
}
