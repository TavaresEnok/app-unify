import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/controllers/diagnostic_binding.dart';
import '../../core/controllers/wifi_management_controller.dart';
import '../../core/providers/providers.dart';
import '../../core/services/onu_wifi_service.dart';
import '../../core/services/subscriber_achievements.dart';
import '../../core/vibe/vibe_page_parts.dart';

class WifiPage extends ConsumerStatefulWidget {
  const WifiPage({super.key});

  @override
  ConsumerState<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends ConsumerState<WifiPage> {
  DiagnosticBinding? _binding;
  WifiManagementController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _binding ??= DiagnosticBinding(ref, context, (_, onu) {
      _controller?.dispose();
      final controller = WifiManagementController(onu);
      _controller = controller;
      if (mounted) setState(() {});
      controller.fetchNetworks();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _binding?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final controller = _controller;
    return VibePageScaffold(
      title: 'Minha rede Wi-Fi',
      subtitle: user?.contratoId == null
          ? 'Redes do contrato'
          : 'Roteador do contrato ${user!.contratoId}',
      onBack: Navigator.of(context).canPop()
          ? () => Navigator.of(context).maybePop()
          : null,
      children: [
        if (controller == null)
          const VibeLoading(blocks: 2, label: 'Consultando o roteador')
        else
          ValueListenableBuilder<WifiState>(
              valueListenable: controller,
              builder: (context, state, _) {
                if (state.isLoading) {
                  return const VibeLoading(
                      blocks: 2, label: 'Consultando o roteador');
                }
                if (state.error != null) {
                  return VibeCard(
                      child: VibeEmpty(
                          icon: 'router',
                          title: 'Não conseguimos consultar sua rede',
                          text:
                              'Tente consultar novamente ou fale com seu provedor.',
                          action: VibePageButton(
                              label: 'Consultar novamente',
                              small: true,
                              expand: false,
                              onPressed: controller.fetchNetworks)));
                }
                if (state.networks.isEmpty) {
                  return VibeCard(
                      child: VibeEmpty(
                          icon: 'router',
                          title: 'Nenhuma rede disponível',
                          text:
                              'O equipamento deste contrato não disponibilizou redes para gerenciamento.',
                          action: VibePageButton(
                              label: 'Consultar novamente',
                              small: true,
                              expand: false,
                              onPressed: controller.fetchNetworks)));
                }
                return VibeCard(
                    child: VibeRows(children: [
                  for (final network in state.networks)
                    VibeRow(
                        icon: 'wifi',
                        title: network.ssid,
                        subtitle: [
                          if (network.frequency.isNotEmpty) network.frequency,
                          if (network.enabled == true) 'Ativada',
                          if (network.enabled == false) 'Desativada',
                        ].join(' · '),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => _EditWifiPage(
                                    network: network,
                                    controller: controller)))),
                ]));
              }),
        const VibeNote(
            'A senha atual não é exibida. As alterações dependem da integração com o roteador.'),
        VibePageButton(
            label: 'Consultar novamente',
            icon: 'g-refresh',
            ghost: true,
            onPressed: controller?.fetchNetworks),
      ],
    );
  }
}

class _EditWifiPage extends ConsumerStatefulWidget {
  const _EditWifiPage({required this.network, required this.controller});
  final WifiNetwork network;
  final WifiManagementController controller;

  @override
  ConsumerState<_EditWifiPage> createState() => _EditWifiPageState();
}

class _EditWifiPageState extends ConsumerState<_EditWifiPage> {
  late final TextEditingController _ssid;
  final _password = TextEditingController();
  String? _error;
  bool _saving = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _ssid = TextEditingController(text: widget.network.ssid);
  }

  @override
  void dispose() {
    _ssid.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final error = _ssid.text.trim().isEmpty
        ? 'Informe o nome da rede.'
        : _password.text.isNotEmpty && _password.text.length < 8
            ? 'A senha precisa ter pelo menos 8 caracteres.'
            : null;
    setState(() => _error = error);
    if (error != null) return;
    final user = ref.read(authNotifierProvider).valueOrNull;
    final config = ref.read(configurationProvider).providerConfig;
    setState(() {
      _saving = true;
      _sent = false;
    });
    final success = await widget.controller.updateWifi(
        context, widget.network.id, _ssid.text.trim(), _password.text);
    if (success && user != null && config != null) {
      try {
        await SubscriberAchievements.record(
            config.id, user.cpfCnpj, AchievementEvent.wifi);
      } catch (_) {
        // A alteração da rede já foi confirmada pelo serviço.
      }
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _sent = success;
    });
    if (success) _password.clear();
  }

  @override
  Widget build(BuildContext context) {
    return VibePageScaffold(
      title: 'Alterar rede Wi-Fi',
      subtitle: widget.network.ssid,
      onBack: () => Navigator.of(context).maybePop(),
      children: [
        if (_sent)
          const VibeCard(
              main: true,
              child: VibeOkBox(
                  title: 'Alterações enviadas ao roteador',
                  text: 'Os aparelhos podem precisar se conectar novamente.')),
        VibeCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              if (widget.network.frequency.isNotEmpty) ...[
                VibeLabel(widget.network.frequency),
                const SizedBox(height: 10),
              ],
              VibeField(
                  label: 'Nome da rede',
                  icon: 'wifi',
                  controller: _ssid,
                  maxLength: 32,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next),
              const SizedBox(height: 12),
              VibeField(
                  label: 'Nova senha',
                  icon: 'lock',
                  hint: 'Deixe em branco para manter',
                  controller: _password,
                  obscure: true,
                  enabled: !_saving,
                  onSubmitted: (_) => _save()),
              const SizedBox(height: 10),
              const VibeNote('A senha precisa ter pelo menos 8 caracteres.'),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Semantics(liveRegion: true, child: VibeErrorLine(_error!)),
              ],
            ])),
        VibePageButton(
            label: _saving ? 'Enviando ao roteador…' : 'Salvar alterações',
            onPressed: _saving ? null : _save),
      ],
    );
  }
}
