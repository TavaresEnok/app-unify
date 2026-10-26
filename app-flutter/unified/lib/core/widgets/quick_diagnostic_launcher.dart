import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/diagnostico_state.dart';
import '../providers/providers.dart';
import '../services/diagnostico_service.dart';
import '../services/onu_wifi_service.dart';
import 'diagnostic_report_sheet.dart';

/// Dispara a "verificação rápida" (§ estudo 4.1) a partir de UM ponto de entrada
/// compartilhado — pensado para o momento "minha internet está ruim".
///
/// Roda o subconjunto essencial do diagnóstico de forma headless (com um
/// indicador de progresso), e ao final abre a folha de resultado com veredito e
/// ações. Não replica UI nas seis telas de diagnóstico: qualquer tela ou botão
/// chama esta função.
Future<void> runQuickDiagnostic(BuildContext context, WidgetRef ref) async {
  final config = ref.read(configurationProvider).providerConfig;
  final user = ref.read(authNotifierProvider).value;

  if (config == null || user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Sessão indisponível. Entre novamente e tente de novo.')),
    );
    return;
  }

  final onuService = OnuWifiService(
    apiUrl: config.apiUrl,
    cpfCnpj: user.cpfCnpj,
    contrato: user.contratoId?.toString(),
    providerId: config.id,
  );
  final service = DiagnosticoService(
    providerConfig: config,
    context: context,
    onuService: onuService,
  );

  final statusNotifier = ValueNotifier<String>('Preparando verificação...');
  final sub = service.stateStream.listen(
    (s) => statusNotifier.value = s.geralStatusMessage,
  );

  // Diálogo de progresso não-cancelável — a verificação rápida dura ~10-15s.
  final progress = showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _QuickProgressDialog(status: statusNotifier),
  );

  late final DiagnosticoState finalState;
  try {
    await service.runQuickCheck();
    finalState = service.currentState;
  } finally {
    await sub.cancel();
    service.dispose();
    statusNotifier.dispose();
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    await progress; // garante o fechamento do diálogo antes de seguir
  }

  if (context.mounted) {
    await showDiagnosticReportSheet(context, ref, finalState);
  }
}

class _QuickProgressDialog extends StatelessWidget {
  final ValueListenable<String> status;
  const _QuickProgressDialog({required this.status});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text('Verificando sua conexão',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          ValueListenableBuilder<String>(
            valueListenable: status,
            builder: (_, value, __) => Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
