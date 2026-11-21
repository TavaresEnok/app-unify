import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/diagnostic_history_store.dart';
import 'providers.dart';

/// Quantas verificações estão guardadas neste aparelho para a conta atual
/// ("3 registros" nas linhas de Histórico do layout aprovado).
final diagnosticHistoryCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final config = ref.watch(configurationProvider).providerConfig;
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (config == null || user == null) return 0;
  final items = await DiagnosticHistoryStore(
          config.id, user.contratoId?.toString() ?? user.cpfCnpj)
      .read();
  return items.length;
});

String diagnosticHistoryLabel(int? count) => switch (count) {
      null => 'Resultados guardados neste aparelho',
      0 => 'Nenhum registro ainda',
      1 => '1 registro',
      _ => '$count registros',
    };
