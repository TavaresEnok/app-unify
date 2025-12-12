// ARQUIVO: lib/widgets/dynamic_module_loader.dart

import 'package:flutter/material.dart';

// Este widget chama loadLibrary() e só exibe o filho quando o Future é concluído.
class DynamicModuleLoader extends StatelessWidget {
  final Future<void> loadLibrary;
  final WidgetBuilder builder;
  final Color primaryColor; // Para a cor do CircularProgressIndicator

  const DynamicModuleLoader({
    super.key,
    required this.loadLibrary,
    required this.builder,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loadLibrary,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // A biblioteca foi carregada com sucesso, exibe o conteúdo real.
          return builder(context);
        }

        // Mostra um indicador de carregamento enquanto a biblioteca é carregada.
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: primaryColor),
                const SizedBox(height: 16),
                const Text("Carregando módulo...")
              ],
            ),
          ),
        );
      },
    );
  }
}