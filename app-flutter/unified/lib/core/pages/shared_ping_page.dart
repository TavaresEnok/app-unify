import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../controllers/diagnostic_binding.dart';
import '../models/diagnostico_state.dart';
import '../services/diagnostico_service.dart';
import '../vibe/vibe_page_parts.dart';
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
    final navigator = Navigator.of(context);
    return VibePageScaffold(
      title: 'Teste de ping',
      subtitle: 'Cinco pacotes',
      onBack: navigator.canPop() ? () => navigator.maybePop() : null,
      children: [
        VibeCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              VibeField(
                label: 'IP ou domínio',
                icon: 'globe',
                controller: _target,
                enabled: !_state.isTesting,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _start(),
              ),
              const SizedBox(height: 10),
              VibeChoiceChips<String>(
                options: [
                  ('8.8.8.8', 'Google'),
                  ('1.1.1.1', 'Cloudflare'),
                  if (_gateway != null) (_gateway!, 'Roteador'),
                ],
                selected: _target.text.trim(),
                enabled: !_state.isTesting,
                onSelected: (host) => setState(() => _target.text = host),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                VibeErrorLine(_error!.replaceFirst('FormatException: ', ''))
              ],
              const SizedBox(height: 10),
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
        if (responses.isNotEmpty || _state.isTesting)
          PingPacketResults(responses: responses, running: _state.isTesting),
        if (!_state.isTesting && result?['status'] == TestStatus.error)
          VibeErrorLine(result?['result']?.toString() ??
              'Não foi possível executar o ping.'),
        if (measured)
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
        if (_state.wasInterrupted) const VibeNote('Teste interrompido.'),
        const VibeNote(
            'Alguns destinos não respondem a ping. Ficar sem resposta, sozinho, não comprova falta de internet.'),
      ],
    );
  }
}

/// Displays only packets reported by the native ping process.
class PingPacketResults extends StatelessWidget {
  const PingPacketResults(
      {super.key, required this.responses, required this.running});
  final List<Map> responses;
  final bool running;

  @override
  Widget build(BuildContext context) => VibeCard(
          child: VibeKvList([
        for (var index = 0; index < responses.length; index++)
          VibeKv(
            responses[index]['sequence'] == null
                ? 'Resposta ${index + 1}'
                : 'Pacote ${responses[index]['sequence']}',
            responses[index]['timeout'] == true
                ? 'Tempo esgotado'
                : '${responses[index]['timeMs']} ms',
            leading: VibeDot(responses[index]['timeout'] == true
                ? VibeTone.bad
                : VibeTone.ok),
          ),
        if (running)
          VibeKv('Pacote ${responses.length + 1}', 'Enviando…', muted: true),
      ]));
}
