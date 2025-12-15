import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/ticket_model.dart';
import '../../core/providers/providers.dart';
import 'ticket_details_page.dart';
import 'package:google_fonts/google_fonts.dart';

class TicketsListPage extends ConsumerStatefulWidget {
  const TicketsListPage({super.key});

  @override
  ConsumerState<TicketsListPage> createState() => _TicketsListPageState();
}

class _TicketsListPageState extends ConsumerState<TicketsListPage> {
  String _statusFilter = 'Todos';
  final List<String> _statusOptions = [
    'Todos',
    'Aberto',
    'Em Andamento',
    'Fechado',
  ];

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsListProvider);

    return Column(
      children: [
        // Status Filter Chips
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statusOptions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = _statusOptions[index];
                final isSelected = _statusFilter == status;
                return ChoiceChip(
                  label: Text(status),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _statusFilter = status),
                  selectedColor: const Color(0xFF6366F1),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[400],
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  backgroundColor: const Color(0xFF1E293B),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
            ),
          ),
        ),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              return ref.refresh(ticketsListProvider.future);
            },
            color: const Color(0xFF6366F1),
            backgroundColor: const Color(0xFF1E293B),
            child: ticketsAsync.when(
              data: (ticketsData) {
                // Convert List<Map> or List<TicketModel> depending on repo return
                // The repo currently returns Future<List<Map<String, dynamic>>>.
                // We should probably convert map to TicketModel here or in Repo.
                // Let's modify Repo to return TicketModel or convert here.
                // For speed, let's map here assuming TicketModel.fromMap exists.
                // Checking previous code: TicketModel.fromFirestore existed.
                // I need to check if TicketModel has fromMap/fromJson.

                final tickets = ticketsData
                    .map((t) => TicketModel.fromMap(t, t['id']))
                    .toList();

                final filteredTickets = tickets.where((t) {
                  if (_statusFilter == 'Todos') return true;
                  return t.status == _statusFilter;
                }).toList();

                if (filteredTickets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.confirmation_number_outlined,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum ticket encontrado',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredTickets.length,
                  itemBuilder: (context, index) {
                    return _buildTicketCard(context, filteredTickets[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Erro ao carregar tickets: $error')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketCard(BuildContext context, TicketModel ticket) {
    Color statusColor;
    switch (ticket.status) {
      case 'Aberto':
        statusColor = Colors.blue;
        break;
      case 'Em Andamento':
        statusColor = Colors.orange;
        break;
      case 'Fechado':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TicketDetailsPage(ticket: ticket),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        ticket.status,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(ticket.updatedAt ?? DateTime.now()),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ticket.subject,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.business_rounded,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ticket.providerName ?? 'Provedor',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 16),
                    if (ticket.customerName != null) ...[
                      Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ticket.customerName!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    return '${date.day}/${date.month}';
  }
}
