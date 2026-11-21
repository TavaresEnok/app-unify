import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/diagnostic_binding.dart';
import '../models/diagnostico_state.dart';
import '../models/diagnostic_presentation.dart';
import '../navigation/customer_routes.dart';
import '../providers/providers.dart';
import '../providers/connectivity_provider.dart';
import '../providers/customer_capabilities_provider.dart';
import '../theme/layout_tokens.dart';
import '../services/diagnostico_service.dart';
import '../services/diagnostic_history_store.dart';
import '../services/subscriber_achievements.dart';
import '../widgets/diagnostics/diagnostic_view.dart';
import '../../layouts/layout_03/wifi_page.dart';
import 'shared_ping_page.dart';
import 'shared_speed_test_page.dart';
import 'shared_traceroute_page.dart';
import 'customer/diagnostic_history_page.dart';
import '../vibe/vibe_page_parts.dart';
import '../navigation/customer_shell_scope.dart';

/// All configured diagnostic IDs resolve to this journey and provider palette.
class DiagnosticoPage extends ConsumerStatefulWidget {
  final String? appearance;
  final bool autoStart;
  final bool speedOnly;
  const DiagnosticoPage(
      {super.key,
      this.appearance,
      this.autoStart = false,
      this.speedOnly = false});
  @override
  ConsumerState<DiagnosticoPage> createState() => _DiagnosticoPageState();
}

class _DiagnosticoPageState extends ConsumerState<DiagnosticoPage> {
  DiagnosticBinding? _binding;
  DiagnosticoService? _service;
  bool _autoStarted = false;
  bool _allowPop = false;
  final Set<String> _savedRuns = {};
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _binding ??= DiagnosticBinding(ref, context, (service, _) {
      setState(() => _service = service);
      if (widget.autoStart && !_autoStarted && service != null) {
        _autoStarted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _start();
        });
      }
    });
  }

  @override
  void dispose() {
    _binding?.dispose();
    super.dispose();
  }

  Future<void> _start({bool complete = false}) async {
    if (!(_binding?.ensureReady() ?? false)) return;
    if (complete || widget.speedOnly) {
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: Text(widget.speedOnly
                      ? 'Iniciar teste de velocidade?'
                      : 'Iniciar diagnóstico completo?'),
                  content: Text(widget.speedOnly
                      ? ref.read(connectivityStatusProvider).valueOrNull ==
                              ConnectivityResult.mobile
                          ? 'Você está usando dados móveis. O teste consome dados e mede a conexão desta operadora. Para avaliar a internet de casa, conecte-se ao Wi-Fi.'
                          : 'O teste consome dados e mede a conexão deste celular. Para avaliar a internet de casa, conecte-se ao Wi-Fi.'
                      : 'Inclui testes de velocidade, rota e rede local. Pode levar alguns minutos e consumir dados. Conecte-se ao Wi-Fi de casa para avaliar sua internet fixa.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Agora não')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(widget.speedOnly
                            ? 'Iniciar teste'
                            : 'Iniciar diagnóstico'))
                  ]));
      if (confirmed != true ||
          !mounted ||
          !(_binding?.ensureReady() ?? false)) {
        return;
      }
    }
    final service = _service!;
    if (widget.speedOnly) {
      await service.runSpeedTestsOnly();
    } else if (complete) {
      await service.runAllTests();
    } else {
      await service.runQuickCheck();
    }
    if (mounted && identical(service, _service)) {
      await _save(service.currentState);
    }
  }

  Future<void> _save(DiagnosticoState state) async {
    final config = ref.read(configurationProvider).providerConfig;
    final user = ref.read(authNotifierProvider).valueOrNull;
    final view = DiagnosticPresentation(state);
    if (config != null && user != null && view.hasResults) {
      final id = state.startedAt?.toIso8601String() ??
          state.finishedAt?.toIso8601String() ??
          'current';
      // Cancellation saves immediately. A late engine completion must not
      // recreate an entry that the customer subsequently cleared.
      if (!_savedRuns.add(id)) return;
      try {
        await DiagnosticHistoryStore(
                config.id, user.contratoId?.toString() ?? user.cpfCnpj)
            .save({
          'id': id,
          'date': state.finishedAt?.toIso8601String() ??
              DateTime.now().toIso8601String(),
          'mode': state.runMode.name,
          'title': view.title,
          'summary': view.shareText(config.name),
        });
        final successful = state.testResultsDisplay.values
            .any((entry) => entry['status'] == TestStatus.success);
        final speedSuccessful = ['speedTestCustom', 'speedTestFast'].any(
          (key) =>
              state.testResultsDisplay[key]?['status'] == TestStatus.success,
        );
        if (successful && user.cpfCnpj.isNotEmpty) {
          try {
            if (state.runMode != DiagnosticRunMode.speed) {
              await SubscriberAchievements.record(
                  config.id, user.cpfCnpj, AchievementEvent.diagnostic);
            }
            if (speedSuccessful) {
              await SubscriberAchievements.record(
                  config.id, user.cpfCnpj, AchievementEvent.speed);
            }
          } catch (_) {
            // The saved diagnostic is still available if achievement storage fails.
          }
        }
      } catch (_) {
        _savedRuns.remove(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Os resultados estão disponíveis, mas não conseguimos salvar o histórico neste aparelho.')));
        }
      }
    }
  }

  Future<void> _cancel() async {
    final service = _service;
    service?.stopAllTests();
    if (service != null) await _save(service.currentState);
  }

  Future<void> _copySummary(DiagnosticoState state) async {
    final name =
        ref.read(configurationProvider).providerConfig?.name ?? 'Seu provedor';
    final summary = DiagnosticPresentation(state).shareText(name);
    await Clipboard.setData(ClipboardData(text: summary));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resumo copiado.')),
      );
    }
  }

  Future<void> _share(DiagnosticoState state) async {
    final name =
        ref.read(configurationProvider).providerConfig?.name ?? 'Seu provedor';
    final summary = DiagnosticPresentation(state).shareText(name);
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
                child: FractionallySizedBox(
              heightFactor: .85,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Compartilhar resumo',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        const Text(
                            'Confira o conteúdo abaixo. O resumo não inclui CPF, senhas, IP, nome da rede ou endereços dos aparelhos.'),
                        const SizedBox(height: 16),
                        Expanded(
                            child: SingleChildScrollView(
                                child: SelectableText(summary))),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                            icon: const Icon(Icons.ios_share),
                            label: const Text('Escolher onde compartilhar'),
                            onPressed: () async {
                              try {
                                await Share.share(summary);
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Não conseguimos abrir o compartilhamento. Você pode copiar o resumo.')));
                                }
                              }
                            }),
                        TextButton.icon(
                            icon: const Icon(Icons.copy_outlined),
                            label: const Text('Copiar resumo'),
                            onPressed: () async {
                              await Clipboard.setData(
                                  ClipboardData(text: summary));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Resumo copiado.')));
                              }
                            }),
                      ])),
            )));
  }

  Future<void> _leave() async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Interromper e voltar?'),
                content: const Text(
                    'Os resultados já obtidos serão mantidos no histórico.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Continuar verificando')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Interromper'))
                ]));
    if (yes != true || !mounted) return;
    await _cancel();
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeTokens = ref.watch(layoutTokensProvider);
    final tokens = widget.appearance == null
        ? activeTokens
        : LayoutTokens.of(widget.appearance)
            .withPrimary(activeTokens.primary)
            .withBrightness(
                activeTokens.isDark ? Brightness.dark : Brightness.light);
    final config = ref.watch(configurationProvider).providerConfig;
    final wifiAvailable =
        ref.watch(wifiManagementAvailableProvider).valueOrNull == true;
    bool enabled(String route) =>
        config != null &&
        CustomerRoutes.enabled(config, route) &&
        (route != 'wifi' || wifiAvailable);
    return Theme(
        data: tokens.themeData(base: Theme.of(context)),
        child: StreamBuilder<DiagnosticoState>(
          key: ObjectKey(_service),
          stream: _service?.stateStream,
          initialData: _service?.currentState ??
              DiagnosticoState.initial().copyWith(
                  runMode: widget.speedOnly
                      ? DiagnosticRunMode.speed
                      : DiagnosticRunMode.complete),
          builder: (context, snapshot) {
            final raw = snapshot.data!;
            final state = widget.speedOnly && raw.startedAt == null
                ? raw.copyWith(runMode: DiagnosticRunMode.speed)
                : raw;
            return PopScope(
              canPop: !state.isTesting || _allowPop,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop && state.isTesting) _leave();
              },
              child: VibeHeaderPage(
                  title:
                      widget.speedOnly ? 'Teste de velocidade' : 'Diagnóstico',
                  subtitle: widget.speedOnly
                      ? 'Download e upload'
                      : 'Verificar conexão',
                  body: widget.speedOnly
                      ? SpeedTestView(
                          state: state,
                          onStart: _service?.canStart != true
                              ? null
                              : () => _start(),
                          onStop: _cancel,
                          onShare: () => _share(state),
                        )
                      : DiagnosticView(
                          state: state,
                          onQuick: _service?.canStart != true
                              ? null
                              : () => _start(),
                          onComplete: _service?.canStart != true
                              ? null
                              : () => _start(complete: true),
                          onCancel: _cancel,
                          onShare: () => _share(state),
                          onCopy: () => _copySummary(state),
                          toolEnabled: enabled,
                          onHistory: !enabled('history')
                              ? null
                              : () => pushCustomerPage<void>(context,
                                  route: 'history',
                                  page: const DiagnosticHistoryPage()),
                          onTool: (route) {
                            final currentConfig =
                                ref.read(configurationProvider).providerConfig;
                            if (currentConfig == null ||
                                !CustomerRoutes.enabled(currentConfig, route) ||
                                (route == 'wifi' &&
                                    ref
                                            .read(
                                                wifiManagementAvailableProvider)
                                            .valueOrNull !=
                                        true)) {
                              return;
                            }
                            pushCustomerPage<void>(context,
                                route: route,
                                page: switch (route) {
                                  'wifi' => const WifiPage(),
                                  'ping' => const SharedPingPage(),
                                  _ => const VibeHeaderPage(
                                      title: 'Tracert',
                                      subtitle: 'Rota da rede',
                                      body: SharedTraceRoutePage()),
                                });
                          },
                        )),
            );
          },
        ));
  }
}
