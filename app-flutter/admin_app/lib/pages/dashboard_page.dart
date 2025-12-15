import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/stat_card.dart';
import '../core/providers/providers.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  // Key _refreshKey = UniqueKey(); // No longer needed with ref.watch

  Future<void> _refreshData() async {
    // setState(() { _refreshKey = UniqueKey(); });
    // await Future.delayed(const Duration(milliseconds: 800));
    return ref.refresh(dashboardStatsProvider.future).then((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF2563EB),
        backgroundColor: const Color(0xFF1E293B),
        child: statsAsync.when(
          data: (stats) {
            // Stats Data
            // stats is Map<String, dynamic> from API

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 0,
                  floating: true,
                  toolbarHeight: 0,
                  backgroundColor: Colors.transparent,
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(24.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Header
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF2563EB),
                                width: 2,
                              ),
                            ),
                            child: const CircleAvatar(
                              radius: 28,
                              backgroundColor: Color(0xFF1E293B),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Olá, Admin',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Visão Geral do Sistema',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Stats Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: [
                          StatCard(
                            title: 'Provedores',
                            value: (stats['totalProviders'] ?? 0).toString(),
                            icon: Icons.business,
                            color: const Color(0xFF2563EB), // Blue
                            trend: '+12%',
                          ),
                          StatCard(
                            title: 'Usuários',
                            value: (stats['totalUsers'] ?? 0).toString(),
                            icon: Icons.people,
                            color: const Color(0xFF0EA5E9), // Sky
                            trend: '+5%',
                          ),
                          StatCard(
                            title: 'Tickets',
                            value: (stats['openTickets'] ?? 0).toString(),
                            icon: Icons.support_agent,
                            color: const Color(0xFF06B6D4), // Cyan
                            trend: '-2%',
                          ),
                          StatCard(
                            title: 'Alertas',
                            value: '3',
                            icon: Icons.warning_amber_rounded,
                            color: const Color(0xFFEF4444), // Red
                            trend: '0%',
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Recent Activity Section
                      Text(
                        'Atividade Recente',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Fake Activity List for Polish
                      _buildActivityItem(
                        context,
                        'Novo provedor registrado',
                        'NetFibras adicionado ao sistema',
                        'Há 5 min',
                        Icons.business_outlined,
                        const Color(0xFF2563EB),
                      ),
                      _buildActivityItem(
                        context,
                        'Ticket de Suporte',
                        'Novo ticket aberto por User #123',
                        'Há 20 min',
                        Icons.support_agent_outlined,
                        const Color(0xFF0EA5E9),
                      ),
                      _buildActivityItem(
                        context,
                        'Backup Automático',
                        'Backup do sistema realizado com sucesso',
                        'Há 2 horas',
                        Icons.backup_outlined,
                        const Color(0xFF10B981),
                      ),
                    ]),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Erro ao carregar dashboard: $error'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.refresh(dashboardStatsProvider),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    String title,
    String subtitle,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        trailing: Text(
          time,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ),
    );
  }
}
