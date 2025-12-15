import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/provider_model.dart';

class SupportTab extends StatefulWidget {
  final ProviderModel provider;
  final Function(Map<String, dynamic>) onSave;

  const SupportTab({super.key, required this.provider, required this.onSave});

  @override
  State<SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends State<SupportTab> {
  List<Map<String, dynamic>> _contacts = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  String _selectedType = 'phone';

  @override
  void initState() {
    super.initState();
    final config = widget.provider.details ?? {};
    _contacts = List<Map<String, dynamic>>.from(
      config['supportContacts'] ?? [],
    );
  }

  void _addContact() {
    if (_nameController.text.isEmpty || _valueController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha nome e valor')));
      return;
    }

    setState(() {
      _contacts.add({
        'id': 'contact_${DateTime.now().millisecondsSinceEpoch}',
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'value': _valueController.text.trim(),
      });
    });

    _nameController.clear();
    _valueController.clear();
    _saveContacts();
  }

  void _removeContact(String id) {
    setState(() {
      _contacts.removeWhere((c) => c['id'] == id);
    });
    _saveContacts();
  }

  void _saveContacts() {
    widget.onSave({
      'details': {
        ...(widget.provider.details ?? {}),
        'supportContacts': _contacts,
      },
    });
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'address':
        return Icons.location_on;
      default:
        return Icons.contact_support;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'phone':
        return Colors.green;
      case 'email':
        return Colors.red;
      case 'address':
        return Colors.blue;
      default:
        return Colors.grey;
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
            'Contatos de Suporte',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gerencie os telefones, emails e endereços exibidos na tela de suporte.',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),

          // Add Contact Form
          Card(
            color: const Color(0xFF1E293B),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adicionar Contato',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      hintText: 'Ex: Suporte Técnico',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'phone', child: Text('Telefone')),
                      DropdownMenuItem(value: 'email', child: Text('Email')),
                      DropdownMenuItem(
                        value: 'address',
                        child: Text('Endereço'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedType = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _valueController,
                    decoration: InputDecoration(
                      labelText: _selectedType == 'phone'
                          ? 'Número'
                          : _selectedType == 'email'
                          ? 'Email'
                          : 'Endereço',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addContact,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Contact List
          if (_contacts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.contact_support_outlined,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhum contato configurado',
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
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getIconColor(
                        contact['type'],
                      ).withValues(alpha: 0.1),
                      child: Icon(
                        _getIcon(contact['type']),
                        color: _getIconColor(contact['type']),
                      ),
                    ),
                    title: Text(contact['name'] ?? 'Sem nome'),
                    subtitle: Text(contact['value'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeContact(contact['id']),
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
