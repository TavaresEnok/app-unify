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
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).cardColor;
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final errorColor = Theme.of(context).colorScheme.error;

    return Scaffold(
      backgroundColor: backgroundColor,
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
                  gradient: SweepGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.15),
                      Colors.transparent,
                      primaryColor.withValues(alpha: 0.15),
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
                  gradient: SweepGradient(
                    colors: [
                      secondaryColor.withValues(alpha: 0.1),
                      Colors.transparent,
                      secondaryColor.withValues(alpha: 0.1),
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
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: CachedNetworkImage(
                          imageUrl: config!.config.logoUrl,
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) {
                            return Image.asset(
                              'assets/images/ajust.png',
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: surfaceColor,
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
                  Text(
                    'Bem-vindo\nde Volta',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Acesse sua conta para gerenciar\nseus serviços de internet',
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondary,
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
                        Text(
                          'CPF / CNPJ',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _cpfController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: '000.000.000-00',
                            hintStyle: TextStyle(
                              color: textSecondary.withValues(alpha: 0.5),
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: primaryColor,
                            ),
                            filled: true,
                            fillColor: surfaceColor.withValues(alpha: 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
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
                        color: errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: errorColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: errorColor,
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
                        backgroundColor: primaryColor,
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
