import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/provider_model.dart';

class TermsTab extends StatefulWidget {
  final ProviderModel provider;
  final Function(Map<String, dynamic>) onSave;

  const TermsTab({super.key, required this.provider, required this.onSave});

  @override
  State<TermsTab> createState() => _TermsTabState();
}

class _TermsTabState extends State<TermsTab> {
  final TextEditingController _termsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _termsController.text =
        (widget.provider.details?['terms'] as String?) ?? '';
  }

  @override
  void dispose() {
    _termsController.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave({
      'details': {...?widget.provider.details, 'terms': _termsController.text},
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
            'Termos de Uso',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Defina os termos que seus clientes devem aceitar ao usar o app.',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _termsController,
            maxLines: 15,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Digite os termos de uso aqui...',
              fillColor: Theme.of(context).cardTheme.color,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => _save(),
          ),
        ],
      ),
    );
  }
}
