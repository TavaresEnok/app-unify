import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/provider_config.dart';
import '../models/usuario.dart';
import '../providers/providers.dart';
import '../theme/layout_tokens.dart';

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
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _cpfController.dispose();
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
          .login(_cpfController.text.trim(), config);
      // Sucesso: o AuthGate navega automaticamente.
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'CPF não encontrado ou erro de conexão.');
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

    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _logo(tokens, config),
                  const SizedBox(height: 40),
                  Text(
                    'Bem-vindo de volta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Acesse sua área de cliente para gerenciar faturas e serviços.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: tokens.textSecondary),
                  ),
                  const SizedBox(height: 40),
                  _label('CPF / CNPJ', tokens),
                  const SizedBox(height: 8),
                  _cpfField(tokens),
                  const SizedBox(height: 24),
                  _loginButton(tokens, config),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    _errorBox(tokens, _errorMessage!),
                  ],
                  const SizedBox(height: 36),
                  Text(
                    'Precisa de ajuda? Fale com o suporte do seu provedor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: tokens.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo(LayoutTokens tokens, ProviderConfig? config) {
    final logoUrl = config?.config.logoUrl ?? '';
    return Center(
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          color: tokens.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: logoUrl.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Image.network(
                  logoUrl,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.wifi, size: 40, color: tokens.primary),
                ),
              )
            : Icon(Icons.wifi, size: 40, color: tokens.primary),
      ),
    );
  }

  Widget _label(String text, LayoutTokens tokens) => Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: tokens.textPrimary,
        ),
      );

  Widget _cpfField(LayoutTokens tokens) {
    final fieldColor = tokens.isNeumorphic
        ? tokens.background
        : (tokens.isDark ? tokens.card : Colors.white);
    return Container(
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(tokens.radius),
        border: Border.all(color: tokens.border),
      ),
      child: TextField(
        controller: _cpfController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: tokens.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: '000.000.000-00',
          hintStyle: TextStyle(color: tokens.textSecondary.withValues(alpha: 0.6)),
          prefixIcon: Icon(Icons.person_outline_rounded, color: tokens.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
        onSubmitted: (_) {
          if (!_isLoading) {
            _handleLogin(ref.read(configurationProvider).providerConfig);
          }
        },
      ),
    );
  }

  Widget _loginButton(LayoutTokens tokens, ProviderConfig? config) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _handleLogin(config),
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radius),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text('Acessar conta',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _errorBox(LayoutTokens tokens, String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: tokens.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: tokens.error, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
