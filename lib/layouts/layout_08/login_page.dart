import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/providers/providers.dart';
import '../../core/models/usuario.dart';
import 'theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final _cpfController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _auroraController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _auroraController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _auroraController.dispose();
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
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final secondaryColor = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: Layout08Theme.background,
      body: Stack(
        children: [
          // Animated Aurora Background
          AnimatedBuilder(
            animation: _auroraController,
            builder: (context, child) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: AuroraPainter(
                  animation: _auroraController.value,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                ),
              );
            },
          ),

          // Blur overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(
              color: Layout08Theme.background.withValues(alpha: 0.7),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 80),

                  // Logo with Aurora glow
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Layout08Theme.surface,
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(
                                    alpha: 0.3 + 0.2 * _pulseController.value),
                                blurRadius: 40 + 20 * _pulseController.value,
                                spreadRadius: -10,
                              ),
                              BoxShadow(
                                color: secondaryColor.withValues(
                                    alpha: 0.2 + 0.1 * _pulseController.value),
                                blurRadius: 60,
                                spreadRadius: -15,
                                offset: const Offset(20, 20),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(28),
                          child: config?.config.logoUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: config!.config.logoUrl,
                                  fit: BoxFit.contain,
                                  errorWidget: (context, url, error) =>
                                      Image.asset('assets/images/ajust.png'),
                                )
                              : Image.asset('assets/images/ajust.png'),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 56),

                  // Welcome Text with gradient
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [primaryColor, secondaryColor],
                    ).createShader(bounds),
                    child: const Text(
                      'Bem-vindo',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Acesse sua conta com seu CPF ou CNPJ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Layout08Theme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 56),

                  // Input Card with aurora border
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withValues(alpha: 0.5),
                          secondaryColor.withValues(alpha: 0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Layout08Theme.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CPF / CNPJ',
                            style: TextStyle(
                              color: Layout08Theme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _cpfController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: Layout08Theme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: '000.000.000-00',
                              hintStyle: TextStyle(
                                color: Layout08Theme.textHint,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.only(right: 12),
                                child: Icon(
                                  Icons.badge_outlined,
                                  color: primaryColor,
                                  size: 24,
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(),
                              filled: true,
                              fillColor: Layout08Theme.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Error Message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Layout08Theme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Layout08Theme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Layout08Theme.error, size: 22),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Layout08Theme.error,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 36),

                  // Login Button with aurora gradient
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            _handleLogin();
                          },
                    child: Container(
                      height: 62,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, secondaryColor],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                'Acessar Conta',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Aurora Background Painter
class AuroraPainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color secondaryColor;

  AuroraPainter({
    required this.animation,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Aurora wave 1
    final path1 = Path();
    final wave1Y = size.height * 0.3 + (size.height * 0.1 * _wave(animation));
    path1.moveTo(0, wave1Y);
    path1.quadraticBezierTo(
      size.width * 0.25,
      wave1Y - 100 * _wave(animation + 0.2),
      size.width * 0.5,
      wave1Y,
    );
    path1.quadraticBezierTo(
      size.width * 0.75,
      wave1Y + 80 * _wave(animation + 0.4),
      size.width,
      wave1Y - 50,
    );
    path1.lineTo(size.width, 0);
    path1.lineTo(0, 0);
    path1.close();

    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor.withValues(alpha: 0.4),
        primaryColor.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, wave1Y));
    canvas.drawPath(path1, paint);

    // Aurora wave 2
    final path2 = Path();
    final wave2Y =
        size.height * 0.25 + (size.height * 0.08 * _wave(animation + 0.3));
    path2.moveTo(0, wave2Y + 50);
    path2.cubicTo(
      size.width * 0.3,
      wave2Y - 60 * _wave(animation),
      size.width * 0.6,
      wave2Y + 80 * _wave(animation + 0.5),
      size.width,
      wave2Y,
    );
    path2.lineTo(size.width, 0);
    path2.lineTo(0, 0);
    path2.close();

    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        secondaryColor.withValues(alpha: 0.3),
        secondaryColor.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, wave2Y + 100));
    canvas.drawPath(path2, paint);
  }

  double _wave(double value) {
    return (value * 2 * 3.14159).remainder(2 * 3.14159).abs() < 3.14159
        ? (value * 2 * 3.14159).remainder(3.14159) / 3.14159 * 2 - 1
        : 1 - ((value * 2 * 3.14159).remainder(3.14159) / 3.14159 * 2 - 1);
  }

  @override
  bool shouldRepaint(covariant AuroraPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
