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
                    Row(children: [
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          child: Text(state.geralStatusMessage,
                              style:
                                  vibeText(t, 14, 800, letterSpacingEm: -.02)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      VibeLabel(
                          '${(view.completed + 1).clamp(1, view.plannedKeys.length)} de ${view.plannedKeys.length}'),
                    ]),
                    const SizedBox(height: 10),
                    VibeProgressBar(value: view.progress),
                    const SizedBox(height: 10),
                    VibePageButton(
                        label: 'Parar',
                        icon: 'g-stop',
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
              DiagnosticGroupCard(
                  key: ValueKey('group-$index'),
                  group: DiagnosticPresentation.groups[index],
                  icon: const ['cell', 'wifi', 'router', 'globe'][index],
                  view: view),
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
          _Tools(
            items: [
              for (final item in const [
                ('wifi', 'Minha rede Wi-Fi', 'router'),
                ('ping', 'Teste de ping', 'pulse'),
                ('trace_route', 'Rota da rede', 'g-route'),
              ])
                if (toolEnabled?.call(item.$1) ?? true) item,
            ],
            onTool: state.isTesting ? null : onTool,
          ),
        ],
      ],
    );
  }
}

/// "Outras ferramentas": linha que abre os atalhos (`data-a="tog"`).
class _Tools extends StatefulWidget {
  const _Tools({required this.items, required this.onTool});
  final List<(String, String, String)> items;
  final ValueChanged<String>? onTool;

  @override
  State<_Tools> createState() => _ToolsState();
}

class _ToolsState extends State<_Tools> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    return VibeCard(
      child: VibeRows(children: [
        Semantics(
          expanded: _open,
          child: VibeRow(
            icon: 'gear',
            plainIcon: true,
            title: 'Outras ferramentas',
            subtitle: widget.items.map((item) => item.$2).join(', '),
            trailing: VibeChevron(open: _open),
            onTap: () => setState(() => _open = !_open),
          ),
        ),
        if (_open)
          for (final item in widget.items)
            VibeRow(
                icon: item.$3,
                title: item.$2,
                onTap: widget.onTool == null
                    ? null
                    : () => widget.onTool!(item.$1)),
      ]),
    );
  }
}

/// Grupo do diagnóstico (`.g-row` + `.g-kv`): quantas verificações já
/// terminaram, a cor do pior resultado e, aberto, cada valor medido.
class DiagnosticGroupCard extends StatefulWidget {
  const DiagnosticGroupCard(
      {super.key, required this.group, required this.icon, required this.view});
  final DiagnosticGroup group;
  final String icon;
  final DiagnosticPresentation view;

  @override
  State<DiagnosticGroupCard> createState() => _DiagnosticGroupCardState();
}

class _DiagnosticGroupCardState extends State<DiagnosticGroupCard> {
  bool? _open;

  static const _names = {
    'deviceInfo': 'Celular',
    'batteryInfo': 'Bateria',
    'wifiInfo': 'Wi-Fi',
    'pingGateway': 'Resposta do roteador',
    'lanScan': 'Dispositivos na rede',
    'onuInfo': 'Sinal da fibra',
    'publicIp': 'IP público',
    'pingGoogle': 'Ping Google',
    'pingCloudflare': 'Ping Cloudflare',
    'traceroute': 'Rota pelo servidor',
    'speedTestCustom': 'Velocidade no provedor',
    'speedTestFast': 'Velocidade de referência',
  };

  static const _renames = {
    'SSID': 'Rede',
    'Força do Sinal': 'Força do sinal',
    'IP Dispositivo': 'IP local',
    'Gateway (Roteador)': 'Roteador',
    'Conexão': 'Tipo de rede',
    'Dispositivo': 'Modelo',
    'Versão OS': 'Sistema',
    'Versão do App': 'Versão do app',
    'Nível': 'Bateria',
    'Estado': 'Energia',
    'Dispositivos encontrados': 'Dispositivos na rede',
    'Freq': 'Frequência do roteador',
  };

  static VibeTone? _tone(DiagnosticOutcome outcome) => switch (outcome) {
        DiagnosticOutcome.measured => VibeTone.ok,
        DiagnosticOutcome.attention => VibeTone.warning,
        _ => null,
      };

  /// Linhas de uma verificação: os valores medidos, um por linha, ou o
  /// motivo de não haver valor.
  List<VibeKv> _lines(String key) {
    final view = widget.view;
    final entry = view.state.testResultsDisplay[key] ?? const {};
    final name = _names[key] ?? entry['label']?.toString() ?? key;
    final outcome = view.outcome(key);
    final dot = VibeDot(_tone(outcome));
    switch (outcome) {
      case DiagnosticOutcome.running:
        return [VibeKv(name, 'Verificando…', muted: true)];
      case DiagnosticOutcome.notVerified:
        return [
          VibeKv(name, view.state.isTesting ? 'Aguardando' : 'Não medido',
              muted: true)
        ];
      case DiagnosticOutcome.permissionRequired:
        return [VibeKv(name, 'Permita a localização para ler', leading: dot)];
      case DiagnosticOutcome.unavailable:
        return [VibeKv(name, 'Exige estar no Wi-Fi', leading: dot)];
      case DiagnosticOutcome.inconclusive:
        return [VibeKv(name, 'Sem resultado', leading: dot)];
      case DiagnosticOutcome.measured:
      case DiagnosticOutcome.attention:
        break;
    }
    final metrics = entry['metrics'];
    if (key.startsWith('ping') &&
        metrics is Map &&
        metrics['latencyMs'] is num) {
      final latency = metrics['latencyMs'] as num;
      final loss = metrics['lossPercent'];
      return [
        VibeKv(
            name,
            '${latency.toStringAsFixed(latency == latency.roundToDouble() ? 0 : 1)} ms'
            '${loss is num && loss > 0 ? ', ${loss.round()}% de perda' : ''}',
            leading: dot),
      ];
    }
    if (key == 'traceroute') {
      final hops = '${entry['result'] ?? ''}'
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .length;
      final reached = metrics is Map && metrics['reached'] == true;
      return [
        VibeKv(
            name,
            '$hops ${hops == 1 ? 'salto' : 'saltos'}, '
            '${reached ? 'destino alcançado' : 'rota parcial'}',
            leading: VibeDot(reached ? VibeTone.ok : VibeTone.warning)),
      ];
    }
    final suffix = switch (key) {
      'speedTestCustom' => ' no provedor',
      'speedTestFast' => ' de referência',
      _ => '',
    };
    final lines = <VibeKv>[];
    for (final raw
        in MeasurementCard.displayResult(entry['result']).split('\n')) {
      final line = raw.replaceAll('⚠️', '').trim();
      // Os dados do roteador remoto repetem os do celular.
      if (line.startsWith('[')) break;
      final cut = line.indexOf(': ');
      if (line.isEmpty || cut <= 0) continue;
      final label = line.substring(0, cut).trim();
      final value = line.substring(cut + 2).trim();
      if (label == 'BSSID' ||
          value.isEmpty ||
          const ['N/A', 'Indisponível', 'null', 'Desconhecido']
              .contains(value)) {
        continue;
      }
      lines.add(VibeKv(
          '${_renames[label] ?? label}$suffix', value == 'true' ? 'Sim' : value,
          leading: dot));
    }
    return lines.isEmpty
        ? [VibeKv(name, 'Dados obtidos', leading: dot)]
        : lines;
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final keys = widget.group.keys.where(view.plannedKeys.contains).toList();
    final done = keys
        .where((key) => const [
              DiagnosticOutcome.measured,
              DiagnosticOutcome.attention,
              DiagnosticOutcome.inconclusive,
              DiagnosticOutcome.unavailable,
              DiagnosticOutcome.permissionRequired,
            ].contains(view.outcome(key)))
        .length;
    final outcomes = keys.map(view.outcome).toList();
    final tone = outcomes.contains(DiagnosticOutcome.attention)
        ? VibeTone.warning
        : outcomes.contains(DiagnosticOutcome.measured)
            ? (outcomes.every((value) => value == DiagnosticOutcome.measured)
                ? VibeTone.ok
                : VibeTone.warning)
            : null;
    final open = _open ?? !view.state.isTesting;
    return VibeCard(
      child: VibeRows(children: [
        Semantics(
          expanded: open,
          child: VibeRow(
            icon: widget.icon,
            title: widget.group.title,
            subtitle: done == 0
                ? (view.state.isTesting ? 'Aguardando' : 'Não medido')
                : '$done de ${keys.length} '
                    '${keys.length == 1 ? 'verificado' : 'verificados'}',
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              VibeDot(tone),
              const SizedBox(width: 12),
              VibeChevron(open: open),
            ]),
            onTap: () => setState(() => _open = !open),
          ),
        ),
        if (open)
          for (final key in keys) ..._lines(key),
      ]),
    );
  }
}
