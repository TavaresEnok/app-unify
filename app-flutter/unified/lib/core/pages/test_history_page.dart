// Test History Page
// Displays test history with charts and statistics

import 'package:flutter/material.dart';
import '../theme/layout_tokens.dart';
import '../widgets/content_state.dart';
import 'shared_diagnostico_page.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/test_history.dart';
import '../services/test_history_service.dart';

class TestHistoryPage extends StatefulWidget {
  const TestHistoryPage({super.key});

  @override
  State<TestHistoryPage> createState() => _TestHistoryPageState();
}

class _TestHistoryPageState extends State<TestHistoryPage> {
  final TestHistoryService _historyService = TestHistoryService();
  List<TestHistoryEntry> _history = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  ColorScheme get _colors => Theme.of(context).colorScheme;
  Color get _text => _colors.onSurface;
  Color get _muted => _colors.onSurfaceVariant;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final history = await _historyService.getHistory();
    final stats = await _historyService.getStats();
    if (!mounted) return;
    setState(() {
      _history = history;
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Histórico de Testes'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Limpar Histórico?'),
                    content: const Text('Todos os testes salvos serão removidos.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Limpar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _historyService.clearHistory();
                  _loadHistory();
                }
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildStatsSection(),
                      const SizedBox(height: 24),
                      _buildChartSection(),
                      const SizedBox(height: 24),
                      _buildHistoryList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() => ContentState(
        icon: Icons.history,
        title: 'Você ainda não fez nenhum teste',
        message:
            'Verifique sua conexão para acompanhar os resultados por aqui.',
        actionLabel: 'Verificar conexão',
        onAction: () async {
          await Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const DiagnosticoPage()));
          if (mounted) _loadHistory();
        },
      );

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00F5FF).withValues(alpha: 0.1),
            const Color(0xFF0EA5E9).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFF00F5FF).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estatísticas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Média Download',
                  '${(_stats['avgDownload'] ?? 0).toStringAsFixed(1)} Mbps',
                  Icons.download_rounded,
                  const Color(0xFF00F5FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Média Upload',
                  '${(_stats['avgUpload'] ?? 0).toStringAsFixed(1)} Mbps',
                  Icons.upload_rounded,
                  const Color(0xFFC026D3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Média Ping',
                  '${_stats['avgPing'] ?? 0} ms',
                  Icons.speed_rounded,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Total Testes',
                  '${_stats['totalTests'] ?? 0}',
                  Icons.analytics_rounded,
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    color = LayoutTokens.readable(color, _colors.surface);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    if (_history.length < 2) return const SizedBox.shrink();

    final recentTests = _history.take(10).toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evolução de Velocidade',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: _colors.outlineVariant,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: recentTests
                        .asMap()
                        .entries
                        .map((e) =>
                            FlSpot(e.key.toDouble(), e.value.downloadSpeed))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFF00F5FF),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00F5FF).withValues(alpha: 0.3),
                          const Color(0xFF00F5FF).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Testes Recentes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _text,
          ),
        ),
        const SizedBox(height: 12),
        ..._history.map((entry) => _buildHistoryItem(entry)),
      ],
    );
  }

  Widget _buildHistoryItem(TestHistoryEntry entry) {
    final scoreColor = LayoutTokens.readable(
        entry.healthScore >= 80
            ? const Color(0xFF10B981)
            : entry.healthScore >= 60
                ? const Color(0xFFF59E0B)
                : const Color(0xFFEF4444),
        _colors.surface);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${entry.healthScore}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.speedSummary,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: _muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      entry.formattedDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '🎮 ${entry.testMode}',
                      style: TextStyle(
                        fontSize: 11,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
