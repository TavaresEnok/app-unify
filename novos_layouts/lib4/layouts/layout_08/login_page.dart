import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../../core/providers/providers.dart';
import '../../core/models/usuario.dart'; // Import Usuario explicitly
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

  // Animation
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
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
      HapticFeedback.vibrate(); // Error Haptic
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

    // Just trigger the login. The listener in build() handles success/error.
    await ref.read(authNotifierProvider.notifier).login(
          _cpfController.text.trim(),
          config,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to Auth State changes for Navigation and Error Handling
    ref.listen<AsyncValue<Usuario?>>(authNotifierProvider, (previous, next) {
      if (next is AsyncError) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Falha no login: ${next.error.toString().replaceAll('Exception:', '').trim()}';
        });
      } else if (next is AsyncData && next.value != null) {
        // Login Success
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
        // Navigate to Dashboard (PainelPage is wrapper)
        // Ensure we replace the route so user can't go back to login
        Navigator.of(context).pushReplacementNamed('/painel');
      }
    });

    final config = ref.watch(configurationProvider).providerConfig;
    // Using Eco-Minimal palette directly
    const Color primaryGreen = Color(0xFF4CAF50);
    const Color secondaryBlue = Color(0xFF2196F3);
    const Color bgLight = Color(0xFFF0F4F8);
    const Color cardBg = Color(0xFFFFFFFF);
    const Color textDark = Color(0xFF333333);
    const Color textGray = Color(0xFF757575);
    const Color errorRed = Colors.red;

    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          // Background gradient orb 1 (Aurora)
          Positioned(
            top: -150,
            right: -100,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animController.value * 2.0 * 3.14159,
                  child: child,
                );
              },
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryGreen.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Background gradient orb 2 (Aurora Counter-Clockwise)
          Positioned(
            bottom: -100,
            left: -100,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -_animController.value * 2.0 * 3.14159,
                  child: child,
                );
              },
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      secondaryBlue.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  // Logo
                  if (config?.config.logoUrl != null)
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: CachedNetworkImage(
                          imageUrl: config!.config.logoUrl,
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/images/ajust.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/ajust.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                  const SizedBox(height: 60),

                  // Title
                  const Text(
                    'Bem-vindo\nde Volta',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Acesse sua conta para gerenciar\nseus serviços de internet',
                    style: TextStyle(
                      fontSize: 16,
                      color: textGray,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Input Card
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CPF / CNPJ',
                          style: TextStyle(
                            color: textGray,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _cpfController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: '000.000.000-00',
                            hintStyle: TextStyle(
                              color: textGray.withValues(alpha: 0.5),
                            ),
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              color: primaryGreen,
                            ),
                            filled: true,
                            fillColor: cardBg.withValues(alpha: 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryGreen,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Error Message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: errorRed, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: errorRed,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Login Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              _handleLogin();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors
                            .black, // Keep text black for contrast on bright primary
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Entrar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
