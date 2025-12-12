import 'package:flutter/material.dart';
import 'theme.dart';

class MeuIpPage extends StatelessWidget {
  const MeuIpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout05Theme.background,
      appBar: AppBar(
        title: const Text('MEU IP',
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
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              margin: const EdgeInsets.all(20),
              decoration: Layout05Theme.neonBorderDecoration,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.public, color: Layout05Theme.primary, size: 40),
                  SizedBox(height: 20),
                  Text('SEU ENDEREÇO IP',
                      style: TextStyle(
                          color: Layout05Theme.primary, letterSpacing: 2)),
                  SizedBox(height: 12),
                  Text('192.168.1.100',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh, color: Colors.white54),
              label: const Text('Atualizar',
                  style: TextStyle(color: Colors.white54)),
            )
          ],
        ),
      ),
    );
  }
}
