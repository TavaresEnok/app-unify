import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/diagnostico_state.dart';

class PdfGeneratorService {
  Future<void> stopAndSharePdf(DiagnosticoState state) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Relatório de Diagnóstico',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            _buildSection(
                'Velocidade (Download/Upload)',
                'Download: ${state.customDownloadResultMbps.toStringAsFixed(1)} Mbps\n'
                    'Upload: ${state.customUploadResultMbps.toStringAsFixed(1)} Mbps'),
            _buildSection('Ping (Latência)',
                '${(state.speedTestPingLatency ?? 0.0).toStringAsFixed(0)} ms'),
            _buildSection('Informações WiFi',
                _parseResult(state.testResultsDisplay['wifiInfo'])),
            _buildSection('Gateway (Roteador)',
                _parseResult(state.testResultsDisplay['pingGateway'])),
            _buildSection('IP Público',
                _parseResult(state.testResultsDisplay['publicIp'])),
            _buildSection(
                'Conexão Internet (Google/Cloudflare)',
                'Google: ${_parseResult(state.testResultsDisplay['pingGoogle'])}\n'
                    'Cloudflare: ${_parseResult(state.testResultsDisplay['pingCloudflare'])}'),
            _buildSection('Dispositivo',
                _parseResult(state.testResultsDisplay['deviceInfo'])),
            _buildSection('Bateria',
                _parseResult(state.testResultsDisplay['batteryInfo'])),
          ];
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file =
          File('${output.path}/diagnostico_${now.millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)],
          text: 'Segue relatório de diagnóstico de rede.');
    } catch (e) {
      debugPrint('Erro ao gerar/compartilhar PDF: $e');
    }
  }

  String _parseResult(Map<String, dynamic>? data) {
    if (data == null) return "---";
    final result = data['result'] as String?;
    if (result == null || result.isEmpty) return "---";
    return result;
  }

  pw.Widget _buildSection(String title, String content) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(content, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
