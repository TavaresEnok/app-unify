import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/biometric_service.dart';
import '../../core/providers/configuration_provider.dart';
import 'theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();

  bool _isLoading = false;
  final BiometricService _biometricService = BiometricService();
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    // No saved CPF loading in current auth service?
    // We can implement it if needed, but sticking to basics first.
  }

  Future<void> _checkBiometrics() async {
    final available = await _biometricService.isAvailable;
    final enabled = await _biometricService.isEnabled;
    if (mounted) {
      setState(() => _canCheckBiometrics = available && enabled);
    }
    if (available && enabled) {
      // Optional: Auto-trigger biometrics
      // _loginWithBiometrics();
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final configProvider = context.read<ConfigurationProvider>();

      if (configProvider.providerConfig == null) {
        throw Exception("Configuração não carregada.");
      }

      // Using performLogin which handles the specific API flow (CPF only)
      await authService.performLogin(
        _cpfController.text,
        configProvider.providerConfig!,
      );

      // Navigation is handled by auth state changes in main/wrapper,
      // but if we need to force it:
      // Navigator.of(context).pushReplacementNamed('/painel');
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $msg'),
            backgroundColor: Layout04Theme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithBiometrics() async {
    final creds = await _biometricService.authenticate();
    if (creds != null && creds['cpf'] != null) {
      _cpfController.text = creds['cpf']!;
      _login();
    }
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<ConfigurationProvider>();
    final config = configProvider.providerConfig?.config;
    final logoUrl = config?.logoUrl;
    final quote = config?.loginQuote ?? 'Bem-vindo de volta';

    return Scaffold(
      backgroundColor: Layout04Theme.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- LOGO AREA ---
                  if (logoUrl != null && logoUrl.isNotEmpty)
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        height: 100,
                        margin: const EdgeInsets.only(bottom: 32),
                        child: Image.network(
                          logoUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.wifi_tethering,
                                  size: 80, color: Layout04Theme.primary),
                        ),
                      ),
                    )
                  else
                    const Icon(Icons.wifi_tethering,
                        size: 80, color: Layout04Theme.primary),

                  const SizedBox(height: 24),

                  // --- WELCOME TEXT ---
                  Text(
                    quote,
                    style: Layout04Theme.heading2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Digite seu CPF/CNPJ para acessar',
                    style: Layout04Theme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // --- FORM ---
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _cpfController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: Layout04Theme.inputDecoration(
                            'CPF / CNPJ',
                            icon: Icons.person_outline_rounded,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira seu CPF ou CNPJ';
                            }
                            return null;
                          },
                        ),
                        // Password field removed as per AuthService flow

                        const SizedBox(height: 32),

                        // --- LOGIN BUTTON ---
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: Layout04Theme.primaryButtonStyle,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Text('ENTRAR'),
                          ),
                        ),

                        // --- BIOMETRICS ---
                        if (_canCheckBiometrics) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: _loginWithBiometrics,
                              style: Layout04Theme.outlineButtonStyle,
                              icon: const Icon(Icons.fingerprint_rounded,
                                  size: 24),
                              label: const Text('Entrar com Biometria'),
                            ),
                          ),
                        ],
                      ],
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
}
