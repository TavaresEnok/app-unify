import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../utils/app_formatters.dart';
import '../widgets/customer_ui.dart';
import '../widgets/content_state.dart';

class ContratoPage extends ConsumerWidget {
  final ValueChanged<String>? onNavigate;
  const ContratoPage({super.key, this.onNavigate});

  String _maskedDocument(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 11) {
      return '***.${digits.substring(3, 6)}.${digits.substring(6, 9)}-**';
    }
    if (digits.length == 14) {
      return '**.${digits.substring(2, 5)}.${digits.substring(5, 8)}/****-**';
    }
    return 'Não informado';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configurationProvider).providerConfig;
    final user = ref.watch(authNotifierProvider).valueOrNull;
    if (user == null) {
      return const ContentState(
          icon: Icons.person_outline,
          title: 'Dados do contrato indisponíveis',
          message: 'Entre novamente para consultar seu contrato.');
    }
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant))),
            const SizedBox(width: 12),
            Expanded(
                child: Text(value.isEmpty ? 'Não informado' : value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
        );
    return CustomerList(children: [
      CustomerCard(
          child: Column(children: [
        row('Titular', user.nome),
        row('CPF/CNPJ', _maskedDocument(user.cpfCnpj)),
        row('Plano', user.plano),
        row('Situação', user.contractStatus ?? ''),
        if (user.contratoId != null) row('Contrato', '${user.contratoId}'),
        if (user.valorFatura.trim().isNotEmpty &&
            user.valorFatura
                .replaceAll(RegExp(r'[^0-9]'), '')
                .contains(RegExp(r'[1-9]')))
          row('Valor informado', AppFormatters.currency(user.valorFatura)),
        if (user.vencimentoFatura.trim().isNotEmpty)
          row('Vencimento', user.vencimentoFatura),
        if (config != null) row('Provedor', config.name),
      ])),
      if (onNavigate != null) ...[
        const SizedBox(height: 16),
        Text(
            'Para alterar dados de cadastro ou trocar de plano, fale com seu provedor.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        OutlinedButton(
            onPressed: () => onNavigate!('support'),
            child: const Text('Falar com o suporte')),
      ],
    ]);
  }
}
