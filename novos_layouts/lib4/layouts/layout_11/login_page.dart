import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../core/providers/providers.dart';

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

  static const Color _auroraPurple = Color(0xFF7B3FF2);
  static const Color _auroraBlue = Color(0xFF3F7BF2);
  static const Color _auroraPink = Color(0xFFF23FB7);

  static const Color _glassWhite = Color(0x1AFFFFFF);
  static const Color _glassDark = Color(0xCC121220);

  static const Color _textPrimaryLight = Color(0xFF1A1A2E);
  static const Color _textSecondaryLight = Color(0xFF6B6B8A);
  static const Color _textPrimaryDark = Color(0xFFFFFFFF);
  static const Color _textSecondaryDark = Color(0xFFB8B8D0);

  static const Color _errorRed = Color(0xFFFF6B6B);

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
    final config = ref.read(configurationProvider).providerConfig;

    if (_cpfController.text.isEmpty) {
      setState(() => _errorMessage = 'Por favor, digite seu CPF/CNPJ');
      HapticFeedback.vibrate(); // Error Haptic
      return;
    }
    if (config == null) {
      setState(() => _errorMessage = 'Configuração não encontrada');
      HapticFeedback.vibrate();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);

      final user = await authRepo.performLoginApi(_cpfController.text, config);
      await authRepo.saveUserLocally(user);
      
      if (mounted) {
        setState(() => _isLoading = false);
        HapticFeedback.lightImpact(); // Success Haptic
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao fazer login: ${e.toString()}';
          _isLoading = false;
        });
        HapticFeedback.vibrate(); // Error Haptic
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Aurora Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _auroraPurple,
                    _auroraBlue,
                    _auroraPink,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Animated Particles Overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: AuroraPainter(
                    animationValue: _animController.value,
                    isDarkMode: isDarkMode,
                  ),
                );
              },
            ),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo/Header Section
                    _buildHeaderSection(isDarkMode),
                    
                    const SizedBox(height: 48),
                    
                    // Glass Login Card
                    _buildGlassLoginCard(isDarkMode),
                    
                    const SizedBox(height: 24),
                    
                    // Additional Options
                    _buildAdditionalOptions(isDarkMode),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(bool isDarkMode) {
    final textPrimary = isDarkMode ? _textPrimaryDark : _textPrimaryLight;
    final textSecondary = isDarkMode ? _textSecondaryDark : _textSecondaryLight;

    return Column(
      children: [
        // App Icon with Glass Effect
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _glassWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.wifi_rounded,
            size: 40,
            color: textPrimary,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Welcome Text
        Text(
          'Bem-vindo de volta',
          style: TextStyle(
            color: textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Acesse sua conta para continuar',
          style: TextStyle(
            color: textSecondary.withValues(alpha: 0.8),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassLoginCard(bool isDarkMode) {
    final textPrimary = isDarkMode ? _textPrimaryDark : _textPrimaryLight;
    final textSecondary = isDarkMode ? _textSecondaryDark : _textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? _glassDark : _glassWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _auroraPurple.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _auroraPurple.withValues(alpha: 0.3),
                    _auroraBlue.withValues(alpha: 0.3),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Form Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CPF Input Field
                  _buildTextField(
                    controller: _cpfController,
                    label: 'CPF/CNPJ',
                    hint: '000.000.000-00',
                    icon: Icons.person_outline_rounded,
                    isDarkMode: isDarkMode,
                    auroraColor: _auroraPurple,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _errorRed.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: _errorRed, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: _errorRed,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _auroraPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                  
                  const SizedBox(height: 16),
                  
                  // Forgot Password
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // Handle forgot password
                    },
                    child: Text(
                      'Esqueceu sua senha?',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    required Color auroraColor,
  }) {
    final textPrimary = isDarkMode ? _textPrimaryDark : _textPrimaryLight;
    final textSecondary = isDarkMode ? _textSecondaryDark : _textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textPrimary.withValues(alpha: 0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: (isDarkMode ? _glassDark : _glassWhite).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: auroraColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: textSecondary.withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(
                icon,
                color: auroraColor,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalOptions(bool isDarkMode) {
    final textPrimary = isDarkMode ? _textPrimaryDark : _textPrimaryLight;
    final textSecondary = isDarkMode ? _textSecondaryDark : _textSecondaryLight;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: textSecondary.withValues(alpha: 0.3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ou',
                style: TextStyle(
                  color: textSecondary.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: textSecondary.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Register Button
        OutlinedButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            // Handle register
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: textSecondary.withValues(alpha: 0.5),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Criar nova conta',
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// Aurora Animation Painter
class AuroraPainter extends CustomPainter {
  final double animationValue;
  final bool isDarkMode;

  AuroraPainter({
    required this.animationValue,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF7B3FF2).withValues(alpha: 0.1),
          const Color(0xFF3F7BF2).withValues(alpha: 0.1),
          const Color(0xFFF23FB7).withValues(alpha: 0.1),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Offset.zero & size)
      ..blendMode = BlendMode.screen;

    // Create flowing aurora effect
    final path = Path();
    
    for (int i = 0; i < 3; i++) {
      final waveOffset = i * 0.33 + animationValue;
      final waveHeight = size.height * 0.3;
      
      path.moveTo(0, size.height * 0.5);
      
      for (double x = 0; x <= size.width; x += 10) {
        final normalizedX = x / size.width;
        final wave = 
          math.sin(normalizedX * math.pi * 2 + waveOffset * math.pi * 2) * waveHeight +
                math.sin(normalizedX * math.pi * 4 + waveOffset * math.pi * 4) * waveHeight * 0.5;
        
        path.lineTo(x, size.height * 0.5 + wave);
      }
      
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      
      canvas.drawPath(path, paint);
      path.reset();
    }
  }

  @override
  bool shouldRepaint(AuroraPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
           isDarkMode != oldDelegate.isDarkMode;
  }
}
