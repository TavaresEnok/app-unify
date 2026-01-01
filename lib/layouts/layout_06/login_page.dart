// Layout 06 Login Page - Clean Dark Theme
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../../core/providers/providers.dart';
import '../../core/models/usuario.dart';
import 'theme.dart';
import 'widgets/glass_card.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _cpfController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final configProvider = ref.read(configurationProvider);
    final config = configProvider.providerConfig;

    if (_cpfController.text.isEmpty) {
      setState(() => _errorMessage = 'Por favor, digite seu CPF/CNPJ');
      HapticFeedback.vibrate();
      return;
    }
    if (config == null) {
      setState(() => _errorMessage = 'Erro de configuração');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await ref.read(authNotifierProvider.notifier).login(
          _cpfController.text.trim(),
          config,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Usuario?>>(authNotifierProvider, (previous, next) {
      if (next is AsyncError) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Falha no login: ${next.error.toString().replaceAll('Exception:', '').trim()}';
        });
      } else if (next is AsyncData && next.value != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
        Navigator.of(context).pushReplacementNamed('/painel');
      }
    });

    final config = ref.watch(configurationProvider).providerConfig;

    return Scaffold(
      backgroundColor: Layout06Theme.background,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  _buildLogo(config),
                  const SizedBox(height: 60),
                  _buildTitle(),
                  const SizedBox(height: 48),
                  _buildLoginForm(),
                  if (_errorMessage != null) _buildErrorMessage(),
                  const SizedBox(height: 32),
                  _buildLoginButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: Layout06Theme.backgroundGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Layout06Theme.primary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Layout06Theme.tertiary.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(dynamic config) {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: Layout06Theme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: Layout06Theme.primary
                      .withOpacity(0.25 + _pulseController.value * 0.15),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: config?.config.logoUrl != null
                ? CachedNetworkImage(
                    imageUrl: config!.config.logoUrl,
                    fit: BoxFit.contain,
                    errorWidget: (context, url, error) => const Icon(
                        Icons.wifi_rounded,
                        color: Colors.white,
                        size: 40),
                  )
                : const Icon(Icons.wifi_rounded, color: Colors.white, size: 40),
          );
        },
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        const Text(
          'Bem-vindo',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const Text(
          'de Volta',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Layout06Theme.primary,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Acesse sua conta para gerenciar\nseus serviços de internet',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.5),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CPF / CNPJ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cpfController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: '000.000.000-00',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
              ),
              prefixIcon: const Icon(
                Icons.person_outline_rounded,
                color: Layout06Theme.primary,
              ),
              filled: true,
              fillColor: Layout06Theme.cardBg.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Layout06Theme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Layout06Theme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Layout06Theme.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                color: Layout06Theme.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Layout06Theme.error,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return GestureDetector(
          onTap: _isLoading
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  _handleLogin();
                },
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: Layout06Theme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Layout06Theme.primary
                      .withOpacity(0.25 + _pulseController.value * 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
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
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
