import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/onu_wifi_service.dart';
import '../../core/providers/configuration_provider.dart';
import '../../core/services/auth_service.dart';
import 'theme.dart';

class WifiPage extends StatefulWidget {
  const WifiPage({super.key});

  @override
  State<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends State<WifiPage> {
  bool _isLoading = true;
  List<WifiNetwork> _networks = [];
  String? _errorMessage;
  OnuWifiService? _wifiService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServiceAndFetch();
    });
  }

  Future<void> _initServiceAndFetch() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final configProvider =
        Provider.of<ConfigurationProvider>(context, listen: false);
    final user = authService.usuario;
    final config = configProvider.providerConfig;

    if (user == null || config == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro de autenticação ou configuração.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // Constructing the real service
      _wifiService = OnuWifiService(
        apiUrl: config.apiUrl,
        cpfCnpj: user.cpfCnpj,
        senha: user.senha,
        contrato: user.contratoId?.toString(),
        sgpParams: {
          'token': config.config.integrations.apiToken,
          'app': config.config.integrations.appName,
          'sgpBaseUrl': config.config.integrations.sgpBaseUrl,
        },
      );

      await _fetchNetworks();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao inicializar serviço: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchNetworks() async {
    if (_wifiService == null) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final networks = await _wifiService!.fetchWifiNetworks();
      if (mounted) {
        setState(() {
          _networks = networks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Não foi possível carregar as redes. Verifique seu equipamento.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateWifi(
      WifiNetwork network, String newSsid, String newPassword) async {
    if (_wifiService == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: Layout05Theme.primary)),
    );

    try {
      final success = await _wifiService!
          .updateWifi(wifiId: network.id, ssid: newSsid, password: newPassword);

      if (!mounted) return;
      Navigator.pop(context); // Hide loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Wi-Fi atualizado com sucesso!'),
              backgroundColor: Layout05Theme.success),
        );
        _fetchNetworks(); // Refresh
      } else {
        throw Exception('Falha ao atualizar');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Hide loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro: $e'), backgroundColor: Layout05Theme.error),
      );
    }
  }

  void _showEditDialog(WifiNetwork network) {
    final ssidController = TextEditingController(text: network.ssid);
    final passwordController = TextEditingController(); // Empty for security

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar ${network.frequency}',
            style:
                Layout05Theme.heading2.copyWith(color: Layout05Theme.textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ssidController,
              decoration:
                  const InputDecoration(labelText: 'Nome da Rede (SSID)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Nova Senha',
                hintText: 'Deixe vazio para manter',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR',
                style: TextStyle(color: Layout05Theme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateWifi(
                  network, ssidController.text, passwordController.text);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Layout05Theme.primary),
            child: const Text('SALVAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout05Theme.background,
      appBar: AppBar(
        title: Text('Minha Rede Wi-Fi', style: Layout05Theme.heading2),
        backgroundColor: Layout05Theme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Layout05Theme.textDark),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Layout05Theme.primary))
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Layout05Theme.error),
                      textAlign: TextAlign.center))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _networks.length,
                  itemBuilder: (context, index) {
                    final network = _networks[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: Layout05Theme.neumorphicDecoration,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(20),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Layout05Theme.background,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.white,
                                  offset: Offset(-2, -2),
                                  blurRadius: 3),
                              BoxShadow(
                                  color: Color(0x11000000),
                                  offset: Offset(2, 2),
                                  blurRadius: 3),
                            ],
                          ),
                          child: Icon(
                            network.frequency.contains('5')
                                ? Icons.wifi_tethering
                                : Icons.wifi,
                            color: Layout05Theme.primary,
                            size: 28,
                          ),
                        ),
                        title: Text(network.ssid,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Layout05Theme.textDark)),
                        subtitle: Text(
                            '${network.frequency} - ${network.enabled ? 'Ativo' : 'Inativo'}',
                            style:
                                Layout05Theme.bodyText.copyWith(fontSize: 13)),
                        trailing: Container(
                          decoration: BoxDecoration(
                            color: Layout05Theme.background,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.white,
                                  offset: Offset(-3, -3),
                                  blurRadius: 5),
                              BoxShadow(
                                  color: Color(0x1FA3B1C6),
                                  offset: Offset(3, 3),
                                  blurRadius: 5),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit_rounded,
                                color: Layout05Theme.textGrey),
                            onPressed: () => _showEditDialog(network),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
