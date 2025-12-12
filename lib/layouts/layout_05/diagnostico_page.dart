import 'package:flutter/material.dart';
import 'theme.dart';

class DiagnosticoPage extends StatelessWidget {
  const DiagnosticoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout05Theme.background,
      appBar: AppBar(
        title: const Text('DIAGNÓSTICO',
            style: TextStyle(letterSpacing: 2, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Layout05Theme.primary.withOpacity(0.1),
                  boxShadow: [
                    BoxShadow(
                        color: Layout05Theme.primary.withOpacity(0.2),
                        blurRadius: 40)
                  ]),
              child: const Icon(Icons.wifi_find,
                  size: 80, color: Layout05Theme.primary),
            ),
            const SizedBox(height: 32),
            const Text('Verificando conexão...',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Aguarde um momento',
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 40),
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                  color: Layout05Theme.primary,
                  backgroundColor: Colors.white10),
            ),
          ],
        ),
      ),
    );
  }
}
