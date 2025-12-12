import 'package:flutter/material.dart';
import 'theme.dart';

class ContratoPage extends StatelessWidget {
  const ContratoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout05Theme.background,
      appBar: AppBar(
        title: const Text('CONTRATO',
            style: TextStyle(letterSpacing: 2, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: Layout05Theme.glassDecoration,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description,
                          color: Layout05Theme.primary),
                      const SizedBox(width: 12),
                      const Text('CONTRATO DE PRESTAÇÃO',
                          style: TextStyle(
                              color: Layout05Theme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'TERMOS E CONDIÇÕES GERAIS',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '1. OBJETO\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\n\n2. OBRIGAÇÕES\nDuis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident.\n\n3. PRAZO\nSed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium.',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download),
                      label: const Text('BAIXAR PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Layout05Theme.primary,
                        side: const BorderSide(color: Layout05Theme.primary),
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
