import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/provider_model.dart';

class PromotionsTab extends StatefulWidget {
  final ProviderModel provider;
  final Function(Map<String, dynamic>) onSave;

  const PromotionsTab({
    super.key,
    required this.provider,
    required this.onSave,
  });

  @override
  State<PromotionsTab> createState() => _PromotionsTabState();
}

class _PromotionsTabState extends State<PromotionsTab> {
  List<Map<String, dynamic>> _promotions = [];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _badgeController = TextEditingController(
    text: 'OFERTA',
  );
  final TextEditingController _imageUrlController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showCountdown = true;

  @override
  void initState() {
    super.initState();
    final config = widget.provider.details ?? {};
    final promoConfig = config['promotions'] ?? {};
    _promotions = List<Map<String, dynamic>>.from(promoConfig['items'] ?? []);
  }

  void _createPromotion() {
    if (_titleController.text.isEmpty ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha título e datas')));
      return;
    }

    setState(() {
      _promotions.add({
        'id': 'promo_${DateTime.now().millisecondsSinceEpoch}',
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'badge': _badgeController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'showCountdown': _showCountdown,
        'status': 'active',
        'createdAt': DateTime.now().toIso8601String(),
      });
    });

    _titleController.clear();
    _descriptionController.clear();
    _badgeController.text = 'OFERTA';
    _imageUrlController.clear();
    _startDate = null;
    _endDate = null;
    _showCountdown = true;

    _savePromotions();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Promoção criada!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deletePromotion(String id) {
    setState(() {
      _promotions.removeWhere((p) => p['id'] == id);
    });
    _savePromotions();
  }

  void _savePromotions() {
    widget.onSave({
      'details': {
        ...(widget.provider.details ?? {}),
        'promotions': {'enabled': true, 'items': _promotions},
      },
    });
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '-';
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
            'Gerenciador de Promoções',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie ofertas especiais para seus clientes.',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),

          // Create Promotion Form
          Card(
            color: const Color(0xFF1E293B),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nova Promoção',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título *',
                      hintText: 'Ex: Black Friday 50% OFF',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Detalhes da promoção...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _badgeController,
                    decoration: const InputDecoration(
                      labelText: 'Badge/Etiqueta',
                      hintText: 'Ex: EXCLUSIVO',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL da Imagem (opcional)',
                      hintText: 'https://...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(true),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _startDate != null
                                ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                : 'Data Início *',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(false),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _endDate != null
                                ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                : 'Data Fim *',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Mostrar Contador Regressivo'),
                    value: _showCountdown,
                    onChanged: (v) => setState(() => _showCountdown = v),
                    // ignore: deprecated_member_use
                    activeColor: const Color(0xFF2563EB),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _createPromotion,
                    icon: const Icon(Icons.local_offer),
                    label: const Text('Criar Promoção'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Promotions List
          Text(
            'Promoções Ativas (${_promotions.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (_promotions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.percent, size: 48, color: Colors.grey[600]),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhuma promoção criada',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _promotions.length,
              itemBuilder: (context, index) {
                final promo = _promotions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                promo['title'] ?? 'Promoção',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (promo['badge'] != null &&
                                promo['badge'].toString().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF97316),
                                      Color(0xFFEF4444),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  promo['badge'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () => _deletePromotion(promo['id']),
                            ),
                          ],
                        ),
                        if (promo['description'] != null &&
                            promo['description'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              promo['description'],
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatDate(promo['startDate'])} até ${_formatDate(promo['endDate'])}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            if (promo['showCountdown'] == true) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Com countdown',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ],
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
