import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../core/providers/providers.dart';
import '../../core/models/usuario.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _cpfController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final configProvider = ref.read(configurationProvider);
    final config = configProvider.providerConfig;
    if (_cpfController.text.isEmpty || config == null) return;

    setState(() => _isLoading = true);
    await ref.read(authNotifierProvider.notifier).login(
          _cpfController.text.trim(),
          config,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Auth Listener
    ref.listen<AsyncValue<Usuario?>>(authNotifierProvider, (prev, next) {
      if (next is AsyncError) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: ${next.error}')));
      } else if (next is AsyncData && next.value != null) {
        Navigator.of(context).pushReplacementNamed('/painel');
      }
    });

    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors
          .white, // Layout 12 is strictly light/minimal mostly, but adaptable
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Huge Typography
              Text(
                "BEM",
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  height: 0.9,
                  color: Colors.black.withOpacity(0.1),
                  letterSpacing: -2,
                ),
              ),
              Text(
                "VINDO.",
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  height: 0.9,
                  color: primaryColor,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 60),

              const Text(
                "ACESSO DO CLIENTE",
                style: TextStyle(
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),

              // Minimal Input
              TextField(
                controller: _cpfController,
                keyboardType: TextInputType.number,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'CPF / CNPJ',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 2),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryColor, width: 4),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 40),

              // Sharp Button
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // Stark contrast
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // Sharp
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "ENTRAR",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
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
}
