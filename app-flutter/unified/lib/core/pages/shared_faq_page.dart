import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../vibe/vibe_page_parts.dart';
import '../vibe/vibe_text.dart';
import '../vibe/vibe_tokens.dart';

/// Perguntas frequentes (`PG.faq` do layout aprovado): perguntas em um
/// cartão, cada uma abrindo a sua resposta.
class FaqPage extends ConsumerStatefulWidget {
  final ValueChanged<String>? onNavigate;
  const FaqPage({super.key, this.onNavigate});

  @override
  ConsumerState<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends ConsumerState<FaqPage> {
  final _open = <int>{};

  static const _defaults = <(String, String)>[
    (
      'Como pago a fatura pelo Pix?',
      'Em Faturas, toque em Copiar Pix, abra o app do seu banco e cole o código na opção Pix copia e cola.'
    ),
    (
      'Paguei e a internet não voltou. E agora?',
      'A confirmação depende do meio de pagamento e do provedor. Consulte a liberação por confiança em Faturas ou fale com o atendimento.'
    ),
    (
      'O que é a liberação por confiança?',
      'Com a fatura vencida, você pode pedir a liberação temporária da internet enquanto o pagamento é confirmado, conforme as regras da sua conta.'
    ),
    (
      'Como mudo a senha do Wi-Fi?',
      'Se o seu roteador estiver integrado ao app, use Minha rede Wi-Fi em Conexão. Se não estiver, fale com o suporte.'
    ),
    (
      'A internet está lenta. O que faço?',
      'Rode a Verificar conexão. Ela mostra se o problema está no celular, no Wi-Fi, no roteador ou na fibra.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final config = ref.watch(configurationProvider);
    final name = config.providerConfig?.name.trim() ?? '';
    final questions = config.providerConfig?.config.faq ?? [];
    final entries = questions.isNotEmpty
        ? questions.map((q) => (q.question, q.answer)).toList()
        : _defaults;
    final navigator = Navigator.of(context);
    return VibePageScaffold(
      title: 'Perguntas frequentes',
      subtitle: name.isEmpty ? 'Respostas rápidas' : 'Respostas da $name',
      onBack: navigator.canPop() ? () => navigator.maybePop() : null,
      children: [
        if (config.isLoading && config.providerConfig == null)
          const VibeLoading(label: 'Carregando perguntas')
        else
          VibeCard(
            child: VibeRows(children: [
              for (var i = 0; i < entries.length; i++)
                Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        expanded: _open.contains(i),
                        child: VibeRow(
                          title: entries[i].$1,
                          trailing: VibeChevron(open: _open.contains(i)),
                          onTap: () => setState(() => _open.contains(i)
                              ? _open.remove(i)
                              : _open.add(i)),
                        ),
                      ),
                      if (_open.contains(i))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(entries[i].$2,
                              style: vibeText(t, 13, 500,
                                  color: t.mut, height: 1.5)),
                        ),
                    ]),
            ]),
          ),
        if (widget.onNavigate != null)
          VibePageButton(
              label: name.isEmpty || name.length > 8
                  ? 'Ainda com dúvida? Fale com a gente'
                  : 'Ainda com dúvida? Fale com a $name',
              ghost: true,
              onPressed: () => widget.onNavigate!('support')),
      ],
    );
  }
}
