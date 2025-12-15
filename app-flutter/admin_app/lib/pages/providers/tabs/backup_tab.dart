import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/provider_model.dart';
import 'dart:convert';

class BackupTab extends StatelessWidget {
  final ProviderModel provider;

  const BackupTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(provider.toMap());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backup & Dados',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Visualize e exporte os dados brutos deste provedor.',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: SelectableText(
              jsonString,
              style: GoogleFonts.firaCode(
                fontSize: 12,
                color: Colors.greenAccent,
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonString));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Dados copiados para a área de transferência',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar JSON'),
            ),
          ),
        ],
      ),
    );
  }
}
