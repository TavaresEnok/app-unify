import 'package:flutter/material.dart';
import 'theme.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout05Theme.background,
      appBar: AppBar(
        title: Text('Perguntas Frequentes', style: Layout05Theme.heading2),
        backgroundColor: Layout05Theme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Layout05Theme.textDark),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _FaqItem(
            question: 'Como emitir a 2ª via do boleto?',
            answer:
                'Acesse a aba "Financeiro" no menu principal e clique em "Visualizar Fatura".',
          ),
          SizedBox(height: 16),
          _FaqItem(
            question: 'Minha internet está lenta, o que fazer?',
            answer:
                'Tente reiniciar seu roteador. Se o problema persistir, use a aba "Suporte" para entrar em contato.',
          ),
          SizedBox(height: 16),
          _FaqItem(
            question: 'Como mudar minha senha do Wi-Fi?',
            answer:
                'Entre em contato com o suporte técnico para realizar a alteração de forma segura.',
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Layout05Theme.cardDecoration,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          title: Text(
            question,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Layout05Theme.textDark),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Text(
                answer,
                style:
                    const TextStyle(color: Layout05Theme.textGrey, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
