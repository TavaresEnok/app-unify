import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_provedor_unified/core/pages/customer/diagnostic_history_page.dart';
import 'package:app_provedor_unified/core/providers/providers.dart';
import 'package:app_provedor_unified/core/services/diagnostic_history_store.dart';
import 'package:app_provedor_unified/core/theme/layout_tokens.dart';
import '../../../tool/capture_preview.dart';

void main() {
  testWidgets(
      'clearing history refreshes the screen without returning a Future from setState',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR');
    final store = DiagnosticHistoryStore('demo', '1');
    await store.save({
      'id': 'entry',
      'title': 'Verificação concluída',
      'mode': 'quick',
      'summary': 'Resumo',
      'date': '2026-11-16T12:00:00'
    });
    await tester.pumpWidget(ProviderScope(
        overrides: [
          configurationProvider.overrideWith((_) => DemoConfig('layout_06')),
          authNotifierProvider.overrideWith(DemoAuth.new),
        ],
        child: MaterialApp(
            theme: LayoutTokens.of('layout_06').themeData(),
            home: const DiagnosticHistoryPage())));
    await tester.pumpAndSettle();
    expect(find.text('Verificação concluída'), findsOneWidget);
    await tester.tap(find.text('Limpar histórico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma verificação guardada'), findsOneWidget);
    expect(await store.read(), isEmpty);
    expect(tester.takeException(), isNull);
  });
}
