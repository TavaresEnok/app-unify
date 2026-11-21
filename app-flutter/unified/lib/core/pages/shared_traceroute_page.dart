import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../providers/providers.dart';
import '../services/traceroute_service.dart';
import '../widgets/customer_ui.dart';

class SharedTraceRoutePage extends ConsumerStatefulWidget {
  const SharedTraceRoutePage({super.key});

  @override
  ConsumerState<SharedTraceRoutePage> createState() =>
      _SharedTraceRoutePageState();
}

class _SharedTraceRoutePageState extends ConsumerState<SharedTraceRoutePage> {
  final _target = TextEditingController(text: 'google.com');
  http.Client? _client;
  bool _running = false;
  int _requestNumber = 0;
  TraceResult? _result;
  String? _message;

  @override
  void dispose() {
    _requestNumber++;
    _client?.close();
    _target.dispose();
    super.dispose();
  }

  void _stop() {
    _requestNumber++;
    _client?.close();
    _client = null;
    setState(() {
      _running = false;
      _message = 'Rastreamento interrompido.';
    });
  }

  Future<void> _start() async {
    if (_running) return;
    final target = _target.text.trim();
    final config = ref.read(configurationProvider).providerConfig;
    if (target.isEmpty || config == null) {
      setState(() => _message = target.isEmpty
          ? 'Informe um IP público ou domínio.'
          : 'Configuração indisponível. Tente novamente.');
      return;
    }
    FocusScope.of(context).unfocus();
    final request = ++_requestNumber;
    final client = http.Client();
    _client = client;
    setState(() {
      _running = true;
      _result = null;
      _message = null;
    });
    try {
      final result = await TracerouteService(client).run(config.apiUrl, target);
      if (!mounted || request != _requestNumber) return;
      setState(() {
        _result = result;
        _message = result.hops.isEmpty
            ? 'Nenhum salto retornado.'
            : result.reached
                ? 'Destino alcançado em ${result.hops.length} salto(s).'
                : 'Rota parcial. O destino não confirmou resposta.';
      });
    } on TimeoutException {
      if (mounted && request == _requestNumber) {
        setState(
            () => _message = 'O rastreamento demorou demais. Tente novamente.');
      }
    } catch (_) {
      if (mounted && request == _requestNumber) {
        setState(() => _message =
            'Não foi possível rastrear a rota. Confira o destino e tente novamente.');
      }
    } finally {
      client.close();
      if (mounted && request == _requestNumber) {
        _client = null;
        setState(() => _running = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hops = _result?.hops ?? [];
    final colors = Theme.of(context).colorScheme;
    return CustomerList(children: [
      CustomerCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
            controller: _target,
            enabled: !_running,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
                labelText: 'IP público ou domínio',
                border: OutlineInputBorder()),
            onSubmitted: (_) => _start()),
        const SizedBox(height: 16),
        FilledButton.icon(
            onPressed: _running ? _stop : _start,
            icon: Icon(_running ? Icons.stop : Icons.play_arrow),
            label: Text(_running ? 'Parar' : 'Iniciar rastreamento')),
        const SizedBox(height: 12),
        Text('A rota parte do servidor do provedor.',
            style: Theme.of(context).textTheme.bodySmall),
        if (_running) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator()
        ],
      ])),
      if (hops.isNotEmpty) ...[
        const SizedBox(height: 16),
        CustomerCard(
            child: Column(children: [
          for (var i = 0; i < hops.length; i++)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  CircleAvatar(
                      radius: 15,
                      backgroundColor: colors.primaryContainer,
                      child: Text('${hops[i]['hop'] ?? i + 1}',
                          style: TextStyle(
                              color: colors.onPrimaryContainer, fontSize: 12))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: SelectableText(
                          (hops[i]['ip'] == null || hops[i]['ip'] == '*')
                              ? 'Sem resposta'
                              : '${hops[i]['ip']}')),
                  Text('${hops[i]['time'] ?? '—'}'),
                ])),
        ])),
      ],
      if (_message != null) ...[const SizedBox(height: 16), Text(_message!)],
    ]);
  }
}
