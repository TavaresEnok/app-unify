import '../../core/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/onu_wifi_service.dart';
import '../../core/controllers/diagnostic_binding.dart';
import '../../core/controllers/wifi_management_controller.dart';
import '../../core/widgets/content_state.dart';
import '../../core/vibe/vibe_page_parts.dart';

class WifiPage extends ConsumerStatefulWidget {
  const WifiPage({super.key});

  @override
  ConsumerState<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends ConsumerState<WifiPage> {
  bool _isLoading = true;
  List<WifiNetwork> _networks = [];
  String? _errorMessage;
  DiagnosticBinding? _binding;
  WifiManagementController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _binding ??= DiagnosticBinding(ref, context, (_, onu) {
      _controller?.dispose();
      final controller = WifiManagementController(onu);
      _controller = controller;
      controller.addListener(() {
        if (!mounted) return;
        setState(() {
          _isLoading = controller.value.isLoading;
          _networks = controller.value.networks;
          _errorMessage = controller.value.error;
        });
      });
      controller.fetchNetworks();
    });
  }

  Future<void> _fetchNetworks() async {
    await _controller?.fetchNetworks();
  }

  Future<void> _updateWifi(
      WifiNetwork network, String newSsid, String newPassword) async {
    await _controller?.updateWifi(context, network.id, newSsid, newPassword);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _binding?.dispose();
    super.dispose();
  }

  Future<void> _showEditDialog(WifiNetwork network) async {
    final ssidController = TextEditingController(text: network.ssid);
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;
    final values = await showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
                title: const Text('Alterar rede Wi-Fi'),
                content: SingleChildScrollView(
                    child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                                controller: ssidController,
                                decoration: const InputDecoration(
                                    labelText: 'Nome da rede'),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Informe o nome da rede.'
                                        : null),
                            const SizedBox(height: 20),
                            TextFormField(
                                controller: passwordController,
                                obscureText: obscurePassword,
                                enableSuggestions: false,
                                autocorrect: false,
                                decoration: InputDecoration(
                                    labelText: 'Nova senha',
                                    helperText:
                                        'Deixe em branco para manter a senha atual.',
                                    helperMaxLines: 2,
                                    suffixIcon: IconButton(
                                        tooltip: obscurePassword
                                            ? 'Mostrar senha'
                                            : 'Ocultar senha',
                                        icon: Icon(obscurePassword
                                            ? Icons.visibility
                                            : Icons.visibility_off),
                                        onPressed: () => update(() =>
                                            obscurePassword =
                                                !obscurePassword))),
                                validator: (value) => value != null &&
                                        value.isNotEmpty &&
                                        value.length < 8
                                    ? 'Use pelo menos 8 caracteres.'
                                    : null),
                            const SizedBox(height: 20),
                            const Text(
                                'Ao alterar a rede, seus aparelhos podem se desconectar. '
                                'Você precisará conectá-los novamente com os novos dados.'),
                          ],
                        ))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(context, [
                            ssidController.text.trim(),
                            passwordController.text
                          ]);
                        }
                      },
                      child: const Text('Salvar alteração')),
                ],
              )),
    );
    // Dialog widgets finish their exit animation before their controllers go away.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    ssidController.dispose();
    passwordController.dispose();
    if (values != null && mounted) {
      await _updateWifi(network, values[0], values[1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(layoutTokensProvider);
    return Theme(
        data: tokens.themeData(base: Theme.of(context)),
        child: Builder(
          builder: (context) => VibeHeaderPage(
            title: 'Minha rede Wi-Fi',
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? ContentState(
                        icon: Icons.wifi_off_outlined,
                        title: 'Não conseguimos consultar sua rede',
                        message:
                            'Os dados do Wi-Fi não carregaram. Sua internet pode estar '
                            'funcionando normalmente. Tente consultar novamente.',
                        actionLabel: 'Tentar de novo',
                        onAction: _fetchNetworks)
                    : _networks.isEmpty
                        ? ContentState(
                            icon: Icons.router_outlined,
                            title: 'Nenhuma rede disponível',
                            message:
                                'O gerenciamento de Wi-Fi pode não estar disponível para seu '
                                'equipamento ou contrato. Consulte seu provedor se precisar de ajuda.',
                            actionLabel: 'Consultar novamente',
                            onAction: _fetchNetworks)
                        : RefreshIndicator(
                            onRefresh: _fetchNetworks,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: _networks.length,
                              itemBuilder: (context, index) {
                                final network = _networks[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: tokens.cardDecoration,
                                  child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.wifi,
                                              color: tokens.textPrimary,
                                              size: 28),
                                          const SizedBox(height: 12),
                                          Text(network.ssid,
                                              style: TextStyle(
                                                  color: tokens.textPrimary,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 8),
                                          Text(
                                              '${network.frequency} · ${network.enabled ? 'Rede ativada' : 'Rede desativada'}',
                                              style: TextStyle(
                                                  color: tokens.textSecondary)),
                                          const SizedBox(height: 16),
                                          OutlinedButton.icon(
                                              onPressed: () =>
                                                  _showEditDialog(network),
                                              icon: const Icon(
                                                  Icons.edit_outlined),
                                              label: const Text(
                                                  'Alterar nome ou senha')),
                                        ],
                                      )),
                                );
                              },
                            )),
          ),
        ));
  }
}
