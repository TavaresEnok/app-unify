import 'package:flutter/material.dart';
import 'theme.dart';

class ConsumoPage extends StatelessWidget {
  const ConsumoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout05Theme.background,
      appBar: AppBar(
        title: const Text('MEU CONSUMO',
            style: TextStyle(letterSpacing: 2, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      body: Center(
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Layout05Theme.surfaceLight, Layout05Theme.background],
            ),
            border: Border.all(
                color: Layout05Theme.secondary.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: Layout05Theme.secondary.withOpacity(0.2),
                blurRadius: 30,
              )
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: 0.5,
                strokeWidth: 12,
                color: Layout05Theme.secondary,
                backgroundColor: Colors.white10,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('50%',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.bold)),
                  Text('CONSUMIDO',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          letterSpacing: 2)),
                  const SizedBox(height: 8),
                  const Text('50 GB / 100 GB',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
