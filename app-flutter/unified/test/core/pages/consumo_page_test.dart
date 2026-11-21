import 'package:app_provedor_unified/core/pages/shared_consumo_page.dart';
import 'package:app_provedor_unified/core/providers/consumo_provider.dart';
import 'package:app_provedor_unified/core/providers/providers.dart';
import 'package:app_provedor_unified/core/theme/layout_tokens.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../../tool/layout_validation_preview.dart' show DemoAuth;

class UsageFixture extends ConsumoViewModel {
  UsageFixture(this.reported) : super(null) {
    final month = DateTime.now();
    state = ConsumoState(
      selectedMonth: month.month,
      selectedYear: month.year,
      data: reported,
    );
  }

  final Map<String, dynamic> reported;

  @override
  void changeMonth(int month, int year) {
    state =
        ConsumoState(selectedMonth: month, selectedYear: year, data: reported);
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets(
      'consumo real ocupa o cartão do layout e permanece no mês correto',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final today = DateTime.now();
    final previous = DateTime(today.year, today.month - 1);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(DemoAuth.new),
          consumoViewModelProvider.overrideWith((_) => UsageFixture({
                'usedGb': 12.5,
                'period': DateFormat('MM/yyyy').format(today),
                'details': [
                  {'day': 1, 'gb': 2.5},
                  {'day': 32, 'gb': 140},
                  {'day': 2, 'gb': 'Infinity'},
                ],
              })),
        ],
        child: MaterialApp(
          theme: LayoutTokens.of('layout_02').themeData(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const ConsumoPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('12,5 GB'), findsOneWidget);
    expect(find.text('Fibra 500 Mega'), findsOneWidget);
    expect(find.textContaining('sem limite'), findsNothing);
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.data.barGroups.first.barRods.single.toY, 2.5);
    expect(chart.data.barGroups.where((bar) => bar.barRods.single.toY > 0),
        hasLength(1));
    await tester
        .tap(find.bySemanticsLabel(DateFormat.yMMMM('pt_BR').format(previous)));
    await tester.pumpAndSettle();
    expect(find.text('Consumo indisponível neste mês'), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
