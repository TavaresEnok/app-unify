import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/configuration_provider.dart';
import 'theme.dart';

class FinanceiroPage extends StatelessWidget {
  const FinanceiroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout04Theme.backgroundBlack,
      appBar: AppBar(
        title: Text("Faturas", style: Layout04Theme.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: Layout04Theme.auroraGradient,
        ),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 100),
          itemCount: 5,
          itemBuilder: (context, index) {
            final isPaid = index > 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: Layout04Theme.glassDecoration,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Fatura #${2024001 + index}",
                          style: Layout04Theme.bodyText.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text("Vencimento: 10/12/2024",
                          style: Layout04Theme.label),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("R\$ 99,90", style: Layout04Theme.heading2),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? Layout04Theme.neonGreen.withOpacity(0.2)
                              : Layout04Theme.neonPink.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: isPaid
                                  ? Layout04Theme.neonGreen
                                  : Layout04Theme.neonPink),
                        ),
                        child: Text(isPaid ? "PAGO" : "ABERTO",
                            style: TextStyle(
                                color: isPaid
                                    ? Layout04Theme.neonGreen
                                    : Layout04Theme.neonPink,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
