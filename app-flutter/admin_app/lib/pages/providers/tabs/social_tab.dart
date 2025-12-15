import 'package:flutter/material.dart';
import '../../../core/models/provider_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialTab extends StatefulWidget {
  final ProviderModel provider;
  final Function(Map<String, dynamic>) onSave;

  const SocialTab({super.key, required this.provider, required this.onSave});

  @override
  State<SocialTab> createState() => _SocialTabState();
}

class _SocialTabState extends State<SocialTab> {
  late TextEditingController _instagramController;
  late TextEditingController _facebookController;
  late TextEditingController _whatsappController;
  late TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    final social =
        widget.provider.details?['social'] as Map<String, dynamic>? ?? {};
    _instagramController = TextEditingController(
      text: social['instagram'] ?? '',
    );
    _facebookController = TextEditingController(text: social['facebook'] ?? '');
    _whatsappController = TextEditingController(text: social['whatsapp'] ?? '');
    _websiteController = TextEditingController(text: social['website'] ?? '');
  }

  @override
  void dispose() {
    _instagramController.dispose();
    _facebookController.dispose();
    _whatsappController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave({
      'details': {
        ...?widget.provider.details,
        'social': {
          'instagram': _instagramController.text.trim(),
          'facebook': _facebookController.text.trim(),
          'whatsapp': _whatsappController.text.trim(),
          'website': _websiteController.text.trim(),
        },
      },
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
            'Redes Sociais',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Links para as redes sociais do provedor',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          _buildField(
            'Instagram',
            _instagramController,
            FontAwesomeIcons.instagram,
            Colors.purple,
          ),
          const SizedBox(height: 16),

          _buildField(
            'Facebook',
            _facebookController,
            FontAwesomeIcons.facebook,
            Colors.blue,
          ),
          const SizedBox(height: 16),

          _buildField(
            'WhatsApp',
            _whatsappController,
            FontAwesomeIcons.whatsapp,
            Colors.green,
          ),
          const SizedBox(height: 16),

          _buildField(
            'Website',
            _websiteController,
            FontAwesomeIcons.globe,
            Colors.grey,
          ),

          const SizedBox(height: 32),
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
                'Salvar Redes Sociais',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
    Color color,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: FaIcon(icon, color: color, size: 20),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
