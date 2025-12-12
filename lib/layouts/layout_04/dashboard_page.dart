import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'theme.dart';

typedef NavigateToPageCallback = void Function(String pageId);

class DashboardPage extends StatelessWidget {
  final String customerName, planName, connectionStatus;
  final double billAmount, usedGb, totalGb, downloadMbps, uploadMbps;
  final DateTime billDueDate;
  final NavigateToPageCallback onNavigate;

  const DashboardPage({
    super.key,
    required this.customerName,
    required this.planName,
    required this.connectionStatus,
    required this.billAmount,
    required this.billDueDate,
    required this.usedGb,
    required this.totalGb,
    required this.downloadMbps,
    required this.uploadMbps,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 680;
        final usagePercent =
            (totalGb == 0) ? 0.0 : (usedGb / totalGb).clamp(0.0, 1.0);

        return Container(
          decoration: const BoxDecoration(
            gradient: Layout04Theme.backgroundGradient,
          ),
          child: CustomScrollView(
            slivers: [
              _buildHeader(context),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _BillCard(
                      amount: billAmount,
                      dueDate: billDueDate,
                      onNavigate: onNavigate,
                    ),
                    const SizedBox(height: 16),
                    if (isWide)
                      Row(
                        children: [
                          Expanded(
                            child: _UsageCard(
                              usedGb: usedGb,
                              totalGb: totalGb,
                              usagePercent: usagePercent,
                              onNavigate: onNavigate,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SpeedCard(
                              download: downloadMbps,
                              upload: uploadMbps,
                              onNavigate: onNavigate,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _UsageCard(
                        usedGb: usedGb,
                        totalGb: totalGb,
                        usagePercent: usagePercent,
                        onNavigate: onNavigate,
                      ),
                      const SizedBox(height: 16),
                      _SpeedCard(
                        download: downloadMbps,
                        upload: uploadMbps,
                        onNavigate: onNavigate,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _QuickActionsGrid(
                      onNavigate: onNavigate,
                      crossAxisCount: isWide ? 4 : 3,
                    ),
                    const SizedBox(height: 16),
                    _SupportCard(onNavigate: onNavigate),
                    const SizedBox(
                        height: 80), // Space for bottom nav if needed
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isConnectionOk = connectionStatus.toLowerCase() == 'ativo';
    final statusColor =
        isConnectionOk ? Layout04Theme.success : Layout04Theme.error;

    return SliverAppBar(
      elevation: 0,
      pinned: true,
      expandedHeight: 200.0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Painel',
          style: Layout04Theme.heading3,
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: Layout04Theme.primaryGradient,
          ),
          child: Stack(
            children: [
              // Pattern overlay
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://www.transparenttextures.com/patterns/diamond-upholstery.png',
                        ),
                        repeat: ImageRepeat.repeat,
                      ),
                    ),
                  ),
                ),
              ),
              // User info
              Positioned(
                left: 16,
                right: 16,
                bottom: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, $customerName',
                      style: Layout04Theme.heading2.copyWith(
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      planName,
                      style: Layout04Theme.bodyLarge.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              boxShadow: Layout04Theme.neonGlow(statusColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            connectionStatus,
                            style: Layout04Theme.bodyMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// === BILL CARD ===

class _BillCard extends StatelessWidget {
  final double amount;
  final DateTime dueDate;
  final NavigateToPageCallback onNavigate;

  const _BillCard({
    required this.amount,
    required this.dueDate,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = dueDate.isBefore(DateTime.now());

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: Layout04Theme.glassCard(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: Layout04Theme.secondaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Sua Fatura', style: Layout04Theme.heading3),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        Layout04Theme.accentGradient.createShader(bounds),
                    child: Text(
                      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                          .format(amount),
                      style: Layout04Theme.heading1.copyWith(
                        color: Colors.white,
                        fontSize: 36,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _BillStatusBadge(isOverdue: isOverdue),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Vencimento: ${DateFormat("d 'de' MMMM", 'pt_BR').format(dueDate)}',
                style: Layout04Theme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Layout04Theme.glassBorder,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _NeonButton(
                      label: 'PAGAR AGORA',
                      onPressed: () => onNavigate('invoices'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => onNavigate('invoices'),
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      color: Layout04Theme.primaryCyan,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Layout04Theme.glassWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Layout04Theme.glassBorder),
                      ),
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
}

class _BillStatusBadge extends StatelessWidget {
  final bool isOverdue;
  const _BillStatusBadge({required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    final color = isOverdue ? Layout04Theme.error : Layout04Theme.success;
    final text = isOverdue ? 'Vencida' : 'Em dia';
    final icon = isOverdue
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: Layout04Theme.statusBadge(color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: Layout04Theme.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// === USAGE CARD ===

class _UsageCard extends StatelessWidget {
  final double usedGb, totalGb, usagePercent;
  final NavigateToPageCallback onNavigate;

  const _UsageCard({
    required this.usedGb,
    required this.totalGb,
    required this.usagePercent,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final percentText = (usagePercent * 100).round();
    final ringColor = usagePercent < 0.6
        ? Layout04Theme.primaryCyan
        : (usagePercent < 0.9 ? Layout04Theme.warning : Layout04Theme.error);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: () => onNavigate('internet_usage'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: Layout04Theme.glassCard(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Consumo', style: Layout04Theme.heading3),
                const SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: usagePercent),
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) =>
                                CircularProgressIndicator(
                              value: value,
                              strokeWidth: 8,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ringColor,
                              ),
                              backgroundColor: Layout04Theme.glassWhite,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Center(
                            child: Text(
                              '$percentText%',
                              style: Layout04Theme.heading3.copyWith(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${usedGb.toStringAsFixed(1)} GB',
                            style: Layout04Theme.heading2.copyWith(
                              fontSize: 22,
                            ),
                          ),
                          Text(
                            'de ${totalGb.toStringAsFixed(1)} GB',
                            style: Layout04Theme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// === SPEED CARD ===

class _SpeedCard extends StatelessWidget {
  final double download, upload;
  final NavigateToPageCallback onNavigate;

  const _SpeedCard({
    required this.download,
    required this.upload,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: () => onNavigate('speed_test'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: Layout04Theme.glassCard(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Velocidade', style: Layout04Theme.heading3),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _SpeedNumber(
                        label: 'Download',
                        value: download,
                        icon: Icons.arrow_downward_rounded,
                        color: Layout04Theme.primaryCyan,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Layout04Theme.glassBorder,
                    ),
                    Expanded(
                      child: _SpeedNumber(
                        label: 'Upload',
                        value: upload,
                        icon: Icons.arrow_upward_rounded,
                        color: Layout04Theme.primaryPink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedNumber extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const _SpeedNumber({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          '${value.toInt()}',
          style: Layout04Theme.heading2,
        ),
        Text(
          'Mbps',
          style: Layout04Theme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Layout04Theme.caption,
        ),
      ],
    );
  }
}

// === QUICK ACTIONS GRID ===

class _QuickActionsGrid extends StatelessWidget {
  final NavigateToPageCallback onNavigate;
  final int crossAxisCount;

  const _QuickActionsGrid({
    required this.onNavigate,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        id: 'invoices',
        icon: Icons.receipt_long_rounded,
        label: 'Faturas',
        gradient: Layout04Theme.primaryGradient,
      ),
      _QuickActionData(
        id: 'internet_usage',
        icon: Icons.data_usage_rounded,
        label: 'Consumo',
        gradient: Layout04Theme.secondaryGradient,
      ),
      _QuickActionData(
        id: 'support',
        icon: Icons.support_agent_rounded,
        label: 'Suporte',
        gradient: Layout04Theme.accentGradient,
      ),
      _QuickActionData(
        id: 'network_diagnostic',
        icon: Icons.wifi_tethering_rounded,
        label: 'Diagnóstico',
        gradient: Layout04Theme.primaryGradient,
      ),
      _QuickActionData(
        id: 'speed_test',
        icon: Icons.speed_rounded,
        label: 'Speedtest',
        gradient: Layout04Theme.secondaryGradient,
      ),
      _QuickActionData(
        id: 'my_ip',
        icon: Icons.public_rounded,
        label: 'Meu IP',
        gradient: Layout04Theme.accentGradient,
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: Layout04Theme.glassCard(),
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: actions.length,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: 95,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return _QuickActionItem(data: action, onNavigate: onNavigate);
            },
          ),
        ),
      ),
    );
  }
}

class _QuickActionData {
  final String id;
  final IconData icon;
  final String label;
  final Gradient gradient;

  _QuickActionData({
    required this.id,
    required this.icon,
    required this.label,
    required this.gradient,
  });
}

class _QuickActionItem extends StatelessWidget {
  final _QuickActionData data;
  final NavigateToPageCallback onNavigate;

  const _QuickActionItem({
    required this.data,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onNavigate(data.id),
      child: Container(
        decoration: BoxDecoration(
          color: Layout04Theme.glassWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Layout04Theme.glassBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: data.gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                data.icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.label,
              textAlign: TextAlign.center,
              style: Layout04Theme.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Layout04Theme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === SUPPORT CARD ===

class _SupportCard extends StatelessWidget {
  final NavigateToPageCallback onNavigate;

  const _SupportCard({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: Layout04Theme.glassCard(),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: Layout04Theme.secondaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precisa de ajuda?',
                      style: Layout04Theme.heading3.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Fale com nosso suporte',
                      style: Layout04Theme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => onNavigate('support'),
                icon: Icon(
                  Icons.arrow_forward_rounded,
                  color: Layout04Theme.primaryCyan,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Layout04Theme.glassWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Layout04Theme.glassBorder),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// === NEON BUTTON WIDGET ===

class _NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _NeonButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: Layout04Theme.neonButton(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Text(
                label,
                style: Layout04Theme.buttonText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
