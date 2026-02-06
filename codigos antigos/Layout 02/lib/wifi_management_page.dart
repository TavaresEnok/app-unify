import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_provedor/services/auth_service.dart';
import 'package:app_provedor/diagnostico_service.dart';
import 'shared/widgets/dashboard_card.dart';

class WifiManagementPage extends StatefulWidget {
  final DiagnosticoService service;

  const WifiManagementPage({super.key, required this.service});

  @override
  State<WifiManagementPage> createState() => _WifiManagementPageState();
}

class _WifiManagementPageState extends State<WifiManagementPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _wifiList = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWifiData();
  }

  Future<void> _loadWifiData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final usuario = authService.usuario;
      if (usuario == null) throw Exception("Usuário não logado");

      final sgpParams = {
        'token': widget.service.providerConfig.config.integrations.apiToken,
        'app': widget.service.providerConfig.config.integrations.appName,
      };

      final sgpBaseUrl =
          widget.service.providerConfig.config.integrations.sgpBaseUrl;

      final result = await widget.service.cpeManager.getWifiList(
        cpfCnpj: usuario.cpfCnpj,
        senha: usuario.senha,
        contractId: usuario.contratoId ?? 0,
        sgpParams: sgpParams,
        sgpBaseUrl: sgpBaseUrl,
      );

      setState(() {
        _wifiList = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception:", "");
        _isLoading = false;
      });
    }
  }

  void _showEditDialog(Map<String, dynamic> wifi) {
    final ssidController = TextEditingController(text: wifi['ssid']);
    final passwordController = TextEditingController(
        text: ''); // Não mostramos senha atual por segurança se não vier da API
    bool obscureText = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text("Alterar Senha Wi-Fi",
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Editando: ${wifi['ssid']}",
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: ssidController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Nome da Rede (SSID)",
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscureText,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Nova Senha",
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue)),
                  suffixIcon: IconButton(
                    icon: Icon(
                        obscureText ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white54),
                    onPressed: () => setState(() => obscureText = !obscureText),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor),
              onPressed: () async {
                Navigator.pop(context);
                await _updateWifi(
                    wifi['id'], ssidController.text, passwordController.text);
              },
              child:
                  const Text("Salvar", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateWifi(String wifiId, String ssid, String password) async {
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("A senha deve ter no mínimo 8 caracteres.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final usuario = authService.usuario!;

      final sgpParams = {
        'token': widget.service.providerConfig.config.integrations.apiToken,
        'app': widget.service.providerConfig.config.integrations.appName,
      };
      final sgpBaseUrl =
          widget.service.providerConfig.config.integrations.sgpBaseUrl;

      await widget.service.cpeManager.updateWifi(
        cpfCnpj: usuario.cpfCnpj,
        senha: usuario.senha,
        contractId: usuario.contratoId ?? 0,
        wifiId: wifiId,
        ssid: ssid,
        password: password,
        sgpParams: sgpParams,
        sgpBaseUrl: sgpBaseUrl,
      );

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Wi-Fi atualizado com sucesso!"),
          backgroundColor: Colors.green));
      _loadWifiData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gerenciar Wi-Fi")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: _errorMessage!.contains("500")
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.router_outlined,
                                size: 64, color: Colors.orange),
                            const SizedBox(height: 16),
                            const Text(
                              "Funcionalidade Indisponível",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                "Seu equipamento não suporta gerenciamento remoto de Wi-Fi ou não está integrado ao sistema.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text("Voltar"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white10,
                                foregroundColor: Colors.white,
                              ),
                            )
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Text("Erro: $_errorMessage",
                                  style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadWifiData,
                                icon: const Icon(Icons.refresh),
                                label: const Text("Tentar Novamente"),
                              )
                            ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _wifiList.length,
                  itemBuilder: (context, index) {
                    final wifi = _wifiList[index];
                    return DashboardCard(
                      child: ListTile(
                        leading: Icon(Icons.wifi,
                            color: Theme.of(context).primaryColor, size: 32),
                        title: Text(wifi['ssid'] ?? 'Sem Nome',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "${wifi['frequency'] ?? ''} | Canal: ${wifi['channel'] ?? 'Auto'}",
                            style: const TextStyle(color: Colors.white70)),
                        trailing: IconButton(
                          icon:
                              const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () => _showEditDialog(wifi),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
