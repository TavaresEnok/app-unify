import 'package:flutter/material.dart';
import 'theme.dart';

class FinanceiroPage extends StatelessWidget {
  const FinanceiroPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dados Mockados para exemplo
    final faturas = [
      {'status': 'open', 'valor': '99,90', 'vencimento': '10/12/2023'},
      {'status': 'paid', 'valor': '99,90', 'vencimento': '10/11/2023'},
      {'status': 'paid', 'valor': '99,90', 'vencimento': '10/10/2023'},
    ];

    return Scaffold(
      backgroundColor: Layout05Theme.background,
      appBar: AppBar(
        title: Text('Minhas Faturas', style: Layout05Theme.heading2),
        backgroundColor: Layout05Theme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Layout05Theme.textDark),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: faturas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final fatura = faturas[index];
          final isOpen = fatura['status'] == 'open';

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: Layout05Theme.cardDecoration,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? Layout05Theme.warning.withOpacity(0.1)
                        : Layout05Theme.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOpen ? Icons.receipt_long : Icons.check_circle,
                    color:
                        isOpen ? Layout05Theme.warning : Layout05Theme.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOpen ? 'Fatura Aberta' : 'Fatura Paga',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Layout05Theme.textDark,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Vencimento: ${fatura['vencimento']}',
                        style: const TextStyle(
                            color: Layout05Theme.textGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$ ${fatura['valor']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Layout05Theme.textDark,
                      ),
                    ),
                    if (isOpen)
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 20),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: Layout05Theme.primary,
                        ),
                        child: const Text('Pagar'),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
