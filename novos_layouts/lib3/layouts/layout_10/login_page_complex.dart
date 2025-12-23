import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/providers.dart';
import '../theme.dart';
import 'widgets/glass_card.dart';

class Layout10LoginPage extends ConsumerStatefulWidget {
  const Layout10LoginPage({super.key});

  @override
  ConsumerState<Layout10LoginPage> createState() => _Layout10LoginPageState();
}

class _Layout10LoginPageState extends ConsumerState<Layout10LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_backgroundController);
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _cardAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    ));
    
    _cardController.forward();
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _backgroundController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final cpfCnpj = _cpfController.text.trim();
      
      await authNotifier.login(cpfCnpj: cpfCnpj);
      
      // AuthGate will handle navigation automatically
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao fazer login. Verifique seus dados.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout10Theme.backgroundColor,
      body: Stack(
        children: [
          // Background animated pattern
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: BackgroundPainter(_backgroundAnimation.value),
              );
            },
          ),
          
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Layout10Theme.spacingXL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Title section
                    AnimatedBuilder(
                      animation: _cardAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _cardAnimation.value,
                          child: FadeTransition(
                            opacity: _cardAnimation,
                            child: Column(
                              children: [
                                // Logo placeholder
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: Layout10Theme.accentGradient,
                                    borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusXXL),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Layout10Theme.accentColor.withValues(alpha: 0.4),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.fiber_smart_record_rounded,
                                    size: 60,
                                    color: Layout10Theme.primaryTextColor,
                                  ),
                                ),
                                
                                const SizedBox(height: Layout10Theme.spacingXL),
                                
                                Text(
                                  'Bem-vindo',
                                  style: Layout10Theme.heading1,
                                ),
                                
                                const SizedBox(height: Layout10Theme.spacingS),
                                
                                Text(
                                  'Digite seu CPF/CNPJ para continuar',
                                  style: Layout10Theme.bodyMedium.copyWith(
                                    color: Layout10Theme.secondaryTextColor.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: Layout10Theme.spacingXXL),
                    
                    // Login form
                    NeonCard(
                      padding: const EdgeInsets.all(Layout10Theme.spacingXL),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // CPF/CNPJ Field
                            TextFormField(
                              controller: _cpfController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(14),
                              ],
                              style: Layout10Theme.bodyLarge.copyWith(
                                color: Layout10Theme.primaryTextColor,
                              ),
                              decoration: InputDecoration(
                                labelText: 'CPF/CNPJ',
                                labelStyle: Layout10Theme.bodyMedium.copyWith(
                                  color: Layout10Theme.secondaryTextColor,
                                ),
                                hintStyle: Layout10Theme.bodyMedium.copyWith(
                                  color: Layout10Theme.secondaryTextColor.withValues(alpha: 0.5),
                                ),
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  color: Layout10Theme.accentColor,
                                ),
                                filled: true,
                                fillColor: Layout10Theme.surfaceColor.withValues(alpha: 0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusM),
                                  borderSide: BorderSide(
                                    color: Layout10Theme.secondaryTextColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusM),
                                  borderSide: BorderSide(
                                    color: Layout10Theme.secondaryTextColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusM),
                                  borderSide: const BorderSide(
                                    color: Layout10Theme.accentColor,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusM),
                                  borderSide: const BorderSide(
                                    color: Layout10Theme.errorColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, digite seu CPF/CNPJ';
                                }
                                if (value.length < 11 || value.length > 14) {
                                  return 'CPF/CNPJ inválido';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: Layout10Theme.spacingL),
                            
                            // Error message
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(Layout10Theme.spacingM),
                                decoration: BoxDecoration(
                                  color: Layout10Theme.errorColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusM),
                                  border: Border.all(
                                    color: Layout10Theme.errorColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: Layout10Theme.errorColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: Layout10Theme.spacingS),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: Layout10Theme.bodyMedium.copyWith(
                                          color: Layout10Theme.errorColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            if (_errorMessage != null)
                              const SizedBox(height: Layout10Theme.spacingL),
                            
                            // Login button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Layout10Theme.accentColor,
                                  foregroundColor: Layout10Theme.primaryTextColor,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusM),
                                  ),
                                  shadowColor: Layout10Theme.accentColor.withValues(alpha: 0.4),
                                ),
                                child: _isLoading
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Layout10Theme.primaryTextColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: Layout10Theme.spacingM),
                                          Text(
                                            'Entrando...',
                                            style: Layout10Theme.bodyLarge.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        'Entrar',
                                        style: Layout10Theme.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: Layout10Theme.spacingXL),
                    
                    // Footer
                    Text(
                      'Desenvolvido com ❤️',
                      style: Layout10Theme.caption.copyWith(
                        color: Layout10Theme.secondaryTextColor.withValues(alpha: 0.6),
                      ),
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

class BackgroundPainter extends CustomPainter {
  final double animation;
  
  BackgroundPainter(this.animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Layout10Theme.accentColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    
    // Create flowing wave pattern
    final waveHeight = 100.0;
    final waveLength = size.width / 3;
    
    for (double x = 0; x <= size.width; x += 10) {
      final y = size.height / 2 + 
          waveHeight * Math.sin((x / waveLength + animation) * 2 * Math.pi) +
          waveHeight / 2 * Math.sin((x / (waveLength / 2) + animation * 1.5) * 2 * Math.pi);
      
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Add floating particles
    final particlePaint = Paint()
      ..color = Layout10Theme.accentColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    
    final particleCount = 20;
    for (int i = 0; i < particleCount; i++) {
      final x = (size.width / particleCount * i + animation * 100) % size.width;
      final y = size.height / 2 + 
          50 * Math.sin((i + animation * 2) * 0.5) +
          30 * Math.cos((i + animation * 3) * 0.3);
      
      canvas.drawCircle(
        Offset(x, y),
        3 + 2 * Math.sin(animation * 2 + i),
        particlePaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Math functions for the painter
class Math {
  static double sin(double x) => math.sin(x);
  static double cos(double x) => math.cos(x);
  static const double pi = math.pi;
}
