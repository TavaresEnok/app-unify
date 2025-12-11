import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/biometric_service.dart';
import '../../core/providers/configuration_provider.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_button.dart';

/// LoginPage para Layout 06 - Premium Dark com GlassCard
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
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
      final configProvider = context.read<ConfigurationProvider>();
      final providerConfig = configProvider.providerConfig;
      if (providerConfig == null) throw Exception('Configuração não carregada');

      await context.read<AuthService>().performLogin(cpfInput, providerConfig);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/painel');
    } on TimeoutException {
      if (mounted) {
        _showErrorDialog('Tempo Esgotado', 'O servidor demorou muito para responder.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erro no Login', e.toString().replaceFirst("Exception: ", ""));
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
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.inter(color: Colors.white70)),
        actions: <Widget>[
          TextButton(
            child: const Text('ENTENDIDO'),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigurationProvider>(context);
    final theme = Theme.of(context);

    if (configProvider.isLoading || configProvider.providerConfig == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final config = configProvider.providerConfig!.config;
    final logoUrl = config.logoUrl;
    final loginQuote = config.loginQuote;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // Gradiente moderno e vibrante (Azul Profundo -> Preto)
          gradient: LinearGradient(
            colors: [Color(0xFF050816), Color(0xFF111B2C), Color(0xFF1E2740)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: GlassCard(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (logoUrl.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: logoUrl,
                              height: 80,
                              fit: BoxFit.contain,
                              placeholder: (context, url) =>
                                  const SizedBox(height: 80),
                              errorWidget: (context, url, error) => const Icon(
                                  Icons.wifi_tethering,
                                  size: 60,
                                  color: Colors.white),
                            ),
                          const SizedBox(height: 40),
                          Text('Bem-vindo',
                              style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(height: 8),
                          Text(
                            loginQuote,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.5),
                          ),
                          const SizedBox(height: 40),
                          Form(
                            key: _formKey,
                            child: TextFormField(
                              controller: _cpfController,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  fontSize: 18,
                                  letterSpacing: 1.5,
                                  color: Colors.white),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'CPF ou CNPJ',
                                hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.4)),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.05),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                prefixIcon: const Icon(Icons.person_outline,
                                    color: Colors.white54),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe seu documento';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              label: 'ENTRAR',
                              onPressed: _handleLogin,
                              isLoading: _isLoading,
                            ),
                          ),
                          // BOTÃO BIOMETRIA
                          if (_canUseBiometry && !_isLoading) ...[
                            const SizedBox(height: 20),
                            TextButton.icon(
                              onPressed: _handleBiometricLogin,
                              icon: Icon(Icons.fingerprint,
                                  size: 24, color: theme.primaryColor),
                              label: Text("Entrar com Biometria",
                                  style: TextStyle(
                                      color: theme.primaryColor,
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
          ),
        ),
      ),
    );
  }
}
