import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _cpfController = TextEditingController();
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A14), // Deep Cyber Dark
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated HUD Ring
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF00FFFF)
                            .withOpacity(0.5 + (_animController.value * 0.5)),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FFFF).withOpacity(0.3),
                          blurRadius: 10 + (_animController.value * 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.lock_outline_rounded,
                        size: 40, color: Color(0xFF00FFFF)),
                  );
                },
              ),

              const SizedBox(height: 50),

              const Text(
                "SECURE_LOGIN",
                style: TextStyle(
                  color: Color(0xFF00FFFF),
                  letterSpacing: 4,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                ),
              ),

              const SizedBox(height: 30),

              // Cyber Input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(
                      color: const Color(0xFF00FFFF).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _cpfController,
                  style: const TextStyle(
                      color: Colors.white, fontFamily: 'Courier'),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "ENTER ID (CPF/CNPJ)",
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    prefixIcon: Icon(Icons.code, color: Colors.white30),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Glitch Button Effect (Simulated)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final config =
                        ref.read(configurationProvider).providerConfig;
                    if (config != null) {
                      ref
                          .read(authNotifierProvider.notifier)
                          .login(_cpfController.text.trim(), config);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFFF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: const StadiumBorder(),
                    shadowColor: const Color(0xFF00FFFF),
                    elevation: 10,
                  ),
                  child: const Text("AUTHENTICATE",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
