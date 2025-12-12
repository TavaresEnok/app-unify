import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'utils.dart';

class LoginPage extends StatefulWidget {
  final Function(String, String, String, String, String, String, String)
      onLoginSuccess;
  final Map<String, dynamic> providerConfig;

  const LoginPage(
      {super.key, required this.onLoginSuccess, required this.providerConfig});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _cpfController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
    _logConfigKeys(); // Loga para diagnóstico
  }

  void _logConfigKeys() {
    // Apenas para debug, sem travar o app
    try {
      final details =
          widget.providerConfig['details'] as Map<String, dynamic>? ?? {};
      print(
          "DEBUG: Configuração carregada. Chaves disponíveis em 'details': ${details.keys.toList()}");
    } catch (_) {}
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    print("--- DEBUG LOGIN ---");

    // IP do middleware/API intermediária
    const apiUrl = 'http://45.176.56.70:3000/get-client-data-for-login';

    try {
      final details =
          widget.providerConfig['details'] as Map<String, dynamic>? ?? {};

      // 1. Tenta obter URL do Firestore
      String sgpBaseUrl = details['baseUrl'] as String? ?? '';
      if (sgpBaseUrl.isEmpty) sgpBaseUrl = details['url'] as String? ?? '';
      if (sgpBaseUrl.isEmpty) sgpBaseUrl = details['sgpUrl'] as String? ?? '';

      // 2. Fallback para URL encontrada no código do provedor 'vibe'
      if (sgpBaseUrl.isEmpty) {
        print(
            "⚠️ AVISO: URL Base SGP não encontrada no Firestore. Usando fallback para 'vibe'.");
        sgpBaseUrl = "https://vibetelecom.sgp.net.br";
      }

      final sgpParams = {
        "token": details['apiToken'] as String? ?? '',
        "app": details['appName'] as String? ?? ''
      };

      if ((sgpParams['token'] ?? '').isEmpty ||
          (sgpParams['app'] ?? '').isEmpty) {
        // Se ainda faltar token, não temos como prosseguir
        throw Exception(
            "Token ou App Name não configurados no painel (Firestore).");
      }

      final requestBody = {
        "cpfCnpj": _cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        "sgpParams": sgpParams,
        "sgpBaseUrl": sgpBaseUrl
      };

      print("Enviando requisição para $apiUrl (Base SGP: $sgpBaseUrl)");

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      print("Status da resposta: ${response.statusCode}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final d = json.decode(response.body)['data'];
        widget.onLoginSuccess(
            d['cpfCnpj'] ?? '',
            d['senha'] ?? '',
            d['userName'] ?? 'Usuário',
            d['userPlan'] ?? 'N/A',
            d['userStatus'] ?? 'N/A',
            d['billValue'] ?? 'R\$ 0,00',
            d['billDueDate'] ?? 'N/A');
        // Navegação é gerenciada pelo AuthGate via setState
      } else {
        final e = json.decode(response.body)['error'];
        _showErrorDialog('Falha no Login',
            e?['message'] ?? 'Verifique seus dados e tente novamente.');
      }
    } on TimeoutException {
      if (mounted)
        _showErrorDialog('Tempo Esgotado',
            'O servidor demorou a responder. Tente novamente.');
    } catch (e) {
      if (mounted)
        _showErrorDialog('Erro', 'Ocorreu um erro inesperado: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
      print("--- FIM DEBUG LOGIN ---");
    }
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Ok'),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configMap =
        widget.providerConfig['config'] as Map<String, dynamic>? ?? {};
    final primaryColor =
        hexToColor(configMap['themeColor'] as String? ?? '#673AB7');
    final secondaryColor =
        hexToColor(configMap['secondaryColor'] as String? ?? '#9575CD');
    final logoUrl = configMap['logoUrl'] as String? ?? '';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (logoUrl.isNotEmpty)
                      Image.network(
                        logoUrl,
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const SizedBox.shrink(),
                      ),
                    const SizedBox(height: 24),
                    const Text('Bem-vindo(a)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(blurRadius: 10, color: Colors.black26)
                            ])),
                    const SizedBox(height: 8),
                    const Text('Acesse com seu CPF ou CNPJ',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.white70)),
                    const SizedBox(height: 48),
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _cpfController,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'CPF / CNPJ',
                          labelStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                          prefixIcon: Icon(Icons.person_outline,
                              color: Colors.white.withValues(alpha: 0.7)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, insira seu CPF ou CNPJ.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    _isLoading
                        ? const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white))
                        : ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 5,
                            ),
                            child: const Text('ENTRAR',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
