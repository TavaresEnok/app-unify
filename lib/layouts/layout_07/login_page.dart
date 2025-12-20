import 'package:flutter/material.dart';

import 'theme.dart';
import 'wave_clipper.dart';

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
            // Cabeçalho gradiente com onda
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  gradient: Layout07Theme.headerGradient(),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wb_sunny_rounded,
                          size: 64, color: Colors.white.withValues(alpha: 0.9)),
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
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            const BorderSide(color: Layout07Theme.accent),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
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
                            if (!mounted) return;
                            setState(() {
                              _isLoading = false;
                            });
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
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 24),
                  if (widget.onBiometricLogin != null)
                    OutlinedButton.icon(
                      onPressed: widget.onBiometricLogin,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Entrar com biometria'),
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
