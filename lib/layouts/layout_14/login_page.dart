import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
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
    // Premium Dark Colors
    const kBgColor = Color(0xFF030303);
    const kGold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          // Ambient Glow
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kGold.withOpacity(0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Icon
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: kGold),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_outlined,
                          color: kGold, size: 40),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Welcome Text
                  Text(
                    "ÁREA DO CLIENTE",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: kGold,
                      fontSize: 12,
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Autenticação",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 32,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Minimalist Input
                  TextField(
                    controller: _cpfController,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 18),
                    cursorColor: kGold,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "CPF ou CNPJ",
                      hintStyle: GoogleFonts.inter(color: Colors.white24),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: kGold),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: Colors.white24, size: 20),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Premium Button
                  ElevatedButton(
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
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: kGold),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(
                      "ACESSAR SISTEMA",
                      style: GoogleFonts.inter(
                        color: kGold,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Text(
                    "Precisa de ajuda?",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white30,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
