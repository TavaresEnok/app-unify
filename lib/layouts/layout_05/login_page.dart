import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/configuration_provider.dart';
import '../../core/models/provider_config.dart';
import 'theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _cpfController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  String? _localErrorMessage; // Added local error message state

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  // New method to handle login logic
  Future<void> _handleLogin(
      AuthService authService, ProviderConfig? config) async {
    setState(() => _localErrorMessage = null); // Clear previous errors

    final cpf = _cpfController.text.trim();
    if (cpf.isEmpty) {
      setState(() => _localErrorMessage = 'Digite o CPF/CNPJ');
      return;
    }

    if (config == null) {
      setState(() => _localErrorMessage = 'Erro de configuração do provedor');
      return;
    }

    try {
      await authService.performLogin(cpf, config);
    } catch (e) {
      setState(() {
        _localErrorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final configProvider = context.watch<ConfigurationProvider>();
    final config = configProvider.providerConfig;

    return Scaffold(
      backgroundColor: Layout05Theme.background,
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Layout05Theme.secondary.withOpacity(0.3),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Layout05Theme.primary.withOpacity(0.2),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      if (config?.config.logoUrl != null)
                        Image.network(config!.config.logoUrl!, height: 80)
                      else
                        const Icon(Icons.wifi_tethering,
                            size: 80, color: Layout05Theme.primary),

                      const SizedBox(height: 48),

                      // Welcome Text
                      Text(
                        'BEM-VINDO',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                                color: Layout05Theme.primary, blurRadius: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Acesse sua conta para continuar',
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      ),

                      const SizedBox(height: 48),

                      // Input Container
                      Container(
                        decoration: Layout05Theme.glassDecoration,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            TextField(
                              controller: _cpfController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'CPF / CNPJ',
                                labelStyle:
                                    const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.person_outline,
                                    color: Layout05Theme.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.1)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Layout05Theme.primary),
                                ),
                                filled: true,
                                fillColor: Colors.black12,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: authService.isLoading
                                    ? null
                                    : () => _handleLogin(authService,
                                        config), // Call new handler
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Layout05Theme.primary,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 10,
                                  shadowColor:
                                      Layout05Theme.primary.withOpacity(0.5),
                                ),
                                child: authService.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.black),
                                      )
                                    : const Text(
                                        'ENTRAR',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_localErrorMessage != null) // Use local error message
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Layout05Theme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Layout05Theme.error.withOpacity(0.5)),
                            ),
                            child: Text(
                              _localErrorMessage!, // Display local error message
                              style:
                                  const TextStyle(color: Layout05Theme.error),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
