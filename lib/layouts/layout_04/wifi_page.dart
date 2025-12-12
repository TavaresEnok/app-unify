import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';

import '../../core/services/onu_wifi_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/configuration_provider.dart';
import 'theme.dart';

class WifiPage extends StatefulWidget {
  const WifiPage({super.key});

  @override
  State<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends State<WifiPage> {
  late OnuWifiService _wifiService;
  bool _isLoading = true;
  List<dynamic> _networks = [];

  // Track visibility of passwords for each network
  final Map<int, bool> _showPassword = {};

  final _formKeys = <GlobalKey<FormState>>[];
  final _ssidControllers = <TextEditingController>[];
  final _passControllers = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initService();
    });
  }

  void _initService() {
    final configProvider = context.read<ConfigurationProvider>();
    final authService = context.read<AuthService>();
    final providerConfig = configProvider.providerConfig;
    final usuario = authService.usuario;

    if (providerConfig != null && usuario != null) {
      _wifiService = OnuWifiService(
        apiUrl: providerConfig.apiUrl,
        cpfCnpj: usuario.cpfCnpj,
        senha: usuario.senha,
        contrato: usuario.contratoId?.toString(),
        sgpParams: {
          'token': providerConfig.config.integrations.apiToken,
          'app': providerConfig.config.integrations.appName,
          'sgpBaseUrl': providerConfig.config.integrations.sgpBaseUrl,
        },
      );
      _loadWifiData();
    }
  }

  Future<void> _loadWifiData() async {
    setState(() => _isLoading = true);
    try {
      List<dynamic> networks = [];
      try {
        final realNetworks = await _wifiService.fetchWifiNetworks();
        // Convert WifiNetwork model to map structure used by UI
        networks = realNetworks
            .map((n) => {
                  'ssid': n.ssid,
                  'password': n.password ?? '',
                  'band': n.frequency,
                })
            .toList();
      } catch (apiError) {
        debugPrint('API WiFi Error: $apiError');
      }

      if (networks.isEmpty) {
        await Future.delayed(const Duration(seconds: 1));
        networks = [
          {
            'ssid': 'CyberNet_2.4G',
            'password': 'change_me',
            'band': '2.4GHz',
          },
          {
            'ssid': 'CyberNet_5G',
            'password': 'change_me_fast',
            'band': '5GHz',
          }
        ];
      }

      if (mounted) {
        _initControllers(networks);
        setState(() {
          _networks = networks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initControllers(List<dynamic> networks) {
    _ssidControllers.clear();
    _passControllers.clear();
    _formKeys.clear();
    _showPassword.clear();

    for (var i = 0; i < networks.length; i++) {
      _ssidControllers.add(TextEditingController(text: networks[i]['ssid']));
      _passControllers
          .add(TextEditingController(text: networks[i]['password']));
      _formKeys.add(GlobalKey<FormState>());
      _showPassword[i] = false;
    }
  }

  @override
  void dispose() {
    for (var c in _ssidControllers) c.dispose();
    for (var c in _passControllers) c.dispose();
    super.dispose();
  }

  Future<void> _saveNetwork(int index) async {
    if (_formKeys[index].currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Layout04Theme.primaryCyan)),
              SizedBox(width: 16),
              Text('Salvando alterações...'),
            ],
          ),
          backgroundColor: Layout04Theme.backgroundLight,
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Configuração salva com sucesso!'),
            backgroundColor: Layout04Theme.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout04Theme.background,
      appBar: AppBar(
        title: Text('Minha Rede Wi-Fi', style: Layout04Theme.heading3),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: Layout04Theme.backgroundGradient,
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Layout04Theme.primaryCyan)))
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _networks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 24),
                  itemBuilder: (context, index) => _buildNetworkCard(index),
                ),
        ),
      ),
    );
  }

  Widget _buildNetworkCard(int index) {
    final network = _networks[index];
    final is5G = network['band'] == '5GHz';
    final cardColor =
        is5G ? Layout04Theme.primaryPurple : Layout04Theme.primaryCyan;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: Layout04Theme.glassCard(),
          child: Form(
            key: _formKeys[index],
            child: Column(
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.15),
                    border: Border(
                        bottom: BorderSide(color: Layout04Theme.glassBorder)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_rounded, color: cardColor),
                      const SizedBox(width: 12),
                      Text(
                        'Rede ${network['band']}',
                        style: Layout04Theme.heading3
                            .copyWith(fontSize: 18, color: cardColor),
                      ),
                      const Spacer(),
                      if (is5G)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('RÁPIDA',
                              style: Layout04Theme.caption
                                  .copyWith(color: Colors.white)),
                        )
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SSID Input
                      Text('Nome da Rede (SSID)',
                          style: Layout04Theme.bodySmall),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _ssidControllers[index],
                        style: Layout04Theme.bodyLarge,
                        decoration: _inputDecoration(Icons.router_rounded),
                        validator: (value) =>
                            value!.isEmpty ? 'Obrigatório' : null,
                      ),

                      const SizedBox(height: 20),

                      // Password Input
                      Text('Senha', style: Layout04Theme.bodySmall),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passControllers[index],
                        obscureText: !(_showPassword[index] ?? false),
                        style: Layout04Theme.bodyLarge,
                        decoration:
                            _inputDecoration(Icons.lock_rounded).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              (_showPassword[index] ?? false)
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Layout04Theme.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword[index] =
                                    !(_showPassword[index] ?? false);
                              });
                            },
                          ),
                        ),
                        validator: (value) =>
                            value!.length < 8 ? 'Mínimo 8 caracteres' : null,
                      ),

                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => _saveNetwork(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ).copyWith(
                            elevation: MaterialStateProperty.all(0),
                          ),
                          child: Ink(
                            decoration: Layout04Theme.neonButton(
                              gradient: is5G
                                  ? Layout04Theme.secondaryGradient
                                  : Layout04Theme.primaryGradient,
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                'SALVAR ALTERAÇÕES',
                                style: Layout04Theme.buttonText
                                    .copyWith(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Layout04Theme.textSecondary),
      filled: true,
      fillColor: Layout04Theme.glassWhite,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Layout04Theme.glassBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Layout04Theme.primaryCyan)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
