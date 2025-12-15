import 'package:flutter/material.dart';
import '../../../core/models/provider_model.dart';

class NotificationsTab extends StatefulWidget {
  final ProviderModel provider;
  final Function(Map<String, dynamic>) onSave;

  const NotificationsTab({
    super.key,
    required this.provider,
    required this.onSave,
  });

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _category = 'info';
  bool _targetAll = true;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _addNotification() {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha título e mensagem')),
      );
      return;
    }

    final newNotif = {
      'id': 'notif_${DateTime.now().millisecondsSinceEpoch}',
      'title': _titleController.text.trim(),
      'message': _messageController.text.trim(),
      'category': _category,
      'targetAll': _targetAll,
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
      'dismissible': _category != 'urgent',
    };

    final currentList =
        (widget.provider.notifications?['list'] as List<dynamic>?) ?? [];
    final newList = [newNotif, ...currentList];

    widget.onSave({
      'notifications': {...?widget.provider.notifications, 'list': newList},
    });

    _titleController.clear();
    _messageController.clear();
    setState(() {
      _category = 'info';
      _targetAll = true;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Notificação criada')));
  }

  void _deleteNotification(String id) {
    final currentList =
        (widget.provider.notifications?['list'] as List<dynamic>?) ?? [];
    final newList = currentList.where((n) => n['id'] != id).toList();

    widget.onSave({
      'notifications': {...?widget.provider.notifications, 'list': newList},
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications =
        (widget.provider.notifications?['list'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nova Notificação',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Mensagem',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: _category,
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'info',
                              child: Text('Informação'),
                            ),
                            DropdownMenuItem(
                              value: 'urgent',
                              child: Text('Urgente'),
                            ),
                            DropdownMenuItem(
                              value: 'promo',
                              child: Text('Promoção'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _category = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SwitchListTile(
                          title: const Text(
                            'Enviar para todos',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _targetAll,
                          onChanged: (v) => setState(() => _targetAll = v),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF673AB7),
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: const Text(
                        'Criar Notificação',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // List
          const Text(
            'Notificações Ativas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (notifications.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Nenhuma notificação ativa',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),

          ...notifications.map((n) {
            final notif = n as Map<String, dynamic>;
            final date =
                DateTime.tryParse(notif['createdAt'] ?? '') ?? DateTime.now();
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getCategoryColor(notif['category']),
                  child: Icon(
                    _getCategoryIcon(notif['category']),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  notif['title'] ?? 'Sem título',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notif['message'] ?? ''),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteNotification(notif['id']),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getCategoryColor(String? cat) {
    switch (cat) {
      case 'urgent':
        return Colors.red;
      case 'promo':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String? cat) {
    switch (cat) {
      case 'urgent':
        return Icons.warning;
      case 'promo':
        return Icons.local_offer;
      default:
        return Icons.info;
    }
  }
}
