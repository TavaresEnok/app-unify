import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/consumo_provider.dart';
import '../providers/providers.dart';
import '../vibe/vibe_page_parts.dart';
import '../vibe/vibe_text.dart';
import '../vibe/vibe_tokens.dart';

class ConsumoPage extends ConsumerWidget {
  const ConsumoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(consumoViewModelProvider);
    final controller = ref.read(consumoViewModelProvider.notifier);
    final plan = ref.watch(authNotifierProvider).valueOrNull?.plano.trim();
    final now = DateTime.now();
    final selectedMonth = DateTime(state.selectedYear, state.selectedMonth);
    final currentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;
    final lastDay = currentMonth
        ? now.day
        : DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final data = state.data;
    final reportedPeriod = data?['period'];
    final periodMatches = reportedPeriod == null ||
        reportedPeriod == DateFormat('MM/yyyy').format(selectedMonth);
    final total = periodMatches ? _validAmount(data?['usedGb']) : null;
    final entries = <int, double>{};
    final details = data?['details'];
    if (details is List && periodMatches) {
      for (final item in details.whereType<Map>()) {
        final day = int.tryParse('${item['day']}');
        final amount = _validAmount(item['gb']);
        if (day != null && day >= 1 && day <= lastDay && amount != null) {
          entries[day] = amount;
        }
      }
    }

    return VibePageScaffold(
      title: 'Consumo',
      subtitle: plan?.isNotEmpty == true ? plan : null,
      onBack: Navigator.of(context).canPop()
          ? () => Navigator.of(context).maybePop()
          : null,
      onRefresh: controller.loadData,
      children: [
        _Months(
          months: List.generate(
              6, (index) => DateTime(now.year, now.month - 5 + index)),
          selected: selectedMonth,
          onSelected: (month) =>
              controller.changeMonth(month.month, month.year),
        ),
        if (state.isLoading)
          const Padding(
            padding: EdgeInsets.all(26),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.error != null)
          VibeCard(
            child: VibeEmpty(
              icon: 'g-chart',
              title: 'Não foi possível consultar o consumo',
              action: VibePageButton(
                label: 'Tentar novamente',
                onPressed: controller.loadData,
                small: true,
                expand: false,
              ),
            ),
          )
        else if (total == null)
          const VibeCard(
            child: VibeEmpty(
              icon: 'g-chart',
              title: 'Consumo indisponível neste mês',
              text: 'Selecione outro mês ou tente atualizar a página.',
            ),
          )
        else ...[
          VibeCard(
            main: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VibeLabel(
                    'Total em ${DateFormat.MMMM('pt_BR').format(selectedMonth)}'
                    '${currentMonth ? ' até hoje' : ''}'),
                VibeBigText('${_gb.format(total)} GB'),
                const SizedBox(height: 10),
                if (entries.isEmpty)
                  const VibeNote(
                      'Detalhes diários indisponíveis para este período.')
                else
                  _DailyChart(entries: entries, lastDay: lastDay),
              ],
            ),
          ),
          const VibeNote(
              'Dias sem dados informados não significam consumo zero.'),
        ],
      ],
    );
  }
}

final _gb =
    NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 2);

double? _validAmount(Object? value) {
  final amount = value is num ? value.toDouble() : double.tryParse('$value');
  return amount != null && amount.isFinite && amount >= 0 ? amount : null;
}

class _Months extends StatelessWidget {
  const _Months(
      {required this.months, required this.selected, required this.onSelected});

  final List<DateTime> months;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final labelSize = MediaQuery.textScalerOf(context).scale(13);
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 5.0;
      final columns =
          (constraints.maxWidth / (labelSize * 4.25)).floor().clamp(1, 3);
      final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final month in months)
            SizedBox(
              width: width,
              child: Semantics(
                button: true,
                selected: month == selected,
                label: DateFormat.yMMMM('pt_BR').format(month),
                child: Material(
                  color:
                      month == selected ? t.ac : t.ink.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(22),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onSelected(month),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Center(
                          child: ExcludeSemantics(
                            child: Text(
                              DateFormat.MMM('pt_BR')
                                  .format(month)
                                  .replaceAll('.', ''),
                              textAlign: TextAlign.center,
                              style: vibeText(t, 13, 650,
                                  color: month == selected ? t.on : t.ink),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.entries, required this.lastDay});

  final Map<int, double> entries;
  final int lastDay;

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final maxGb = entries.values.fold(0.0, (peak, gb) => gb > peak ? gb : peak);
    return Column(
      children: [
        SizedBox(
          height: 112,
          child: LayoutBuilder(builder: (context, constraints) {
            final width = (constraints.maxWidth / lastDay * .7).clamp(1.0, 8.0);
            return Semantics(
              label: 'Uso diário, ${entries.length} dias informados',
              child: BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxGb > 0 ? maxGb * 1.08 : 1,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, _, rod, __) {
                      if (!entries.containsKey(group.x)) return null;
                      return BarTooltipItem(
                        'Dia ${group.x} · ${_gb.format(rod.toY)} GB',
                        vibeText(t, 12.5, 650, color: Colors.white),
                      );
                    },
                    getTooltipColor: (_) => const Color(0xFF172033),
                  ),
                ),
                barGroups: [
                  for (var day = 1; day <= lastDay; day++)
                    BarChartGroupData(x: day, barRods: [
                      BarChartRodData(
                        toY: entries[day] ?? 0,
                        width: width,
                        color: t.ac,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2)),
                      ),
                    ]),
                ],
              )),
            );
          }),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(child: VibeLabel('Dia 1')),
            const SizedBox(width: 8),
            Flexible(child: VibeLabel('Dia $lastDay')),
          ],
        ),
      ],
    );
  }
}
