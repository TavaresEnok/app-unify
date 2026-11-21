import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../widgets/customer_ui.dart';

class FaqPage extends ConsumerWidget {
  final ValueChanged<String>? onNavigate;
  const FaqPage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configurationProvider);
    final questions = config.providerConfig?.config.faq ?? [];
    if (config.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (config.errorMessage != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(config.errorMessage!)));
    }
    final entries = questions.isNotEmpty
        ? questions.map((q) => (q.question, q.answer)).toList()
        : <(String, String)>[
            (
              'Como pago a fatura pelo Pix?',
              'Em Faturas, selecione a mensalidade, copie o código Pix disponível e cole no aplicativo do seu banco.'
            ),
            (
              'Paguei e a internet ainda não voltou. O que faço?',
              'A confirmação depende do meio de pagamento e do provedor. Consulte as opções de liberação disponíveis em Faturas ou fale com o atendimento.'
            ),
            (
              'O que é a liberação por confiança?',
              'Quando disponível para sua fatura, esta opção permite solicitar a liberação temporária enquanto o pagamento é processado.'
            ),
            (
              'Como altero o Wi-Fi?',
              'Se o roteador estiver integrado ao aplicativo, abra Minha rede Wi-Fi em Conexão. Caso contrário, fale com o suporte.'
            ),
            (
              'Minha internet está lenta. O que faço?',
              'Use Verificar conexão para consultar os resultados dos testes disponíveis.'
            ),
          ];
    return CustomerList(children: [
      CustomerCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
              ExpansionTile(
                title: Text(entries[i].$1,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text(entries[i].$2))
                ],
              ),
            ],
          ])),
      if (onNavigate != null) ...[
        const SizedBox(height: 16),
        OutlinedButton(
            onPressed: () => onNavigate!('support'),
            child: Text(
                'Ainda com dúvida? Fale com ${config.providerConfig?.name ?? 'o suporte'}')),
      ],
    ]);
  }
}
