import 'package:flutter/material.dart';
import 'theme.dart';

class WifiPage extends StatelessWidget {
  const WifiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout04Theme.backgroundBlack,
      appBar: AppBar(
        title: Text("Meu Wi-Fi", style: Layout04Theme.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: Layout04Theme.auroraGradient,
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: Layout04Theme.glassDecoration,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_lock_rounded,
                    size: 64, color: Layout04Theme.neonPurple),
                const SizedBox(height: 24),
                Text("Gerenciar Redes", style: Layout04Theme.heading1),
                const SizedBox(height: 16),
                Text(
                  "Altere sua senha e nome da rede com segurança.",
                  textAlign: TextAlign.center,
                  style: Layout04Theme.bodyText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
