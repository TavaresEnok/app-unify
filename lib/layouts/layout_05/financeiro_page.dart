import 'package:flutter/material.dart';
import 'theme.dart';

class FinanceiroPage extends StatelessWidget {
  const FinanceiroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout05Theme.background,
      appBar: AppBar(
        title: const Text('FINANCEIRO',
            style: TextStyle(letterSpacing: 2, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (context, index) {
          final isPending = index == 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: isPending
                ? Layout05Theme.neonBorderDecoration
                : Layout05Theme.glassDecoration,
            child: Row(
              children: [
                Icon(
                  isPending
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: isPending
                      ? Layout05Theme.primary
                      : const Color(0xFF00E676),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPending ? 'FATURA ABERTA' : 'PAGO',
                        style: TextStyle(
                            color: isPending
                                ? Layout05Theme.primary
                                : const Color(0xFF00E676),
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text('R\$ 99,90',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const Text('Vencimento 10/12/2025',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                if (isPending)
                  IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white),
                      onPressed: () {})
              ],
            ),
          );
        },
      ),
    );
  }
}
