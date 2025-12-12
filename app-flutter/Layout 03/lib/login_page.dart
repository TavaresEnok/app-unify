import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/auth_service.dart';
import 'services/biometric_service.dart';
import 'configuration_provider.dart';
import 'shared/theme/app_colors.dart';
import 'utils.dart'; // Importado para hexToColor

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _cpfController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final BiometricService _biometricService = BiometricService();
  bool _canUseBiometry = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();

    _checkBiometry();
  }

  Future<void> _checkBiometry() async {
    final available = await _biometricService.isAvailable;
    final enabled = await _biometricService.isEnabled;

    if (available) {
      setState(() => _canUseBiometry = enabled);
      if (enabled) {
        // Se já estiver habilitado, tenta login direto
        _handleBiometricLogin();
      }
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
      // A lógica de login agora está centralizada no AuthService
      await context.read<AuthService>().performLogin(cpfInput);

      // Se sucesso, navega para o painel
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/painel');
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
            'Erro no Login', e.toString().replaceFirst("Exception: ", ""));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  Future<void> _handleBiometricLogin() async {
    final creds = await _biometricService.authenticate();
    if (creds != null) {
      _cpfController.text = creds['cpf']!; // Preenche visualmente
      _handleLogin(overrideCpf: creds['cpf']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigurationProvider>(context);

    if (configProvider.isLoading || configProvider.providerConfig == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue)),
      );
    }

    final config = configProvider.providerConfig!.config;
    final logoUrl = config.logoUrl;
    final loginQuote = config.loginQuote;

    // --- CORREÇÃO: Obtém a cor customizada dos botões ---
    final actionColor = config.actionColor != null
        ? hexToColor(config.actionColor!) // Added ! force unwrap
        : AppColors.primaryBlue;

    return Scaffold(
      backgroundColor: AppColors.background, // Branco limpo
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO
                    if (logoUrl.isNotEmpty)
                      Hero(
                        tag: 'logo',
                        child: CachedNetworkImage(
                          imageUrl: logoUrl,
                          height: 100,
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              const SizedBox(height: 100),
                          errorWidget: (context, url, error) => const Icon(
                              Icons.wifi_tethering,
                              size: 80,
                              color: AppColors.primaryBlue),
                        ),
                      )
                    else
                      Icon(Icons.wifi_tethering, size: 80, color: actionColor),

                    const SizedBox(height: 32),

                    // TEXTOS
                    Text('Bem-vindo de volta!',
                        style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(
                      loginQuote,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),

                    const SizedBox(height: 40),

                    // FORMULÁRIO
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10))
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _cpfController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'CPF ou CNPJ',
                                hintText: 'Digite apenas números',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade200)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: actionColor, width: 2)),
                                prefixIcon: Icon(Icons.person_outline_rounded,
                                    color: AppColors.textSecondary),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                              ),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                      ? 'Informe seu documento'
                                      : null,
                            ),

                            const SizedBox(height: 16),

                            // Checkbox Biometria
                            Row(
                              children: [
                                Checkbox(
                                    value: _rememberMe,
                                    activeColor:
                                        actionColor, // Usa a cor customizada
                                    onChanged: (val) =>
                                        setState(() => _rememberMe = val!)),
                                Text('Lembrar com Biometria',
                                    style: GoogleFonts.inter(
                                        color: AppColors.textSecondary,
                                        fontSize: 13)),
                              ],
                            ),

                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : () => _handleLogin(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      actionColor, // <--- CORREÇÃO APLICADA AQUI
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : Text('ACESSAR CONTA',
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // BOTÃO BIOMETRIA EXTERNO
                    if (_canUseBiometry && !_isLoading) ...[
                      const SizedBox(height: 32),
                      IconButton(
                        onPressed: _handleBiometricLogin,
                        iconSize: 48,
                        icon:
                            Icon(Icons.fingerprint_rounded, color: actionColor),
                        style: IconButton.styleFrom(
                          backgroundColor: actionColor.withOpacity(0.1),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Toque para entrar',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 12)),
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
