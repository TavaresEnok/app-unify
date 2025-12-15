import 'package:flutter/material.dart';
import '../../../core/models/provider_model.dart';

class FaqTab extends StatefulWidget {
  final ProviderModel provider;
  final Function(Map<String, dynamic>) onSave;

  const FaqTab({super.key, required this.provider, required this.onSave});

  @override
  State<FaqTab> createState() => _FaqTabState();
}

class _FaqTabState extends State<FaqTab> {
  final List<Map<String, TextEditingController>> _items = [];

  @override
  void initState() {
    super.initState();
    final faq = widget.provider.details?['faq'] as List<dynamic>? ?? [];
    for (var item in faq) {
      final map = item as Map<String, dynamic>;
      _items.add({
        'question': TextEditingController(text: map['question'] ?? ''),
        'answer': TextEditingController(text: map['answer'] ?? ''),
      });
    }
  }

  @override
  void dispose() {
    for (var item in _items) {
      item['question']!.dispose();
      item['answer']!.dispose();
    }
    super.dispose();
  }

  void _save() {
    final faq = _items
        .where(
          (item) =>
              item['question']!.text.isNotEmpty &&
              item['answer']!.text.isNotEmpty,
        )
        .map(
          (item) => {
            'question': item['question']!.text.trim(),
            'answer': item['answer']!.text.trim(),
          },
        )
        .toList();

    widget.onSave({
      'details': {...?widget.provider.details, 'faq': faq},
    });
  }

  void _addItem() {
    setState(() {
      _items.add({
        'question': TextEditingController(),
        'answer': TextEditingController(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FAQ e Dicas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Perguntas frequentes',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              IconButton(
                onPressed: _addItem,
                icon: const Icon(
                  Icons.add_circle,
                  color: Color(0xFF673AB7),
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.quiz_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Nenhuma pergunta cadastrada',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Pergunta #${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => setState(() {
                            _items[index]['question']!.dispose();
                            _items[index]['answer']!.dispose();
                            _items.removeAt(index);
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: item['question'],
                      decoration: const InputDecoration(
                        labelText: 'Pergunta',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: item['answer'],
                      decoration: const InputDecoration(
                        labelText: 'Resposta',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _items.isEmpty ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF673AB7),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Salvar FAQ',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
