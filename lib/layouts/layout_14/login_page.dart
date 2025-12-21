import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../core/providers/providers.dart';
import '../../core/models/usuario.dart';

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
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
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

    // Simulate login with demo user for Layout 14
    // In production, this would call the actual auth service
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // Create demo user matching Usuario model requirements
      final user = Usuario(
        nome: 'Usuário Demo',
        cpfCnpj: _cpfController.text,
        senha: 'demo123',
        plano: 'Fibra 300 Mbps',
        status: 'active',
        valorFatura: '149.90',
        vencimentoFatura: '15/12/2024',
        email: 'demo@example.com',
      );

      // Simulate successful login
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
      
      // Navigate to Dashboard
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/painel');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Falha no login: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configurationProvider).providerConfig;
    
    // Cyberpunk-Neon Palette
    const Color deepSpace = Color(0xFF0A0A0F);
    const Color voidBlack = Color(0xFF050508);
    const Color darkPurple = Color(0xFF1A0A2E);
    
    const Color neonCyan = Color(0xFF00FFFF);
    const Color neonMagenta = Color(0xFFFF00FF);
    const Color neonYellow = Color(0xFFFFFF00);
    
    const Color glassCyan = Color(0x1A00FFFF);
    const Color glassMagenta = Color(0x1AFF00FF);
    const Color glassSurface = Color(0x0DFFFFFF);
    
    const Color textPrimary = Color(0xFFFFFFFF);
    const Color textSecondary = Color(0xFFB0B0C0);
    const Color textNeon = Color(0xFF00FFFF);

    return Scaffold(
      backgroundColor: deepSpace,
      body: Stack(
        children: [
          // Animated Cyber Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: CyberGridPainter(),
            ),
          ),

          // Scan Lines
          Positioned.fill(
            child: CustomPaint(
              painter: ScanLinesPainter(),
            ),
          ),

          // Neon Glow Orbs (Cyberpunk Style)
          Positioned(
            top: -100,
            right: -50,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        neonCyan.withValues(alpha: _glowAnimation.value * 0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: neonCyan.withValues(alpha: _glowAnimation.value * 0.6),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Positioned(
            bottom: -80,
            left: -80,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        neonMagenta.withOpacity(_glowAnimation.value * 0.25),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: neonMagenta.withOpacity(_glowAnimation.value * 0.5),
                        blurRadius: 50,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo with Glass Effect
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: glassSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: neonCyan, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: neonCyan.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: config?.config.logoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: config!.config.logoUrl,
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) {
                                return Image.asset(
                                  'assets/images/ajust.png',
                                  fit: BoxFit.contain,
                                );
                              },
                            )
                          : Image.asset(
                              'assets/images/ajust.png',
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Title with Neon Effect
                  const Text(
                    'BEM-VINDO\nAO SISTEMA',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                      height: 1.1,
                      fontFamily: 'JetBrains Mono',
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          color: neonCyan,
                          blurRadius: 8,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    'Acesse sua conta para gerenciar\nseus serviços de internet',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary.withValues(alpha: 0.8),
                      height: 1.6,
                      fontFamily: 'JetBrains Mono',
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Glass Login Card
                  _buildGlassLoginCard(
                    neonCyan,
                    neonMagenta,
                    glassSurface,
                    textPrimary,
                    textSecondary,
                  ),

                  // Error Message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: neonMagenta.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: neonMagenta, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: neonMagenta.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: neonMagenta, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: neonMagenta,
                                fontSize: 13,
                                fontFamily: 'JetBrains Mono',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Cyberpunk Login Button
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
                        backgroundColor: const Color(0xFF050508),
                        foregroundColor: textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: neonCyan, width: 2),
                        ),
                        elevation: 0,
                        shadowColor: neonCyan.withValues(alpha: 0.5),
                      ).copyWith(
                        elevation: WidgetStateProperty.all(8),
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.pressed)) {
                            return neonCyan.withValues(alpha: 0.2);
                          }
                          if (states.contains(WidgetState.hovered)) {
                            return neonCyan.withValues(alpha: 0.1);
                          }
                          return const Color(0xFF050508);
                        }),
                        overlayColor: WidgetStateProperty.all(neonCyan.withValues(alpha: 0.2)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: neonCyan,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login_rounded, color: neonCyan, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'ENTRAR NO SISTEMA',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'JetBrains Mono',
                                    letterSpacing: 1.5,
                                    color: neonCyan,
                                    shadows: [
                                      Shadow(
                                        color: neonCyan,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Additional Options
                  _buildAdditionalOptions(textSecondary, neonCyan, glassSurface),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassLoginCard(
    Color neonCyan,
    Color neonMagenta,
    Color glassSurface,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [neonCyan, neonMagenta],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: neonCyan.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: glassSurface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: neonCyan.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF050508),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: textSecondary.withValues(alpha: 0.3), width: 1),
                ),
                child: Text(
                  'CPF / CNPJ',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'JetBrains Mono',
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Input Field
              _buildTextField(
                controller: _cpfController,
                label: 'Documento',
                hint: '000.000.000-00',
                icon: Icons.person_outline_rounded,
                neonCyan: neonCyan,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color neonCyan,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF050508),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: neonCyan.withValues(alpha: 0.3 + _animController.value * 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: neonCyan.withValues(alpha: 0.2 * _animController.value),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'JetBrains Mono',
              letterSpacing: 1.0,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: textSecondary.withValues(alpha: 0.4),
                fontFamily: 'JetBrains Mono',
              ),
              prefixIcon: Icon(
                icon,
                color: neonCyan,
                size: 22,
              ),
              filled: true,
              fillColor: const Color(0xFF0A0A0F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: neonCyan,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: neonCyan.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              // Trigger rebuild for glow effect
              setState(() {});
            },
          ),
        );
      },
    );
  }

  Widget _buildAdditionalOptions(
    Color textSecondary,
    Color neonCyan,
    Color glassSurface,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Não tem conta?',
          style: TextStyle(
            color: textSecondary,
            fontSize: 13,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            // Navigate to support or registration
          },
          child: Text(
            'Entre em contato',
            style: TextStyle(
              color: neonCyan,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'JetBrains Mono',
              decoration: TextDecoration.underline,
              decorationColor: neonCyan,
            ),
          ),
        ),
      ],
    );
  }
}

// Cyber Grid Background Painter
class CyberGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: 0.03)
      ..strokeWidth = 1;

    const spacing = 40.0;

    // Vertical lines
    for (var i = 0.0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Horizontal lines
    for (var i = 0.0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Diagonal lines (subtle)
    final diagPaint = Paint()
      ..color = const Color(0xFFFF00FF).withValues(alpha: 0.02)
      ..strokeWidth = 0.5;

    for (var i = -size.height; i < size.width; i += spacing * 2) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), diagPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Scan Lines Painter
class ScanLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.02)
      ..strokeWidth = 1;

    const spacing = 4.0;

    for (var i = 0.0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}