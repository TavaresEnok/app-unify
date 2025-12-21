import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/providers/providers.dart';
import '../../core/models/usuario.dart';
import 'theme.dart';

class Layout12LoginPage extends ConsumerStatefulWidget {
  const Layout12LoginPage({super.key});

  @override
  ConsumerState<Layout12LoginPage> createState() => _Layout12LoginPageState();
}

class _Layout12LoginPageState extends ConsumerState<Layout12LoginPage>
    with SingleTickerProviderStateMixin {
  final _cpfController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(seconds: 12),
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
      }
    });

    final config = ref.watch(configurationProvider).providerConfig;

    return Scaffold(
      backgroundColor: Layout12Palette.bg,
      body: Stack(
        children: [
          // Aurora layers
          Positioned(
            top: -120,
            right: -80,
            child: _movingOrb(
              size: 420,
              colors: [
                Layout12Palette.primary.withValues(alpha: 0.35),
                Colors.transparent
              ],
              clockwise: true,
            ),
          ),
          Positioned(
            bottom: -120,
            left: -120,
            child: _movingOrb(
              size: 360,
              colors: [
                Layout12Palette.secondary.withValues(alpha: 0.28),
                Colors.transparent
              ],
              clockwise: false,
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),

                  // Logo
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Layout12Palette.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Layout12Palette.primary.withValues(alpha: 0.35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Layout12Palette.primary.withValues(alpha: 0.15),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: (config?.config.logoUrl != null)
                          ? CachedNetworkImage(
                              imageUrl: config!.config.logoUrl,
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) =>
                                  Image.asset('assets/images/ajust.png'),
                            )
                          : Image.asset('assets/images/ajust.png'),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Bem-vindo',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Layout12Palette.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Acesse sua conta com seu CPF/CNPJ.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Layout12Palette.textSecondary,
                        ),
                  ),

                  const SizedBox(height: 28),

                  TextField(
                    controller: _cpfController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Layout12Palette.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'CPF/CNPJ',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      errorText: _errorMessage,
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Layout12Palette.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Entrar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: _isLoading ? null : () {},
                    child: Text(
                      'Precisa de ajuda? Fale com o suporte.',
                      style: const TextStyle(color: Layout12Palette.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _movingOrb({required double size, required List<Color> colors, required bool clockwise}) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final angle = _animController.value * 6.283 + (clockwise ? 0 : 3.1415);
        return Transform.rotate(angle: angle, child: child);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(colors: colors),
        ),
      ),
    );
  }
}
