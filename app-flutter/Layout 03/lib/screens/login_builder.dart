import 'package:flutter/material.dart';
import '../models/login_config.dart';
import 'login/login_classic.dart';
import 'login/login_modern.dart';
import 'login/login_minimal.dart';

/// Builder que escolhe qual tela de login mostrar baseado na configuração
class LoginBuilder extends StatelessWidget {
  final LoginConfig? config;
  final Function(String, String) onLogin;

  const LoginBuilder({
    super.key,
    this.config,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    // Se não houver config, usar estilo clássico por padrão
    final style = config?.style ?? 'classic';

    switch (style.toLowerCase()) {
      case 'modern':
        return LoginModern(
          config: config,
          onLogin: onLogin,
        );
      case 'minimal':
        return LoginMinimal(
          config: config,
          onLogin: onLogin,
        );
      case 'classic':
      default:
        return LoginClassic(
          config: config,
          onLogin: onLogin,
        );
    }
  }
}
