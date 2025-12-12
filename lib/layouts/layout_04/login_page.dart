import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/biometric_service.dart';
import '../../core/providers/configuration_provider.dart';
import 'theme.dart';

/// LoginPage para Layout 04 - Cyber Wave
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
  late Animation<double> _scaleAnimation;

  final BiometricService _biometricService = BiometricService();
  bool _canUseBiometry = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
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
        _showErrorDialog(
            'Tempo Esgotado', 'O servidor demorou muito para responder.');
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
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Layout04Theme.backgroundLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Layout04Theme.glassBorder, width: 1),
          ),
          title: Text(title, style: Layout04Theme.heading3),
          content: Text(message, style: Layout04Theme.bodyMedium),
          actions: <Widget>[
            TextButton(
              child: Text(
                'ENTENDIDO',
                style: Layout04Theme.buttonText.copyWith(
                  color: Layout04Theme.primaryCyan,
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigurationProvider>(context);

    if (configProvider.isLoading || configProvider.providerConfig == null) {
      return Scaffold(
        backgroundColor: Layout04Theme.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(Layout04Theme.primaryCyan),
          ),
        ),
      );
    }

    final config = configProvider.providerConfig!.config;
    final logoUrl = config.logoUrl;
    final loginQuote = config.loginQuote;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration:
            const BoxDecoration(gradient: Layout04Theme.backgroundGradient),
        child: Stack(
          children: [
            // Animated background particles/circles
            ...List.generate(5, (index) {
              return Positioned(
                top: (index * 150.0) % MediaQuery.of(context).size.height,
                left: (index * 100.0) % MediaQuery.of(context).size.width,
                child: TweenAnimationBuilder<double>(
                  duration: Duration(seconds: 3 + index),
                  tween: Tween(begin: 0, end: 1),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: 0.1,
                      child: Container(
                        width: 100 + (index * 20),
                        height: 100 + (index * 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: index % 2 == 0
                              ? Layout04Theme.primaryGradient
                              : Layout04Theme.secondaryGradient,
                        ),
                      ),
                    );
                  },
                  onEnd: () {
                    setState(() {}); // Restart animation
                  },
                ),
              );
            }),
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: _buildGlassCard(logoUrl, loginQuote),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard(String logoUrl, String loginQuote) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: Layout04Theme.glassCard(borderRadius: 24),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              if (logoUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: logoUrl,
                  height: 80,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(height: 80),
                  errorWidget: (context, url, error) => Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      gradient: Layout04Theme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_tethering,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 40),
              // Title with gradient
              ShaderMask(
                shaderCallback: (bounds) =>
                    Layout04Theme.accentGradient.createShader(bounds),
                child: Text(
                  'Bem-vindo',
                  style: Layout04Theme.heading1.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loginQuote,
                textAlign: TextAlign.center,
                style: Layout04Theme.bodyMedium,
              ),
              const SizedBox(height: 40),
              // CPF Input
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _cpfController,
                  textAlign: TextAlign.center,
                  style: Layout04Theme.bodyLarge.copyWith(
                    letterSpacing: 1.5,
                    fontSize: 18,
                  ),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'CPF ou CNPJ',
                    hintStyle: Layout04Theme.bodyMedium.copyWith(
                      color: Layout04Theme.textTertiary,
                    ),
                    filled: true,
                    fillColor: Layout04Theme.glassWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Layout04Theme.glassBorder,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Layout04Theme.glassBorder,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Layout04Theme.primaryCyan,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: Layout04Theme.primaryCyan,
                      size: 24,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe seu documento';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 28),
              // Login Button with Neon Glow
              SizedBox(
                width: double.infinity,
                height: 56,
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Layout04Theme.primaryCyan,
                          ),
                        ),
                      )
                    : Container(
                        decoration: Layout04Theme.neonButton(),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _handleLogin,
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: Text(
                                'ENTRAR',
                                style: Layout04Theme.buttonText,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              // Biometric Button
              if (_canUseBiometry && !_isLoading) ...[
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: _handleBiometricLogin,
                  icon: Icon(
                    Icons.fingerprint_rounded,
                    size: 28,
                    color: Layout04Theme.primaryPink,
                  ),
                  label: Text(
                    'Entrar com Biometria',
                    style: Layout04Theme.bodyLarge.copyWith(
                      color: Layout04Theme.primaryPink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
