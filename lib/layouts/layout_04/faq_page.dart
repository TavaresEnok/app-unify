// LAYOUT 04 - AURORA - FAQ PAGE

import 'package:flutter/material.dart';
import 'aurora_theme.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      _FaqItem(
        question: 'Como pago minha fatura?',
        answer:
            'Você pode pagar via PIX, boleto bancário ou cartão de crédito através do app.',
      ),
      _FaqItem(
        question: 'Minha internet está lenta, o que fazer?',
        answer:
            'Primeiro, reinicie seu roteador. Se o problema persistir, faça um diagnóstico de rede no app.',
      ),
      _FaqItem(
        question: 'Como altero meu plano?',
        answer:
            'Entre em contato com nosso suporte pelo WhatsApp ou telefone para solicitar alteração de plano.',
      ),
      _FaqItem(
        question: 'Qual a velocidade do meu plano?',
        answer:
            'Você pode verificar a velocidade contratada na página inicial ou na seção de consumo.',
      ),
      _FaqItem(
        question: 'Como faço um teste de velocidade?',
        answer:
            'Acesse a opção "Speed Test" no menu para testar a velocidade da sua conexão.',
      ),
    ];

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          pinned: true,
          expandedHeight: 100,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'Perguntas Frequentes',
                    style: TextStyle(
                      color: AuroraColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FaqCard(faq: faqs[index]),
              ),
              childCount: faqs.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  _FaqItem({required this.question, required this.answer});
}

class _FaqCard extends StatefulWidget {
  final _FaqItem faq;

  const _FaqCard({required this.faq});

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AuroraCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.faq.question,
                  style: const TextStyle(
                    color: AuroraColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AuroraColors.textMuted,
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            Text(
              widget.faq.answer,
              style: const TextStyle(
                  color: AuroraColors.textSecondary, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
