import 'package:flutter/material.dart';
import 'theme.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout05Theme.background,
      appBar: AppBar(
        title:
            const Text('FAQ', style: TextStyle(letterSpacing: 2, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (int i = 1; i <= 5; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: Layout05Theme.glassDecoration,
              child: ExpansionTile(
                iconColor: Layout05Theme.primary,
                collapsedIconColor: Colors.white54,
                title: Text('Dúvida frequente número $i?',
                    style: const TextStyle(color: Colors.white)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Esta é uma resposta genérica para a pergunta $i. Aqui explicamos detalhadamente como resolver o problema do cliente.',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}
