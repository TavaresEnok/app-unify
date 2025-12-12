import 'package:flutter/material.dart';
import 'shared/theme/app_colors.dart';
import 'shared/widgets/dashboard_card.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _filters = ['Todos', 'Urgente', 'Residencial', 'Comercial'];
  String _selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Serviços'),
        backgroundColor: AppColors.background,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Novos (3)'),
            Tab(text: 'Ativos (1)'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(isNew: true),
                _buildOrdersList(isActive: true),
                _buildOrdersList(isHistory: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList({bool isNew = false, bool isActive = false, bool isHistory = false}) {
    // Mock Data
    final orders = [
      if (isNew) ...[
        _OrderModel(
          id: '101', type: 'Instalação Fibra', price: 120.0, 
          distance: '2.4 km', address: 'Rua das Flores, 123', 
          time: '14:00 - 16:00', rating: 4.8, isUrgent: true
        ),
        _OrderModel(
          id: '102', type: 'Manutenção Externa', price: 85.0, 
          distance: '5.1 km', address: 'Av. Paulista, 900', 
          time: '16:30 - 17:30', rating: 5.0
        ),
      ],
      if (isActive) ...[
        _OrderModel(
          id: '100', type: 'Visita Técnica - Reparo', price: 0.0, 
          distance: '0.2 km', address: 'Rua Augusta, 1500', 
          time: 'Agora', rating: 4.9, status: 'Em Andamento'
        ),
      ],
      if (isHistory) ...[
        _OrderModel(
          id: '099', type: 'Instalação 5G', price: 150.0, 
          distance: '10 km', address: 'Rua Vergueiro, 100', 
          time: 'Ontem, 10:00', rating: 5.0, status: 'Concluído'
        ),
      ]
    ];

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              'Nenhum serviço encontrado',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _OrderCard(order: orders[index], isNew: isNew, isActive: isActive);
      },
    );
  }
}

class _OrderModel {
  final String id, type, distance, address, time;
  final double price;
  final double rating;
  final bool isUrgent;
  final String? status;

  _OrderModel({
    required this.id, required this.type, required this.price, 
    required this.distance, required this.address, required this.time, 
    required this.rating, this.isUrgent = false, this.status
  });
}

class _OrderCard extends StatelessWidget {
  final _OrderModel order;
  final bool isNew;
  final bool isActive;

  const _OrderCard({required this.order, this.isNew = false, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DashboardCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        order.type,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (order.isUrgent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('URGENTE', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold)),
                        )
                      ]
                    ],
                  ),
                ),
                if (order.price > 0)
                  Text(
                    'R\$ ${order.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Details
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(order.distance, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(width: 16),
                const Icon(Icons.star, size: 16, color: AppColors.accent),
                const SizedBox(width: 4),
                Text('${order.rating}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              order.address,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  order.time,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Actions
            if (isNew)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.border),
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text('Rejeitar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: const Text('Aceitar'),
                    ),
                  ),
                ],
              )
            else if (isActive)
               SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navegar'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
               )
            else
              Container(
                 width: double.infinity,
                 padding: const EdgeInsets.symmetric(vertical: 12),
                 decoration: BoxDecoration(
                   color: AppColors.surface,
                   borderRadius: BorderRadius.circular(8)
                 ),
                 alignment: Alignment.center,
                 child: Text(order.status ?? 'Concluído', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
