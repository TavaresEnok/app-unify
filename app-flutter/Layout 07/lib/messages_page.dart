import 'package:flutter/material.dart';
import 'shared/theme/app_colors.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final List<String> _filters = ['Todos', 'Clientes', 'Suporte'];
  String _selectedFilter = 'Todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mensagens'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
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
          
          // Message List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                _MessageItem(
                  name: 'Central de Suporte',
                  message: 'Seu chamado #1024 foi atualizado.',
                  time: '14:30',
                  unreadCount: 1,
                  isSupport: true,
                ),
                _MessageItem(
                  name: 'João Silva (Cliente)',
                  message: 'Estou aguardando no local.',
                  time: '14:15',
                  unreadCount: 2,
                  avatarUrl: 'https://i.pravatar.cc/150?u=joao',
                ),
                _MessageItem(
                  name: 'Maria Oliveira (Cliente)',
                  message: 'Obrigada pelo serviço!',
                  time: 'Ontem',
                  unreadCount: 0,
                  avatarUrl: 'https://i.pravatar.cc/150?u=maria',
                ),
                _MessageItem(
                  name: 'Carlos Souza (Cliente)',
                  message: 'Qual o valor da visita?',
                  time: 'Ontem',
                  unreadCount: 0,
                  avatarUrl: 'https://i.pravatar.cc/150?u=carlos',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageItem extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final int unreadCount;
  final String? avatarUrl;
  final bool isSupport;

  const _MessageItem({
    required this.name,
    required this.message,
    required this.time,
    this.unreadCount = 0,
    this.avatarUrl,
    this.isSupport = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = unreadCount > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isUnread ? AppColors.primary.withOpacity(0.03) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Stack(
          children: [
            if (isSupport)
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.headset_mic, color: AppColors.primary),
              )
            else
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surface,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null ? const Icon(Icons.person, color: AppColors.textSecondary) : null,
              ),
            if (isUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: isUnread ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isUnread) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        onTap: () {},
      ),
    );
  }
}
