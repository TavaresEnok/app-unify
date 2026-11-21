import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../controllers/diagnostic_binding.dart';
import '../models/diagnostico_state.dart';
import '../services/diagnostico_service.dart';
import '../vibe/vibe_page_parts.dart';
import '../vibe/vibe_text.dart';
import '../vibe/vibe_tokens.dart';

class SharedPingPage extends ConsumerStatefulWidget {
  const SharedPingPage({super.key});
  @override
  ConsumerState<SharedPingPage> createState() => _SharedPingPageState();
}

class _SharedPingPageState extends ConsumerState<SharedPingPage> {
  final _target = TextEditingController(text: '8.8.8.8');
  DiagnosticBinding? _binding;
  DiagnosticoService? _service;
  StreamSubscription<DiagnosticoState>? _subscription;
  DiagnosticoState _state = DiagnosticoState.initial();
  String? _error;
  String? _gateway;

  @override
  void initState() {
    super.initState();
    _loadGateway();
  }

  Future<void> _loadGateway() async {
    try {
      final gateway = await NetworkInfo().getWifiGatewayIP();
      if (mounted &&
          gateway != null &&
          gateway.isNotEmpty &&
          gateway != '0.0.0.0') {
        setState(() => _gateway = gateway);
      }
    } catch (_) {
      // The router shortcut requires an address reported by the device.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _binding ??= DiagnosticBinding(ref, context, (service, _) {
      _subscription?.cancel();
      _service = service;
      _subscription = service?.stateStream.listen((state) {
        if (mounted) setState(() => _state = state);
      });
      setState(
          () => _state = service?.currentState ?? DiagnosticoState.initial());
    });
  }

  Future<void> _start() async {
    if (_service == null || _state.isTesting) return;
    setState(() => _error = null);
    try {
      await _service!.runPingOnly(_target.text.trim());
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _binding?.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final result = _state.testResultsDisplay['pingGoogle'];
    final metrics = result?['metrics'];
    final responses = metrics is Map && metrics['responses'] is List
        ? (metrics['responses'] as List).whereType<Map>().toList()
        : <Map>[];
    final summary = metrics is Map ? metrics : const {};
    final measured = !_state.isTesting && summary['packetsSent'] != null;
    String format(dynamic value, String unit) => value is num
        ? '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}$unit'
        : '—';
    return VibeHeaderPage(
      title: 'Teste de ping',
      subtitle: 'Cinco pacotes',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        VibeCard(
            main: true,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('IP ou domínio', style: vibeText(t, 13, 650)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _target,
                    enabled: !_state.isTesting,
                    autocorrect: false,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.public),
                        border: OutlineInputBorder()),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _start(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    for (final preset in [
                      ('Google', '8.8.8.8'),
                      ('Cloudflare', '1.1.1.1'),
                      if (_gateway != null) ('Roteador', _gateway!)
                    ])
                      ChoiceChip(
                        label: Text(preset.$1),
                        selected: _target.text.trim() == preset.$2,
                        onSelected: _state.isTesting
                            ? null
                            : (_) => setState(() => _target.text = preset.$2),
                      ),
                  ]),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    VibeErrorLine(_error!.replaceFirst('FormatException: ', ''))
                  ],
                  const SizedBox(height: 12),
                  VibePageButton(
                    icon: _state.isTesting ? 'g-stop' : 'g-play',
                    label: _state.isTesting ? 'Parar' : 'Iniciar',
                    ghost: _state.isTesting,
                    onPressed: _service == null
                        ? null
                        : _state.isTesting
                            ? () => _service?.stopAllTests()
                            : _start,
                  ),
                ])),
        if (responses.isNotEmpty || _state.isTesting) ...[
          const SizedBox(height: 12),
          VibeCard(
              child: VibeKvList([
            for (var index = 0; index < responses.length; index++)
              VibeKv('Resposta ${responses[index]['sequence'] ?? index + 1}',
                  '${responses[index]['timeMs']} ms'),
            if (_state.isTesting) const VibeKv('Próximo pacote', 'Enviando…'),
          ])),
        ],
        if (measured) ...[
          const SizedBox(height: 12),
          VibeCard(
              child: VibeKvList([
            VibeKv('Latência média', format(summary['latencyMs'], ' ms')),
            VibeKv(
                'Variação',
                summary['minMs'] is num && summary['maxMs'] is num
                    ? format(
                        (summary['maxMs'] as num) - (summary['minMs'] as num),
                        ' ms')
                    : '—'),
            VibeKv('Perda de pacotes', format(summary['lossPercent'], '%')),
          ])),
        ] else if (!_state.isTesting &&
            result?['status'] == TestStatus.error) ...[
          const SizedBox(height: 12),
          VibeErrorLine(result?['result']?.toString() ??
              'Não foi possível executar o ping.'),
        ],
        if (_state.wasInterrupted) ...[
          const SizedBox(height: 12),
          const VibeNote('Teste interrompido.')
        ],
        const SizedBox(height: 12),
        const VibeNote(
            'Alguns destinos bloqueiam ICMP. A ausência de resposta ao ping, sozinha, não comprova falta de internet.'),
      ]),
    );
  }
}
