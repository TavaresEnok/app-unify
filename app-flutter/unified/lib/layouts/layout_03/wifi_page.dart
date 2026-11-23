import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/controllers/diagnostic_binding.dart';
import '../../core/controllers/wifi_management_controller.dart';
import '../../core/providers/providers.dart';
import '../../core/services/onu_wifi_service.dart';
import '../../core/services/subscriber_achievements.dart';
import '../../core/services/tr069_service.dart';
import '../../core/vibe/vibe_page_parts.dart';
import '../../core/vibe/vibe_text.dart';
import '../../core/vibe/vibe_tokens.dart';
import '../../core/widgets/wifi_qr_sheet.dart';

class WifiPage extends ConsumerStatefulWidget {
  const WifiPage({super.key});

  @override
  ConsumerState<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends ConsumerState<WifiPage> {
  DiagnosticBinding? _binding;
  WifiManagementController? _controller;
  Tr069Service? _tr069;

  Tr069Capabilities _caps = const Tr069Capabilities();
  Tr069Overview? _overview;
  List<Tr069Host> _hosts = const [];
  Tr069Diagnostic? _cpeDiag;
  bool _loadingTr069 = false;
  bool _busyAction = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_binding == null) {
      final config = ref.read(configurationProvider).providerConfig;
      _tr069 = Tr069Service(apiUrl: config?.apiUrl);
      _binding = DiagnosticBinding(ref, context, (_, onu) {
        _controller?.dispose();
        final controller = WifiManagementController(onu);
        _controller = controller;
        if (mounted) setState(() {});
        controller.fetchNetworks();
        _loadTr069();
      });
    }
  }

  Future<void> _loadTr069() async {
    final tr = _tr069;
    if (tr == null) return;
    final contratoId =
        ref.read(authNotifierProvider).valueOrNull?.contratoId?.toString();
    setState(() => _loadingTr069 = true);
    try {
      final caps = await tr.fetchCapabilities();
      if (!mounted) return;
      _caps = caps;
      if (caps.enabled) {
        final overview = await tr.fetchStatus(contratoId: contratoId);
        final hosts = caps.features.hosts
            ? await tr.fetchHosts(contratoId: contratoId)
            : const <Tr069Host>[];
        if (!mounted) return;
        setState(() {
          _overview = overview;
          _hosts = hosts;
        });
      }
    } catch (_) {
      // Fallback transparente para o controller SGP padrão.
    } finally {
      if (mounted) setState(() => _loadingTr069 = false);
    }
  }

  Future<void> _rebootRouter() async {
    final tr = _tr069;
    if (tr == null || _busyAction) return;
    final ok = await showVibeConfirm(
      context,
      title: 'Reiniciar roteador?',
      message:
          'A internet será interrompida por cerca de 2 minutos enquanto o equipamento reinicia.',
      confirmLabel: 'Reiniciar',
      cancelLabel: 'Cancelar',
    );
    if (ok != true || !mounted) return;
    setState(() => _busyAction = true);
    try {
      final contratoId =
          ref.read(authNotifierProvider).valueOrNull?.contratoId?.toString();
      final msg = await tr.reboot(contratoId: contratoId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  Future<void> _optimizeChannel() async {
    final tr = _tr069;
    if (tr == null || _busyAction) return;
    setState(() => _busyAction = true);
    try {
      final contratoId =
          ref.read(authNotifierProvider).valueOrNull?.contratoId?.toString();
      final msg = await tr.optimizeWifi(contratoId: contratoId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  Future<void> _runCpeDiagnostic() async {
    final tr = _tr069;
    if (tr == null || _busyAction) return;
    setState(() => _busyAction = true);
    try {
      final contratoId =
          ref.read(authNotifierProvider).valueOrNull?.contratoId?.toString();
      final result = await tr.runDiagnostic(contratoId: contratoId);
      if (mounted) {
        setState(() => _cpeDiag = result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  Future<void> _toggleGuest(Tr069WifiNetwork net) async {
    final tr = _tr069;
    if (tr == null || _busyAction) return;
    setState(() => _busyAction = true);
    try {
      final contratoId =
          ref.read(authNotifierProvider).valueOrNull?.contratoId?.toString();
      final msg = await tr.updateWifi(
        wifiId: net.id,
        enabled: !net.enabled,
        isGuest: true,
        contratoId: contratoId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
      await _loadTr069();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _binding?.dispose();
    _tr069?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final controller = _controller;
    final useTr069Wifis =
        _caps.enabled && _overview != null && _overview!.wifiNetworks.isNotEmpty;

    return VibePageScaffold(
      title: 'Minha rede Wi-Fi',
      subtitle: user?.contratoId == null
          ? 'Redes do contrato'
          : 'Roteador do contrato ${user!.contratoId}',
      onBack: Navigator.of(context).canPop()
          ? () => Navigator.of(context).maybePop()
          : null,
      children: [
        if (_overview != null && _overview!.lanBottleneck100Mbps)
          VibeCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: t.bad, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cabo de rede limitado a 100 Mbps',
                          style: vibeText(t, 13.5, 700, color: t.bad)),
                      const SizedBox(height: 3),
                      Text(
                        'Detectamos uma porta de cabo limitada a 100 Mbps no seu plano de ${_overview!.planDownloadMbps ?? ''} Mega. Use cabo Cat5e/Cat6 para aproveitar toda a velocidade.',
                        style: vibeText(t, 12, 500, color: t.mut, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (_overview != null)
          VibeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        [_overview!.manufacturer, _overview!.model]
                                .where((s) => s.isNotEmpty)
                                .join(' ')
                                .isNotEmpty
                            ? [_overview!.manufacturer, _overview!.model]
                                .where((s) => s.isNotEmpty)
                                .join(' ')
                            : 'Roteador gerenciado',
                        style: vibeText(t, 14.5, 700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (_overview!.online ? t.ok : t.bad)
                            .withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        _overview!.online ? 'Online' : 'Offline',
                        style: vibeText(
                          t,
                          11,
                          700,
                          color: _overview!.online ? t.ok : t.bad,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (_overview!.uptimeSeconds != null)
                      'Ligado há ${(_overview!.uptimeSeconds! / 3600).floor()}h',
                    if (_overview!.opticalRxDbm != null)
                      'Fibra ${_overview!.opticalRxDbm!.toStringAsFixed(1)} dBm',
                    if (_hosts.isNotEmpty)
                      '${_hosts.length} aparelho(s) conectado(s)',
                  ].join(' · '),
                  style: vibeText(t, 12, 500, color: t.mut),
                ),
              ],
            ),
          ),
        if (useTr069Wifis)
          VibeCard(
            child: VibeRows(
              children: [
                for (final net in _overview!.wifiNetworks)
                  VibeRow(
                    icon: 'wifi',
                    title: net.isGuest ? '${net.ssid} (Visitante)' : net.ssid,
                    subtitle: [
                      net.band,
                      'Canal ${net.channel}',
                      net.enabled ? 'Ativada' : 'Desativada',
                    ].join(' · '),
                    onTap: () async {
                      if (net.isGuest && _caps.features.guestWifi) {
                        await _toggleGuest(net);
                        return;
                      }
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _EditWifiPage(
                            network: WifiNetwork(
                              id: net.id,
                              ssid: net.ssid,
                              frequency: net.band,
                              enabled: net.enabled,
                            ),
                            controller: controller,
                            tr069Service: _tr069,
                            onUpdated: _loadTr069,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          )
        else if (controller == null || _loadingTr069)
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
                              onPressed: () {
                                controller.fetchNetworks();
                                _loadTr069();
                              })));
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
                              onPressed: () {
                                controller.fetchNetworks();
                                _loadTr069();
                              })));
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
        if (_caps.enabled &&
            (_caps.features.reboot ||
                _caps.features.channelOptimize ||
                _caps.features.speedDiagnostic))
          VibeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const VibeLabel('Ações no roteador'),
                const SizedBox(height: 10),
                if (_caps.features.channelOptimize) ...[
                  VibePageButton(
                    label: _busyAction
                        ? 'Enviando comando…'
                        : 'Otimizar canal Wi-Fi',
                    ghost: true,
                    onPressed: _busyAction ? null : _optimizeChannel,
                  ),
                  const SizedBox(height: 8),
                ],
                if (_caps.features.speedDiagnostic) ...[
                  VibePageButton(
                    label: _busyAction
                        ? 'Testando no roteador…'
                        : 'Testar fibra direto no roteador',
                    ghost: true,
                    onPressed: _busyAction ? null : _runCpeDiagnostic,
                  ),
                  const SizedBox(height: 8),
                ],
                if (_caps.features.reboot)
                  VibePageButton(
                    label: 'Reiniciar roteador',
                    ghost: true,
                    onPressed: _busyAction ? null : _rebootRouter,
                  ),
              ],
            ),
          ),
        if (_cpeDiag != null)
          VibeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VibeLabel('Teste direto no roteador (TR-143)'),
                const SizedBox(height: 6),
                Text(_cpeDiag!.summary,
                    style: vibeText(t, 13, 600, height: 1.4)),
              ],
            ),
          ),
        if (_hosts.isNotEmpty)
          VibeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VibeLabel('Dispositivos conectados (${_hosts.length})'),
                const SizedBox(height: 8),
                for (final host in _hosts)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          host.interfaceType == 'ethernet'
                              ? Icons.lan_outlined
                              : Icons.smartphone_rounded,
                          size: 18,
                          color: t.mut,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(host.hostname,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: vibeText(t, 13, 600)),
                              Text(
                                [
                                  host.interfaceLabel,
                                  if (host.ip.isNotEmpty) host.ip,
                                  if (host.rssiDbm != null)
                                    '${host.rssiDbm} dBm',
                                ].join(' · '),
                                style: vibeText(t, 11.5, 500, color: t.mut),
                              ),
                            ],
                          ),
                        ),
                        if (host.qualityLabel.isNotEmpty)
                          Text(
                            host.qualityLabel,
                            style: vibeText(
                              t,
                              11,
                              700,
                              color: host.signalQuality == 'weak'
                                  ? t.bad
                                  : host.signalQuality == 'fair'
                                      ? t.wa
                                      : t.ok,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        const VibeNote(
            'A senha atual não é exibida. As alterações dependem da integração com o roteador.'),
        VibePageButton(
            label: 'Consultar novamente',
            icon: 'g-refresh',
            ghost: true,
            onPressed: () {
              controller?.fetchNetworks();
              _loadTr069();
            }),
      ],
    );
  }
}

class _EditWifiPage extends ConsumerStatefulWidget {
  const _EditWifiPage({
    required this.network,
    required this.controller,
    this.tr069Service,
    this.onUpdated,
  });
  final WifiNetwork network;
  final WifiManagementController? controller;
  final Tr069Service? tr069Service;
  final Future<void> Function()? onUpdated;

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
    bool success = false;
    if (widget.tr069Service != null) {
      try {
        await widget.tr069Service!.updateWifi(
          wifiId: widget.network.id,
          ssid: _ssid.text.trim(),
          password: _password.text.isEmpty ? null : _password.text,
          contratoId: user?.contratoId?.toString(),
        );
        success = true;
        await widget.onUpdated?.call();
      } catch (e) {
        if (mounted) {
          setState(
              () => _error = e.toString().replaceFirst('Exception: ', ''));
        }
      }
    } else if (widget.controller != null) {
      success = await widget.controller!.updateWifi(
          context, widget.network.id, _ssid.text.trim(), _password.text);
    }
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
        VibePageButton(
            label: 'Gerar QR Code do Wi-Fi',
            ghost: true,
            onPressed: () => showWifiQrSheet(
                  context,
                  ssid: _ssid.text.trim().isNotEmpty
                      ? _ssid.text.trim()
                      : widget.network.ssid,
                  initialPassword: _password.text,
                )),
      ],
    );
  }
}
