import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/provider_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TextsTab extends StatefulWidget {
  final ProviderModel provider;
  final Function(Map<String, dynamic>) onSave;

  const TextsTab({super.key, required this.provider, required this.onSave});

  @override
  State<TextsTab> createState() => _TextsTabState();
}

class _TextsTabState extends State<TextsTab> {
  final TextEditingController _welcomeTitleController = TextEditingController();
  final TextEditingController _welcomeMsgController = TextEditingController();
  final TextEditingController _supportTitleController = TextEditingController();
  final TextEditingController _supportMsgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final texts =
        (widget.provider.details?['texts'] as Map<String, dynamic>?) ?? {};
    _welcomeTitleController.text = texts['welcomeTitle'] ?? '';
    _welcomeMsgController.text = texts['welcomeMsg'] ?? '';
    _supportTitleController.text = texts['supportTitle'] ?? '';
    _supportMsgController.text = texts['supportMsg'] ?? '';
  }

  @override
  void dispose() {
    _welcomeTitleController.dispose();
    _welcomeMsgController.dispose();
    _supportTitleController.dispose();
    _supportMsgController.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave({
      'details': {
        ...?widget.provider.details,
        'texts': {
          'welcomeTitle': _welcomeTitleController.text,
          'welcomeMsg': _welcomeMsgController.text,
          'supportTitle': _supportTitleController.text,
          'supportMsg': _supportMsgController.text,
        },
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
          const Text(
            'Textos Personalizados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Personalize as mensagens exibidas no app do cliente.',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),

          _buildSection('Tela Inicial', FontAwesomeIcons.house, [
            _buildInput('Título de Boas-vindas', _welcomeTitleController),
            const SizedBox(height: 12),
            _buildInput(
              'Mensagem de Boas-vindas',
              _welcomeMsgController,
              maxLines: 2,
            ),
          ]),

          const SizedBox(height: 24),

          _buildSection('Tela de Suporte', FontAwesomeIcons.headset, [
            _buildInput('Título do Suporte', _supportTitleController),
            const SizedBox(height: 12),
            _buildInput(
              'Mensagem do Suporte',
              _supportMsgController,
              maxLines: 3,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFF0F172A),
      ),
      onChanged: (_) => _save(),
    );
  }
}
