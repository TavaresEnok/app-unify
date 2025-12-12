import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/configuration_provider.dart'; // Add this
import '../../core/services/auth_service.dart';
// import '../../core/utils/validations.dart'; // Does not exist? Checking utils
// Assuming Validations class is in core/utils/validations.dart but error says it doesn't exist.
// Checking file structure...
import 'theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() =>
      _LoginPageState(); // FIXED: Standard State naming
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  // FIXED: Standard State naming
  final _formKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();
    final configProvider = context.read<ConfigurationProvider>();

    try {
      if (configProvider.providerConfig == null) {
        throw Exception("Configuração não carregada");
      }

      await authService.performLogin(
        _cpfController.text,
        configProvider.providerConfig!,
      );

      if (mounted) Navigator.pushReplacementNamed(context, '/painel');
    } catch (e) {
      if (mounted)
        _showError('Erro: ${e.toString().replaceAll("Exception:", "")}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Layout04Theme.neonPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: Layout04Theme.auroraGradient,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Area (Placeholder for now, using Icon)
                Icon(
                  Icons.bolt_rounded,
                  size: 64,
                  color: Layout04Theme.neonCyan,
                ),
                const SizedBox(height: 16),
                Text(
                  "AURORA",
                  style: Layout04Theme.headingHero.copyWith(
                    color: Layout04Theme.neonCyan,
                    shadows: [
                      BoxShadow(
                          color: Layout04Theme.neonCyan.withOpacity(0.5),
                          blurRadius: 20),
                    ],
                  ),
                ),
                Text("CONNECT",
                    style: Layout04Theme.heading2.copyWith(letterSpacing: 4)),

                const SizedBox(height: 48),

                // Glass Form Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: Layout04Theme.glassDecoration,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text("Bem-vindo de volta",
                            style: Layout04Theme.heading2,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 32),

                        _buildGlassInput(
                          controller: _cpfController,
                          label: 'CPF / CNPJ',
                          icon: Icons.person_outline_rounded,
                          validator: (v) => v != null && v.isNotEmpty
                              ? null
                              : 'Campo obrigatório', // Inline validation for now
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 24),

                        _buildGlassInput(
                          controller: _senhaController,
                          label: 'Senha',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          validator: (v) => v != null && v.isNotEmpty
                              ? null
                              : 'Campo obrigatório', // Inline validation
                        ),

                        const SizedBox(height: 32),

                        // Neon Button
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Layout04Theme.neonCyan.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            gradient: const LinearGradient(
                              colors: [
                                Layout04Theme.neonCyan,
                                Color(0xFF2D68FF)
                              ],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text("ACESSAR CONTA",
                                    style: Layout04Theme.label.copyWith(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Biometric / Forgot Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                                onPressed: () {},
                                child: Text("Esqueci a senha",
                                    style: Layout04Theme.label)),
                            IconButton(
                              onPressed: () {}, // To implement Biometrics later
                              icon: Icon(Icons.fingerprint,
                                  color: Layout04Theme.neonPurple),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Layout04Theme.neonCyan),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white60,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Layout04Theme.neonCyan),
        ),
        errorStyle: const TextStyle(color: Layout04Theme.neonPink),
      ),
    );
  }
}
