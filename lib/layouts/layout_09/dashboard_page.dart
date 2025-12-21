import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets/aurora_background.dart';
import 'widgets/frosted_card.dart';
import 'widgets/pill_bottom_nav.dart';

class DashboardPage extends StatefulWidget {
  final String customerName;
  final String planName;
  final String connectionStatus;
  final double billAmount;
  final DateTime billDueDate;
  final double usedGb;
  final double totalGb;
  final double downloadMbps;
  final double uploadMbps;
  final Function(String) onNavigate;
  final List<Map<String, dynamic>>? menuItems;
  final Future<void> Function()? onRefresh;

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
    this.menuItems,
    this.onRefresh,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;
    final onSurfaceVariant =
        Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.9);

    final remainingDays = widget.billDueDate.difference(DateTime.now()).inDays;

    return Stack(
      children: [
        const Positioned.fill(child: AuroraBackground()),
        SafeArea(
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    if (widget.onRefresh != null) {
                      HapticFeedback.mediumImpact();
                      await widget.onRefresh!();
                    }
                  },
                  color: scheme.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          name: widget.customerName,
                          onOpenDrawer: () {
                            HapticFeedback.lightImpact();
                            Scaffold.maybeOf(context)?.openDrawer();
                          },
                          onOpenNotifications: () {
                            HapticFeedback.lightImpact();
                            widget.onNavigate('notifications');
                          },
                        ),
                        const SizedBox(height: 18),
                        _BillCard(
                          billAmount: widget.billAmount,
                          connectionStatus: widget.connectionStatus,
                          remainingDays: remainingDays,
                        ),
                        const SizedBox(height: 14),
                        _QuickActions(
                          onNavigate: (route) {
                            HapticFeedback.lightImpact();
                            widget.onNavigate(route);
                          },
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'SUA CONEXÃO',
                          style: TextStyle(
                            color: onSurfaceVariant,
                            fontSize: 12,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FrostedCard(
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(Icons.router_rounded,
                                    color: scheme.primary),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.planName,
                                      style: TextStyle(
                                        color: onSurface,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 6,
                                      children: [
                                        _MetricChip(
                                          icon: Icons.download_rounded,
                                          label:
                                              '${widget.downloadMbps.toInt()} Mb',
                                        ),
                                        _MetricChip(
                                          icon: Icons.upload_rounded,
                                          label:
                                              '${widget.uploadMbps.toInt()} Mb',
                                        ),
                                        _MetricChip(
                                          icon: Icons.data_usage_rounded,
                                          label:
                                              '${widget.usedGb.toStringAsFixed(0)}/${widget.totalGb.toStringAsFixed(0)} GB',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'SERVIÇOS & DIAGNÓSTICO',
                          style: TextStyle(
                            color: onSurfaceVariant,
                            fontSize: 12,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _ServiceTile(
                          icon: Icons.analytics_rounded,
                          title: 'Diagnóstico de rede',
                          subtitle: 'Verificar qualidade e status da conexão',
                          onTap: () => widget.onNavigate('network_diagnostic'),
                        ),
                        _ServiceTile(
                          icon: Icons.speed_rounded,
                          title: 'Teste de velocidade',
                          subtitle: 'Medir download / upload',
                          onTap: () => widget.onNavigate('speed_test'),
                          accent: scheme.secondary,
                        ),
                        _ServiceTile(
                          icon: Icons.route_rounded,
                          title: 'Traceroute',
                          subtitle: 'Rastrear rota de pacotes',
                          onTap: () => widget.onNavigate('trace_route'),
                        ),
                        _ServiceTile(
                          icon: Icons.public_rounded,
                          title: 'Meu IP',
                          subtitle: 'Visualizar endereço IP',
                          onTap: () => widget.onNavigate('my_ip'),
                          accent: scheme.secondary,
                        ),
                        _ServiceTile(
                          icon: Icons.description_rounded,
                          title: 'Contrato',
                          subtitle: 'Termos e serviços',
                          onTap: () => widget.onNavigate('contract'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: PillBottomNav(
            currentIndex: _navIndex,
            onTap: (index) {
              HapticFeedback.lightImpact();
              setState(() => _navIndex = index);
              switch (index) {
                case 0:
                  widget.onNavigate('dashboard');
                  break;
                case 1:
                  widget.onNavigate('wifi');
                  break;
                case 2:
                  widget.onNavigate('invoices');
                  break;
                case 3:
                  widget.onNavigate('support');
                  break;
                case 4:
                  Scaffold.maybeOf(context)?.openDrawer();
                  break;
              }
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenNotifications;

  const _Header({
    required this.name,
    required this.onOpenDrawer,
    required this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Abrir menu',
          child: InkWell(
            onTap: onOpenDrawer,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.80),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: scheme.onSurface.withValues(alpha: 0.10),
                ),
              ),
              child: Icon(Icons.menu_rounded, color: scheme.onSurface),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá,',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.70),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                name.split(' ').first,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: 'Abrir notificações',
          child: InkWell(
            onTap: onOpenNotifications,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.80),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: scheme.onSurface.withValues(alpha: 0.10),
                ),
              ),
              child: Icon(Icons.notifications_none_rounded,
                  color: scheme.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}

class _BillCard extends StatelessWidget {
  final double billAmount;
  final String connectionStatus;
  final int remainingDays;

  const _BillCard({
    required this.billAmount,
    required this.connectionStatus,
    required this.remainingDays,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final dueText = remainingDays >= 0
        ? 'Vence em $remainingDays dias'
        : 'Vencida há ${remainingDays.abs()} dias';

    final dueColor = remainingDays < 0 ? scheme.error : scheme.onSurface;

    return FrostedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FATURA ATUAL',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  connectionStatus.toUpperCase(),
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'R\$ ${billAmount.toStringAsFixed(2)}',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 16, color: scheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dueText,
                  style: TextStyle(
                    color: dueColor.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: remainingDays < 0
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final ValueChanged<String> onNavigate;

  const _QuickActions({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.receipt_long_rounded,
            label: 'Faturas',
            onTap: () => onNavigate('invoices'),
            accent: scheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.speed_rounded,
            label: 'Velocidade',
            onTap: () => onNavigate('speed_test'),
            accent: scheme.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.support_agent_rounded,
            label: 'Suporte',
            onTap: () => onNavigate('support'),
            accent: scheme.primary,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accent;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.onSurface.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurface.withValues(alpha: 0.70)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? accent;

  const _ServiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final a = accent ?? scheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FrostedCard(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: a.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: a),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: scheme.onSurface.withValues(alpha: 0.45)),
          ],
        ),
      ),
    );
  }
}
