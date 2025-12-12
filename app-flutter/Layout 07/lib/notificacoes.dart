// ARQUIVO: lib/notificacoes.dart (MIGRADO PARA CONSUMO VIA PROVIDER)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- NOVO
import 'utils.dart';
import 'configuration_provider.dart'; // <-- NOVO

class NotificacoesPage extends StatelessWidget {
  // REMOVIDO: final Map<String, dynamic> providerConfig;

  const NotificacoesPage({super.key}); // Construtor simplificado

  @override
  Widget build(BuildContext context) {
    // Acessa a configuração via Provider
    final providerConfig = Provider.of<ConfigurationProvider>(context).providerConfig!;

    final primaryColor = hexToColor(providerConfig.config.themeColor);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notificações"),
        backgroundColor: primaryColor, // <-- COR DINÂMICA
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              "Nenhuma notificação no momento.",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
