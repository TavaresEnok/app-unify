import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/diagnostic_binding.dart';
import '../models/diagnostico_state.dart';
import '../services/diagnostico_service.dart';
import '../widgets/customer_ui.dart';
import '../vibe/vibe_page_parts.dart';

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
    return VibeHeaderPage(
      title: 'Teste de ping',
      subtitle: 'Cinco pacotes',
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text(
            'Mede a conexão deste aparelho até o destino, com 5 pacotes. Você pode testar seu roteador, um IP ou domínio.'),
        const SizedBox(height: 20),
        TextField(
            controller: _target,
            enabled: !_state.isTesting,
            autocorrect: false,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
                labelText: 'IP ou domínio', border: OutlineInputBorder()),
            onSubmitted: (_) => _start()),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          for (final host in ['8.8.8.8', '1.1.1.1'])
            ActionChip(
                label: Text(host),
                onPressed: _state.isTesting
                    ? null
                    : () => setState(() => _target.text = host)),
        ]),
        const SizedBox(height: 16),
        FilledButton.icon(
            icon: Icon(_state.isTesting ? Icons.stop : Icons.network_ping),
            label: Text(_state.isTesting ? 'Interromper' : 'Iniciar ping'),
            onPressed: _service == null
                ? null
                : () {
                    if (_state.isTesting) {
                      _service?.stopAllTests();
                    } else {
                      _start();
                    }
                  }),
        if (_state.isTesting) const LinearProgressIndicator(),
        const SizedBox(height: 20),
        if (_error != null)
          Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        if (responses.isNotEmpty)
          CustomerCard(
              child: Column(children: [
            for (var index = 0; index < responses.length; index++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Expanded(
                      child: Text(
                          'Resposta ${responses[index]['sequence'] ?? index + 1}')),
                  Text('${responses[index]['timeMs']} ms'),
                ]),
              ),
          ])),
        if (responses.isNotEmpty) const SizedBox(height: 12),
        if (result?['result'] != null && !_state.isTesting)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(result!['result'].toString(),
                      style: Theme.of(context).textTheme.titleMedium))),
        if (!_state.isTesting && result?['result'] != null)
          Text(_state.geralStatusMessage),
        const SizedBox(height: 12),
        const Text(
            'Alguns destinos bloqueiam ICMP. Ausência de resposta ao ping, sozinha, não comprova falta de internet.'),
      ]),
    );
  }
}
