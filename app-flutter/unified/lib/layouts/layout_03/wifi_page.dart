import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/controllers/diagnostic_binding.dart';
import '../../core/controllers/wifi_management_controller.dart';
import '../../core/navigation/customer_routes.dart';
import '../../core/navigation/customer_shell_scope.dart';
import '../../core/providers/equipment_status_provider.dart';
import '../../core/providers/providers.dart';
import '../../core/services/onu_wifi_service.dart';
import '../../core/services/subscriber_achievements.dart';
import '../../core/services/tr069_service.dart';
import '../../core/vibe/vibe_page_parts.dart';
import '../../core/vibe/vibe_text.dart';
import '../../core/vibe/vibe_tokens.dart';
import '../../core/widgets/equipment_status_card.dart';
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

  /// Recursos do gerenciador; `null` até a primeira resposta ou quando a
  /// consulta falhou (aí vale a lista de redes direta do ERP).
  Tr069Capabilities? _caps;
  bool _capsChecked = false;
  Tr069Overview? _overview;
  List<Tr069Host> _hosts = const [];
  Tr069Diagnostic? _cpeDiag;
  bool _loading = false;
  bool _unmanaged = false;
  String? _statusError;
  bool _busyAction = false;
  int _loadSeq = 0;

  bool get _managed => _caps?.enabled == true;

  String? get _contratoId =>
      ref.read(authNotifierProvider).valueOrNull?.contratoId?.toString();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_binding == null) {
      final config = ref.read(configurationProvider).providerConfig;
      _tr069 = ref.read(tr069ServiceFactoryProvider)(config?.apiUrl);
      _binding = DiagnosticBinding(ref, context, (_, onu) {
        _controller?.dispose();
        _controller = WifiManagementController(onu);
        if (mounted) setState(() {});
        _load();
      });
    }
  }

  /// Uma leitura do roteador por vez: o status já traz redes e aparelhos.
  /// A lista direta do ERP só é usada quando não há gerenciador TR-069.
  Future<void> _load() async {
    final tr = _tr069;
    if (tr == null || _loading) return;
    final seq = ++_loadSeq;
    setState(() {
      _loading = true;
      _statusError = null;
    });
    try {
      final contratoId = _contratoId;
      final caps = await tr.fetchCapabilitiesOrNull(contratoId: contratoId);
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _caps = caps;
        _capsChecked = true;
        if (caps?.deviceManaged == false) _unmanaged = true;
      });
      if (caps == null || !caps.enabled) {
        await _controller?.fetchNetworks();
        return;
      }
      try {
        final overview = await tr.fetchStatus(contratoId: contratoId);
        if (!mounted || seq != _loadSeq) return;
        setState(() {
          _overview = overview;
          if (overview?.hosts != null) _hosts = overview!.hosts!;
          _unmanaged = caps.deviceManaged == false ||
              overview?.deviceManaged == false ||
              (overview != null && !overview.hasRouter);
          _loading = false;
        });
        // Servidor antigo: os aparelhos vêm numa segunda chamada, depois
        // que o cartão do roteador já está na tela.
        if (overview != null &&
            overview.hosts == null &&
            caps.features.hosts &&
            !_unmanaged) {
          final hosts = await tr.fetchHosts(contratoId: contratoId);
          if (mounted && seq == _loadSeq) setState(() => _hosts = hosts);
        }
      } on Tr069Exception catch (e) {
        if (!mounted || seq != _loadSeq) return;
        setState(() {
          if (e.unmanaged) {
            _unmanaged = true;
          } else {
            _statusError = e.message;
          }
        });
      } catch (_) {
        if (!mounted || seq != _loadSeq) return;
        setState(() => _statusError =
            'Não conseguimos consultar seu roteador agora. Tente de novo em instantes.');
      }
    } finally {
      if (mounted && seq == _loadSeq) setState(() => _loading = false);
    }
  }

  void _openSupport() {
    final shell = CustomerShellScope.maybeOf(context);
    if (shell?.navigate != null) {
      shell!.navigate!('support');
    } else {
      Navigator.of(context).maybePop();
    }
  }

  String _errorText(Object e) => e.toString().replaceFirst('Exception: ', '');

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
      final msg = await tr.reboot(contratoId: _contratoId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorText(e))));
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
      final msg = await tr.optimizeWifi(contratoId: _contratoId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorText(e))));
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
      final result = await tr.runDiagnostic(contratoId: _contratoId);
      if (mounted) setState(() => _cpeDiag = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorText(e))));
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
      final msg = await tr.updateWifi(
        wifiId: net.id,
        enabled: !net.enabled,
        isGuest: true,
        contratoId: _contratoId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorText(e))));
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

  /// Duas linhas de rede no desenho real, com os textos cobertos.
  Widget _wifiLoadingCard() => Semantics(
        label: 'Consultando o roteador',
        liveRegion: true,
        child: const VibeCard(
          child: VibeRows(children: [
            VibeRow(
                icon: 'wifi',
                title: 'Nome da rede Wi-Fi',
                subtitle: 'Wi-Fi 2,4 GHz · Canal 11',
                redacted: true),
            VibeRow(
                icon: 'wifi',
                title: 'Nome da rede Wi-Fi 5G',
                subtitle: 'Wi-Fi 5 GHz · Canal 44 · Wi-Fi 5 (ac)',
                redacted: true),
          ]),
        ),
      );

  Widget _unmanagedCard() {
    final config = ref.read(configurationProvider).providerConfig;
    final canSupport =
        config == null || CustomerRoutes.enabled(config, 'support');
    return VibeCard(
      child: VibeEmpty(
        icon: 'router',
        title: 'Seu roteador ainda não é gerenciado pelo app',
        text: 'Para trocar o nome ou a senha do Wi-Fi, fale com o suporte.',
        action: canSupport
            ? VibePageButton(
                label: 'Falar com o suporte',
                small: true,
                expand: false,
                onPressed: _openSupport)
            : null,
      ),
    );
  }

  Widget _errorCard(String message) => VibeCard(
        child: VibeEmpty(
          icon: 'router',
          title: 'Não conseguimos consultar sua rede',
          text: message,
          action: VibePageButton(
              label: 'Consultar novamente',
              small: true,
              expand: false,
              onPressed: _loading ? null : _load),
        ),
      );

  void _openEdit(Tr069WifiNetwork net) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _EditWifiPage(
          network: WifiNetwork(
            id: net.id,
            ssid: net.ssid,
            frequency: net.bandLabel,
            enabled: net.enabled,
          ),
          controller: _controller,
          tr069Service: _tr069,
          passwordRequired: _overview?.passwordReadable == false,
          onUpdated: _load,
        ),
      ),
    );
  }

  Widget _tr069Networks(VibeTokens t) {
    final overview = _overview!;
    final shown = Tr069WifiNetwork.visible(overview.wifiNetworks,
        includeGuest: _caps!.features.guestWifi);
    final hidden = overview.wifiNetworks.length - shown.length;
    if (shown.isEmpty) {
      return VibeCard(
        child: VibeEmpty(
          icon: 'wifi',
          title: 'Nenhuma rede Wi-Fi ativa no roteador.',
          text: 'Se precisar ativar o Wi-Fi, fale com o suporte.',
          action: VibePageButton(
              label: 'Falar com o suporte',
              small: true,
              expand: false,
              onPressed: _openSupport),
        ),
      );
    }
    return VibeCard(
      child: VibeRows(children: [
        for (final net in shown)
          VibeRow(
            icon: 'wifi',
            title: net.isGuest ? '${net.ssid} (Visitante)' : net.ssid,
            subtitle: [
              net.summary,
              if (net.isGuest) net.enabled ? 'Ativada' : 'Desativada',
            ].join(' · '),
            onTap: _busyAction
                ? null
                : () async {
                    if (net.isGuest) {
                      await _toggleGuest(net);
                      return;
                    }
                    _openEdit(net);
                  },
          ),
        if (hidden > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              hidden == 1
                  ? '1 rede desativada do roteador não aparece aqui.'
                  : '$hidden redes desativadas do roteador não aparecem aqui.',
              style: vibeText(t, 12, 500, color: t.mut, height: 1.4),
            ),
          ),
      ]),
    );
  }

  Widget _legacyNetworks(WifiManagementController controller) =>
      ValueListenableBuilder<WifiState>(
          valueListenable: controller,
          builder: (context, state, _) {
            if (state.isLoading && state.networks.isEmpty) {
              return _wifiLoadingCard();
            }
            if (state.error != null && state.networks.isEmpty) {
              final text = state.error!.replaceFirst('Exception: ', '');
              if (RegExp(r'gerenciad|n[ãa]o definido|422', caseSensitive: false)
                  .hasMatch(text)) {
                return _unmanagedCard();
              }
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
                          onPressed: _loading ? null : _load)));
            }
            final networks =
                state.networks.where((n) => n.enabled != false).toList();
            final list = networks.isEmpty ? state.networks : networks;
            if (list.isEmpty) {
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
                          onPressed: _loading ? null : _load)));
            }
            return VibeCard(
                child: VibeRows(children: [
              for (final network in list)
                VibeRow(
                    icon: 'wifi',
                    title: network.ssid,
                    subtitle: network.frequency,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => _EditWifiPage(
                                network: network, controller: controller)))),
            ]));
          });

  Widget _hostsCard(VibeTokens t) {
    final snapshot = _overview?.online == null;
    return VibeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          VibeLabel('Aparelhos conectados (${_hosts.length})'),
          if (snapshot) ...[
            const SizedBox(height: 2),
            Text('Vistos na última leitura do roteador',
                style: vibeText(t, 11.5, 500, color: t.mut)),
          ],
          const SizedBox(height: 4),
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
                            style: vibeText(t, 13, 600,
                                color: host.hostname == Tr069Host.unnamed
                                    ? t.mut
                                    : null)),
                        Text(
                          [
                            host.interfaceLabel,
                            if (host.ip.isNotEmpty) host.ip,
                            if (host.rssiDbm != null) '${host.rssiDbm} dBm',
                          ].join(' · '),
                          style: vibeText(t, 11.5, 500, color: t.mut),
                        ),
                      ],
                    ),
                  ),
                  if (host.rssiDbm != null && host.qualityLabel.isNotEmpty)
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
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final controller = _controller;
    final overview = _overview;
    final firstLoad = _loading && overview == null;

    final Widget networks;
    if (!_capsChecked || controller == null) {
      networks = _wifiLoadingCard();
    } else if (_managed) {
      if (_unmanaged) {
        networks = _unmanagedCard();
      } else if (overview != null) {
        networks = _tr069Networks(t);
      } else if (firstLoad) {
        networks = _wifiLoadingCard();
      } else {
        networks = _errorCard(_statusError ??
            'Tente consultar novamente ou fale com seu provedor.');
      }
    } else {
      networks = _legacyNetworks(controller);
    }

    final showEquipment = _managed &&
        (firstLoad && !_unmanaged ||
            overview?.fiber != null ||
            overview?.hasRouter == true);

    return VibePageScaffold(
      title: 'Minha rede Wi-Fi',
      subtitle: user?.contratoId == null
          ? 'Redes do contrato'
          : 'Roteador do contrato ${user!.contratoId}',
      onBack: Navigator.of(context).canPop()
          ? () => Navigator.of(context).maybePop()
          : null,
      children: [
        if (overview != null && overview.lanBottleneck100Mbps)
          VibeCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                          'Detectamos uma porta de cabo limitada a 100 Mbps no seu plano de ${overview.planDownloadMbps ?? ''} Mega. Use cabo Cat5e/Cat6 para aproveitar toda a velocidade.',
                          style:
                              vibeText(t, 12, 500, color: t.mut, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Fibra e roteador: na primeira consulta, o mesmo cartão com os
        // valores cobertos, para a lista não descer quando ele chegar.
        if (showEquipment)
          EquipmentStatusCard(
            overview: overview,
            loading: firstLoad,
            showRouter: !_unmanaged,
            hostsCount: overview?.hosts == null && _hosts.isNotEmpty
                ? _hosts.length
                : null,
          ),
        networks,
        if (_managed &&
            !_unmanaged &&
            overview != null &&
            (_caps!.features.reboot ||
                _caps!.features.channelOptimize ||
                _caps!.features.speedDiagnostic))
          VibeCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const VibeLabel('Ações no roteador'),
                  const SizedBox(height: 10),
                  if (_caps!.features.channelOptimize) ...[
                    VibePageButton(
                      label: _busyAction
                          ? 'Enviando comando…'
                          : 'Otimizar canal Wi-Fi',
                      ghost: true,
                      onPressed: _busyAction ? null : _optimizeChannel,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_caps!.features.speedDiagnostic) ...[
                    VibePageButton(
                      label: _busyAction
                          ? 'Testando no roteador…'
                          : 'Testar fibra direto no roteador',
                      ghost: true,
                      onPressed: _busyAction ? null : _runCpeDiagnostic,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_caps!.features.reboot)
                    VibePageButton(
                      label: 'Reiniciar roteador',
                      ghost: true,
                      onPressed: _busyAction ? null : _rebootRouter,
                    ),
                ],
              ),
            ),
          ),
        if (_cpeDiag != null)
          VibeCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
          ),
        if (_hosts.isNotEmpty && !_unmanaged) _hostsCard(t),
        if (!_unmanaged)
          VibeNote(overview?.passwordReadable == false
              ? 'O roteador não informa a senha salva. Para trocar o nome da rede, digite a senha atual ou uma nova.'
              : 'A senha atual não é exibida. As alterações dependem da integração com o roteador.'),
        VibePageButton(
            label: _loading ? 'Consultando…' : 'Consultar novamente',
            icon: 'g-refresh',
            ghost: true,
            onPressed: _loading ? null : _load),
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
    this.passwordRequired = false,
  });
  final WifiNetwork network;
  final WifiManagementController? controller;
  final Tr069Service? tr069Service;
  final Future<void> Function()? onUpdated;

  /// O roteador não informa a senha salva: sem digitar uma senha, a
  /// alteração falharia no equipamento.
  final bool passwordRequired;

  @override
  ConsumerState<_EditWifiPage> createState() => _EditWifiPageState();
}

class _EditWifiPageState extends ConsumerState<_EditWifiPage> {
  late final TextEditingController _ssid;
  final _password = TextEditingController();
  String? _error;
  bool _saving = false;
  bool _sent = false;

  /// Depois de uma demora do roteador, o envio fica bloqueado por 1 minuto
  /// para não mandar uma segunda troca enquanto ele se reconfigura. O prazo
  /// vale para a rede, não para a tela: sair e voltar não libera antes.
  static final Map<String, DateTime> _lockedUntil = {};
  static const cooldown = Duration(seconds: 60);
  Timer? _cooldown;

  @override
  void initState() {
    super.initState();
    _ssid = TextEditingController(text: widget.network.ssid);
    _scheduleUnlock();
  }

  void _scheduleUnlock() {
    _cooldown?.cancel();
    final until = _lockedUntil[widget.network.id];
    if (until == null) return;
    final left = until.difference(DateTime.now());
    if (left <= Duration.zero) {
      _lockedUntil.remove(widget.network.id);
      return;
    }
    _cooldown = Timer(left, () {
      _lockedUntil.remove(widget.network.id);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cooldown?.cancel();
    _ssid.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _locked => _cooldown?.isActive == true;

  Future<void> _save() async {
    if (_saving || _locked) return;
    final error = _ssid.text.trim().isEmpty
        ? 'Informe o nome da rede.'
        : widget.passwordRequired && _password.text.isEmpty
            ? 'Digite a senha do Wi-Fi (a atual ou uma nova).'
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
        // A lista atualiza por trás; a confirmação aparece já.
        unawaited(widget.onUpdated?.call());
      } on Tr069Exception catch (e) {
        if (mounted) {
          setState(() {
            _error = e.message;
            if (e.timeout) {
              _lockedUntil[widget.network.id] = DateTime.now().add(cooldown);
              _scheduleUnlock();
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
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
                  label:
                      widget.passwordRequired ? 'Senha do Wi-Fi' : 'Nova senha',
                  icon: 'lock',
                  hint: widget.passwordRequired
                      ? 'Digite a senha atual ou uma nova (mín. 8 caracteres)'
                      : 'Deixe em branco para manter',
                  controller: _password,
                  obscure: true,
                  enabled: !_saving,
                  onSubmitted: (_) => _save()),
              const SizedBox(height: 10),
              VibeNote(widget.passwordRequired
                  ? 'O roteador não informa a senha salva, por isso ela precisa ser digitada.'
                  : 'A senha precisa ter pelo menos 8 caracteres.'),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Semantics(liveRegion: true, child: VibeErrorLine(_error!)),
              ],
            ])),
        VibePageButton(
            label: _saving
                ? 'Enviando ao roteador…'
                : _locked
                    ? 'Aguarde 1 minuto para tentar de novo'
                    : 'Salvar alterações',
            onPressed: _saving || _locked ? null : _save),
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
