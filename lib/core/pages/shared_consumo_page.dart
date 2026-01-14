import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/consumo_provider.dart';
import '../../layouts/layout_03/theme.dart';

class ConsumoPage extends ConsumerStatefulWidget {
  const ConsumoPage({super.key});

  @override
  ConsumerState<ConsumoPage> createState() => _ConsumoPageState();
}

class _ConsumoPageState extends ConsumerState<ConsumoPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final configProvider = ref.watch(configurationProvider);
    final consumoState =
        ref.watch(consumoViewModelProvider); // Watch new provider
    final usuario = authState.value;
    final config = configProvider.providerConfig;
    final layoutType = config?.layoutType;
    final isLayout05 = layoutType == 'layout_05';
    final isDarkLayout = layoutType == 'layout_06' ||
        layoutType == 'layout_04' ||
        layoutType == 'layout_01' ||
        layoutType == 'layout_11' ||
        layoutType == 'layout_14';

    Color backgroundColor;
    if (isDarkLayout) {
      backgroundColor = theme.scaffoldBackgroundColor;
    } else if (isLayout05) {
      backgroundColor = Layout03Theme.background;
    } else {
      backgroundColor = theme.scaffoldBackgroundColor;
    }

    // Retorna apenas o conteúdo - PainelPage já fornece Scaffold e AppBar
    return Container(
      color: backgroundColor,
      child: RefreshIndicator(
        onRefresh: () async {
          if (isDarkLayout) {
            await ref.read(consumoViewModelProvider.notifier).loadData();
          }
        },
        child: isDarkLayout
            ? _buildLayout06Content(context, theme, consumoState)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildUnlimitedCard(theme, usuario?.plano ?? 'Plano Fibra',
                      config?.name ?? 'Provedor', isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildSpeedCard(theme, usuario, isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildConnectionStatusCard(theme, isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 16),
                  _buildBenefitsCard(theme, isLayout05,
                      isDarkLayout: isDarkLayout),
                  const SizedBox(height: 180),
                ],
              ),
      ),
    );
  }

  // --- LAYOUT 06 SPECIFIC IMPLEMENTATION ---

  Widget _buildLayout06Content(
      BuildContext context, ThemeData theme, ConsumoState state) {
    // Parse consumed data
    final data = state.data;
    final usedGb = data?['usedGb'] as double? ?? 0.0;
    final planName = data?['planName'] as String? ?? 'Carregando...';
    // final period = data?['period'] as String? ?? '';
    final details = data?['details'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Month Selector
        _buildMonthSelector(theme, state),
        const SizedBox(height: 24),

        if (state.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (state.error != null)
          Center(
              child: Text('Erro: ${state.error}',
                  style: const TextStyle(color: Colors.red)))
        else ...[
          // Main Consumption Card (Summary)
          _buildL06SummaryCard(theme, usedGb, planName),

          const SizedBox(height: 24),

          // Chart Section
          if (details.isNotEmpty)
            _buildL06Chart(theme, details)
          else
            _buildL06Chart(theme, []), // Force chart render with empty data
        ],

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildMonthSelector(ThemeData theme, ConsumoState state) {
    final now = DateTime.now();
    // Generate last 6 months
    final months = List.generate(6, (index) {
      final date = DateTime(now.year, now.month - index, 1);
      return date;
    });

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: months.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = months[index];
          final isSelected = date.month == state.selectedMonth &&
              date.year == state.selectedYear;
          final label = DateFormat('MMM yyyy', 'pt_BR')
              .format(date); // Requires intl initialized with pt_BR

          return ChoiceChip(
            label: Text(label.toUpperCase()),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                ref
                    .read(consumoViewModelProvider.notifier)
                    .changeMonth(date.month, date.year);
              }
            },
            selectedColor: theme.primaryColor,
            backgroundColor: const Color(0xFF1C1C1E),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), side: BorderSide.none),
          );
        },
      ),
    );
  }

  Widget _buildL06SummaryCard(ThemeData theme, double usedGb, String planName) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.2),
            const Color(0xFF1C1C1E)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Consumo Total',
              style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '${usedGb.toStringAsFixed(2)} GB',
            style: const TextStyle(
                color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(planName,
                style: TextStyle(
                    color: theme.primaryColor, fontWeight: FontWeight.w600)),
          )
        ],
      ),
    );
  }

  Widget _buildL06Chart(ThemeData theme, List<dynamic> details) {
    // Process details into chart spots
    // Assuming 'details' has { data: 'YYYY-MM-DD', download: bytes, upload: bytes }
    // We'll map day of month (x) to GB (y)

    // Group/Sum by day if needed, but assuming one entry per day or session

    // Mocking logic for safety if structure is unknown, but trying to parse
    List<FlSpot> spots = [];

    // We will show dots for daily total usage (Download + Upload)
    // Map to aggregate by day
    Map<int, double> dailyUsage = {};

    for (var item in details) {
      try {
        // Try to parse date
        // item['data_inicio'] or item['data']?
        // SGP API 'extratouso' usually returns: { data: '2023-10-01', download: 123, upload: 123 }
        String dateStr = item['data'] ?? '';
        if (dateStr.isNotEmpty) {
          DateTime date = DateTime.parse(dateStr);
          double down =
              double.tryParse(item['download']?.toString() ?? '0') ?? 0;
          double up = double.tryParse(item['upload']?.toString() ?? '0') ?? 0;
          double totalGb = (down + up) / (1024 * 1024 * 1024);

          dailyUsage[date.day] = (dailyUsage[date.day] ?? 0) + totalGb;
        }
      } catch (e) {
        // ignore
      }
    }

    dailyUsage.forEach((day, gb) {
      spots.add(FlSpot(day.toDouble(), gb));
    });

    spots.sort((a, b) => a.x.compareTo(b.x));

    // If no real data, generate mock zero spots for the last 5 days so the chart frame appears
    if (spots.isEmpty) {
      final now = DateTime.now();
      for (int i = 4; i >= 0; i--) {
        spots.add(FlSpot(now.day - i.toDouble(), 0));
      }
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Evolução Diária',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 10));
                      },
                      interval: 1,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: theme.primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.primaryColor.withValues(alpha: 0.1),
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

  Widget _buildUnlimitedCard(
      ThemeData theme, String planName, String providerName, bool isLayout05,
      {bool isDarkLayout = false}) {
    final decoration = isDarkLayout
        ? BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
          )
        : (isLayout05
            ? Layout03Theme.neumorphicDecoration
            : BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor.withValues(alpha: 0.1),
                    theme.primaryColor.withValues(alpha: 0.05),
                  ],
                ),
              ));

    return Card(
      elevation: isLayout05 ? 0 : 4,
      color: isLayout05 ? Colors.transparent : null,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: decoration,
        child: Column(
          children: [
            // Ícone de infinito animado
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withValues(alpha: 0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.all_inclusive,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              '∞ ILIMITADO',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Navegue sem limites!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                planName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedCard(ThemeData theme, dynamic usuario, bool isLayout05,
      {bool isDarkLayout = false}) {
    // Extract speed from plan name (e.g., "100 Mega" -> 100)
    String speedValue = '100';
    String planName = usuario?.plano ?? 'Plano Fibra';
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(planName);
    if (match != null) {
      speedValue = match.group(1)!;
    }

    final decoration = isDarkLayout
        ? BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
          )
        : (isLayout05
            ? Layout03Theme.neumorphicDecoration
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ));

    return Container(
      decoration: isLayout05 ? decoration : null,
      child: Card(
        elevation: isLayout05 ? 0 : 1,
        color: isLayout05 ? Colors.transparent : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.speed,
                      color: isLayout05
                          ? Layout03Theme.primary
                          : theme.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    'Velocidades Contratadas',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkLayout
                          ? Colors.white
                          : (isLayout05 ? Layout03Theme.textDark : null),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildSpeedItem(
                      theme,
                      'Download',
                      '$speedValue Mbps',
                      Icons.arrow_downward,
                      Colors.green,
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: theme.dividerColor,
                  ),
                  Expanded(
                    child: _buildSpeedItem(
                      theme,
                      'Upload',
                      '$speedValue Mbps',
                      Icons.arrow_upward,
                      Colors.blue,
                      isLayout05: isLayout05,
                      isDarkLayout: isDarkLayout,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedItem(
      ThemeData theme, String label, String value, IconData icon, Color color,
      {bool isLayout05 = false, bool isDarkLayout = false}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDarkLayout
                ? Colors.white
                : (isLayout05 ? Layout03Theme.textDark : null),
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isLayout05
                ? Layout03Theme.textGrey
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatusCard(ThemeData theme, bool isLayout05,
      {bool isDarkLayout = false}) {
    final decoration = isDarkLayout
        ? BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
          )
        : (isLayout05
            ? Layout03Theme.neumorphicDecoration
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ));

    return Container(
      decoration: isLayout05 ? decoration : null,
      child: Card(
        elevation: isLayout05 ? 0 : 1,
        color: isLayout05 ? Colors.transparent : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wifi,
                      color: isLayout05
                          ? Layout03Theme.primary
                          : theme.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    'Status da Conexão',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkLayout
                          ? Colors.white
                          : (isLayout05 ? Layout03Theme.textDark : null),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Ativo',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildStatusRow(
                  theme, 'Tipo de Conexão', 'Fibra Óptica', Icons.cable,
                  isDarkLayout: isDarkLayout),
              _buildStatusRow(
                  theme, 'Franquia', 'Ilimitada', Icons.all_inclusive,
                  isDarkLayout: isDarkLayout),
              _buildStatusRow(
                  theme, 'Fidelidade', 'Sem fidelidade', Icons.lock_open,
                  isDarkLayout: isDarkLayout),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(
      ThemeData theme, String label, String value, IconData icon,
      {bool isDarkLayout = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDarkLayout ? Colors.white70 : null,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDarkLayout ? Colors.white : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard(ThemeData theme, bool isLayout05,
      {bool isDarkLayout = false}) {
    final decoration = isDarkLayout
        ? BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF3A3A3C).withValues(alpha: 0.3)),
          )
        : (isLayout05
            ? Layout03Theme.neumorphicDecoration
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ));

    return Container(
      decoration: isLayout05 ? decoration : null,
      child: Card(
        elevation: isLayout05 ? 0 : 1,
        color: isLayout05 ? Colors.transparent : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 12),
                  Text(
                    'Benefícios do Seu Plano',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkLayout
                          ? Colors.white
                          : (isLayout05 ? Layout03Theme.textDark : null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBenefitItem(theme, Icons.all_inclusive,
                  'Internet ilimitada', isDarkLayout),
              _buildBenefitItem(
                  theme, Icons.bolt, 'Velocidade garantida', isDarkLayout),
              _buildBenefitItem(
                  theme, Icons.support_agent, 'Suporte 24/7', isDarkLayout),
              _buildBenefitItem(
                  theme, Icons.router, 'Wi-Fi de alta qualidade', isDarkLayout),
              _buildBenefitItem(
                  theme, Icons.security, 'Conexão segura', isDarkLayout),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(
      ThemeData theme, IconData icon, String text, bool isDarkLayout) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDarkLayout ? Colors.white : null,
            ),
          ),
        ],
      ),
    );
  }
}
