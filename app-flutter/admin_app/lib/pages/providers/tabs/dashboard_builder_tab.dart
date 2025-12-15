import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/provider_model.dart';

class DashboardBuilderTab extends StatefulWidget {
  final ProviderModel provider;
  final Function(Map<String, dynamic>) onSave;

  const DashboardBuilderTab({
    super.key,
    required this.provider,
    required this.onSave,
  });

  @override
  State<DashboardBuilderTab> createState() => _DashboardBuilderTabState();
}

class _DashboardBuilderTabState extends State<DashboardBuilderTab> {
  List<Map<String, dynamic>> _widgets = [];

  final Map<String, String> _widgetLabels = {
    'stats_card': 'Card de Estatísticas',
    'banner': 'Banner Promocional',
    'action_grid': 'Grid de Ações',
    'carousel': 'Carrossel',
    'chart': 'Gráfico',
    'announcements': 'Avisos',
    'quick_pay': 'Pagamento Rápido',
    'speed_test': 'Teste de Velocidade',
    'usage_meter': 'Medidor de Consumo',
  };

  final Map<String, IconData> _widgetIcons = {
    'stats_card': Icons.bar_chart,
    'banner': Icons.image,
    'action_grid': Icons.grid_3x3,
    'carousel': Icons.view_carousel,
    'chart': Icons.trending_up,
    'announcements': Icons.announcement,
    'quick_pay': Icons.payment,
    'speed_test': Icons.speed,
    'usage_meter': Icons.data_usage,
  };

  @override
  void initState() {
    super.initState();
    final dashboard = widget.provider.details?['dashboard'] ?? {};
    _widgets = List<Map<String, dynamic>>.from(dashboard['widgets'] ?? []);
  }

  void _addWidget(String type) {
    setState(() {
      _widgets.add({
        'id': 'widget_${DateTime.now().millisecondsSinceEpoch}',
        'type': type,
        'position': _widgets.length + 1,
        'visible': true,
        'title': _widgetLabels[type] ?? 'Widget',
        'config': {},
      });
    });
    _saveWidgets();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Widget adicionado!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteWidget(String id) {
    setState(() {
      _widgets.removeWhere((w) => w['id'] == id);
      // Recalculate positions
      for (int i = 0; i < _widgets.length; i++) {
        _widgets[i]['position'] = i + 1;
      }
    });
    _saveWidgets();
  }

  void _toggleWidget(String id, bool visible) {
    setState(() {
      final index = _widgets.indexWhere((w) => w['id'] == id);
      if (index != -1) {
        _widgets[index]['visible'] = visible;
      }
    });
    _saveWidgets();
  }

  void _moveWidget(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _widgets.removeAt(oldIndex);
      _widgets.insert(newIndex, item);
      // Recalculate positions
      for (int i = 0; i < _widgets.length; i++) {
        _widgets[i]['position'] = i + 1;
      }
    });
    _saveWidgets();
  }

  void _saveWidgets() {
    widget.onSave({
      'details': {
        ...(widget.provider.details ?? {}),
        'dashboard': {'widgets': _widgets},
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Builder',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monte o dashboard perfeito para seus clientes.',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),

          // Add Widget Section
          Text(
            'Adicionar Widget',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _widgetLabels.entries.map((entry) {
              return ActionChip(
                avatar: Icon(_widgetIcons[entry.key], size: 18),
                label: Text(entry.value),
                onPressed: () => _addWidget(entry.key),
                backgroundColor: const Color(0xFF1E293B),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),

          // Widgets List
          Text(
            'Widgets Ativos (${_widgets.length})',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Arraste para reordenar. Use o switch para ocultar.',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 16),

          if (_widgets.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.grid_3x3, size: 48, color: Colors.grey[600]),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhum widget adicionado',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use os botões acima para adicionar',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _widgets.length,
              onReorder: _moveWidget,
              itemBuilder: (context, index) {
                final w = _widgets[index];
                final icon = _widgetIcons[w['type']] ?? Icons.widgets;
                final label = _widgetLabels[w['type']] ?? 'Widget';

                return Card(
                  key: ValueKey(w['id']),
                  margin: const EdgeInsets.only(bottom: 12),
                  color: w['visible'] == true ? null : Colors.grey[800],
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.drag_handle, color: Colors.grey),
                        const SizedBox(width: 12),
                        Icon(
                          icon,
                          color: w['visible'] == true
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ],
                    ),
                    title: Text(w['title'] ?? label),
                    subtitle: Text(
                      'Posição: ${w['position']}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: w['visible'] ?? true,
                          onChanged: (v) => _toggleWidget(w['id'], v),
                          // ignore: deprecated_member_use
                          activeColor: const Color(0xFF2563EB),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _deleteWidget(w['id']),
                        ),
                      ],
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
