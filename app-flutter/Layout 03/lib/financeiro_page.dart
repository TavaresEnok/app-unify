import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'configuration_provider.dart';
import 'providers/financeiro_provider.dart';
import 'services/financeiro_service.dart';

class FinanceiroPage extends StatelessWidget {
  final String cpfCnpj;
  final String senha;
  final Map<String, dynamic> sgpParams;

  const FinanceiroPage({
    super.key,
    required this.cpfCnpj,
    required this.senha,
    required this.sgpParams,
  });

  @override
  Widget build(BuildContext context) {
    // Extraindo configuração do Provider
    final configProvider =
        Provider.of<ConfigurationProvider>(context, listen: false);
    final providerConfig = configProvider.providerConfig;

    final apiUrl = providerConfig?.apiUrl ?? '';
    // sgpBaseUrl não é mais passado para o service deste layout

    // Preparando CPF limpo
    final cpfCnpjUnformatted = cpfCnpj.replaceAll(RegExp(r'[^0-9]'), '');

    return ChangeNotifierProvider(
      create: (_) => FinanceiroProvider(
        FinanceiroService(
          apiUrl: apiUrl,
          cpfCnpjUnformatted: cpfCnpjUnformatted,
          senha: senha,
          sgpParams: sgpParams,
          // sgpBaseUrl removed
        ),
      )..fetchHistory(), // Corrected method name
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Financeiro'),
          centerTitle: true,
        ),
        body: Consumer<FinanceiroProvider>(
          builder: (context, provider, child) {
            if (provider.state == FinanceiroState.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.state == FinanceiroState.error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        provider.errorMessage ?? 'Erro ao carregar faturas',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: provider.fetchHistory, // Corrected method
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final faturas = provider.invoices;
            if (faturas.isEmpty) {
              return const Center(
                child: Text('Nenhuma fatura encontrada'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: faturas.length,
              itemBuilder: (context, index) {
                final fatura = faturas[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      fatura.status ==
                              'pago' // Corrected status check ('pago' vs 'paid')
                          ? Icons.check_circle
                          : Icons.pending,
                      color: fatura.status == 'pago'
                          ? Colors.green
                          : Colors.orange,
                      size: 32,
                    ),
                    title: Text(
                      'Vencimento: ${DateFormat('dd/MM/yyyy').format(fatura.vencimento)}', // Corrected field
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'R\$ ${fatura.valor.toStringAsFixed(2)}', // Corrected field
                      style: const TextStyle(fontSize: 18),
                    ),
                    trailing: fatura.status != 'pago'
                        ? ElevatedButton(
                            onPressed: () {
                              // TODO: Implementar pagamento
                            },
                            child: const Text('Pagar'),
                          )
                        : null,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
