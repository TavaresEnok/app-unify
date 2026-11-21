import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pages/shared_diagnostico_page.dart';

/// Every quick entry uses the same cancellable diagnostic journey.
Future<void> runQuickDiagnostic(BuildContext context, WidgetRef ref) =>
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => const DiagnosticoPage(autoStart: true)));
