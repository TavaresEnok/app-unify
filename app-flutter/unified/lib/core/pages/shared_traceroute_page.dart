import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../providers/providers.dart';
import '../services/traceroute_service.dart';
import '../services/subscriber_achievements.dart';
import '../vibe/vibe_page_parts.dart';
import '../vibe/vibe_text.dart';
import '../vibe/vibe_tokens.dart';

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
  bool _stopped = false;

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
      _stopped = true;
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
    final user = ref.read(authNotifierProvider).valueOrNull;
    FocusScope.of(context).unfocus();
    final request = ++_requestNumber;
    final client = http.Client();
    _client = client;
    setState(() {
      _running = true;
      _stopped = false;
      _result = null;
      _message = null;
    });
    try {
      final result = await TracerouteService(client).run(config.apiUrl, target);
      if (!mounted || request != _requestNumber) return;
      setState(() {
        _result = result;
        if (result.hops.isEmpty) {
          _message = result.timedOut
              ? 'O rastreamento demorou demais. Tente novamente.'
              : 'Nenhum salto retornado.';
        }
      });
      if (result.hops.isNotEmpty && user != null) {
        unawaited(SubscriberAchievements.record(
                config.id, user.cpfCnpj, AchievementEvent.trace)
            .catchError((_) {}));
      }
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
    final config = ref.watch(configurationProvider).providerConfig;
    final providerName = config?.name.trim();
    final result = _result;
    final hops = result?.hops ?? const <Map<String, dynamic>>[];
    return VibePageScaffold(
      title: 'Tracert',
      subtitle: 'Rota da rede',
      onBack: Navigator.of(context).canPop()
          ? () => Navigator.of(context).maybePop()
          : null,
      children: [
        VibeCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: VibeGap(gap: 8, children: [
            VibeField(
              label: 'IP público ou domínio',
              icon: 'g-route',
              hint: 'Ex.: google.com',
              controller: _target,
              enabled: !_running,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _start(),
            ),
            if (_message != null) VibeErrorLine(_message!),
            VibePageButton(
              label: _running ? 'Parar' : 'Iniciar rastreamento',
              icon: _running ? 'g-stop' : 'g-play',
              ghost: _running,
              onPressed: _running ? _stop : _start,
            ),
            VibeNote(providerName?.isNotEmpty == true
                ? 'A rota parte do servidor de $providerName.'
                : 'A rota parte do servidor do provedor.'),
            if (_running) const VibeProgressBar(),
          ]),
        ),
        if (hops.isNotEmpty)
          VibeCard(
            child: VibeRows(children: [
              for (final (index, hop) in hops.indexed)
                _TraceHop(index: index, hop: hop),
            ]),
          ),
        if (_stopped)
          const VibeOkBox(
              title: 'Rastreamento interrompido', strip: true, warning: true)
        else if (hops.isNotEmpty)
          VibeOkBox(
            title: result!.reached
                ? 'Destino alcançado em ${hops.length} saltos'
                : 'Rota parcial · ${hops.length} saltos retornados',
            strip: true,
            warning: !result.reached,
          ),
      ],
    );
  }
}

class _TraceHop extends StatelessWidget {
  const _TraceHop({required this.index, required this.hop});

  /// "0.069 ms" → "<1 ms"; "30.980 ms" → "31 ms"; "*" → "sem resposta".
  static String _time(Object? raw) {
    final text = raw?.toString().trim() ?? '';
    final match = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(text);
    final value = double.tryParse(match?.group(1)?.replaceAll(',', '.') ?? '');
    if (value == null) return 'sem resposta';
    return value < 1 ? '<1 ms' : '${value.round()} ms';
  }

  final int index;
  final Map<String, dynamic> hop;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final address = hop['ip']?.toString().trim();
    final missing = address == null || address.isEmpty || address == '*';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Container(
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          padding: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
              color: t.ac.withValues(alpha: .15), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text('${hop['hop'] ?? index + 1}',
              style: vibeText(t, 12, 700, color: t.at)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SelectableText(missing ? 'Sem resposta' : address,
              style: vibeText(t, 13.5, missing ? 500 : 650,
                  color: missing ? t.mut : t.ink)),
        ),
        const SizedBox(width: 10),
        Text(_time(hop['time']),
            textAlign: TextAlign.end,
            style: missing || _time(hop['time']) == 'sem resposta'
                ? vibeText(t, 13.5, 500, color: t.mut)
                : vibeText(t, 13.5, 700)),
      ]),
    );
  }
}
