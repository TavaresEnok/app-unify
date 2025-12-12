import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/login_config.dart';
import '../../shared/theme/app_colors.dart';

/// Tela de login estilo Clássico
class LoginClassic extends StatefulWidget {
  final LoginConfig? config;
  final Function(String, String) onLogin;

  const LoginClassic({
    super.key,
    this.config,
    required this.onLogin,
  });

  @override
  State<LoginClassic> createState() => _LoginClassicState();
}

class _LoginClassicState extends State<LoginClassic> {
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length >= 6 && !hex.contains('ff')) buffer.write('ff');
    buffer.write(hex.replaceAll('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Future<void> _handleLogin() async {
    if (_cpfController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await widget.onLogin(_cpfController.text, _passwordController.text);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final bgConfig = config?.background;
    final logoConfig = config?.logo;
    final formConfig = config?.form;
    final quoteConfig = config?.quote;

    // Background
    final bgColors = bgConfig?.type == 'gradient'
        ? (bgConfig!.colors.map(_hexToColor).toList())
        : [_hexToColor('#1E293B'), _hexToColor('#334155')];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  if (logoConfig?.show ?? true)
                    if (logoConfig?.url != null)
                      Image.network(
                        logoConfig!.url!,
                        height: logoConfig.size == 'large' ? 120 : 80,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                  const SizedBox(height: 48),

                  // Card do formulário
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Título
                        if (formConfig?.showWelcomeText ?? true)
                          Text(
                            formConfig?.welcomeText ?? 'Acesse sua conta',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        const SizedBox(height: 32),

                        // Campo CPF
                        TextField(
                          controller: _cpfController,
                          decoration: InputDecoration(
                            labelText:
                                formConfig?.placeholderCPF ?? 'CPF ou CNPJ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),

                        // Campo Senha
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText:
                                formConfig?.placeholderPassword ?? 'Senha',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Botão Login
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text(
                                    formConfig?.buttonText ?? 'Entrar',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quote
                  if (quoteConfig?.show ?? false) ...[
                    const SizedBox(height: 32),
                    Text(
                      quoteConfig!.text,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
