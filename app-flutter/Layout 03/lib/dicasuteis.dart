// ARQUIVO: lib/dicasuteis.dart (MIGRADO PARA CONSUMO VIA PROVIDER)

import 'package:layout01/models/provider_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils.dart';
import 'configuration_provider.dart';

class DicasUteisPage extends StatelessWidget {
  const DicasUteisPage({super.key}); // Construtor simplificado

  @override
  Widget build(BuildContext context) {
    // Acessa a configuração via Provider
    final providerConfig = Provider.of<ConfigurationProvider>(context).providerConfig!;

    final primaryColor = hexToColor(providerConfig.config.themeColor);
    final List<TipItem> dicasList = providerConfig.config.tips;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dicas Úteis"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: dicasList.isEmpty
          ? const Center(
              child: Text("Nenhuma dica útil cadastrada.",
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: dicasList.length,
              itemBuilder: (context, index) {
                final dicaItem = dicasList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dicaItem.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                        const SizedBox(height: 8),
                        Text(dicaItem.description, style: TextStyle(color: Colors.grey.shade700, height: 1.5, fontSize: 15)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
