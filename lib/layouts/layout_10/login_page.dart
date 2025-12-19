import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../../core/providers/providers.dart';
import '../../core/models/usuario.dart';
import 'theme.dart';

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
  late AnimationController _meshController;

  @override
  void initState() {
    super.initState();
    _meshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _meshController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final configProvider = ref.read(configurationProvider);
    final config = configProvider.providerConfig;

    if (_cpfController.text.isEmpty) {
      setState(() => _errorMessage = 'Por favor, digite seu CPF/CNPJ');
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
          _errorMessage = 'Falha ao acessar sua conta';
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
    final primaryColor = Layout10Theme.primary(ref.watch(themeProvider).config);
    final secondaryColor = Layout10Theme.secondary(null);

    return Scaffold(
      backgroundColor:
          Layout10Theme.backgroundColor(ref.watch(themeProvider).config),
      body: Stack(
        children: [
          // Mesh Gradient Background
          AnimatedBuilder(
            animation: _meshController,
            builder: (context, child) {
              return CustomPaint(
                painter: MeshGradientPainter(
                  animation: _meshController.value,
                  primary: primaryColor,
                  secondary: secondaryColor,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Glass Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Layout10Theme.glassCard(
                blur: 30,
                opacity: 0.1,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo with subtle glow
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: config?.config.logoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: config!.config.logoUrl,
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) =>
                                  Image.asset('assets/images/ajust.png'),
                            )
                          : Image.asset('assets/images/ajust.png'),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Portal do Cliente',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acesse sua conexão premium',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 48),

                    TextField(
                      controller: _cpfController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: 'C P F   ou   C N P J',
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 14),
                      ),
                    ],

                    const SizedBox(height: 48),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        foregroundColor: primaryColor,
                        shadowColor: Colors.black.withValues(alpha: 0.2),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: primaryColor, strokeWidth: 2),
                            )
                          : const Text('ENTRAR AGORA'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MeshGradientPainter extends CustomPainter {
  final double animation;
  final Color primary;
  final Color secondary;

  MeshGradientPainter(
      {required this.animation,
      required this.primary,
      required this.secondary});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw spots that move
    _drawSpot(
        canvas,
        size,
        Offset(size.width * (0.3 + 0.2 * math.sin(animation * 2 * math.pi)),
            size.height * (0.2 + 0.2 * math.cos(animation * 2 * math.pi))),
        primary.withValues(alpha: 0.3),
        size.width * 0.8);

    _drawSpot(
        canvas,
        size,
        Offset(size.width * (0.7 + 0.2 * math.cos(animation * 2 * math.pi)),
            size.height * (0.8 + 0.1 * math.sin(animation * 2 * math.pi))),
        secondary.withValues(alpha: 0.2),
        size.width * 0.7);

    _drawSpot(
        canvas,
        size,
        Offset(size.width * (0.1 + 0.1 * math.sin(animation * 3 * math.pi)),
            size.height * (0.6 + 0.2 * math.cos(animation * 3 * math.pi))),
        primary.withValues(alpha: 0.15),
        size.width * 0.5);
  }

  void _drawSpot(
      Canvas canvas, Size size, Offset center, Color color, double radius) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
