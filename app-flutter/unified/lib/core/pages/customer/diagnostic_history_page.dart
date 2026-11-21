import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../services/diagnostic_history_store.dart';
import '../../widgets/content_state.dart';
import '../../widgets/customer_ui.dart';
import '../../utils/app_formatters.dart';
import '../shared_diagnostico_page.dart';
import '../../vibe/vibe_page_parts.dart';

class DiagnosticHistoryPage extends ConsumerStatefulWidget {
  const DiagnosticHistoryPage({super.key});
  @override
  ConsumerState<DiagnosticHistoryPage> createState() =>
      _DiagnosticHistoryPageState();
}

class _DiagnosticHistoryPageState extends ConsumerState<DiagnosticHistoryPage> {
  late Future<List<Map<String, dynamic>>> _history;
  DiagnosticHistoryStore? _store;
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

  @override
  Widget build(BuildContext context) => VibeHeaderPage(
        title: 'Histórico de verificações',
        subtitle: 'Guardados neste aparelho',
        actions: [
          VibeHeaderAction(
              tooltip: 'Limpar histórico',
              icon: 'g-x',
              onPressed: () async {
                final yes = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                            title: const Text('Limpar histórico?'),
                            content: const Text(
                                'Os resumos desta conta serão removidos deste aparelho.'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancelar')),
                              FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Limpar'))
                            ]));
                if (yes == true) {
                  await _store?.clear();
                  if (mounted) _reload();
                }
              }),
        ],
        body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _history,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ContentState(
                    icon: Icons.history,
                    title: 'Não conseguimos ler o histórico',
                    message: 'Tente consultar novamente.',
                    actionLabel: 'Tentar de novo',
                    onAction: _reload);
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return ContentState(
                    icon: Icons.history,
                    title: 'Suas próximas verificações aparecem aqui',
                    message:
                        'Os resumos ficam salvos neste aparelho, separados por conta.',
                    actionLabel: 'Verificar conexão',
                    onAction: () async {
                      await Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => const DiagnosticoPage()));
                      if (mounted) _reload();
                    });
              }
              return CustomerList(children: [
                for (final item in items)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CustomerCard(
                          child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: Text(
                                  item['title']?.toString() ?? 'Verificação'),
                              subtitle: Text(
                                  '${item['mode'] == 'quick' ? 'Rápida' : item['mode'] == 'speed' ? 'Velocidade' : 'Completa'} · ${_date(item['date'])}'),
                              children: [
                            SelectableText(item['summary']?.toString() ??
                                'Resumo indisponível.')
                          ])))
              ]);
            }),
      );
  String _date(dynamic raw) {
    final value = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    return value == null
        ? 'Horário não informado'
        : '${AppFormatters.date(value)} às ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}
