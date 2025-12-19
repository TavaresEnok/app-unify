import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../../core/providers/providers.dart';
import '../../core/models/usuario.dart';
import 'theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _cpfController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final configProvider = ref.read(configurationProvider);
    final config = configProvider.providerConfig;

    if (_cpfController.text.isEmpty) {
      setState(() => _errorMessage = 'Digite seu CPF/CNPJ');
      HapticFeedback.vibrate();
      return;
    }
    if (config == null) {
      setState(() => _errorMessage = 'Erro de configuração');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await ref.read(authNotifierProvider.notifier).login(
          _cpfController.text.trim(),
          config,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Usuario?>>(authNotifierProvider, (previous, next) {
      if (next is AsyncError) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Falha no login';
        });
      } else if (next is AsyncData && next.value != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
        Navigator.of(context).pushReplacementNamed('/painel');
      }
    });

    final config = ref.watch(configurationProvider).providerConfig;
    final primaryColor = Layout08Theme.primary(ref.watch(themeProvider).config);

    return Scaffold(
      backgroundColor: Layout08Theme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo com Neubrutalismo
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: Layout08Theme.neubrutalismDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(0),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: config?.config.logoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: config!.config.logoUrl,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) =>
                              Image.asset('assets/images/ajust.png'),
                        )
                      : Image.asset('assets/images/ajust.png'),
                ),
              ),
              const SizedBox(height: 40),
              // Texto de Boas-vindas
              Container(
                decoration: Layout08Theme.neubrutalismDecoration(
                  color: primaryColor,
                ),
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'LOGIN_ISP',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              // Campo de Entrada
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'IDENTIFICAÇÃO:',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: Layout08Theme.neubrutalismDecoration(
                        color: Colors.white),
                    child: TextField(
                      controller: _cpfController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                      decoration: const InputDecoration(
                        hintText: '000.000.000-00',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: Layout08Theme.neubrutalismDecoration(
                      color: const Color(0xFFFF4B4B)),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              // Botão de Login
              GestureDetector(
                onTapDown: (_) => HapticFeedback.lightImpact(),
                onTap: _isLoading ? null : _handleLogin,
                child: Container(
                  height: 64,
                  decoration: Layout08Theme.neubrutalismDecoration(
                    color: Layout08Theme.secondary(
                        ref.watch(themeProvider).config),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            'ENTRAR →',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
