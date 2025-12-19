import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:app_provedor_unified/layouts/layout_14/widgets/gold_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Velvet Gold Palette
    const bgColor = Color(0xFF101010);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const GoldGradientText(
                child:
                    Icon(FontAwesomeIcons.crown, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'ROYAL PROVIDER',
                style: GoogleFonts.cinzel(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3),
              ),
              const SizedBox(height: 60),
              VelvetCard(
                child: Column(
                  children: [
                    _buildGoldTextField(
                        controller: _cpfController,
                        label: 'Identificação',
                        icon: Icons.person_outline),
                    const SizedBox(height: 20),
                    _buildGoldTextField(
                        controller: _passwordController,
                        label: 'Senha de Acesso',
                        icon: Icons.lock_outline,
                        obscureText: true),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(colors: [
                              Color(0xFFBF953F),
                              Color(0xFFFCF6BA),
                              Color(0xFFB38728),
                            ])),
                        child: ElevatedButton(
                          onPressed: () {
                            print("Login");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(
                            'ACESSAR CONTA',
                            style: GoogleFonts.cinzel(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Esqueci minha senha',
                  style: GoogleFonts.lato(color: const Color(0xFFBF953F)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoldTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.lato(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.lato(color: Colors.white38),
        prefixIcon: Icon(icon, color: const Color(0xFFBF953F)),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white10),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFBF953F)),
        ),
      ),
    );
  }
}
