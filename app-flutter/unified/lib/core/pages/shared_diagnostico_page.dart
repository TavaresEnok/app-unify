import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/diagnostic_binding.dart';
import '../models/diagnostico_state.dart';
import '../models/diagnostic_presentation.dart';
import '../navigation/customer_routes.dart';
import '../providers/providers.dart';
import '../providers/history_count_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/customer_capabilities_provider.dart';
import '../services/diagnostico_service.dart';
import '../services/diagnostic_history_store.dart';
import '../services/subscriber_achievements.dart';
import '../widgets/diagnostics/diagnostic_share_card.dart';
import '../widgets/diagnostics/diagnostic_view.dart';
import '../../layouts/layout_03/wifi_page.dart';
import 'shared_ping_page.dart';
import 'shared_speed_test_page.dart';
import 'shared_traceroute_page.dart';
import 'customer/diagnostic_history_page.dart';
import '../vibe/vibe_page_parts.dart';
import '../vibe/vibe_text.dart';
import '../vibe/vibe_tokens.dart';
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
      final confirmed = await showVibeConfirm(context,
          title: widget.speedOnly
              ? 'O teste usa dados'
              : 'Iniciar diagnóstico completo?',
          message: widget.speedOnly
              ? ref.read(connectivityStatusProvider).valueOrNull ==
                      ConnectivityResult.mobile
                  ? 'Você está nos dados móveis. O teste consome dados do seu plano de celular e mede a operadora, não a fibra de casa.'
                  : 'O teste consome dados e mede a conexão deste celular. Para avaliar a internet de casa, fique no Wi-Fi.'
              : 'Inclui velocidade, rota e rede local. Pode levar alguns minutos e consumir dados. Fique no Wi-Fi de casa para avaliar a sua fibra.',
          confirmLabel: 'Iniciar',
          cancelLabel: 'Cancelar');
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
          'tone': view.tone,
          'summary': view.shareText(config.name),
        });
        ref.invalidate(diagnosticHistoryCountProvider);
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
        unawaited(_uploadDiagnosticResult(
          apiUrl: config.apiUrl,
          contratoId: user.contratoId?.toString() ?? '',
          clientName: user.nome,
          planName: user.plano,
          state: state,
          view: view,
        ));
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

  Future<void> _uploadDiagnosticResult({
    required String? apiUrl,
    required String contratoId,
    required String clientName,
    required String planName,
    required DiagnosticoState state,
    required DiagnosticPresentation view,
  }) async {
    final base = apiUrl?.trim().replaceAll(RegExp(r'/+$'), '') ?? '';
    if (base.isEmpty) return;
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null || token.isEmpty) return;

      final onuEntry = state.testResultsDisplay['onuInfo'];
      final onuMetrics =
          onuEntry?['metrics'] is Map ? onuEntry!['metrics'] as Map : null;
      final onuRxRaw = onuMetrics?['rxPower'] ?? onuMetrics?['rx'];
      final onuRxDbm = onuRxRaw is num
          ? onuRxRaw.toDouble()
          : double.tryParse(onuRxRaw?.toString() ?? '');
      final onuStatus = onuMetrics?['status']?.toString() ?? '';

      final googleMetrics =
          state.testResultsDisplay['pingGoogle']?['metrics'] is Map
              ? state.testResultsDisplay['pingGoogle']!['metrics'] as Map
              : null;
      final pingMs = googleMetrics?['latencyMs'] is num
          ? (googleMetrics!['latencyMs'] as num).toDouble()
          : state.speedTestPingLatency;
      final lossPercent = googleMetrics?['lossPercent'] is num
          ? (googleMetrics!['lossPercent'] as num).toDouble()
          : null;

      final downloadMbps = state.customDownloadResultMbps > 0
          ? state.customDownloadResultMbps
          : (state.fastDownloadResultMbps > 0
              ? state.fastDownloadResultMbps
              : null);
      final uploadMbps = state.customUploadResultMbps > 0
          ? state.customUploadResultMbps
          : (state.fastUploadResultMbps > 0
              ? state.fastUploadResultMbps
              : null);

      final gwOk =
          state.testResultsDisplay['pingGateway']?['status'] == TestStatus.success;
      final extFail =
          state.testResultsDisplay['pingGoogle']?['status'] == TestStatus.error;
      final onuOffline = onuStatus.toLowerCase().contains('offline') ||
          onuStatus.toLowerCase().contains('los');
      final onuWeak = onuRxDbm != null && onuRxDbm < -28.0;

      final needsProviderSupport =
          onuOffline || onuWeak || (gwOk && extFail);
      final verdict = (onuOffline || (gwOk && extFail))
          ? 'critical'
          : (onuWeak || view.tone == 'wa')
              ? 'degraded'
              : view.tone == 'ok'
                  ? 'healthy'
                  : 'unknown';
      final cause = onuOffline
          ? 'onu_offline'
          : onuWeak
              ? 'fiber_attenuation'
              : (gwOk && extFail)
                  ? 'external_routing'
                  : view.tone == 'ok'
                      ? 'healthy'
                      : 'local_or_partial';

      final summary = <String, dynamic>{
        'needsProviderSupport': needsProviderSupport,
        if (downloadMbps != null) 'downloadMbps': downloadMbps,
        if (uploadMbps != null) 'uploadMbps': uploadMbps,
        if (pingMs != null) 'pingMs': pingMs,
        if (lossPercent != null) 'lossPercent': lossPercent,
        if (onuRxDbm != null) 'onuRxDbm': onuRxDbm,
        if (onuStatus.isNotEmpty) 'onuStatus': onuStatus,
      };

      await http
          .post(
            Uri.parse('$base/diagnostic/results'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'contratoId': contratoId,
              'clientName': clientName,
              'planName': planName,
              'mode': state.runMode.name,
              'verdict': verdict,
              'verdictHeadline': view.title,
              'cause': cause,
              'summary': summary,
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Best-effort: o diagnóstico local permanece salvo mesmo sem rede/servidor.
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
    final planName = ref.read(authNotifierProvider).valueOrNull?.plano;
    final summary = DiagnosticPresentation(state).shareText(name);
    final captureKey = GlobalKey();
    var capturing = false;

    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheet) {
          final t = VibeTokens.of(sheet);
          return StatefulBuilder(
            builder: (sheetContext, setSheetState) => Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheet).height * .88),
              decoration: BoxDecoration(
                  color: t.card,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24))),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: t.ink.withValues(alpha: .18),
                                  borderRadius: BorderRadius.circular(2))),
                        ),
                        const SizedBox(height: 14),
                        Semantics(
                          header: true,
                          child: Text('Compartilhar resultado',
                              style: vibeText(t, 19, 800, letterSpacingEm: -.01)),
                        ),
                        const SizedBox(height: 4),
                        Text('Print completo com todos os testes abertos.',
                            style: vibeText(t, 13, 500,
                                color: t.mut, height: 1.45)),
                        const SizedBox(height: 12),
                        Flexible(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: t.line),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: SingleChildScrollView(
                                child: RepaintBoundary(
                                  key: captureKey,
                                  child: DiagnosticShareCard(
                                    state: state,
                                    providerName: name,
                                    planName: planName,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        VibeTwo(
                          VibePageButton(
                              label: 'Copiar texto',
                              icon: 'copy',
                              ghost: true,
                              onPressed: capturing
                                  ? null
                                  : () async {
                                      await Clipboard.setData(
                                          ClipboardData(text: summary));
                                      if (sheet.mounted) {
                                        ScaffoldMessenger.of(sheet)
                                            .showSnackBar(const SnackBar(
                                                content:
                                                    Text('Resumo copiado.')));
                                      }
                                    }),
                          VibePageButton(
                              label: capturing ? 'Gerando print…' : 'Enviar print',
                              icon: 'share',
                              onPressed: capturing
                                  ? null
                                  : () async {
                                      setSheetState(() => capturing = true);
                                      try {
                                        final bytes = await captureWidgetAsPng(
                                            captureKey);
                                        if (bytes != null && bytes.isNotEmpty) {
                                          final dir =
                                              await getTemporaryDirectory();
                                          final file = File(
                                              '${dir.path}/diagnostico_${DateTime.now().millisecondsSinceEpoch}.png');
                                          await file.writeAsBytes(bytes,
                                              flush: true);
                                          await Share.shareXFiles(
                                            [
                                              XFile(file.path,
                                                  mimeType: 'image/png')
                                            ],
                                            text:
                                                'Diagnóstico de conexão — $name',
                                          );
                                        } else {
                                          await Share.share(summary);
                                        }
                                      } catch (_) {
                                        if (sheet.mounted) {
                                          ScaffoldMessenger.of(sheet)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Não conseguimos abrir o compartilhamento. Você pode copiar o texto.')));
                                        }
                                      } finally {
                                        if (sheet.mounted) {
                                          setSheetState(
                                              () => capturing = false);
                                        }
                                      }
                                    }),
                        ),
                      ]),
                ),
              ),
            ),
          );
        });
  }

  Future<void> _leave() async {
    final yes = await showVibeConfirm(context,
        title: 'Interromper e voltar?',
        message: 'Os resultados já obtidos ficam guardados no histórico.',
        confirmLabel: 'Interromper',
        cancelLabel: 'Continuar');
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
    // O diagnóstico usa sempre o layout ativo do app: os estilos antigos por
    // tela ([appearance]) trocavam o cabeçalho e as cores no meio da jornada.
    final tokens = ref.watch(layoutTokensProvider);
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
                                  _ => const SharedTraceRoutePage(),
                                });
                          },
                        )),
            );
          },
        ));
  }
}
