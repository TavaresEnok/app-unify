import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import 'theme.dart';

// Locally defined model for mock data
class DailyUsage {
  final DateTime date;
  final double download;
  final double upload;

  DailyUsage(this.date, this.download, this.upload);
}

class ConsumoPage extends StatefulWidget {
  const ConsumoPage({super.key});

  @override
  State<ConsumoPage> createState() => _ConsumoPageState();
}

class _ConsumoPageState extends State<ConsumoPage> {
  bool _isLoading = true;
  List<DailyUsage> _dailyUsage = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Mocking data for visual consistency since API structure is unknown
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _dailyUsage = List.generate(7, (index) {
          // Last 7 days
          return DailyUsage(
              DateTime.now().subtract(Duration(days: 6 - index)),
              (index + 3) * 1.5, // Random-ish values
              (index + 1) * 0.8);
        });
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final planName = authService.usuario?.plano ?? 'Plano Internet';

    return Scaffold(
      backgroundColor: Layout04Theme.background,
      appBar: AppBar(
        title: Text('Relatório de Consumo', style: Layout04Theme.heading3),
        backgroundColor: Layout04Theme.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: Layout04Theme.activeCardDecoration,
                    child: Row(
                      children: [
                        Icon(Icons.speed_rounded,
                            color: Layout04Theme.primary, size: 32),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Seu Plano Atual',
                                style: Layout04Theme.bodySmall),
                            Text(planName, style: Layout04Theme.heading3),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ChartCard(dailyUsage: _dailyUsage),
                  const SizedBox(height: 24),
                  Text('Detalhamento da Semana', style: Layout04Theme.heading3),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _dailyUsage.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _dailyUsage[
                          _dailyUsage.length - 1 - index]; // Reverse order
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: Layout04Theme.cardDecoration,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Dia ${item.date.day}/${item.date.month}',
                              style: Layout04Theme.bodyMedium,
                            ),
                            Row(children: [
                              Icon(Icons.arrow_downward,
                                  size: 14, color: Layout04Theme.success),
                              const SizedBox(width: 4),
                              Text(
                                '${item.download.toStringAsFixed(1)} GB',
                                style: Layout04Theme.bodyMedium,
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.arrow_upward,
                                  size: 14, color: Layout04Theme.primary),
                              const SizedBox(width: 4),
                              Text(
                                '${item.upload.toStringAsFixed(1)} GB',
                                style: Layout04Theme.bodyMedium,
                              ),
                            ])
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final List<DailyUsage> dailyUsage;

  const _ChartCard({required this.dailyUsage});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: Layout04Theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Últimos 7 dias', style: Layout04Theme.bodyMedium),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20, // Scale for mock data
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: dailyUsage.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data.download + data.upload,
                        color: Layout04Theme.primary,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 20,
                          color: Layout04Theme.surfaceHighlight,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
