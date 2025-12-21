import 'package:flutter/material.dart';
import '../theme.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final String trend;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = trend.startsWith('+');
    final trendColor = isPositive ? Layout10Theme.successColor : Layout10Theme.errorColor;
    
    return Container(
      margin: const EdgeInsets.all(Layout10Theme.spacingS),
      padding: const EdgeInsets.all(Layout10Theme.spacingM),
      decoration: BoxDecoration(
        color: Layout10Theme.surfaceColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusL),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and trend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(Layout10Theme.spacingS),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusM),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              
              // Trend indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Layout10Theme.spacingS,
                  vertical: Layout10Theme.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusXXL),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 14,
                      color: trendColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: Layout10Theme.caption.copyWith(
                        color: trendColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: Layout10Theme.spacingM),
          
          // Main value
          Text(
            value,
            style: Layout10Theme.heading3.copyWith(
              color: Layout10Theme.primaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          
          if (subtitle != null) ...[
            const SizedBox(height: Layout10Theme.spacingXS),
            Text(
              subtitle!,
              style: Layout10Theme.caption.copyWith(
                color: Layout10Theme.secondaryTextColor.withValues(alpha: 0.8),
              ),
            ),
          ],
          
          const SizedBox(height: Layout10Theme.spacingS),
          
          // Title
          Text(
            title,
            style: Layout10Theme.caption.copyWith(
              color: Layout10Theme.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class CompactStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const CompactStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Layout10Theme.spacingM),
        decoration: BoxDecoration(
          color: Layout10Theme.surfaceColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusM),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Layout10Theme.spacingS),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(Layout10Theme.borderRadiusS),
              ),
              child: Icon(
                icon,
                color: color,
                size: 16,
              ),
            ),
            
            const SizedBox(width: Layout10Theme.spacingM),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Layout10Theme.bodyMedium.copyWith(
                      color: Layout10Theme.primaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    title,
                    style: Layout10Theme.caption.copyWith(
                      color: Layout10Theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
