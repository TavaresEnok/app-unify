import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/provider_model.dart';

class OtherTab extends StatefulWidget {
  final ProviderModel provider;
  final Function(Map<String, dynamic>) onSave;

  const OtherTab({super.key, required this.provider, required this.onSave});

  @override
  State<OtherTab> createState() => _OtherTabState();
}

class _OtherTabState extends State<OtherTab> {
  late TextEditingController _privacyPolicyUrlController;
  late TextEditingController _customDomainController;

  @override
  void initState() {
    super.initState();
    final other = widget.provider.details?['other'] ?? {};
    _privacyPolicyUrlController = TextEditingController(
      text: other['privacyPolicyUrl'] ?? '',
    );
    _customDomainController = TextEditingController(
      text: other['customDomain'] ?? '',
    );
  }

  @override
  void dispose() {
    _privacyPolicyUrlController.dispose();
    _customDomainController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    widget.onSave({
      'details': {
        ...(widget.provider.details ?? {}),
        'other': {
          'privacyPolicyUrl': _privacyPolicyUrlController.text.trim(),
          'customDomain': _customDomainController.text.trim(),
        },
      },
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações salvas!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Outras Configurações',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Opções diversas e links não cobertos nas outras seções.',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),

          Card(
            color: const Color(0xFF1E293B),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _privacyPolicyUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL da Política de Privacidade',
                      hintText: 'https://seuprovedor.com/privacidade',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Link externo para a política de privacidade da sua empresa.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _customDomainController,
                    decoration: const InputDecoration(
                      labelText: 'Domínio Personalizado (opcional)',
                      hintText: 'Ex: app.seuprovedor.com',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pode ser usado para personalizar links internos, se aplicável.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save),
                    label: const Text('Aplicar Configurações'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
