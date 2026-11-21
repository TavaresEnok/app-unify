import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../models/diagnostic_presentation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/diagnostico_state.dart';
import '../providers/connectivity_provider.dart';
import '../vibe/vibe_icon.dart';
import '../vibe/vibe_page_parts.dart';
import '../vibe/vibe_text.dart';
import '../vibe/vibe_tokens.dart';

/// Presentation of the shared speed-test engine. Callbacks keep execution,
/// cancellation, confirmation, history and sharing in the diagnostic journey.
class SpeedTestView extends ConsumerWidget {
  const SpeedTestView({
    super.key,
    required this.state,
    required this.onStart,
    required this.onStop,
    required this.onShare,
  });

  final DiagnosticoState state;
  final VoidCallback? onStart;
  final VoidCallback onStop;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VibeTokens.of(context);
    final connection = ref.watch(connectivityStatusProvider).valueOrNull;
    final offline = connection == ConnectivityResult.none;
    final mobile = connection == ConnectivityResult.mobile;
    final custom = state.testResultsDisplay['speedTestCustom'];
    final external = state.testResultsDisplay['speedTestFast'];
    final customStatus = custom?['status'];
    final externalStatus = external?['status'];
    final customMeasured = customStatus == TestStatus.success ||
        state.downloadHistory.isNotEmpty ||
        state.uploadHistory.isNotEmpty;
    final externalMeasured = externalStatus == TestStatus.success ||
        state.fastDownloadHistory.isNotEmpty ||
        state.fastUploadHistory.isNotEmpty;
    final hasMeasurement = customMeasured || externalMeasured;
    final finished = state.startedAt != null && !state.isTesting;
    final failed = finished && !state.wasInterrupted && !hasMeasurement;
    final activeExternal = externalStatus == TestStatus.running;
    final uploadPhase = state.isTesting &&
        state.geralStatusMessage.toLowerCase().contains('upload');
    final customDownloadMeasured =
        customStatus == TestStatus.success || state.downloadHistory.isNotEmpty;
    final externalDownloadMeasured = externalStatus == TestStatus.success ||
        state.fastDownloadHistory.isNotEmpty;
    final displayDownload = customDownloadMeasured
        ? state.customDownloadResultMbps
        : externalDownloadMeasured
            ? state.fastDownloadResultMbps
            : null;
    final displayUpload =
        customStatus == TestStatus.success || state.uploadHistory.isNotEmpty
            ? state.customUploadResultMbps
            : externalStatus == TestStatus.success ||
                    state.fastUploadHistory.isNotEmpty
                ? state.fastUploadResultMbps
                : null;
    final double? gaugeValue;
    if (!state.isTesting) {
      gaugeValue = state.startedAt == null ? 0 : displayDownload;
    } else if (activeExternal) {
      gaugeValue = uploadPhase
          ? (state.fastUploadHistory.isNotEmpty
              ? state.fastUploadResultMbps
              : null)
          : (state.fastDownloadHistory.isNotEmpty
              ? state.fastDownloadResultMbps
              : null);
    } else {
      gaugeValue = uploadPhase
          ? (state.uploadHistory.isNotEmpty
              ? state.customUploadResultMbps
              : null)
          : displayDownload;
    }

    return ListView(padding: const EdgeInsets.all(16), children: [
      if (offline && !state.isTesting && !hasMeasurement)
        const VibeCard(
            main: true,
            child: VibeEmpty(
                icon: 'alert',
                title: 'Sem conexão com a internet',
                text: 'Conecte o celular ao Wi-Fi ou aos dados para medir.'))
      else ...[
        VibeCard(
            main: true,
            child: Column(children: [
              _SpeedGauge(
                  value: gaugeValue,
                  label: uploadPhase ? 'upload' : 'download'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _SpeedValue(
                        label: 'Download',
                        icon: 'down',
                        value: displayDownload)),
                const SizedBox(width: 8),
                Expanded(
                    child: _SpeedValue(
                        label: 'Upload', icon: 'arr', value: displayUpload)),
              ]),
              if (finished && hasMeasurement) ...[
                const SizedBox(height: 10),
                VibeKvList([
                  if (state.speedTestPingLatency != null &&
                      state.speedTestPingLatency! > 0)
                    VibeKv('Latência',
                        '${state.speedTestPingLatency!.round()} ms'),
                  if (customStatus == TestStatus.success)
                    const VibeKv('Servidor', 'Servidor do provedor'),
                  if (externalStatus == TestStatus.success)
                    VibeKv('Referência externa',
                        '${state.fastDownloadResultMbps.round()} Mbps'),
                ]),
              ],
              if (state.isTesting) ...[
                const SizedBox(height: 12),
                Semantics(
                    liveRegion: true,
                    child: Text(
                        DiagnosticPresentation.stepLabel(
                            state.geralStatusMessage),
                        textAlign: TextAlign.center,
                        style: vibeText(t, 12, 500, color: t.mut))),
                const SizedBox(height: 12),
                VibePageButton(
                    label: 'Parar',
                    icon: 'g-stop',
                    ghost: true,
                    onPressed: onStop),
              ],
            ])),
        const SizedBox(height: 12),
        if (state.wasInterrupted)
          const VibeNote(
              'Teste interrompido. Os valores medidos até agora foram mantidos.')
        else if (failed)
          const VibeErrorLine(
              'Não foi possível concluir a medição. Tente novamente.')
        else if (finished && mobile)
          const VibeOkBox(
              title:
                  'Medição pelos dados móveis. Conecte-se ao Wi-Fi de casa para avaliar a internet fixa.',
              strip: true,
              warning: true),
        if (!state.isTesting) ...[
          if (finished) const SizedBox(height: 12),
          if (finished && hasMeasurement)
            VibeTwo(
              VibePageButton(
                  label: 'Compartilhar',
                  icon: 'share',
                  ghost: true,
                  onPressed: onShare),
              VibePageButton(
                  label: 'Testar de novo', icon: 'g-play', onPressed: onStart),
            )
          else
            VibePageButton(
                label: finished ? 'Tentar novamente' : 'Iniciar teste',
                icon: 'g-play',
                onPressed: offline ? null : onStart),
          if (!finished) ...[
            const SizedBox(height: 12),
            const VibeNote(
                'Mede download e upload neste celular, no servidor do provedor e em uma referência externa.'),
          ],
        ],
      ],
    ]);
  }
}

class _SpeedValue extends StatelessWidget {
  const _SpeedValue(
      {required this.label, required this.icon, required this.value});
  final String label;
  final String icon;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration:
          BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          VibeIcon(icon, size: 15, color: t.mut),
          const SizedBox(width: 4),
          Expanded(
              child: Text(label, style: vibeText(t, 12, 500, color: t.mut)))
        ]),
        const SizedBox(height: 6),
        Text(value == null ? '—' : '${value!.round()} Mbps',
            style: vibeText(t, 15, 750), maxLines: 2),
      ]),
    );
  }
}

class _SpeedGauge extends StatelessWidget {
  const _SpeedGauge({required this.value, required this.label});
  final double? value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final measuredValue = value ?? 0;
    final ceiling = measuredValue > 500
        ? 1000.0
        : measuredValue > 100
            ? 500.0
            : 100.0;
    return Semantics(
        label: value == null
            ? 'Medição de $label indisponível'
            : '${value!.round()} megabits por segundo de $label',
        child: SizedBox(
          width: 220,
          height: 145,
          child: Stack(alignment: Alignment.center, children: [
            Positioned.fill(
                child: CustomPaint(
                    painter: _GaugePainter(
                        progress: (measuredValue / ceiling).clamp(0, 1),
                        track: t.line,
                        color: t.ac))),
            Positioned(
                bottom: 10,
                child: Column(children: [
                  Text(value?.toStringAsFixed(0) ?? '—',
                      style: vibeText(t, 38, 800)),
                  Text('Mbps · $label',
                      style: vibeText(t, 12, 500, color: t.mut)),
                ])),
          ]),
        ));
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter(
      {required this.progress, required this.track, required this.color});
  final double progress;
  final Color track;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(10, 10, size.width - 20, size.width - 20);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(
          rect, math.pi, math.pi * progress, false, paint..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.progress != progress || old.track != track || old.color != color;
}
