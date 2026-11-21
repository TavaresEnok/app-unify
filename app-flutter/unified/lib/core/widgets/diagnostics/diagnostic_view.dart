import 'package:flutter/material.dart';
import '../../models/diagnostico_state.dart';
import '../../models/diagnostic_presentation.dart';
import '../customer_ui.dart';
import 'measurement_card.dart';
import 'speed_measurement_card.dart';

/// Stateless presentation can be exercised with the same states used by the engine.
class DiagnosticView extends StatelessWidget {
  final DiagnosticoState state;
  final VoidCallback? onQuick, onComplete, onCancel, onShare, onHistory;
  final ValueChanged<String>? onTool;
  final bool Function(String)? toolEnabled;
  const DiagnosticView(
      {super.key,
      required this.state,
      this.onQuick,
      this.onComplete,
      this.onCancel,
      this.onShare,
      this.onHistory,
      this.onTool,
      this.toolEnabled});

  @override
  Widget build(BuildContext context) {
    final view = DiagnosticPresentation(state);
    final colors = Theme.of(context).colorScheme;
    final speedOnly = state.runMode == DiagnosticRunMode.speed;
    return CustomerList(children: [
      CustomerCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(
            state.isTesting
                ? Icons.wifi_find
                : view.hasResults
                    ? Icons.fact_check_outlined
                    : Icons.wifi_find_rounded,
            size: 36,
            color: colors.onSurface),
        const SizedBox(height: 16),
        Text(
            speedOnly && !view.hasResults && !state.isTesting
                ? 'Qual velocidade chega a este celular?'
                : view.title,
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
                height: 1.2)),
        const SizedBox(height: 12),
        Text(
            speedOnly && !view.hasResults && !state.isTesting
                ? 'O resultado depende do sinal, do aparelho e de outros usos da rede. Um teste por Wi-Fi não mede, sozinho, a entrega do plano por cabo.'
                : view.description,
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.5)),
        const SizedBox(height: 20),
        if (state.isTesting) ...[
          Semantics(liveRegion: true, child: Text(state.geralStatusMessage)),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: view.progress),
          const SizedBox(height: 8),
          Text(
              '${view.completed} de ${view.plannedKeys.length} verificações finalizadas',
              style: TextStyle(color: colors.onSurfaceVariant)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Interromper verificação')),
        ] else ...[
          SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                  onPressed: onQuick,
                  icon: const Icon(Icons.bolt),
                  label: Text(speedOnly
                      ? (view.hasResults ? 'Testar de novo' : 'Iniciar teste')
                      : view.hasResults
                          ? 'Verificar de novo'
                          : 'Verificação rápida'),
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)))),
          const SizedBox(height: 8),
          if (!speedOnly)
            OutlinedButton.icon(
                onPressed: onComplete,
                icon: const Icon(Icons.checklist_outlined),
                label: const Text('Diagnóstico completo')),
          if (view.hasResults)
            TextButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.ios_share),
                label: const Text('Compartilhar resumo')),
        ],
      ])),
      if (!speedOnly && !view.hasResults && !state.isTesting)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
                'A verificação rápida não mede velocidade. O diagnóstico completo usa mais dados e inclui outros testes. '
                'O app pode solicitar permissão para consultar informações do Wi-Fi.',
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.5))),
      const SizedBox(height: 20),
      CustomerSection(view.hasResults || state.isTesting
          ? 'O que foi verificado'
          : 'O que vamos verificar'),
      if (speedOnly) SpeedMeasurementCard(state: state),
      for (var index = 0; index < DiagnosticPresentation.groups.length; index++)
        if (DiagnosticPresentation.groups[index].keys
            .any(view.plannedKeys.contains)) ...[
          CustomerCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ExpansionTile(
                  key: PageStorageKey('group-$index'),
                  tilePadding: EdgeInsets.zero,
                  leading: Icon(
                      const [
                        Icons.phone_android_outlined,
                        Icons.wifi,
                        Icons.router_outlined,
                        Icons.public
                      ][index],
                      color: colors.onSurface),
                  title: Text(DiagnosticPresentation.groups[index].title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(!state.isTesting && !view.hasResults
                      ? DiagnosticPresentation.groups[index].description
                      : DiagnosticPresentation.label(view
                          .groupOutcome(DiagnosticPresentation.groups[index]))),
                  children: [
                    for (final key in DiagnosticPresentation.groups[index].keys)
                      if (view.plannedKeys.contains(key))
                        MeasurementCard(
                            testKey: key,
                            measurement:
                                state.testResultsDisplay[key] ?? const {},
                            isTesting: state.isTesting),
                    if (state.runMode == DiagnosticRunMode.quick)
                      Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                              'Alguns testes ficam disponíveis apenas no diagnóstico completo.',
                              style:
                                  TextStyle(color: colors.onSurfaceVariant))),
                  ])),
          const SizedBox(height: 12),
        ],
      if (!speedOnly) SpeedMeasurementCard(state: state),
      if (view.hasResults && !state.isTesting && onHistory != null)
        OutlinedButton.icon(
            onPressed: onHistory,
            icon: const Icon(Icons.history),
            label: const Text('Ver histórico')),
      const SizedBox(height: 12),
      ExpansionTile(
          title: const Text('Outras ferramentas'),
          subtitle: const Text('Rede Wi-Fi, ping e rota'),
          children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final item in [
                ('wifi', 'Minha rede Wi-Fi', Icons.router_outlined),
                ('ping', 'Ping', Icons.network_ping),
                ('trace_route', 'Rota da rede', Icons.route)
              ])
                if (toolEnabled?.call(item.$1) ?? true)
                  OutlinedButton.icon(
                      onPressed: state.isTesting || onTool == null
                          ? null
                          : () => onTool!(item.$1),
                      icon: Icon(item.$3),
                      label: Text(item.$2)),
            ]),
            const SizedBox(height: 16),
          ]),
    ]);
  }
}
