import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/login_config.dart';
import '../../shared/theme/app_colors.dart';

/// Tela de login estilo Minimal (apenas formulário, sem distrações)
class LoginMinimal extends StatefulWidget {
  final LoginConfig? config;
  final Function(String, String) onLogin;

  const LoginMinimal({
    super.key,
    this.config,
    required this.onLogin,
  });

  @override
  State<LoginMinimal> createState() => _LoginMinimalState();
}

class _LoginMinimalState extends State<LoginMinimal> {
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

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
    final formConfig = widget.config?.form;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título minimalista
                  if (formConfig?.showWelcomeText ?? true)
                    Text(
                      formConfig?.welcomeText ?? 'Login',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                  const SizedBox(height: 48),

                  // Campo CPF
                  TextField(
                    controller: _cpfController,
                    decoration: InputDecoration(
                      labelText: formConfig?.placeholderCPF ?? 'CPF ou CNPJ',
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF4F46E5), width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),

                  // Campo Senha
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: formConfig?.placeholderPassword ?? 'Senha',
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF4F46E5), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Botão Login minimalista
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              formConfig?.buttonText ?? 'ENTRAR',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
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

  @override
  void dispose() {
    _cpfController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
