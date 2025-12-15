import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/biometric_service.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/color_utils.dart';

/// LoginPage para Layout 07 - Refatorado para usar Riverpod
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _cpfController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final BiometricService _biometricService = BiometricService();
  bool _canUseBiometry = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
    _checkBiometry();
  }

  Future<void> _checkBiometry() async {
    final available = await _biometricService.isAvailable;
    final enabled = await _biometricService.isEnabled;

    if (available && enabled) {
      setState(() => _canUseBiometry = true);
      _handleBiometricLogin();
    }
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({String? overrideCpf}) async {
    if (overrideCpf == null && !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final cpfInput = overrideCpf ?? _cpfController.text;

    try {
      final configProvider = ref.read(configurationProvider);
      final providerConfig = configProvider.providerConfig;
      if (providerConfig == null) throw Exception('Configuração não carregada');

      await ref
          .read(authNotifierProvider.notifier)
          .login(cpfInput, configProvider.providerConfig!);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/painel');
    } on TimeoutException {
      if (mounted) {
        _showErrorDialog('Tempo Esgotado', 'O servidor demorou a responder.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
            'Erro no Login', e.toString().replaceFirst("Exception: ", ""));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBiometricLogin() async {
    final creds = await _biometricService.authenticate();
    if (creds != null) {
      _cpfController.text = creds['cpf']!;
      _handleLogin(overrideCpf: creds['cpf']);
    }
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Ok'),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = ref.watch(configurationProvider);

    if (configProvider.isLoading || configProvider.providerConfig == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final config = configProvider.providerConfig!.config;
    final themeColor = config.themeColor;
    final secondaryColor = config.secondaryColor;
    final logoUrl = config.logoUrl;

    final primaryColor = hexToColor(themeColor);
    final gradientSecondary = secondaryColor != null
        ? hexToColor(secondaryColor)
        : const Color(0xFF9575CD);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, gradientSecondary.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (logoUrl.isNotEmpty)
                      Image.network(
                        logoUrl,
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const SizedBox.shrink(),
                      ),
                    const SizedBox(height: 24),
                    Text('Bem-vindo(a)',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              const Shadow(
                                  blurRadius: 10, color: Colors.black26)
                            ])),
                    const SizedBox(height: 8),
                    Text('Acesse com seu CPF ou CNPJ',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 16, color: Colors.white70)),
                    const SizedBox(height: 48),
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _cpfController,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'CPF / CNPJ',
                          labelStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                          prefixIcon: Icon(Icons.person_outline,
                              color: Colors.white.withValues(alpha: 0.7)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, insira seu CPF ou CNPJ.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    _isLoading
                        ? const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white))
                        : ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 5,
                            ),
                            child: Text('ENTRAR',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                    // BOTÃO BIOMETRIA
                    if (_canUseBiometry && !_isLoading) ...[
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: _handleBiometricLogin,
                        icon: const Icon(Icons.fingerprint,
                            size: 24, color: Colors.white),
                        label: Text("Entrar com Biometria",
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
