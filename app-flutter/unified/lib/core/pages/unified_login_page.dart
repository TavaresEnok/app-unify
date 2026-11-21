import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/provider_config.dart';
import '../models/usuario.dart';
import '../providers/providers.dart';
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

  @override
  void dispose() {
    _cpfController.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(ProviderConfig? config) async {
    if (_cpfController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Por favor, digite seu CPF ou CNPJ.');
      return;
    }
    if (config == null) {
      setState(() => _errorMessage = 'Erro de configuração. Tente novamente.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Usuario?>>(authNotifierProvider, (previous, next) {
      if (next is AsyncError && mounted) {
        setState(() {
          _isLoading = false;
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
                            : _errorMessage != null
                                ? 'Tentar novamente'
                                : 'Entrar',
                        onPressed:
                            _isLoading ? null : () => _handleLogin(config),
                      ),
                      const SizedBox(height: 14),
                      Text(
                          name.isEmpty
                              ? 'Dificuldade para entrar? Procure o seu provedor pelos canais de atendimento.'
                              : 'Dificuldade para entrar? Procure a $name pelos canais de atendimento.',
                          textAlign: TextAlign.center,
                          style: vibeText(t, 12.5, 500,
                              color: t.mut, height: 1.5)),
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

/// Máscara de CPF (000.000.000-00) ou CNPJ (00.000.000/0000-00) enquanto o
/// assinante digita. A API recebe só os dígitos.
class CpfCnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
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
    return TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
