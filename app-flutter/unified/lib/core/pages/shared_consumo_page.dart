import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/consumo_provider.dart';
import '../widgets/customer_ui.dart';

class ConsumoPage extends ConsumerWidget {
  const ConsumoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(consumoViewModelProvider);
    final controller = ref.read(consumoViewModelProvider.notifier);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final months =
        List.generate(6, (index) => DateTime(now.year, now.month - 5 + index));
    final selectedDate = DateTime(state.selectedYear, state.selectedMonth);
    final data = state.data;
    final rawTotal = data?['usedGb'];
    final total =
        rawTotal is num ? rawTotal.toDouble() : double.tryParse('$rawTotal');
    final rawDetails = data?['details'];
    final details =
        rawDetails is List ? rawDetails.whereType<Map>().toList() : <Map>[];
    final entries = <int, double>{};
    for (final item in details) {
      final day = int.tryParse('${item['day']}');
      final value = double.tryParse('${item['gb']}');
      if (day != null && day >= 1 && day <= 31 && value != null && value >= 0) {
        entries[day] = value;
      }
    }
    final maxValue = entries.values
        .fold<double>(0, (max, value) => value > max ? value : max);

    return CustomerList(onRefresh: controller.loadData, children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final month in months)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(DateFormat('MMM yyyy', 'pt_BR').format(month)),
                selected: month.month == state.selectedMonth &&
                    month.year == state.selectedYear,
                onSelected: (_) =>
                    controller.changeMonth(month.month, month.year),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 20),
      if (state.isLoading)
        const Center(
            child: Padding(
                padding: EdgeInsets.all(36),
                child: CircularProgressIndicator()))
      else if (state.error != null)
        CustomerCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Não foi possível consultar o consumo.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: controller.loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente')),
        ]))
      else if (data == null || total == null)
        const CustomerCard(
            child: Text('O consumo deste período não está disponível.'))
      else ...[
        CustomerCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              'Total em ${DateFormat('MMMM yyyy', 'pt_BR').format(selectedDate)}',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
              '${NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 2).format(total)} GB',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (entries.isEmpty)
            Text('Detalhes diários indisponíveis para este período.',
                style: theme.textTheme.bodyMedium)
          else ...[
            SizedBox(
                height: 160,
                child: Semantics(
                  label:
                      'Gráfico de consumo por dia, com ${entries.length} dias informados',
                  child: BarChart(BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue > 0 ? maxValue * 1.15 : 1,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    barTouchData: BarTouchData(enabled: true),
                    barGroups: entries.entries
                        .map((entry) => BarChartGroupData(
                                x: entry.key,
                                barRods: [
                                  BarChartRodData(
                                      toY: entry.value,
                                      color: theme.colorScheme.primary,
                                      width: 6)
                                ]))
                        .toList(),
                  )),
                )),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Dia ${entries.keys.reduce((a, b) => a < b ? a : b)}'),
              Text('Dia ${entries.keys.reduce((a, b) => a > b ? a : b)}')
            ]),
          ],
        ])),
        const SizedBox(height: 16),
        Text('Dias sem dados informados não significam consumo zero.',
            style: theme.textTheme.bodySmall),
      ],
    ]);
  }
}
