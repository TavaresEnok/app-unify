import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/provider_model.dart';

class TipsTab extends StatefulWidget {
  final ProviderModel provider;
  final Function(Map<String, dynamic>) onSave;

  const TipsTab({super.key, required this.provider, required this.onSave});

  @override
  State<TipsTab> createState() => _TipsTabState();
}

class _TipsTabState extends State<TipsTab> {
  List<Map<String, dynamic>> _tips = [];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final config = widget.provider.details ?? {};
    final rawTips = config['tips'] ?? [];

    _tips = List<Map<String, dynamic>>.from(
      rawTips.map((item) {
        if (item is String) {
          return {
            'id': 'tip_${DateTime.now().millisecondsSinceEpoch}',
            'title': 'Dica',
            'description': item,
          };
        }
        return Map<String, dynamic>.from(item);
      }),
    );
  }

  void _addTip() {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A descrição não pode estar vazia')),
      );
      return;
    }

    setState(() {
      _tips.add({
        'id': 'tip_${DateTime.now().millisecondsSinceEpoch}',
        'title': _titleController.text.trim().isEmpty
            ? 'Dica Útil'
            : _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
      });
    });

    _titleController.clear();
    _descriptionController.clear();
    _saveTips();
  }

  void _removeTip(String id) {
    setState(() {
      _tips.removeWhere((t) => t['id'] == id);
    });
    _saveTips();
  }

  void _saveTips() {
    final tipsToSave = _tips
        .map((t) => {'title': t['title'], 'description': t['description']})
        .toList();

    widget.onSave({
      'details': {...(widget.provider.details ?? {}), 'tips': tipsToSave},
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
            'Dicas Úteis (Carrossel)',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gerencie as dicas exibidas no aplicativo.',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),

          // Add Tip Form
          Card(
            color: const Color(0xFF1E293B),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adicionar Nova Dica',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      hintText: 'Ex: Reinicie seus equipamentos',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Ex: Desligue o modem por 10 segundos...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addTip,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Dica'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Tips List
          if (_tips.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhuma dica configurada',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dicas Atuais (${_tips.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _tips.length,
                  itemBuilder: (context, index) {
                    final tip = _tips[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFEF3C7),
                          child: Icon(
                            Icons.lightbulb,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        title: Text(tip['title'] ?? 'Dica'),
                        subtitle: Text(
                          tip['description'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeTip(tip['id']),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
