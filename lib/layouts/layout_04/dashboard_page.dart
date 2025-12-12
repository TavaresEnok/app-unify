// LAYOUT 04 - AURORA - DASHBOARD PAGE
// Design: Clean gradient dashboard following layout_06/07 patterns

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/auth_service.dart';
import 'aurora_theme.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final usuario = authService.usuario;

    final customerName = usuario?.nome ?? 'Cliente';
    final planName = usuario?.plano ?? 'Plano';
    final status = usuario?.status ?? 'Ativo';
    final isActive = status.toLowerCase() == 'ativo';

    return CustomScrollView(
      slivers: [
        // Header
        _AuroraHeader(
          customerName: customerName,
          planName: planName,
          status: status,
          isActive: isActive,
          onMenuTap: () => Scaffold.of(context).openDrawer(),
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Fatura Card
              _BillCard(
                amount: double.tryParse(usuario?.valorFatura ?? '0') ?? 0,
                dueDate: _parseDate(usuario?.vencimentoFatura),
              ),
              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: AuroraStatCard(
                      title: 'Seu Plano',
                      value: planName,
                      subtitle: '∞ Ilimitado',
                      icon: Icons.speed_rounded,
                      accentColor: AuroraColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AuroraStatCard(
                      title: 'Conexão',
                      value: isActive ? 'Online' : 'Offline',
                      subtitle: 'Fibra Óptica',
                      icon: Icons.wifi_rounded,
                      accentColor:
                          isActive ? AuroraColors.success : AuroraColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions Title
              const Text(
                'Acesso Rápido',
                style: TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Quick Actions Grid
              const _QuickActionsGrid(),

              const SizedBox(height: 24),

              // Support Card
              const _SupportCard(),

              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    try {
      return DateFormat('dd/MM/yyyy').parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }
}

class _AuroraHeader extends StatelessWidget {
  final String customerName;
  final String planName;
  final String status;
  final bool isActive;
  final VoidCallback onMenuTap;

  const _AuroraHeader({
    required this.customerName,
    required this.planName,
    required this.status,
    required this.isActive,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = customerName.split(' ').first;
    final hour = DateTime.now().hour;
    String greeting = 'Bom dia';
    if (hour >= 12 && hour < 18) greeting = 'Boa tarde';
    if (hour >= 18) greeting = 'Boa noite';

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      expandedHeight: 140,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting,',
                        style: const TextStyle(
                          color: AuroraColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        firstName,
                        style: const TextStyle(
                          color: AuroraColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _HeaderIconButton(
                        icon: Icons.notifications_outlined,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      _HeaderIconButton(
                        icon: Icons.menu_rounded,
                        onTap: onMenuTap,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AuroraStatusBadge(
                text: status,
                color: isActive ? AuroraColors.success : AuroraColors.error,
                icon: isActive ? Icons.check_circle : Icons.error,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AuroraColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AuroraColors.border),
        ),
        child: Icon(icon, color: AuroraColors.textPrimary, size: 22),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final double amount;
  final DateTime dueDate;

  const _BillCard({required this.amount, required this.dueDate});

  @override
  Widget build(BuildContext context) {
    final isOverdue = dueDate.isBefore(DateTime.now());
    final formattedAmount =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(amount);
    final formattedDate = DateFormat("d 'de' MMMM", 'pt_BR').format(dueDate);

    return AuroraCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AuroraIconBox(
                icon: Icons.receipt_long_rounded,
                color: AuroraColors.secondary,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sua Fatura',
                  style: TextStyle(
                    color: AuroraColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AuroraStatusBadge(
                text: isOverdue ? 'Vencida' : 'Em dia',
                color: isOverdue ? AuroraColors.error : AuroraColors.success,
                icon: isOverdue
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            formattedAmount,
            style: const TextStyle(
              color: AuroraColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vencimento: $formattedDate',
            style: const TextStyle(
              color: AuroraColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AuroraButton(
                  label: 'Pagar agora',
                  icon: Icons.payment_rounded,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              AuroraButton(
                label: 'Ver faturas',
                onPressed: () {},
                isOutlined: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
          icon: Icons.receipt_long_rounded,
          label: 'Faturas',
          color: AuroraColors.secondary),
      _QuickAction(
          icon: Icons.data_usage_rounded,
          label: 'Consumo',
          color: AuroraColors.primary),
      _QuickAction(
          icon: Icons.support_agent_rounded,
          label: 'Suporte',
          color: AuroraColors.warning),
      _QuickAction(
          icon: Icons.router_rounded,
          label: 'ONU',
          color: AuroraColors.success),
      _QuickAction(
          icon: Icons.speed_rounded,
          label: 'Speed Test',
          color: AuroraColors.error),
      _QuickAction(
          icon: Icons.public_rounded,
          label: 'Meu IP',
          color: AuroraColors.primary),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return AuroraCard(
          onTap: () {},
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AuroraIconBox(icon: action.icon, color: action.color, size: 44),
              const SizedBox(height: 10),
              Text(
                action.label,
                style: const TextStyle(
                  color: AuroraColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;

  _QuickAction({required this.icon, required this.label, required this.color});
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    return AuroraCard(
      child: Row(
        children: [
          const AuroraIconBox(
            icon: Icons.warning_amber_rounded,
            color: AuroraColors.warning,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Problemas técnicos?',
                  style: TextStyle(
                    color: AuroraColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Faça um diagnóstico automático',
                  style: TextStyle(
                    color: AuroraColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Iniciar',
              style: TextStyle(
                  color: AuroraColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
