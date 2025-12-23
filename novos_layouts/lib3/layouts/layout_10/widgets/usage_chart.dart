import 'package:flutter/material.dart';
import '../theme.dart';

class UsageChart extends StatelessWidget {
  final Map<String, dynamic> dadosUso;

  const UsageChart({
    super.key,
    required this.dadosUso,
  });

  @override
  Widget build(BuildContext context) {
    final used = double.tryParse(dadosUso['usados']?.toString() ?? '0') ?? 0.0;
    final limit = double.tryParse(dadosUso['limite']?.toString() ?? '100') ?? 100.0;
    final percentage = limit > 0 ? (used / limit) : 0.0;
    
    return Container(
      margin: const EdgeInsets.all(Layout10Theme.spacingS),
      padding: const EdgeInsets.all(Layout10Theme.spacingL),
      decoration: BoxDecoration(
        color: Layout10Theme.surfaceColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusL),
        border: Border.all(
          color: _getUsageColor(percentage).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getUsageColor(percentage).withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: _getUsageColor(percentage).withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consumo Mensal',
                style: Layout10Theme.heading3.copyWith(
                  color: Layout10Theme.primaryTextColor,
                ),
              ),
              
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Layout10Theme.spacingM,
                  vertical: Layout10Theme.spacingS,
                ),
                decoration: BoxDecoration(
                  color: _getUsageColor(percentage).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusXXL),
                ),
                child: Text(
                  '${(percentage * 100).toStringAsFixed(1)}%',
                  style: Layout10Theme.bodyMedium.copyWith(
                    color: _getUsageColor(percentage),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: Layout10Theme.spacingL),
          
          // Progress bar
          Container(
            height: 24,
            decoration: BoxDecoration(
              color: Layout10Theme.surfaceColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusXXL),
            ),
            child: Stack(
              children: [
                // Background gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Layout10Theme.surfaceColor,
                        Layout10Theme.surfaceColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusXXL),
                  ),
                ),
                
                // Progress
                FractionallySizedBox(
                  widthFactor: percentage.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getUsageColor(percentage),
                          _getUsageColor(percentage).withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusXXL),
                      boxShadow: [
                        BoxShadow(
                          color: _getUsageColor(percentage).withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: Layout10Theme.spacingL),
          
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usados',
                    style: Layout10Theme.caption.copyWith(
                      color: Layout10Theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: Layout10Theme.spacingXS),
                  Text(
                    '${used.toStringAsFixed(1)} GB',
                    style: Layout10Theme.bodyLarge.copyWith(
                      color: Layout10Theme.primaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Limite',
                    style: Layout10Theme.caption.copyWith(
                      color: Layout10Theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: Layout10Theme.spacingXS),
                  Text(
                    '${limit.toStringAsFixed(1)} GB',
                    style: Layout10Theme.bodyLarge.copyWith(
                      color: Layout10Theme.primaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: Layout10Theme.spacingM),
          
          // Warning message if needed
          if (percentage > 0.8)
            Container(
              padding: const EdgeInsets.all(Layout10Theme.spacingM),
              decoration: BoxDecoration(
                color: Layout10Theme.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusM),
                border: Border.all(
                  color: Layout10Theme.warningColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Layout10Theme.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: Layout10Theme.spacingS),
                  Expanded(
                    child: Text(
                      percentage > 0.95
                          ? 'Você está quase atingindo seu limite de dados!'
                          : 'Atenção: você usou ${(percentage * 100).toStringAsFixed(0)}% do seu plano.',
                      style: Layout10Theme.bodyMedium.copyWith(
                        color: Layout10Theme.warningColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getUsageColor(double percentage) {
    if (percentage < 0.5) return Layout10Theme.successColor;
    if (percentage < 0.8) return Layout10Theme.warningColor;
    return Layout10Theme.errorColor;
  }
}

class DetailedUsageChart extends StatelessWidget {
  final List<Map<String, dynamic>> dailyUsage;
  final double totalUsed;
  final double totalLimit;

  const DetailedUsageChart({
    super.key,
    required this.dailyUsage,
    required this.totalUsed,
    required this.totalLimit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(Layout10Theme.spacingS),
      padding: const EdgeInsets.all(Layout10Theme.spacingL),
      decoration: BoxDecoration(
        color: Layout10Theme.surfaceColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusL),
        border: Border.all(
          color: Layout10Theme.accentColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Layout10Theme.accentColor.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Layout10Theme.accentColor.withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Histórico de Uso',
            style: Layout10Theme.heading3.copyWith(
              color: Layout10Theme.primaryTextColor,
            ),
          ),
          
          const SizedBox(height: Layout10Theme.spacingL),
          
          // Chart bars
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                dailyUsage.length.clamp(0, 7),
                (index) {
                  final day = dailyUsage[index];
                  final usage = double.tryParse(day['usage']?.toString() ?? '0') ?? 0.0;
                  final maxUsage = dailyUsage.fold<double>(
                    0.0,
                    (max, d) => double.tryParse(d['usage']?.toString() ?? '0') ?? 0.0,
                  );
                  final height = maxUsage > 0 ? (usage / maxUsage) * 180 : 0.0;
                  
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Layout10Theme.accentColor,
                                  Layout10Theme.accentColor.withValues(alpha: 0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusS),
                            ),
                          ),
                          
                          const SizedBox(height: Layout10Theme.spacingS),
                          
                          Text(
                            day['day']?.toString() ?? '',
                            style: Layout10Theme.caption.copyWith(
                              color: Layout10Theme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: Layout10Theme.spacingL),
          
          // Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total do período',
                style: Layout10Theme.bodyMedium.copyWith(
                  color: Layout10Theme.secondaryTextColor,
                ),
              ),
              Text(
                '${totalUsed.toStringAsFixed(1)} GB',
                style: Layout10Theme.bodyMedium.copyWith(
                  color: Layout10Theme.primaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
