import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/onu_wifi_service.dart';
import '../../core/providers/configuration_provider.dart';
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
  // OnuWifiService? _wifiService; // TODO: Uncomment when ready to use real service

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServiceAndFetch();
    });
  }

  Future<void> _initServiceAndFetch() async {
    try {
      final configProvider =
          Provider.of<ConfigurationProvider>(context, listen: false);
      final providerConfig = configProvider.providerConfig;

      if (providerConfig == null) {
        setState(() {
          _errorMessage = 'Configuração não encontrada.';
          _isLoading = false;
        });
        return;
      }

      // Initialize service with data from provider
      // final apiUrl = providerConfig.apiUrl; // Unused for now while mocking
      // We need user data. I'll rely on global providers if designed so.

      // TODO: Instantiate _wifiService with real data when Auth is available in scope
      // _wifiService = OnuWifiService(apiUrl: apiUrl, cpfCnpj: ..., sgpParams: ...);

      // MOCK DATA for now
      setState(() {
        _isLoading = false;
        _networks = [
          WifiNetwork(
              id: '1',
              ssid: 'MinhaCasa_2G',
              frequency: '2.4GHz',
              enabled: true),
          WifiNetwork(
              id: '2', ssid: 'MinhaCasa_5G', frequency: '5GHz', enabled: true),
        ];
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showEditDialog(WifiNetwork network) {
    final ssidController = TextEditingController(text: network.ssid);
    final passwordController = TextEditingController(); // Empty for security

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('Editar ${network.frequency}', style: Layout05Theme.heading2),
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
              // Call update service
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Solicitação enviada! O roteador irá reiniciar em instantes.')),
              );
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
                      style: const TextStyle(color: Layout05Theme.error)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _networks.length,
                  itemBuilder: (context, index) {
                    final network = _networks[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: Layout05Theme.cardDecoration,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Layout05Theme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
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
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(
                            '${network.frequency} - ${network.enabled ? 'Ativo' : 'Inativo'}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Layout05Theme.textGrey),
                          onPressed: () => _showEditDialog(network),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
