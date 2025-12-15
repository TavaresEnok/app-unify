import 'package:flutter/material.dart';
import '../../../core/models/provider_model.dart';

class BannersTab extends StatefulWidget {
  final ProviderModel provider;
  final Function(Map<String, dynamic>) onSave;

  const BannersTab({super.key, required this.provider, required this.onSave});

  @override
  State<BannersTab> createState() => _BannersTabState();
}

class _BannersTabState extends State<BannersTab> {
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    final banners = widget.provider.details?['banners'] as List<dynamic>? ?? [];
    for (var banner in banners) {
      _controllers.add(TextEditingController(text: banner.toString()));
    }
    if (_controllers.isEmpty) {
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final banners = _controllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    widget.onSave({
      'details': {...?widget.provider.details, 'banners': banners},
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Banners Promocionais',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione URLs de imagens para o carrossel do app',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          ..._controllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'URL da Imagem ${index + 1}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.image),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_controllers.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          setState(() => _controllers.removeAt(index)),
                    ),
                ],
              ),
            );
          }),

          TextButton.icon(
            onPressed: () =>
                setState(() => _controllers.add(TextEditingController())),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Banner'),
          ),

          const SizedBox(height: 24),
          const Text(
            'Preview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _controllers.map((c) {
                if (c.text.isEmpty) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      c.text,
                      height: 200,
                      width: 300,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        width: 300,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 48),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF673AB7),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Salvar Banners',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
