import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/models/provider_config.dart';
import '../../core/models/usuario.dart';
import 'theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _cpfController = TextEditingController();
  bool _isLoading = false;
  String? _localErrorMessage;

  // Animation constants
  // static const Duration _animDuration = Duration(milliseconds: 800);

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(ProviderConfig? config) async {
    if (_cpfController.text.isEmpty) {
      setState(() => _localErrorMessage = 'Por favor, digite seu CPF ou CNPJ');
      return;
    }
    if (config == null) {
      setState(
          () => _localErrorMessage = 'Erro de configuração. Tente novamente.');
      return;
    }

    setState(() {
      _isLoading = true;
      _localErrorMessage = null;
    });

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .login(_cpfController.text.trim(), config);
      // Sucesso navega automaticamente via AuthGate
    } catch (e) {
      if (mounted) {
        setState(() =>
            _localErrorMessage = 'CPF não encontrado ou erro de conexão.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Monitora erros de autenticação via AsyncValue
    ref.listen<AsyncValue<Usuario?>>(authNotifierProvider, (previous, next) {
      if (next is AsyncError) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _localErrorMessage = next.error
                .toString()
                .replaceAll('Exception:', '')
                .trim();
          });
        }
      }
    });

    // Config via Riverpod
    final configProvider = ref.watch(configurationProvider);
    final config = configProvider.providerConfig;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox.expand(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // 1. Logo Section
                Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Layout03Theme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: config?.config.logoUrl != null
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Image.network(config!.config.logoUrl),
                          )
                        : const Icon(Icons.wifi,
                            size: 40, color: Layout03Theme.primary),
                  ),
                ),

                const SizedBox(height: 48),

                // 2. Welcome Text
                Text(
                  'Bem-vindo de volta',
                  style: Layout03Theme.heading1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Acesse sua área de cliente para gerenciar suas faturas e serviços.',
                  style: Layout03Theme.bodyText
                      .copyWith(color: Layout03Theme.textGrey),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                // 3. Input Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CPF / CNPJ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Layout03Theme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Layout03Theme.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: TextField(
                        controller: _cpfController,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Layout03Theme.textDark),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '000.000.000-00',
                          hintStyle: TextStyle(
                              color: Layout03Theme.textGrey
                                  .withValues(alpha: 0.5)),
                          prefixIcon: const Icon(Icons.person_outline_rounded,
                              color: Layout03Theme.textGrey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(20),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 4. Action Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleLogin(config),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Layout03Theme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Acessar Conta',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                Center(
                  child: IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Funcionalidade Bio-Login em breve!'),
                            backgroundColor: Layout03Theme.textGrey),
                      );
                    },
                    icon: const Icon(Icons.fingerprint,
                        size: 40, color: Layout03Theme.primary),
                    tooltip: 'Entrar com Biometria',
                  ),
                ),

                // 5. Error Feedback
                if (_localErrorMessage != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Layout03Theme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Layout03Theme.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _localErrorMessage!,
                            style: const TextStyle(
                                color: Layout03Theme.error,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Precisa de ajuda? ', style: Layout03Theme.bodyText),
                    GestureDetector(
                      onTap: () {
                        // TODO: Implementar ação de ajuda se necessário
                      },
                      child: const Text(
                        'Fale com o suporte',
                        style: TextStyle(
                          color: Layout03Theme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
