import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/push_notification_service.dart';
import '../vibe/vibe_icon.dart';
import '../vibe/vibe_page_parts.dart';
import '../vibe/vibe_text.dart';
import '../vibe/vibe_tokens.dart';

/// Apresentação inicial (`PG.apresentacao` do layout aprovado): quatro
/// cartões com arte na cor da marca, pontos de página e o botão logo abaixo.
class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  /// Pede a permissão de notificações (padrão: o pedido único do FCM).
  final Future<void> Function()? requestNotifications;

  /// Registra o "Agora não" para não pedir de novo após o login.
  final Future<void> Function()? declineNotifications;
  const OnboardingPage(
      {super.key,
      required this.onComplete,
      this.requestNotifications,
      this.declineNotifications});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _current = 0;
  bool _completing = false;
  static const _items = [
    (
      'wifi',
      'Sua conexão na mão',
      'Verifique a internet, o Wi-Fi e a velocidade em poucos toques.'
    ),
    (
      'file',
      'Faturas sem complicação',
      'Consulte valores, vencimentos e as formas de pagamento disponíveis para sua fatura.'
    ),
    (
      'chat',
      'Ajuda quando precisar',
      'Encontre os canais de atendimento do seu provedor e orientações sobre sua conexão.'
    ),
    (
      'bell',
      'Avisos do seu provedor',
      'Ative os avisos para saber quando a fatura vence e quando houver manutenção na sua região.'
    ),
  ];

  Future<void> _complete() async {
    if (_completing) return;
    setState(() => _completing = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) widget.onComplete();
  }

  Future<void> _enableNotifications() async {
    if (_completing) return;
    setState(() => _completing = true);
    try {
      await (widget.requestNotifications ??
          PushNotificationService().requestPermissionOnce)();
    } catch (_) {}
    _completing = false;
    await _complete();
  }

  Future<void> _skipNotifications() async {
    if (_completing) return;
    try {
      await (widget.declineNotifications ??
          PushNotificationService.markPermissionAsked)();
    } catch (_) {}
    await _complete();
  }

  void _go(int index) =>
      setState(() => _current = index.clamp(0, _items.length - 1));

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final item = _items[_current];
    final last = _current == _items.length - 1;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final slide = Column(
      key: ValueKey(_current),
      children: [
        Container(
          width: 150,
          height: 150,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              color: t.hero, borderRadius: BorderRadius.circular(44)),
          alignment: Alignment.center,
          child: VibeIcon(item.$1, size: 64, strokeWidth: 1.5, color: t.hx),
        ),
        const SizedBox(height: 14),
        Semantics(
          header: true,
          child: Text(item.$2,
              textAlign: TextAlign.center,
              style: vibeText(t, 24, 800, letterSpacingEm: -.02, height: 1.2)),
        ),
        const SizedBox(height: 14),
        Text(item.$3,
            textAlign: TextAlign.center,
            style: vibeText(t, 14.5, 500, color: t.mut, height: 1.5)),
      ],
    );
    final dots = Semantics(
      label: 'Cartão ${_current + 1} de ${_items.length}',
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < _items.length; i++)
          Semantics(
            button: true,
            selected: i == _current,
            label: 'Cartão ${i + 1} de ${_items.length}',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _go(i),
              child: SizedBox(
                width: i == _current ? 26 : 18,
                height: 44,
                child: Center(
                  child: AnimatedContainer(
                    duration: reduce
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    width: i == _current ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color:
                          i == _current ? t.ac : t.ink.withValues(alpha: .22),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
    return Material(
      color: t.bg,
      child: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v < -200) _go(_current + 1);
            if (v > 200) _go(_current - 1);
          },
          child: Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 2),
                child: TextButton(
                  onPressed: _completing ? null : _complete,
                  style: TextButton.styleFrom(
                      foregroundColor: t.mut, minimumSize: const Size(64, 44)),
                  child:
                      Text('Pular', style: vibeText(t, 14, 700, color: t.mut)),
                ),
              ),
            ),
            // O conteúdo ocupa só o que precisa, com o botão logo abaixo;
            // com texto ampliado ele rola e o botão segue visível.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
                child: Column(children: [
                  AnimatedSwitcher(
                    duration: reduce
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    child: slide,
                  ),
                  const SizedBox(height: 8),
                  dots,
                ]),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(22, 14, 22, last ? 12 : 34),
              child: VibePageButton(
                label: last ? 'Ativar avisos' : 'Avançar',
                onPressed: _completing
                    ? null
                    : () => last ? _enableNotifications() : _go(_current + 1),
              ),
            ),
            // No último cartão, a escolha fica com o assinante.
            if (last)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                child: VibePageButton(
                  label: 'Agora não',
                  ghost: true,
                  onPressed: _completing ? null : _skipNotifications,
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
