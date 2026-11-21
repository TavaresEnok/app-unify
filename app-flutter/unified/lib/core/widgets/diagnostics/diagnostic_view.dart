import 'package:flutter/material.dart';

import '../../models/diagnostico_state.dart';
import '../../models/diagnostic_presentation.dart';
import '../../vibe/vibe_page_parts.dart';
import '../../vibe/vibe_text.dart';
import '../../vibe/vibe_tokens.dart';
import 'measurement_card.dart';

/// Presentation of the actual diagnostic state, shared by each visual style.
class DiagnosticView extends StatelessWidget {
  final DiagnosticoState state;
  final VoidCallback? onQuick, onComplete, onCancel, onShare, onCopy, onHistory;
  final ValueChanged<String>? onTool;
  final bool Function(String)? toolEnabled;

  const DiagnosticView({
    super.key,
    required this.state,
    this.onQuick,
    this.onComplete,
    this.onCancel,
    this.onShare,
    this.onCopy,
    this.onHistory,
    this.onTool,
    this.toolEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final view = DiagnosticPresentation(state);
    final t = VibeTokens.of(context);
    final speedOnly = state.runMode == DiagnosticRunMode.speed;
    final started =
        state.startedAt != null || state.wasInterrupted || view.hasResults;
    final showGroups = started || state.isTesting;
    final allMeasured = view.plannedKeys.isNotEmpty &&
        view.plannedKeys
            .every((key) => view.outcome(key) == DiagnosticOutcome.measured);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      children: [
        if (!showGroups) ...[
          VibeCard(
            main: true,
            child: Text(
              speedOnly
                  ? 'O resultado é medido neste celular e depende do sinal e dos outros usos da rede.'
                  : 'A verificação consulta o seu celular, o Wi-Fi, o roteador, a internet e o sinal da fibra quando disponível.',
              style: vibeText(t, 13.5, 500, color: t.mut, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          if (speedOnly)
            VibePageButton(label: 'Iniciar teste', onPressed: onQuick)
          else
            VibeCard(
              child: VibeRows(children: [
                VibeRow(
                  icon: 'bolt',
                  title: 'Verificação rápida',
                  subtitle:
                      'Celular, Wi-Fi, roteador, ping e fibra quando disponíveis',
                  onTap: onQuick,
                ),
                VibeRow(
                  icon: 'g-shield',
                  title: 'Diagnóstico completo',
                  subtitle: 'Inclui rota, equipamentos e velocidade',
                  onTap: onComplete,
                ),
              ]),
            ),
        ] else ...[
          if (state.isTesting)
            VibeCard(
              main: true,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(state.geralStatusMessage,
                          style: vibeText(t, 15, 700)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        '${view.completed} de ${view.plannedKeys.length} verificações finalizadas',
                        style: vibeText(t, 12.5, 500, color: t.mut)),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: view.progress),
                    const SizedBox(height: 14),
                    VibePageButton(
                        label: 'Parar',
                        ghost: true,
                        small: true,
                        expand: false,
                        onPressed: onCancel),
                  ]),
            )
          else
            VibeCard(
              main: true,
              center: true,
              child: Column(children: [
                VibeStatusCircle(
                  icon:
                      state.wasInterrupted || !allMeasured ? 'alert' : 'check',
                  tone: state.wasInterrupted || !allMeasured
                      ? VibeTone.warning
                      : VibeTone.ok,
                ),
                const SizedBox(height: 12),
                Text(view.title,
                    textAlign: TextAlign.center, style: vibeText(t, 18, 750)),
                const SizedBox(height: 8),
                Text(view.description,
                    textAlign: TextAlign.center,
                    style: vibeText(t, 13.5, 500, color: t.mut, height: 1.45)),
              ]),
            ),
          const SizedBox(height: 12),
          for (var index = 0;
              index < DiagnosticPresentation.groups.length;
              index++)
            if (DiagnosticPresentation.groups[index].keys
                .any(view.plannedKeys.contains)) ...[
              VibeCard(
                child: ExpansionTile(
                  key: PageStorageKey('group-$index'),
                  initiallyExpanded: !state.isTesting,
                  tilePadding: EdgeInsets.zero,
                  leading: Icon(
                      const [
                        Icons.phone_android_outlined,
                        Icons.wifi,
                        Icons.router_outlined,
                        Icons.public,
                      ][index],
                      color: t.at),
                  title: Text(DiagnosticPresentation.groups[index].title,
                      style: vibeText(t, 14, 700)),
                  subtitle: Text(
                    DiagnosticPresentation.label(view
                        .groupOutcome(DiagnosticPresentation.groups[index])),
                    style: vibeText(t, 12.5, 500, color: t.mut),
                  ),
                  children: [
                    for (final key in DiagnosticPresentation.groups[index].keys)
                      if (view.plannedKeys.contains(key))
                        MeasurementCard(
                            testKey: key,
                            measurement:
                                state.testResultsDisplay[key] ?? const {},
                            isTesting: state.isTesting),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          if (!state.isTesting) ...[
            VibeTwo(
              VibePageButton(
                  label: 'Copiar resumo',
                  icon: 'copy',
                  ghost: true,
                  onPressed: onCopy),
              VibePageButton(
                  label: 'Compartilhar',
                  icon: 'share',
                  ghost: true,
                  onPressed: onShare),
            ),
            const SizedBox(height: 12),
            VibePageButton(label: 'Verificar de novo', onPressed: onQuick),
            if (!speedOnly) ...[
              const SizedBox(height: 8),
              VibePageButton(
                  label: 'Diagnóstico completo',
                  ghost: true,
                  onPressed: onComplete),
            ],
            if (onHistory != null) ...[
              const SizedBox(height: 8),
              VibePageButton(
                  label: 'Ver histórico', ghost: true, onPressed: onHistory),
            ],
            const SizedBox(height: 12),
            const VibeNote(
                'O resumo não leva CPF, senha, nome da rede nem IP.'),
          ],
        ],
        if (!speedOnly) ...[
          const SizedBox(height: 12),
          VibeCard(
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Outras ferramentas', style: vibeText(t, 14, 700)),
              subtitle: Text('Rede Wi-Fi, ping e rota',
                  style: vibeText(t, 12.5, 500, color: t.mut)),
              children: [
                for (final item in [
                  ('wifi', 'Minha rede Wi-Fi', 'router'),
                  ('ping', 'Ping', 'pulse'),
                  ('trace_route', 'Rota da rede', 'g-route'),
                ])
                  if (toolEnabled?.call(item.$1) ?? true)
                    VibeRow(
                        icon: item.$3,
                        title: item.$2,
                        onTap: state.isTesting || onTool == null
                            ? null
                            : () => onTool!(item.$1)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
