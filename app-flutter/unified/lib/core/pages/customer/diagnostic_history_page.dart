import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../navigation/customer_shell_scope.dart';
import '../../providers/providers.dart';
import '../../services/diagnostic_history_store.dart';
import '../../utils/app_formatters.dart';
import '../../vibe/vibe_page_parts.dart';
import '../../vibe/vibe_text.dart';
import '../../vibe/vibe_tokens.dart';
import '../shared_diagnostico_page.dart';

class DiagnosticHistoryPage extends ConsumerStatefulWidget {
  const DiagnosticHistoryPage({super.key});

  @override
  ConsumerState<DiagnosticHistoryPage> createState() =>
      _DiagnosticHistoryPageState();
}

class _DiagnosticHistoryPageState extends ConsumerState<DiagnosticHistoryPage> {
  late Future<List<Map<String, dynamic>>> _history;
  DiagnosticHistoryStore? _store;
  bool _confirmClear = false;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(configurationProvider).providerConfig;
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (config != null && user != null) {
      _store = DiagnosticHistoryStore(
          config.id, user.contratoId?.toString() ?? user.cpfCnpj);
    }
    _history = _store?.read() ?? Future.value([]);
  }

  void _reload() {
    final next = _store?.read() ?? Future<List<Map<String, dynamic>>>.value([]);
    setState(() {
      _history = next;
    });
  }

  Future<void> _clear() async {
    if (_clearing) return;
    setState(() => _clearing = true);
    try {
      await _store?.clear();
      if (mounted) {
        setState(() {
          _confirmClear = false;
          _clearing = false;
        });
        _reload();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _clearing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Não foi possível limpar o histórico. Tente novamente.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _history,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        return VibeHeaderPage(
          title: 'Histórico de verificações',
          subtitle: '${items.length} de 20',
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : snapshot.hasError
                  ? ListView(padding: const EdgeInsets.all(14), children: [
                      VibeCard(
                        child: VibeEmpty(
                          icon: 'clock',
                          title: 'Não conseguimos ler o histórico',
                          text: 'Tente consultar novamente.',
                          action: VibePageButton(
                              label: 'Tentar de novo',
                              onPressed: _reload,
                              small: true,
                              expand: false),
                        ),
                      ),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                      children: [
                        if (items.isEmpty)
                          VibeCard(
                            child: VibeEmpty(
                              icon: 'clock',
                              title: 'Nenhuma verificação guardada',
                              text:
                                  'As verificações e testes que você fizer aparecem aqui.',
                              action: VibePageButton(
                                label: 'Verificar conexão',
                                small: true,
                                expand: false,
                                onPressed: () async {
                                  await pushCustomerPage<void>(context,
                                      route: 'network_diagnostic',
                                      page: const DiagnosticoPage());
                                  if (mounted) _reload();
                                },
                              ),
                            ),
                          )
                        else ...[
                          VibeCard(
                            child: Column(children: [
                              for (var index = 0;
                                  index < items.length;
                                  index++) ...[
                                if (index > 0)
                                  Divider(height: 1, color: t.line),
                                ExpansionTile(
                                  key: PageStorageKey('history-$index'),
                                  tilePadding: EdgeInsets.zero,
                                  leading: Icon(
                                      items[index]['mode'] == 'speed'
                                          ? Icons.speed_outlined
                                          : Icons.monitor_heart_outlined,
                                      color: t.at),
                                  title: Text(
                                      items[index]['title']?.toString() ??
                                          'Verificação',
                                      style: vibeText(t, 14, 700)),
                                  subtitle: Text(
                                      '${_mode(items[index]['mode'])} · ${_date(items[index]['date'])}',
                                      style:
                                          vibeText(t, 12.5, 500, color: t.mut)),
                                  childrenPadding:
                                      const EdgeInsets.only(bottom: 14),
                                  expandedCrossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    SelectableText(
                                        items[index]['summary']?.toString() ??
                                            'Resumo indisponível.',
                                        style: vibeText(t, 13, 500,
                                            color: t.ink, height: 1.5))
                                  ],
                                ),
                              ],
                            ]),
                          ),
                          const SizedBox(height: 12),
                          if (_confirmClear)
                            VibeCard(
                              main: true,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Limpar o histórico?',
                                        style: vibeText(t, 15, 700)),
                                    const SizedBox(height: 8),
                                    Text(
                                        'Os ${items.length} registros guardados neste aparelho serão apagados.',
                                        style:
                                            vibeText(t, 13, 500, color: t.mut)),
                                    const SizedBox(height: 14),
                                    VibeTwo(
                                      VibePageButton(
                                          label: 'Cancelar',
                                          ghost: true,
                                          onPressed: _clearing
                                              ? null
                                              : () => setState(
                                                  () => _confirmClear = false)),
                                      VibePageButton(
                                          label: 'Limpar',
                                          danger: true,
                                          onPressed: _clearing ? null : _clear),
                                    ),
                                  ]),
                            )
                          else
                            VibePageButton(
                                label: 'Limpar histórico',
                                ghost: true,
                                onPressed: () =>
                                    setState(() => _confirmClear = true)),
                          const SizedBox(height: 12),
                          const VibeNote(
                              'Até 20 registros, guardados neste aparelho e separados por conta.'),
                        ],
                      ],
                    ),
        );
      },
    );
  }

  String _mode(dynamic mode) => switch (mode) {
        'quick' => 'Rápida',
        'speed' => 'Velocidade',
        _ => 'Completa',
      };

  String _date(dynamic raw) {
    final value = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    return value == null
        ? 'Horário não informado'
        : '${AppFormatters.date(value)} às ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}
