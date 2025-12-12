import 'package:flutter/material.dart';
// unused import removed
import 'theme.dart';

class WifiPage extends StatefulWidget {
  const WifiPage({super.key});

  @override
  State<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends State<WifiPage> {
  // Assuming mocked service for UI logic
  final _formKey = GlobalKey<FormState>();
  final _ssidController = TextEditingController(text: 'Minha Casa 5G');
  final _passController = TextEditingController(text: 'senha123');
  bool _obscurePass = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout04Theme.background,
      appBar: AppBar(
        title: Text('Configurar Wi-Fi', style: Layout04Theme.heading3),
        backgroundColor: Layout04Theme.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: Layout04Theme.activeCardDecoration,
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Layout04Theme.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Altere o nome e senha da sua rede 5GHz para melhor performance.',
                        style: Layout04Theme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _ssidController,
                style: const TextStyle(color: Colors.white),
                decoration: Layout04Theme.inputDecoration(
                  'Nome da Rede (SSID)',
                  icon: Icons.wifi,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passController,
                obscureText: _obscurePass,
                style: const TextStyle(color: Colors.white),
                decoration: Layout04Theme.inputDecoration(
                  'Senha',
                  icon: Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Layout04Theme.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveConfig,
                  style: Layout04Theme.primaryButtonStyle,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white))
                      : const Text('SALVAR ALTERAÇÕES'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveConfig() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas com sucesso!')),
      );
    }
  }
}
