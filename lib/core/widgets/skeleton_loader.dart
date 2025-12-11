// ARQUIVO: lib/core/widgets/skeleton_loader.dart
// DESCRIÇÃO: Widget de skeleton loading para estados de carregamento modernos

import 'package:flutter/material.dart';

/// Widget de skeleton loading animado
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
    this.isCircle = false,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.isCircle ? widget.height : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.isCircle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton para um card de fatura
class InvoiceSkeletonCard extends StatelessWidget {
  const InvoiceSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonLoader(width: 100, height: 24),
                const Spacer(),
                SkeletonLoader(width: 80, height: 28, borderRadius: 14),
              ],
            ),
            const SizedBox(height: 12),
            const SkeletonLoader(width: 150, height: 14),
            const SizedBox(height: 16),
            const SkeletonLoader(height: 44, borderRadius: 8),
          ],
        ),
      ),
    );
  }
}

/// Skeleton para uma lista de faturas
class InvoiceListSkeleton extends StatelessWidget {
  final int itemCount;

  const InvoiceListSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const InvoiceSkeletonCard(),
    );
  }
}

/// Skeleton para o card de ONU
class OnuSkeletonCard extends StatelessWidget {
  const OnuSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonLoader(width: 24, height: 24, isCircle: true),
                const SizedBox(width: 12),
                const SkeletonLoader(width: 150, height: 20),
                const Spacer(),
                const SkeletonLoader(width: 32, height: 32, isCircle: true),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: const [
                Expanded(child: SkeletonLoader(height: 80, borderRadius: 12)),
                SizedBox(width: 12),
                Expanded(child: SkeletonLoader(height: 80, borderRadius: 12)),
              ],
            ),
            const SizedBox(height: 16),
            const SkeletonLoader(height: 44, borderRadius: 12),
            const SizedBox(height: 12),
            const SkeletonLoader(width: 200, height: 14),
            const SizedBox(height: 8),
            const SkeletonLoader(width: 160, height: 14),
          ],
        ),
      ),
    );
  }
}
