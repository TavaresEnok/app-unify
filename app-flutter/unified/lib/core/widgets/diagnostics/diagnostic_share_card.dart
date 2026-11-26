import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../models/diagnostico_state.dart';
import '../../models/diagnostic_presentation.dart';
import '../../vibe/vibe_icon.dart';
import '../../vibe/vibe_page_parts.dart';
import '../../vibe/vibe_text.dart';
import '../../vibe/vibe_tokens.dart';
import 'diagnostic_view.dart';

/// Captura um widget envolvido em [RepaintBoundary] como imagem PNG completa,
/// preservando toda a altura do conteúdo mesmo quando está dentro de um scroll.
Future<Uint8List?> captureWidgetAsPng(GlobalKey boundaryKey) async {
  final renderObject = boundaryKey.currentContext?.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) return null;
  if (renderObject.debugNeedsPaint) {
    await WidgetsBinding.instance.endOfFrame;
  }
  final size = renderObject.size;
  if (size.isEmpty) return null;
  final pixelRatio = size.height > 2200 ? 1.5 : 2.0;
  final image = await renderObject.toImage(pixelRatio: pixelRatio);
  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// Cartão completo do diagnóstico ou teste de velocidade para captura de imagem
/// com todos os grupos expandidos, pronto para envio ao suporte ou cliente.
class DiagnosticShareCard extends StatelessWidget {
  const DiagnosticShareCard({
    super.key,
    required this.state,
    required this.providerName,
    this.planName,
  });

  final DiagnosticoState state;
  final String providerName;
  final String? planName;

  static String _formatWhen(DateTime when) {
    final local = when.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        'às ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final view = DiagnosticPresentation(state);
    final isSpeed = state.runMode == DiagnosticRunMode.speed;
    final allMeasured = view.plannedKeys.isNotEmpty &&
        view.plannedKeys
            .every((key) => view.outcome(key) == DiagnosticOutcome.measured);
    final when = state.finishedAt ?? state.startedAt ?? DateTime.now();
    final safePlan = planName?.trim() ?? '';

    return Container(
      color: t.bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            color: t.hero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  providerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: vibeText(t, 12.5, 650,
                      color: t.hx.withValues(alpha: .82)),
                ),
                const SizedBox(height: 2),
                Text(
                  isSpeed ? 'Teste de velocidade' : 'Diagnóstico de conexão',
                  style: vibeText(t, 20, 800,
                      color: t.hx, height: 1.15, letterSpacingEm: -.02),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    _formatWhen(when),
                    if (safePlan.isNotEmpty) safePlan,
                  ].join(' · '),
                  style:
                      vibeText(t, 12, 500, color: t.hx.withValues(alpha: .82)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isSpeed)
                  _speedBody(t)
                else ...[
                  VibeCard(
                    main: true,
                    center: true,
                    child: Column(children: [
                      VibeStatusCircle(
                        icon: state.wasInterrupted || !allMeasured
                            ? 'alert'
                            : 'check',
                        tone: state.wasInterrupted || !allMeasured
                            ? VibeTone.warning
                            : VibeTone.ok,
                      ),
                      const SizedBox(height: 10),
                      Text(view.title,
                          textAlign: TextAlign.center,
                          style: vibeText(t, 17, 750)),
                      const SizedBox(height: 6),
                      Text(view.description,
                          textAlign: TextAlign.center,
                          style:
                              vibeText(t, 13, 500, color: t.mut, height: 1.45)),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  for (var index = 0;
                      index < DiagnosticPresentation.groups.length;
                      index++)
                    if (DiagnosticPresentation.groups[index].keys
                        .any(view.plannedKeys.contains)) ...[
                      DiagnosticGroupCard(
                        key: ValueKey('share-group-$index'),
                        group: DiagnosticPresentation.groups[index],
                        icon: const ['cell', 'wifi', 'router', 'globe'][index],
                        view: view,
                        forceExpanded: true,
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
                const SizedBox(height: 4),
                Text(
                  'Gerado pelo aplicativo $providerName',
                  textAlign: TextAlign.center,
                  style: vibeText(t, 11.5, 500, color: t.mut),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _speedBody(VibeTokens t) {
    final custom = state.testResultsDisplay['speedTestCustom'];
    final external = state.testResultsDisplay['speedTestFast'];
    final customOk = custom?['status'] == TestStatus.success ||
        state.downloadHistory.isNotEmpty ||
        state.uploadHistory.isNotEmpty;
    final externalOk = external?['status'] == TestStatus.success ||
        state.fastDownloadHistory.isNotEmpty ||
        state.fastUploadHistory.isNotEmpty;
    final down = customOk
        ? state.customDownloadResultMbps
        : externalOk
            ? state.fastDownloadResultMbps
            : null;
    final up = (customOk && state.customUploadResultMbps > 0)
        ? state.customUploadResultMbps
        : (externalOk && state.fastUploadResultMbps > 0)
            ? state.fastUploadResultMbps
            : null;
    final refServer = state.speedTestReferenceServerName;

    Widget metricTile(String label, String icon, double? mbps) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: t.bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                VibeIcon(icon, size: 15, color: t.mut),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(label, style: vibeText(t, 12, 500, color: t.mut)),
                ),
              ]),
              const SizedBox(height: 6),
              Text(
                mbps == null ? '—' : '${mbps.round()} Mbps',
                style: vibeText(t, 17, 800),
              ),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: VibeCard(
        main: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(child: metricTile('Download', 'down', down)),
              const SizedBox(width: 8),
              Expanded(child: metricTile('Upload', 'arr', up)),
            ]),
            const SizedBox(height: 10),
            VibeKvList([
              if (state.speedTestPingLatency != null &&
                  state.speedTestPingLatency! > 0)
                VibeKv('Latência', '${state.speedTestPingLatency!.round()} ms'),
              VibeKv(
                'Servidor',
                state.speedTestServerName ?? 'Servidor do provedor',
              ),
              if (external?['status'] == TestStatus.success)
                VibeKv(
                  'Referência',
                  refServer != null
                      ? '${state.fastDownloadResultMbps.round()} Mbps · $refServer'
                      : '${state.fastDownloadResultMbps.round()} Mbps',
                ),
              VibeKv(
                'Status',
                state.wasInterrupted ? 'Teste interrompido' : 'Concluído',
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
