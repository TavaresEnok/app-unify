import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/provider_model.dart';

class MenusTab extends StatefulWidget {
  final ProviderModel provider;
  final Function(Map<String, dynamic>) onSave;

  const MenusTab({super.key, required this.provider, required this.onSave});

  @override
  State<MenusTab> createState() => _MenusTabState();
}

class _MenusTabState extends State<MenusTab> {
  List<Map<String, dynamic>> _menuItems = [];

  final List<Map<String, dynamic>> _defaultItems = [
    {
      'id': 'notifications',
      'name': 'Notificações',
      'type': 'internal',
      'color': '#F59E0B',
    },
    {
      'id': 'invoices',
      'name': 'Faturas',
      'type': 'internal',
      'color': '#1E6FF8',
    },
    {
      'id': 'payment_promise',
      'name': 'Promessa de Pagamento',
      'type': 'internal',
      'color': '#10B981',
    },
    {
      'id': 'speed_test',
      'name': 'Teste de Velocidade',
      'type': 'internal',
      'color': '#8B5CF6',
    },
    {
      'id': 'internet_usage',
      'name': 'Consumo de Internet',
      'type': 'internal',
      'color': '#EC4899',
    },
    {
      'id': 'support',
      'name': 'Suporte',
      'type': 'internal',
      'color': '#06B6D4',
    },
    {
      'id': 'contract',
      'name': 'Contrato',
      'type': 'internal',
      'color': '#6366F1',
    },
    {'id': 'my_ip', 'name': 'Meu IP', 'type': 'internal', 'color': '#F97316'},
  ];

  @override
  void initState() {
    super.initState();
    final menuConfig = widget.provider.details?['menuConfig'];
    if (menuConfig != null && menuConfig['items'] != null) {
      final order = List<String>.from(menuConfig['order'] ?? []);
      final items = Map<String, dynamic>.from(menuConfig['items']);

      _menuItems = order.map((id) {
        final item = items[id] ?? {};
        final defaultItem = _defaultItems.firstWhere(
          (d) => d['id'] == id,
          orElse: () => {},
        );
        return {
          'id': id,
          'name': item['name'] ?? defaultItem['name'] ?? 'Item',
          'type': item['type'] ?? 'internal',
          'color': item['color'] ?? defaultItem['color'] ?? '#673AB7',
          'enabled': item['enabled'] ?? true,
          'url': item['url'],
        };
      }).toList();
    } else {
      _menuItems = _defaultItems
          .map((item) => {...item, 'enabled': true})
          .toList();
    }
  }

  void _toggleItem(String id, bool enabled) {
    setState(() {
      final index = _menuItems.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        _menuItems[index]['enabled'] = enabled;
      }
    });
    _saveMenuConfig();
  }

  void _moveItem(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _menuItems.removeAt(oldIndex);
      _menuItems.insert(newIndex, item);
    });
    _saveMenuConfig();
  }

  void _saveMenuConfig() {
    final menuConfig = {
      'order': _menuItems.map((item) => item['id']).toList(),
      'items': {
        for (var item in _menuItems)
          item['id']: {
            'name': item['name'],
            'type': item['type'],
            'color': item['color'],
            'enabled': item['enabled'],
            if (item['url'] != null) 'url': item['url'],
          },
      },
    };

    widget.onSave({
      'details': {...(widget.provider.details ?? {}), 'menuConfig': menuConfig},
    });
  }

  Color _parseColor(String? hex) {
    if (hex == null) return const Color(0xFF673AB7);
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF673AB7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menus & Cores',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Organize os menus e defina uma cor para cada cartão.',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),

          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _menuItems.length,
            onReorder: _moveItem,
            itemBuilder: (context, index) {
              final item = _menuItems[index];
              final color = _parseColor(item['color']);

              return Card(
                key: ValueKey(item['id']),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.drag_handle, color: Colors.grey),
                      const SizedBox(width: 12),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                  title: Text(item['name'] ?? 'Item'),
                  subtitle: Text(
                    item['type'] == 'external_link' ? 'Link Externo' : 'Nativo',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  trailing: Switch(
                    value: item['enabled'] ?? true,
                    onChanged: (v) => _toggleItem(item['id'], v),
                    // ignore: deprecated_member_use
                    activeColor: const Color(0xFF2563EB),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
