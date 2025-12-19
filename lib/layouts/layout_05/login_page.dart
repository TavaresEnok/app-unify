import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
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
  late AnimationController _blobController;

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final configProvider = ref.read(configurationProvider);
    final config = configProvider.providerConfig;

    if (_cpfController.text.isEmpty) {
      setState(() => _errorMessage = 'Por favor, digite seu CPF/CNPJ');
      HapticFeedback.lightImpact();
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
    final primaryColor = Layout09Theme.primary(ref.watch(themeProvider).config);

    return Scaffold(
      backgroundColor:
          Layout09Theme.backgroundColor(ref.watch(themeProvider).config),
      body: Stack(
        children: [
          // Background Blobs (Organic)
          AnimatedBuilder(
            animation: _blobController,
            builder: (context, child) {
              return CustomPaint(
                painter: BlobBackgroundPainter(
                  animationValue: _blobController.value,
                  color: primaryColor.withValues(alpha: 0.1),
                ),
                size: Size.infinite,
              );
            },
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Logo in a soft circle
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: config?.config.logoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: config!.config.logoUrl,
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) =>
                                  Image.asset('assets/images/ajust.png'),
                            )
                          : Image.asset('assets/images/ajust.png'),
                    ),
                  ),

                  const SizedBox(height: 60),

                  const Text(
                    'Bem-vindo',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Conecte-se aos seus serviços de forma fluida e simples.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 60),

                  // Input Field with soft design
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 8),
                        child: Text(
                          'IDENTIFICAÇÃO:',
                          style: TextStyle(
                            color: primaryColor.withValues(alpha: 0.7),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      TextField(
                        controller: _cpfController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 18),
                        decoration: InputDecoration(
                          hintText: 'Digite seu CPF ou CNPJ',
                          prefixIcon: Icon(Icons.person_pin_rounded,
                              color: primaryColor),
                        ),
                      ),
                    ],
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: Color(0xFFE74C3C), fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // Login Button (Pill shaped)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'ACESSAR CONTA',
                            style: TextStyle(fontSize: 16, letterSpacing: 1.1),
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
}

class BlobBackgroundPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  BlobBackgroundPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    // Simplificar blobs para performance, usando senos para movimento orgânico
    final path1 = Path();
    path1.moveTo(0, size.height * 0.7);
    path1.quadraticBezierTo(
        size.width * 0.25,
        size.height * (0.6 + 0.1 * (1 + 0.5 * (1 + (animationValue * 2)))),
        size.width * 0.5,
        size.height * 0.75);
    path1.quadraticBezierTo(
        size.width * 0.8, size.height * 0.9, size.width, size.height * 0.7);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(size.width, size.height * 0.3);
    path2.quadraticBezierTo(
        size.width * 0.7,
        size.height * (0.2 + 0.05 * (1 + (animationValue * 3))),
        size.width * 0.4,
        size.height * 0.35);
    path2.quadraticBezierTo(
        size.width * 0.2, size.height * 0.5, 0, size.height * 0.25);
    path2.lineTo(0, 0);
    path2.lineTo(size.width, 0);
    path2.close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
