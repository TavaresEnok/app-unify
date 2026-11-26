import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/provider_config.dart';
import '../models/usuario.dart';
import '../providers/providers.dart';
import '../utils/external_link.dart';
import '../vibe/vibe_home_parts.dart' show VibeLogo;
import '../vibe/vibe_icon.dart';
import '../vibe/vibe_page_parts.dart';
import '../vibe/vibe_text.dart';
import '../vibe/vibe_tokens.dart';

/// Login ÚNICO, temático via [LayoutTokens].
///
/// Substitui os cinco `layouts/layout_0X/login_page.dart` — que reimplementavam
/// o MESMO fluxo (coletar CPF → `authNotifier.login`) com estilos diferentes.
/// Aqui o fluxo é um só e a aparência (claro/escuro/neumórfico, cor primária,
/// fundo) vem dos tokens do provedor. Uma correção de login passa a valer para
/// todos os layouts de uma vez.
class UnifiedLoginPage extends ConsumerStatefulWidget {
  const UnifiedLoginPage({super.key});

  @override
  ConsumerState<UnifiedLoginPage> createState() => _UnifiedLoginPageState();
}

class _UnifiedLoginPageState extends ConsumerState<UnifiedLoginPage> {
  final _cpfController = TextEditingController();
  final _focus = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  /// Erro de digitação (sem ida ao servidor): o botão segue "Entrar".
  bool _localError = false;

  /// Documento que já recebeu o aviso de dígito verificador: tocar em
  /// Entrar de novo com o mesmo número consulta o provedor assim mesmo.
  String? _warnedDigits;

  /// Etapas da espera: 0 até 3 s, 1 até 10 s, 2 depois disso.
  int _waitStage = 0;
  final List<Timer> _waitTimers = [];

  void _startWait() {
    _stopWait();
    _waitStage = 0;
    _waitTimers
      ..add(Timer(const Duration(seconds: 3), () {
        if (mounted && _isLoading) setState(() => _waitStage = 1);
      }))
      ..add(Timer(const Duration(seconds: 10), () {
        if (mounted && _isLoading) setState(() => _waitStage = 2);
      }));
  }

  void _stopWait() {
    for (final timer in _waitTimers) {
      timer.cancel();
    }
    _waitTimers.clear();
    _waitStage = 0;
  }

  @override
  void dispose() {
    _stopWait();
    _cpfController.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(ProviderConfig? config) async {
    final invalid = validateDocument(_cpfController.text);
    final digits = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
    // Dígito verificador errado (ou 12-13 números) só avisa uma vez: há
    // cadastros no ERP com documento digitado errado, e esse assinante
    // precisa conseguir entrar com o número que o provedor tem.
    final soft = isSoftDocumentWarning(_cpfController.text);
    if (invalid != null && !(soft && _warnedDigits == digits)) {
      setState(() {
        _errorMessage = soft
            ? '$invalid Se estiver certo, toque em Entrar de novo.'
            : invalid;
        _localError = true;
        _warnedDigits = digits;
      });
      return;
    }
    if (config == null) {
      setState(() {
        _errorMessage = 'Erro de configuração. Tente novamente.';
        _localError = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _localError = false;
      _startWait();
    });

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .login(_cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''), config);
      // Sucesso: o AuthGate navega automaticamente.
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'CPF não encontrado ou erro de conexão.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _stopWait();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Usuario?>>(authNotifierProvider, (previous, next) {
      if (next is AsyncError && mounted) {
        setState(() {
          _isLoading = false;
          _stopWait();
          _localError = false;
          _errorMessage =
              next.error.toString().replaceAll('Exception:', '').trim();
        });
      }
    });

    final tokens = ref.watch(layoutTokensProvider);
    final config = ref.watch(configurationProvider).providerConfig;
    final theme = tokens.themeData(base: Theme.of(context));
    final t = theme.extension<VibeTokens>()!;
    final name = config?.name.trim() ?? '';

    // Entrada: faixa da marca (logo, promessa e ondas de sinal) e, por cima,
    // a folha com o CPF ou CNPJ e o botão, ao alcance do polegar. A tela
    // ocupa a altura toda; com o teclado aberto ela rola.
    final onBrandDark =
        ThemeData.estimateBrightnessForColor(t.ac) == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Theme(
      data: theme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: onBrandDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: t.bg,
          // Ocupa a altura toda quando cabe; em tela baixa (paisagem, fonte
          // grande ou teclado aberto) o conteúdo rola em vez de estourar.
          body: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _brandHero(t, name, config)),
                      ColoredBox(
                        color: t.ac,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, child) => Transform.translate(
                              offset: Offset(0, (1 - v) * 14), child: child),
                          child: _sheet(t, name, config),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Faixa da marca: logo, promessa do app e ondas de sinal ao fundo.
  Widget _brandHero(VibeTokens t, String name, ProviderConfig? config) {
    // Em tela larga a coluna fica com 440 de largura pela margem (e não por
    // um ConstrainedBox): assim a altura medida vale para a largura real.
    final side =
        ((MediaQuery.sizeOf(context).width - 440) / 2).clamp(22.0, 4000.0);
    return SizedBox(
      child: ClipRect(
        child: CustomPaint(
          painter: _SignalPainter(t.ac, t.on),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(side, 20, side, 26),
              child: SizedBox(
                child: SizedBox(
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Altura fixa: a logo carrega depois e não informa
                        // a própria altura na medição da tela.
                        SizedBox(
                          height: 44,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: VibeLogo(
                                name: name.isEmpty ? 'Central' : name,
                                logoUrl: config?.config.logoUrl,
                                onBrand: true,
                                height: 40),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 20),
                        Text('Sua internet,\nna palma da mão.',
                            style: vibeText(t, 29, 800,
                                color: t.on,
                                height: 1.12,
                                letterSpacingEm: -.03)),
                        const SizedBox(height: 10),
                        Text('Faturas, Wi-Fi e suporte em um só lugar.',
                            style: vibeText(t, 14.5, 500,
                                color: t.on.withValues(alpha: .78),
                                height: 1.4)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Folha de entrada: documento, botão e o que há dentro do app.
  Widget _sheet(VibeTokens t, String name, ProviderConfig? config) {
    final side =
        ((MediaQuery.sizeOf(context).width - 440) / 2).clamp(22.0, 4000.0);
    return Container(
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(side, 26, side, 14),
          child: SizedBox(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text('Acesse sua conta',
                        style: vibeText(t, 21, 800, letterSpacingEm: -.02)),
                  ),
                  const SizedBox(height: 6),
                  Text('Digite o CPF ou CNPJ do titular do contrato.',
                      style: vibeText(t, 14, 500, color: t.mut, height: 1.45)),
                  const SizedBox(height: 18),
                  _cpfField(t),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    VibeErrorLine(_errorMessage!),
                  ],
                  const SizedBox(height: 14),
                  VibePageButton(
                    label: _isLoading
                        ? 'Entrando…'
                        : _errorMessage != null && !_localError
                            ? 'Tentar novamente'
                            : 'Entrar',
                    loading: _isLoading,
                    onPressed: _isLoading ? null : () => _handleLogin(config),
                  ),
                  // O provedor pode levar alguns segundos para responder: a
                  // espera ganha explicação em vez de um botão parado.
                  VibeReveal(
                    child: _isLoading && _waitStage > 0
                        ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                  _waitStage == 1
                                      ? 'Consultando seu cadastro no provedor… isso pode levar alguns segundos.'
                                      : 'Quase lá. A resposta do provedor está mais lenta que o normal.',
                                  textAlign: TextAlign.center,
                                  style: vibeText(t, 13, 600,
                                      color: t.mut, height: 1.45)),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  const SizedBox(height: 22),
                  Row(children: [
                    Expanded(child: _feature(t, 'i-pix', 'Faturas e PIX')),
                    const SizedBox(width: 10),
                    Expanded(child: _feature(t, 'wifi', 'Sua conexão')),
                    const SizedBox(width: 10),
                    Expanded(child: _feature(t, 'chat', 'Suporte')),
                  ]),
                  const SizedBox(height: 18),
                  Text(
                      name.isEmpty
                          ? 'Não conseguiu entrar? Fale com o seu provedor.'
                          : 'Não conseguiu entrar? Fale com a $name.',
                      textAlign: TextAlign.center,
                      style: vibeText(t, 12.5, 500, color: t.mut, height: 1.5)),
                  if (config?.privacyPolicyUrl.isNotEmpty == true)
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            openExternalLink(context, config!.privacyPolicyUrl),
                        style: TextButton.styleFrom(
                            foregroundColor: t.mut,
                            minimumSize: const Size(48, 44)),
                        child: Text('Política de privacidade',
                            style: vibeText(t, 12.5, 650, color: t.mut)
                                .copyWith(
                                    decoration: TextDecoration.underline)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Um dos três atalhos do que o assinante encontra depois de entrar.
  Widget _feature(VibeTokens t, String icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.line),
      ),
      child: Column(children: [
        VibeIcon(icon, size: 20, color: t.at),
        const SizedBox(height: 7),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: vibeText(t, 11.5, 650, color: t.mut)),
      ]),
    );
  }

  /// Campo do documento (`.g-in`): ícone, borda de 1,5 e foco na cor da marca.
  Widget _cpfField(VibeTokens t) {
    return AnimatedBuilder(
      animation: _focus,
      builder: (context, _) => Container(
        height: 54,
        padding: const EdgeInsets.only(left: 16, right: 6),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _focus.hasFocus ? t.ac : t.line,
              width: _focus.hasFocus ? 2 : 1.5),
        ),
        child: Row(children: [
          VibeIcon('user', size: 18, color: t.mut),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _cpfController,
              focusNode: _focus,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.go,
              inputFormatters: [CpfCnpjInputFormatter()],
              style: vibeText(t, 16, 600),
              decoration: InputDecoration(
                filled: false,
                isCollapsed: true,
                hintText: 'CPF ou CNPJ',
                hintStyle: vibeText(t, 16, 500, color: t.mut),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onChanged: (_) {
                if (_localError) {
                  setState(() {
                    _localError = false;
                    _errorMessage = null;
                  });
                }
              },
              onSubmitted: (_) {
                if (!_isLoading) {
                  _handleLogin(ref.read(configurationProvider).providerConfig);
                }
              },
            ),
          ),
        ]),
      ),
    );
  }
}

/// Ondas de sinal saindo do canto superior direito da faixa da marca.
class _SignalPainter extends CustomPainter {
  const _SignalPainter(this.background, this.color);

  final Color background, color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final center = Offset(size.width + 10, -10);
    for (var i = 0; i < 5; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..color = color.withValues(alpha: .085 - i * .014);
      canvas.drawCircle(center, 70.0 + i * 62, paint);
    }
  }

  @override
  bool shouldRepaint(_SignalPainter old) =>
      old.color != color || old.background != background;
}

/// Confere o CPF ou CNPJ antes de ir ao provedor (tamanho e dígitos
/// verificadores). `null` quando está certo.
String? validateDocument(String input) {
  final d = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.isEmpty) return 'Por favor, digite seu CPF ou CNPJ.';
  if (d.length < 11) return 'CPF incompleto. Confira os 11 números.';
  if (d.length == 11) {
    return _validCpf(d) ? null : 'CPF inválido. Confira os números.';
  }
  if (d.length < 14) return 'CNPJ incompleto. Confira os 14 números.';
  return _validCnpj(d) ? null : 'CNPJ inválido. Confira os números.';
}

/// O aviso de [validateDocument] pode estar errado (documento com dígito
/// verificador inválido no cadastro do ERP): vale para 11 números ou mais.
bool isSoftDocumentWarning(String input) =>
    input.replaceAll(RegExp(r'[^0-9]'), '').length >= 11 &&
    validateDocument(input) != null;

bool _validCpf(String d) {
  if (RegExp(r'^(\d)\1{10}$').hasMatch(d)) return false;
  int digit(int len) {
    var sum = 0;
    for (var i = 0; i < len; i++) {
      sum += int.parse(d[i]) * (len + 1 - i);
    }
    final r = (sum * 10) % 11;
    return r == 10 ? 0 : r;
  }

  return digit(9) == int.parse(d[9]) && digit(10) == int.parse(d[10]);
}

bool _validCnpj(String d) {
  if (RegExp(r'^(\d)\1{13}$').hasMatch(d)) return false;
  int digit(List<int> weights) {
    var sum = 0;
    for (var i = 0; i < weights.length; i++) {
      sum += int.parse(d[i]) * weights[i];
    }
    final r = sum % 11;
    return r < 2 ? 0 : 11 - r;
  }

  const w1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  const w2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  return digit(w1) == int.parse(d[12]) && digit(w2) == int.parse(d[13]);
}

/// Máscara de CPF (000.000.000-00) ou CNPJ (00.000.000/0000-00) enquanto o
/// assinante digita. A API recebe só os dígitos. O cursor fica depois do
/// mesmo dígito em que estava (corrigir um número no meio não o joga para
/// o fim).
class CpfCnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final cursor = newValue.selection.isValid
        ? newValue.selection.extentOffset.clamp(0, newValue.text.length)
        : newValue.text.length;
    final digitsBefore = newValue.text
        .substring(0, cursor)
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;
    final capped = digits.length > 14 ? digits.substring(0, 14) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (capped.length <= 11) {
        if (i == 3 || i == 6) buffer.write('.');
        if (i == 9) buffer.write('-');
      } else {
        if (i == 2 || i == 5) buffer.write('.');
        if (i == 8) buffer.write('/');
        if (i == 12) buffer.write('-');
      }
      buffer.write(capped[i]);
    }
    final text = buffer.toString();
    var offset = text.length;
    final wanted = digitsBefore.clamp(0, capped.length);
    if (wanted < capped.length) {
      var seen = 0;
      for (var i = 0; i < text.length; i++) {
        if (seen == wanted) {
          offset = i;
          break;
        }
        if (RegExp(r'[0-9]').hasMatch(text[i])) seen++;
      }
      if (wanted == 0) offset = 0;
    }
    return TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: offset));
  }
}
