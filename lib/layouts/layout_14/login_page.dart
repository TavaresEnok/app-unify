import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _cpfController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                "assets/images/dark_texture_bg.png"), // Placeholder for texture
            fit: BoxFit.cover,
            opacity: 0.2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.diamond_outlined,
                size: 60, color: Color(0xFFD4AF37)),
            const SizedBox(height: 40),
            const Text(
              "ACESSO PRIVATE",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFD4AF37),
                letterSpacing: 5,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 60),

            // Minimal Gold Input
            TextField(
              controller: _cpfController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              cursorColor: const Color(0xFFD4AF37),
              decoration: const InputDecoration(
                hintText: "CPF ou CNPJ",
                hintStyle: TextStyle(color: Colors.white30),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFD4AF37))),
                contentPadding: EdgeInsets.only(bottom: 12),
              ),
            ),

            const SizedBox(height: 60),

            OutlinedButton(
              onPressed: () {
                final config = ref.read(configurationProvider).providerConfig;
                if (config != null) {
                  ref
                      .read(authNotifierProvider.notifier)
                      .login(_cpfController.text.trim(), config);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD4AF37),
                side: const BorderSide(color: Color(0xFFD4AF37)),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0)), // Sharp elegant
              ),
              child: const Text("ENTRAR"),
            )
          ],
        ),
      ),
    );
  }
}
