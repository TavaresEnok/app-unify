import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/widgets/dashboard_card.dart';

class ContratoPage extends ConsumerWidget {
  const ContratoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configProvider = ref.watch(configurationProvider);
    final authState = ref.watch(authNotifierProvider);
    final usuario = authState.value;
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    if (usuario == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meu Contrato')),
        body: const Center(child: Text('Usuário não logado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Contrato'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Card do Cliente
            DashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child:
                            Icon(Icons.person, size: 32, color: primaryColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              usuario.nome,
                              style: textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CPF/CNPJ: ${_formatCpfCnpj(usuario.cpfCnpj)}',
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: textTheme.bodySmall?.color),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card do Plano
            DashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plano Contratado',
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Divider(height: 24),
                  _buildInfoRow(context,
                      icon: Icons.wifi, label: 'Plano', value: usuario.plano),
                  const SizedBox(height: 12),
                  _buildInfoRow(context,
                      icon: Icons.check_circle_outline,
                      label: 'Status',
                      value: usuario.status,
                      valueColor: _getStatusColor(usuario.status)),
                  if (usuario.contratoId != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(context,
                        icon: Icons.tag,
                        label: 'Contrato ID',
                        value: '#${usuario.contratoId}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card Financeiro
            DashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informações Financeiras',
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Divider(height: 24),
                  _buildInfoRow(context,
                      icon: Icons.attach_money,
                      label: 'Valor',
                      value: 'R\$ ${usuario.valorFatura}'),
                  const SizedBox(height: 12),
                  _buildInfoRow(context,
                      icon: Icons.calendar_today,
                      label: 'Vencimento',
                      value: 'Dia ${usuario.vencimentoFatura}'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card do Provedor
            if (configProvider.providerConfig != null)
              DashboardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Provedor',
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Divider(height: 24),
                    _buildInfoRow(context,
                        icon: Icons.business,
                        label: 'Empresa',
                        value: configProvider.providerConfig!.name),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon,
      required String label,
      required String value,
      Color? valueColor}) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: textTheme.bodySmall?.color),
        const SizedBox(width: 12),
        Text('$label:', style: textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ativo':
        return Colors.green;
      case 'bloqueado':
        return Colors.red;
      case 'pendente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatCpfCnpj(String value) {
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 11) {
      return '${clean.substring(0, 3)}.${clean.substring(3, 6)}.${clean.substring(6, 9)}-${clean.substring(9)}';
    } else if (clean.length == 14) {
      return '${clean.substring(0, 2)}.${clean.substring(2, 5)}.${clean.substring(5, 8)}/${clean.substring(8, 12)}-${clean.substring(12)}';
    }
    return value;
  }
}
