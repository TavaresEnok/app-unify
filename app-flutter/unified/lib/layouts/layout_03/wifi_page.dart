import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/onu_wifi_service.dart';
import '../../core/providers/providers.dart';
import 'theme.dart';

class WifiPage extends ConsumerStatefulWidget {
  const WifiPage({super.key});

  @override
  ConsumerState<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends ConsumerState<WifiPage> {
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
    final authState = ref.read(authNotifierProvider);
    final configProvider = ref.read(configurationProvider);
    final user = authState.value;
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
      // Check if TR069/SGP integration is configured
      final sgpBaseUrl = config.config.integrations.sgpBaseUrl;
      if (sgpBaseUrl.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Gerenciamento WiFi não disponível.\n\nO seu provedor não possui integração TR069 configurada para gerenciamento remoto do roteador.';
            _isLoading = false;
          });
        }
        return;
      }

      // Constructing the real service
      _wifiService = OnuWifiService(
        apiUrl: config.apiUrl,
        cpfCnpj: user.cpfCnpj,
        senha: user.senha,
        contrato: user.contratoId?.toString(),
        sgpParams: {
          'token': config.config.integrations.apiToken,
          'app': config.config.integrations.appName,
          'sgpBaseUrl': sgpBaseUrl,
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
          child: CircularProgressIndicator(color: Layout03Theme.primary)),
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
              backgroundColor: Layout03Theme.success),
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
            content: Text('Erro: $e'), backgroundColor: Layout03Theme.error),
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
                Layout03Theme.heading2.copyWith(color: Layout03Theme.textDark)),
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
                style: TextStyle(color: Layout03Theme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateWifi(
                  network, ssidController.text, passwordController.text);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Layout03Theme.primary),
            child: const Text('SALVAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = ref.watch(configurationProvider);
    final layoutType = configProvider.providerConfig?.layoutType;
    final isDarkLayout = layoutType == 'layout_04' || layoutType == 'layout_06';

    Color backgroundColor;
    Color appBarColor;
    Color appBarTextColor;
    if (isDarkLayout) {
      backgroundColor = const Color(0xFF0A0A0A);
      appBarColor = const Color(0xFF0A0A0A);
      appBarTextColor = Colors.white;
    } else {
      backgroundColor = Layout03Theme.background;
      appBarColor = Layout03Theme.background;
      appBarTextColor = Layout03Theme.textDark;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Minha Rede Wi-Fi',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appBarTextColor)),
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: appBarTextColor),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Layout03Theme.primary))
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Layout03Theme.error),
                      textAlign: TextAlign.center))
              : _networks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off,
                              size: 64, color: Layout03Theme.textGrey),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma rede Wi-Fi encontrada.',
                            style: Layout03Theme.heading2
                                .copyWith(color: Layout03Theme.textDark),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'O gerenciamento de Wi-Fi pode não estar disponível para o seu equipamento ou contrato.',
                              textAlign: TextAlign.center,
                              style: Layout03Theme.bodyText,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _fetchNetworks,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar Novamente'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Layout03Theme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                      itemCount: _networks.length,
                      itemBuilder: (context, index) {
                        final network = _networks[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: isDarkLayout
                              ? BoxDecoration(
                                  color: const Color(0xFF1C1C1E),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: const Color(0xFF3A3A3C)
                                          .withValues(alpha: 0.3)),
                                )
                              : Layout03Theme.neumorphicDecoration,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(20),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDarkLayout
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : Layout03Theme.background,
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
                                color: isDarkLayout
                                    ? const Color(0xFF00D9FF)
                                    : Layout03Theme.primary,
                                size: 28,
                              ),
                            ),
                            title: Text(network.ssid,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDarkLayout
                                        ? Colors.white
                                        : Layout03Theme.textDark)),
                            subtitle: Text(
                                '${network.frequency} - ${network.enabled ? 'Ativo' : 'Inativo'}',
                                style: Layout03Theme.bodyText.copyWith(
                                    fontSize: 13,
                                    color:
                                        isDarkLayout ? Colors.white70 : null)),
                            trailing: Container(
                              decoration: BoxDecoration(
                                color: isDarkLayout
                                    ? Colors.transparent
                                    : Layout03Theme.background,
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
                                    color: Layout03Theme.textGrey),
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
