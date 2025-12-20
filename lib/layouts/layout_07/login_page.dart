import 'package:flutter/material.dart';

import 'theme.dart';

/// Página de login simplificada para o layout 07.
///
/// Aceita um callback opcional [onLogin] que será chamado com o CPF/CNPJ
/// digitado. Também aceita um [onBiometricLogin] opcional para autenticação
/// biométrica.
class LoginPage extends StatefulWidget {
  final Future<void> Function(String cpf)? onLogin;
  final VoidCallback? onBiometricLogin;

  const LoginPage({
    super.key,
    this.onLogin,
    this.onBiometricLogin,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _cpfController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho gradiente
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                gradient: Layout07Theme.headerGradient(),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wb_sunny_rounded,
                          size: 60, color: Colors.white.withOpacity(0.9)),
                      const SizedBox(height: 16),
                      Text(
                        'Bem‑vindo',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Insira seu CPF/CNPJ',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Layout07Theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cpfController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Layout07Theme.cardBackground,
                      hintText: '000.000.000-00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Layout07Theme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                      shadowColor: Layout07Theme.accent.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final cpf = _cpfController.text.trim();
                            if (cpf.isEmpty) return;
                            setState(() {
                              _isLoading = true;
                            });
                            if (widget.onLogin != null) {
                              await widget.onLogin!(cpf);
                            }
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          },
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Entrar',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 24),
                  if (widget.onBiometricLogin != null)
                    OutlinedButton.icon(
                      onPressed: widget.onBiometricLogin,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Entrar com biometria'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Layout07Theme.accent,
                        side: BorderSide(color: Layout07Theme.accent),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
