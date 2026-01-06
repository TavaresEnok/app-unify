import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/providers.dart';
import '../../core/models/usuario.dart';
import 'theme.dart';

/// Layout 02 - NetLink Premium Login Page
/// Design moderno com gradiente azul/cyan - APENAS CPF/CNPJ (sem senha)
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
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _animController.dispose();
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
    // Listen to Auth State changes
    ref.listen<AsyncValue<Usuario?>>(authNotifierProvider, (previous, next) {
      if (next is AsyncError) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'CPF/CNPJ não encontrado. Verifique e tente novamente.';
        });
      } else if (next is AsyncData && next.value != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
        // A navegação para o PainelPage é feita automaticamente pelo AuthGate
        // quando authNotifierProvider.value != null
      }
    });

    final config = ref.watch(configurationProvider).providerConfig;
    final providerName = config?.name ?? 'Provedor';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Layout02Theme.primary,
              Layout02Theme.primaryDark,
              Color(0xFF002966),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  _buildLogo(config?.config.logoUrl),
                  const SizedBox(height: 20),
                  _buildWelcomeText(providerName),
                  const SizedBox(height: 50),
                  _buildLoginCard(),
                  const SizedBox(height: 30),
                  _buildFooter(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(String? logoUrl) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Layout02Theme.secondary.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: logoUrl != null
            ? CachedNetworkImage(
                imageUrl: logoUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Icon(
                  Icons.wifi_rounded,
                  size: 50,
                  color: Colors.white,
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.wifi_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.wifi_rounded,
                size: 50,
                color: Colors.white,
              ),
      ),
    );
  }

  Widget _buildWelcomeText(String providerName) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Layout02Theme.secondary],
          ).createShader(bounds),
          child: Text(
            providerName,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Acesse sua conta',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Entrar',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Layout02Theme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Digite seu CPF ou CNPJ para acessar',
            style: TextStyle(
              fontSize: 14,
              color: Layout02Theme.textGrey.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 28),

          // Campo CPF/CNPJ
          TextFormField(
            controller: _cpfController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 18,
              color: Layout02Theme.textDark,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: 'CPF ou CNPJ',
              hintText: '000.000.000-00',
              labelStyle: TextStyle(
                color: Layout02Theme.textGrey.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              hintStyle: TextStyle(
                color: Layout02Theme.textGrey.withOpacity(0.5),
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 16, right: 12),
                child: const Icon(Icons.person_rounded,
                    color: Layout02Theme.primary, size: 24),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: Layout02Theme.greyLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Layout02Theme.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Layout02Theme.red, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),

          // Mensagem de Erro
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Layout02Theme.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Layout02Theme.red, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Layout02Theme.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLogin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: _isLoading
              ? LinearGradient(
                  colors: [
                    Layout02Theme.grey,
                    Layout02Theme.grey.withOpacity(0.8)
                  ],
                )
              : Layout02Theme.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _isLoading
              ? null
              : [
                  BoxShadow(
                    color: Layout02Theme.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) ...[
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              _isLoading ? 'Entrando...' : 'Entrar',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (!_isLoading) ...[
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 22),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Precisa de ajuda?',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => HapticFeedback.lightImpact(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.headset_mic_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Falar com Suporte',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
