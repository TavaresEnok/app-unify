import 'package:flutter/material.dart';
import 'theme.dart';

class ContratoPage extends StatelessWidget {
  const ContratoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout05Theme.background,
      appBar: AppBar(
        title: Text('Contrato', style: Layout05Theme.heading2),
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
              padding: const EdgeInsets.all(24),
              decoration: Layout05Theme.cardDecoration,
              child: Column(
                children: [
                  const Icon(Icons.description_outlined,
                      size: 64, color: Layout05Theme.textGrey),
                  const SizedBox(height: 24),
                  Text(
                    'Termos de Serviço',
                    style: Layout05Theme.heading2,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Visualize ou faça o download do seu contrato de prestação de serviços.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: Layout05Theme.textGrey, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('BAIXAR PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Layout05Theme.textDark,
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
