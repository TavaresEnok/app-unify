import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../models/login_config.dart';
import '../../shared/theme/app_colors.dart';

/// Tela de login estilo Moderno (carousel + glass card)
class LoginModern extends StatefulWidget {
  final LoginConfig? config;
  final Function(String, String) onLogin;

  const LoginModern({
    super.key,
    this.config,
    required this.onLogin,
  });

  @override
  State<LoginModern> createState() => _LoginModernState();
}

class _LoginModernState extends State<LoginModern> {
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length >= 6 && !hex.contains('ff')) buffer.write('ff');
    buffer.write(hex.replaceAll('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Future<void> _handleLogin() async {
    if (_cpfController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await widget.onLogin(_cpfController.text, _passwordController.text);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final bgConfig = config?.background;
    final carouselConfig = config?.carousel;
    final formConfig = config?.form;

    final bgColors = bgConfig?.colors.map(_hexToColor).toList() ??
        [_hexToColor('#1E293B'), _hexToColor('#334155')];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Carousel de imagens (se configurado)
              if (carouselConfig != null &&
                  carouselConfig.show &&
                  carouselConfig.images.isNotEmpty)
                CarouselSlider(
                  options: CarouselOptions(
                    height: 200,
                    autoPlay: carouselConfig.autoPlay,
                    autoPlayInterval:
                        Duration(milliseconds: carouselConfig.interval),
                    enlargeCenterPage: true,
                  ),
                  items: carouselConfig.images.map((url) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (formConfig?.showWelcomeText ?? true)
                            Text(
                              formConfig?.welcomeText ?? 'Bem-vindo!',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          const SizedBox(height: 32),
                          TextField(
                            controller: _cpfController,
                            decoration: InputDecoration(
                              labelText:
                                  formConfig?.placeholderCPF ?? 'CPF ou CNPJ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText:
                                  formConfig?.placeholderPassword ?? 'Senha',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      formConfig?.buttonText ?? 'Entrar',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
