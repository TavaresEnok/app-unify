import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../core/providers/providers.dart';

// Simple theme constants for Layout 10
class _Layout10Colors {
  static const Color backgroundColor = Color(0xFF0A0F1C);
  static const Color surfaceColor = Color(0xFF0D1B2A);
  static const Color primaryColor = Color(0xFF1E3A5F);
  static const Color accentColor = Color(0xFF00BCD4);
  static const Color primaryTextColor = Color(0xFFFFFFFF);
  static const Color secondaryTextColor = Color(0xFFB0BEC5);
  static const Color errorColor = Color(0xFFE91E63);
}

class _Layout10Spacing {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class _Layout10BorderRadius {
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
}

class _Layout10TextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: _Layout10Colors.primaryTextColor,
    letterSpacing: -0.5,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: _Layout10Colors.primaryTextColor,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: _Layout10Colors.secondaryTextColor,
    height: 1.4,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: _Layout10Colors.secondaryTextColor,
  );
}

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
  
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    
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
      final config = ref.read(configurationProvider).providerConfig!;
      
      await authNotifier.login(cpfCnpj, config);
      
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
      backgroundColor: _Layout10Colors.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _Layout10Colors.backgroundColor,
              _Layout10Colors.primaryColor.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(_Layout10Spacing.xl),
              child: AnimatedBuilder(
                animation: _cardAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _cardAnimation.value,
                    child: FadeTransition(
                      opacity: _cardAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF00BCD4),
                                  Color(0xFF4FC3F7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(_Layout10BorderRadius.xxl),
                              boxShadow: [
                                BoxShadow(
                                  color: _Layout10Colors.accentColor.withValues(alpha: 0.4),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.fiber_smart_record_rounded,
                              size: 60,
                              color: _Layout10Colors.primaryTextColor,
                            ),
                          ),
                          
                          const SizedBox(height: _Layout10Spacing.xl),
                          
                          Text(
                            'Bem-vindo',
                            style: _Layout10TextStyles.heading1,
                          ),
                          
                          const SizedBox(height: _Layout10Spacing.s),
                          
                          Text(
                            'Digite seu CPF/CNPJ para continuar',
                            style: _Layout10TextStyles.bodyMedium.copyWith(
                              color: _Layout10Colors.secondaryTextColor.withValues(alpha: 0.8),
                            ),
                          ),
                          
                          const SizedBox(height: _Layout10Spacing.xxl),
                          
                          // Login form
                          Container(
                            padding: const EdgeInsets.all(_Layout10Spacing.xl),
                            decoration: BoxDecoration(
                              color: _Layout10Colors.surfaceColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(_Layout10BorderRadius.l),
                              border: Border.all(
                                color: _Layout10Colors.accentColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _Layout10Colors.accentColor.withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
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
                                    style: _Layout10TextStyles.bodyLarge,
                                    decoration: InputDecoration(
                                      labelText: 'CPF/CNPJ',
                                      labelStyle: _Layout10TextStyles.bodyMedium,
                                      hintStyle: _Layout10TextStyles.bodyMedium.copyWith(
                                        color: _Layout10Colors.secondaryTextColor.withValues(alpha: 0.5),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.person_outline_rounded,
                                        color: _Layout10Colors.accentColor,
                                      ),
                                      filled: true,
                                      fillColor: _Layout10Colors.surfaceColor.withValues(alpha: 0.5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(_Layout10BorderRadius.m),
                                        borderSide: BorderSide(
                                          color: _Layout10Colors.secondaryTextColor.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(_Layout10BorderRadius.m),
                                        borderSide: BorderSide(
                                          color: _Layout10Colors.secondaryTextColor.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(_Layout10BorderRadius.m),
                                        borderSide: const BorderSide(
                                          color: _Layout10Colors.accentColor,
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(_Layout10BorderRadius.m),
                                        borderSide: const BorderSide(
                                          color: _Layout10Colors.errorColor,
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
                                  
                                  const SizedBox(height: _Layout10Spacing.l),
                                  
                                  // Error message
                                  if (_errorMessage != null)
                                    Container(
                                      padding: const EdgeInsets.all(_Layout10Spacing.m),
                                      decoration: BoxDecoration(
                                        color: _Layout10Colors.errorColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(_Layout10BorderRadius.m),
                                        border: Border.all(
                                          color: _Layout10Colors.errorColor.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline_rounded,
                                            color: _Layout10Colors.errorColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: _Layout10Spacing.s),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: _Layout10TextStyles.bodyMedium.copyWith(
                                                color: _Layout10Colors.errorColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  
                                  if (_errorMessage != null)
                                    const SizedBox(height: _Layout10Spacing.l),
                                  
                                  // Login button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _Layout10Colors.accentColor,
                                        foregroundColor: _Layout10Colors.primaryTextColor,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(_Layout10BorderRadius.m),
                                        ),
                                        shadowColor: _Layout10Colors.accentColor.withValues(alpha: 0.4),
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
                                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                                      _Layout10Colors.primaryTextColor,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: _Layout10Spacing.m),
                                                Text(
                                                  'Entrando...',
                                                  style: _Layout10TextStyles.bodyLarge.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              'Entrar',
                                              style: _Layout10TextStyles.bodyLarge.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: _Layout10Spacing.xl),
                          
                          // Footer
                          Text(
                            'Desenvolvido com ❤️',
                            style: _Layout10TextStyles.caption.copyWith(
                              color: _Layout10Colors.secondaryTextColor.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
