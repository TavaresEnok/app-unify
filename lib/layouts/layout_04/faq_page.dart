// LAYOUT 04 - AURORA - FAQ PAGE
// Design: Expandable FAQ with glassmorphic cards

import 'package:flutter/material.dart';
import 'aurora_theme.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  int? _expandedIndex;

  final List<Map<String, String>> _faqItems = [
    {
      'question': 'Como faço para pagar minha fatura?',
      'answer':
          'Você pode pagar via PIX usando o código disponível na sua fatura, através do boleto bancário, ou em nosso app. O pagamento é confirmado automaticamente.',
    },
    {
      'question': 'O que fazer se minha internet estiver lenta?',
      'answer':
          'Primeiro, reinicie seu roteador/ONU. Se o problema persistir, faça um speed test no nosso app. Se a velocidade estiver abaixo do contratado, entre em contato conosco.',
    },
    {
      'question': 'Como reiniciar minha ONU?',
      'answer':
          'Desconecte o cabo de energia da ONU, aguarde 30 segundos e reconecte. Aguarde cerca de 2 minutos para a conexão ser restabelecida.',
    },
    {
      'question': 'Posso mudar meu plano de internet?',
      'answer':
          'Sim! Você pode solicitar upgrade ou downgrade do seu plano entrando em contato com nosso suporte. A mudança é feita sem custos adicionais.',
    },
    {
      'question': 'Como obter a 2ª via do meu boleto?',
      'answer':
          'No app, acesse a seção Faturas e clique em "Ver boleto" na fatura desejada. Você também pode copiar o código de barras ou o código PIX.',
    },
    {
      'question': 'O que é o desbloqueio por confiança?',
      'answer':
          'É uma opção para liberar sua internet por 24 horas caso você tenha uma fatura vencida. Isso dá tempo para você efetuar o pagamento.',
    },
    {
      'question': 'Qual a velocidade do meu plano?',
      'answer':
          'A velocidade do seu plano está indicada no contrato e também aparece no seu app. Use o Speed Test para verificar se está recebendo a velocidade contratada.',
    },
    {
      'question': 'Como entro em contato com o suporte?',
      'answer':
          'Você pode nos contatar via WhatsApp, telefone ou e-mail. Acesse a seção Suporte no app para ver todas as opções de contato.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: ShaderMask(
            shaderCallback: (bounds) =>
                AuroraColors.primaryGradient.createShader(bounds),
            child: const Text('FAQ',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            GlassCard(
              child: Column(
                children: [
                  NeonIconBadge(
                      icon: Icons.help_outline,
                      color: AuroraColors.neonCyan,
                      size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Perguntas Frequentes',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AuroraColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Encontre respostas para suas dúvidas',
                    style: TextStyle(color: AuroraColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // FAQ Items
            ...List.generate(_faqItems.length, (index) => _buildFaqItem(index)),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(int index) {
    final item = _faqItems[index];
    final isExpanded = _expandedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        glowColor: isExpanded ? AuroraColors.neonCyan.withOpacity(0.5) : null,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Question
            InkWell(
              onTap: () {
                setState(() {
                  _expandedIndex = isExpanded ? null : index;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AuroraColors.neonCyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AuroraColors.neonCyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item['question']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isExpanded
                              ? AuroraColors.neonCyan
                              : AuroraColors.textPrimary,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: isExpanded
                            ? AuroraColors.neonCyan
                            : AuroraColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Answer
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AuroraColors.neonCyan.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AuroraColors.neonCyan.withOpacity(0.2)),
                  ),
                  child: Text(
                    item['answer']!,
                    style: TextStyle(
                      color: AuroraColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}
