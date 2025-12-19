import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:app_provedor_unified/layouts/layout_13/widgets/cyber_card.dart';

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
    // Cyber Palette
    const bgColor = Color(0xFF050505);
    const accentColor = Color(0xFF00FFFF); // Cyan

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                FontAwesomeIcons.robot,
                size: 50,
                color: accentColor,
              ),
              const SizedBox(height: 10),
              Text(
                'SECURE_LOGIN_V1.0',
                style: GoogleFonts.robotoMono(
                    color: accentColor,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 50),
              CyberCard(
                borderColor: accentColor,
                cutSize: 30,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Column(
                  children: [
                    _buildCyberTextField(
                      controller: _cpfController,
                      label: 'USER_ID / CPF',
                      icon: Icons.person,
                      accent: accentColor,
                    ),
                    const SizedBox(height: 20),
                    _buildCyberTextField(
                      controller: _passwordController,
                      label: 'ACCESS_KEY',
                      icon: Icons.vpn_key,
                      accent: accentColor,
                      obscureText: true,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          print("Login Attempt");
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.black,
                            shape: const BeveledRectangleBorder(
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    bottomRight: Radius.circular(10))),
                            padding: const EdgeInsets.symmetric(vertical: 20)),
                        child: Text(
                          'INITIATE_SESSION()',
                          style: GoogleFonts.robotoMono(
                              fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {},
                child: Text(
                  '[ RECOVER_ACCESS ]',
                  style: GoogleFonts.robotoMono(color: Colors.grey),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCyberTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color accent,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '> $label',
          style: GoogleFonts.robotoMono(color: accent, fontSize: 10),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: GoogleFonts.robotoMono(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[800]!),
              borderRadius: BorderRadius.zero,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[800]!),
              borderRadius: BorderRadius.zero,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: accent),
              borderRadius: BorderRadius.zero,
            ),
            prefixIcon: Icon(icon, color: Colors.grey),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          ),
        ),
      ],
    );
  }
}
