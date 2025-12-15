import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

class MeuIpPage extends StatelessWidget {
  const MeuIpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout05Theme.background,
      appBar: AppBar(
        title: Text('Meu IP', style: Layout05Theme.heading2),
        backgroundColor: Layout05Theme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Layout05Theme.textDark),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: Layout05Theme.cardDecoration,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Layout05Theme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.public,
                        size: 48, color: Layout05Theme.primary),
                  ),
                  const SizedBox(height: 24),
                  const Text('Seu IP Atual',
                      style: TextStyle(color: Layout05Theme.textGrey)),
                  const SizedBox(height: 8),
                  const Text(
                    '192.168.1.10',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Layout05Theme.textDark,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                            const ClipboardData(text: '192.168.1.10'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('IP copiado!')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 20),
                      label: const Text('COPIAR ENDEREÇO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Layout05Theme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
