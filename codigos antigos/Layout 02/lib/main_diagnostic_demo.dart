import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/diagnostico_page.dart';
import 'configuration_provider.dart';
import 'services/auth_service.dart';
import 'models/usuario.dart';

void main() {
  runApp(const DiagnosticDemoApp());
}

class DiagnosticDemoApp extends StatelessWidget {
  const DiagnosticDemoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConfigurationProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Diagnóstico Demo',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          useMaterial3: true,
        ),
        home: const DemoLoginPage(),
      ),
    );
  }
}

class DemoLoginPage extends StatefulWidget {
  const DemoLoginPage({Key? key}) : super(key: key);

  @override
  State<DemoLoginPage> createState() => _DemoLoginPageState();
}

class _DemoLoginPageState extends State<DemoLoginPage> {
  final _cpfController = TextEditingController(text: '12345678900');
  final _senhaController = TextEditingController(text: 'senha123');

  void _login() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final configProvider =
        Provider.of<ConfigurationProvider>(context, listen: false);

    // Simular usuário
    final usuario = Usuario(
      nome: 'Demo User',
      cpfCnpj: _cpfController.text,
      senha: _senhaController.text,
      contratoId: 12345,
      plano: 'Fibra 500MB',
      status: 'Ativo',
      vencimentoFatura: '15/12/2024',
      valorFatura: 'R\$ 99,90',
    );

    authService.setUsuario(usuario);

    // Carregar config mock
    await configProvider.loadConfiguration('demo-provider');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DiagnosticoPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.network_check,
                size: 100,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 40),
              Text(
                'DIAGNÓSTICO DEMO',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _cpfController,
                decoration: InputDecoration(
                  labelText: 'CPF/CNPJ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _senhaController,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'ENTRAR E TESTAR DIAGNÓSTICO',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
