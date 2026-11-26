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

    // Entrada (`PG.login` do layout aprovado): marca, título, o campo de
    // CPF ou CNPJ e o botão. A central do assinante entra só pelo documento.
    return Theme(
      data: theme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: t.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: t.bg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 34),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: VibeLogo(
                            name: name.isEmpty ? 'Central' : name,
                            logoUrl: config?.config.logoUrl,
                            height: 44),
                      ),
                      const SizedBox(height: 30),
                      Semantics(
                        header: true,
                        child: Text('Entrar',
                            style: vibeText(t, 24, 800, letterSpacingEm: -.02)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                          'Use o CPF ou CNPJ do titular para acessar a Central do Assinante.',
                          style: vibeText(t, 14.5, 500,
                              color: t.mut, height: 1.5)),
                      const SizedBox(height: 20),
                      Text('CPF ou CNPJ', style: vibeText(t, 13, 650)),
                      const SizedBox(height: 6),
                      _cpfField(t),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
                        VibeErrorLine(_errorMessage!),
                      ],
                      const SizedBox(height: 24),
                      VibePageButton(
                        label: _isLoading
                            ? 'Entrando…'
                            : _errorMessage != null && !_localError
                                ? 'Tentar novamente'
                                : 'Entrar',
                        loading: _isLoading,
                        onPressed:
                            _isLoading ? null : () => _handleLogin(config),
                      ),
                      // O provedor pode levar alguns segundos para
                      // responder: a espera ganha explicação em vez de um
                      // botão parado.
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
                      const SizedBox(height: 14),
                      Text(
                          name.isEmpty
                              ? 'Dificuldade para entrar? Procure o seu provedor pelos canais de atendimento.'
                              : 'Dificuldade para entrar? Procure a $name pelos canais de atendimento.',
                          textAlign: TextAlign.center,
                          style: vibeText(t, 12.5, 500,
                              color: t.mut, height: 1.5)),
                      if (config?.privacyPolicyUrl.isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton(
                            onPressed: () => openExternalLink(
                                context, config!.privacyPolicyUrl),
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

  /// Campo do documento (`.g-in`): ícone, borda de 1,5 e foco na cor da marca.
  Widget _cpfField(VibeTokens t) {
    return AnimatedBuilder(
      animation: _focus,
      builder: (context, _) => Container(
        height: 48,
        padding: const EdgeInsets.only(left: 14, right: 6),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _focus.hasFocus ? t.ac : t.line,
              width: _focus.hasFocus ? 2 : 1.5),
        ),
        child: Row(children: [
          VibeIcon('user', size: 16, color: t.mut),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _cpfController,
              focusNode: _focus,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.go,
              inputFormatters: [CpfCnpjInputFormatter()],
              style: vibeText(t, 15, 500),
              decoration: InputDecoration(
                filled: false,
                isCollapsed: true,
                hintText: '000.000.000-00',
                hintStyle: vibeText(t, 15, 500, color: t.mut),
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
