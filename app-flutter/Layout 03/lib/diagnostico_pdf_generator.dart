
// ARQUIVO: lib/diagnostico_pdf_generator.dart (COMPLETO E FINAL)

import 'dart:io';
import 'package:layout01/models/provider_config.dart';
import 'package:flutter/material.dart';
import 'package:layout01/diagnostico_page.dart'; // Importa o enum
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdfLib;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class DiagnosticoPdfGenerator {
  // Cores do PDF
  static final pdfColorBackground = pdfLib.PdfColor.fromHex('0F0F11');
  static final pdfColorCard = pdfLib.PdfColor.fromHex('1A1A1E');
  static final pdfColorText = pdfLib.PdfColor.fromHex('FFFFFF');
  static final pdfColorTextLight = pdfLib.PdfColor.fromHex('B0B0B0');
  static final pdfColorGreen = pdfLib.PdfColor.fromHex('00C853');
  static final pdfColorRed = pdfLib.PdfColor.fromHex('D50000');

  // Helpers para extrair dados
  static String _parseResultLine(String? resultText, String key) {
    if (resultText == null || resultText.isEmpty) return "---";
    try {
      return resultText
          .split('\n')
          .firstWhere((l) => l.startsWith(key), orElse: () => "$key ---")
          .split(':')
          .sublist(1)
          .join(':')
          .trim();
    } catch (e) {
      return "---";
    }
  }

  static String _parseResultBlock(String? resultText, String key) {
    if (resultText == null || resultText.isEmpty) return "---";
    try {
      final lines = resultText.split('\n');
      final startIndex = lines.indexWhere((l) => l.startsWith(key));
      if (startIndex == -1) return "---";

      final blockLines = <String>[];
      for (int i = startIndex + 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty || line.contains(':')) break;
        blockLines.add(line);
      }
      final block = blockLines.join('\n').trim();

      return block.isEmpty ? "---" : block;
    } catch (e) {
      return "---";
    }
  }

  /// Gera um relatório em PDF com os resultados dos testes e permite compartilhá-lo.
  static Future<void> generateAndSharePdf({
    required Map<String, dynamic> testResultsDisplay,
    required double speedTestPingLatency,
    required Color primaryColor,
    required BuildContext context,
    required String clientName,
    required ProviderConfig providerConfig,
  }) async {
    final pdf = pw.Document();
    final pdfColorPrimary = pdfLib.PdfColor.fromInt(primaryColor.value);

    // --- DADOS PARA PERSONALIZAÇÃO ---
    final appName = providerConfig.config.integrations.appName;
    final customSpeedTestLabel = "Velocidade ($appName)";
    // --- FIM DADOS PARA PERSONALIZAÇÃO ---

    // --- Coleta de Dados (Mantido) ---
    final wifiInfo = testResultsDisplay['wifiInfo'];
    final wifiStatus = wifiInfo?['status'] as TestStatus;
    final wifiResult = wifiInfo?['result'] as String?;
    final wifiSignalText = _parseResultLine(wifiResult, "Força do Sinal:");
    final wifiSsidText = _parseResultLine(wifiResult, "SSID:");
    final wifiFreqText = _parseResultLine(wifiResult, "Frequência:");

    final gatewayPing = testResultsDisplay['pingGateway'];
    final gatewayStatus = gatewayPing?['status'] as TestStatus;
    final gatewayResult = gatewayPing?['result'] as String?;
    final gatewayIp = _parseResultLine(wifiResult, "Gateway (Roteador):");
    final gatewayLatencyText = _parseResultLine(gatewayResult, "Latência Média:");
    final gatewayLossText = _parseResultLine(gatewayResult, "Perda:");

    final publicIp = testResultsDisplay['publicIp'];
    final ipStatus = publicIp?['status'] as TestStatus;
    final ipResult = publicIp?['result'] as String?;
    final ipText = _parseResultLine(ipResult, "IP:");
    final providerText = _parseResultLine(ipResult, "Provedor:");

    final googlePing = testResultsDisplay['pingGoogle'];
    final googleStatus = googlePing?['status'] as TestStatus;
    final googleResult = googlePing?['result'] as String?;
    final googleLatencyText = _parseResultLine(googleResult, "Latência Média:");
    final googleLossText = _parseResultLine(googleResult, "Perda:");
    final cloudflarePing = testResultsDisplay['pingCloudflare'];
    final cloudflareStatus = cloudflarePing?['status'] as TestStatus;
    final cloudflareResult = cloudflarePing?['result'] as String?;
    final cloudflareLatencyText = _parseResultLine(cloudflareResult, "Latência Média:");
    final cloudflareLossText = _parseResultLine(cloudflareResult, "Perda:");

    final customSpeed = testResultsDisplay['speedTestCustom'];
    final customSpeedStatus = customSpeed?['status'] as TestStatus;
    final customSpeedResult = customSpeed?['result'] as String?;
    final customLatency = speedTestPingLatency != 0 ? "${speedTestPingLatency.toStringAsFixed(0)} ms" : "Falha";
    final customDown = _parseResultLine(customSpeedResult, "Download (Pico):");
    final customUp = _parseResultLine(customSpeedResult, "Upload (Pico):");

    final fastSpeed = testResultsDisplay['speedTestFast'];
    final fastSpeedStatus = fastSpeed?['status'] as TestStatus;
    final fastSpeedResult = fastSpeed?['result'] as String?;
    final fastDown = _parseResultLine(fastSpeedResult, "Download (Pico):");
    final fastUp = _parseResultLine(fastSpeedResult, "Upload (Pico):");

    final bssid = _parseResultLine(wifiResult, "BSSID:");
    final ipLocal = _parseResultLine(wifiResult, "IP Dispositivo:");
    final dnsServers = _parseResultBlock(wifiResult, "Servidores DNS:");

    final deviceInfo = testResultsDisplay['deviceInfo'];
    final deviceStatus = deviceInfo?['status'] as TestStatus;
    final deviceResult = deviceInfo?['result'] as String?;
    final connection = _parseResultLine(deviceResult, "Conexão:");
    final device = _parseResultLine(deviceResult, "Dispositivo:");
    final os = _parseResultLine(deviceResult, "Versão OS:");
    final app = _parseResultLine(deviceResult, "Versão do App:");
    // ------------------------------------

    final baseTextStyle = pw.TextStyle(color: pdfColorText);
    final lightTextStyle = pw.TextStyle(color: pdfColorTextLight);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdfLib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24), // Aumenta margem geral
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ).copyWith(
          defaultTextStyle: baseTextStyle,
          paragraphStyle: pw.TextStyle(color: pdfColorText, fontSize: 10),
          header0: pw.TextStyle(color: pdfColorText, fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        build: (pw.Context context) {
          return [
            pw.Container(
              color: pdfColorBackground,
              padding: const pw.EdgeInsets.all(12), // Padding interno
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // 1. Cabeçalho PROFISSIONAL
                  pw.Container(
                      padding: const pw.EdgeInsets.all(12), // Destaque para o cabeçalho
                      decoration: pw.BoxDecoration(
                        color: pdfColorPrimary, // Usa a cor primária
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("RELATÓRIO DE DIAGNÓSTICO DE REDE", style: pw.TextStyle(color: pdfLib.PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 5),
                            pw.Text("Cliente: $clientName", style: const pw.TextStyle(color: pdfLib.PdfColors.white, fontSize: 12)),
                            pw.Text("Emitido em: ${DateTime.now().toLocal()}", style: const pw.TextStyle(color: pdfLib.PdfColors.white, fontSize: 10)),
                          ]
                      )
                  ),
                  pw.SizedBox(height: 24),

                  // 2. Card: Jornada da Conexão
                  _buildPdfCard(
                      pdfColorCard: pdfColorCard,
                      child: pw.Stack(
                          children: [
                            // CAMADA 1: A Linha vertical de fundo
                            pw.Positioned(
                              left: 6, top: 35, bottom: 10,
                              child: pw.Container(width: 1, color: const pdfLib.PdfColor(0.69, 0.69, 0.69, 0.2)),
                            ),

                            // CAMADA 2: O conteúdo
                            pw.Column(
                                children: [
                                  _buildPdfHeader("Diagnóstico da Conexão", TestStatus.success, pdfColorGreen, pdfColorRed, pdfColorPrimary, pdfColorTextLight),
                                  pw.SizedBox(height: 20),
                                  // --- PERSONALIZAÇÃO: NOME DO CLIENTE ---
                                  _buildPdfJourneyStep(
                                      title: "$clientName (Dispositivo)", status: wifiStatus, pdfColorGreen: pdfColorGreen, pdfColorRed: pdfColorRed, pdfColorPrimary: pdfColorPrimary, pdfColorTextLight: pdfColorTextLight,
                                      children: [
                                        _buildPdfInfoRow("Sinal:", wifiSignalText, pdfColorText, pdfColorTextLight),
                                        _buildPdfInfoRow("SSID:", wifiSsidText, pdfColorText, pdfColorTextLight),
                                        _buildPdfInfoRow("Frequência:", wifiFreqText, pdfColorText, pdfColorTextLight),
                                      ]
                                  ),
                                  // --- FIM PERSONALIZAÇÃO ---
                                  _buildPdfJourneyStep(
                                      title: "ROTEADOR (Gateway)", status: gatewayStatus, pdfColorGreen: pdfColorGreen, pdfColorRed: pdfColorRed, pdfColorPrimary: pdfColorPrimary, pdfColorTextLight: pdfColorTextLight,
                                      children: [
                                        _buildPdfInfoRow("IP:", gatewayIp, pdfColorText, pdfColorTextLight),
                                        _buildPdfInfoRow("Latência:", gatewayLatencyText, pdfColorText, pdfColorTextLight),
                                        _buildPdfInfoRow("Perda:", gatewayLossText, pdfColorText, pdfColorTextLight),
                                      ]
                                  ),
                                  _buildPdfJourneyStep(
                                      title: "INTERNET (Rede Externa)", status: ipStatus, pdfColorGreen: pdfColorGreen, pdfColorRed: pdfColorRed, pdfColorPrimary: pdfColorPrimary, pdfColorTextLight: pdfColorTextLight,
                                      children: [
                                        _buildPdfInfoRow("IP Público:", ipText, pdfColorText, pdfColorTextLight),
                                        _buildPdfInfoRow("Provedor:", providerText, pdfColorText, pdfColorTextLight, isLast: true),
                                      ]
                                  ),
                                  _buildPdfJourneyStep(
                                      title: "SERVIDORES (DNS)",
                                      status: (googleStatus == TestStatus.success || cloudflareStatus == TestStatus.success) ? TestStatus.success : (googleStatus == TestStatus.running || cloudflareStatus == TestStatus.running) ? TestStatus.running : (googleStatus == TestStatus.error && cloudflareStatus == TestStatus.error) ? TestStatus.error : TestStatus.pending,
                                      pdfColorGreen: pdfColorGreen, pdfColorRed: pdfColorRed, pdfColorPrimary: pdfColorPrimary, pdfColorTextLight: pdfColorTextLight, isLastStep: true,
                                      children: [
                                        _buildPdfInfoRow("Google:", "$googleLatencyText (Perda: $googleLossText)", pdfColorText, pdfColorTextLight),
                                        _buildPdfInfoRow("Cloudflare:", "$cloudflareLatencyText (Perda: $cloudflareLossText)", pdfColorText, pdfColorTextLight),
                                      ]
                                  ),
                                ]
                            ),
                          ]
                      )
                  ),
                  pw.SizedBox(height: 12),

                  // 3. Card: Testes de Velocidade
                  _buildPdfCard(
                      pdfColorCard: pdfColorCard,
                      child: pw.Column(
                          children: [
                            // --- PERSONALIZAÇÃO: NOME DO SERVIDOR/APP ---
                            _buildPdfSpeedStat(label: customSpeedTestLabel, status: customSpeedStatus, latency: customLatency, download: customDown, upload: customUp, pdfColorGreen: pdfColorGreen, pdfColorRed: pdfColorRed, pdfColorPrimary: pdfColorPrimary, pdfColorText: pdfColorText, pdfColorTextLight: pdfColorTextLight),
                            // --- FIM PERSONALIZAÇÃO ---
                            pw.Divider(color: pdfLib.PdfColor.fromHex('333333'), height: 24, thickness: 0.5),
                            _buildPdfSpeedStat(label: "Velocidade (Fast.com)", status: fastSpeedStatus, latency: null, download: fastDown, upload: fastUp, pdfColorGreen: pdfColorGreen, pdfColorRed: pdfColorRed, pdfColorPrimary: pdfColorPrimary, pdfColorText: pdfColorText, pdfColorTextLight: pdfColorTextLight),
                          ]
                      )
                  ),
                  pw.SizedBox(height: 12),

                  // 4. Card: Detalhes da Rede
                  _buildPdfCard(
                      pdfColorCard: pdfColorCard,
                      child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildPdfHeader("Detalhes da Rede Wi-Fi", wifiStatus, pdfColorGreen, pdfColorRed, pdfColorPrimary, pdfColorTextLight),
                            if (wifiStatus == TestStatus.success) ...[
                              pw.Divider(color: pdfLib.PdfColor.fromHex('333333'), height: 24, thickness: 0.5),
                              _buildPdfInfoRow("BSSID:", bssid, pdfColorText, pdfColorTextLight),
                              _buildPdfInfoRow("IP Local:", ipLocal, pdfColorText, pdfColorTextLight),
                              _buildPdfDeviceInfoRow("Servidores DNS", dnsServers == "---" ? dnsServers : "\n$dnsServers", pdfColorText, pdfColorTextLight),
                            ] else
                              _buildPdfStatusText(wifiStatus, "Coletando...", pdfColorPrimary, pdfColorTextLight),
                          ]
                      )
                  ),
                  pw.SizedBox(height: 12),

                  // 5. Card: Informações do Dispositivo
                  _buildPdfCard(
                      pdfColorCard: pdfColorCard,
                      child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildPdfHeader("Informações do Dispositivo", deviceStatus, pdfColorGreen, pdfColorRed, pdfColorPrimary, pdfColorTextLight),
                            if (deviceStatus == TestStatus.success) ...[
                              pw.Divider(color: pdfLib.PdfColor.fromHex('333333'), height: 24, thickness: 0.5),
                              // Layout simplificado de 2 colunas
                              pw.Row(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Expanded(
                                        child: pw.Column(
                                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                                            children: [
                                              _buildPdfDeviceInfoRow("Conexão", connection, pdfColorText, pdfColorTextLight),
                                              pw.SizedBox(height: 8), // Adicionado espaçamento
                                              _buildPdfDeviceInfoRow("Versão OS", os, pdfColorText, pdfColorTextLight),
                                            ]
                                        )
                                    ),
                                    pw.SizedBox(width: 16),
                                    pw.Expanded(
                                        child: pw.Column(
                                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                                            children: [
                                              _buildPdfDeviceInfoRow("Dispositivo", device, pdfColorText, pdfColorTextLight),
                                              pw.SizedBox(height: 8), // Adicionado espaçamento
                                              _buildPdfDeviceInfoRow("Versão do App", app, pdfColorText, pdfColorTextLight),
                                            ]
                                        )
                                    ),
                                  ]
                              )
                            ] else
                              _buildPdfStatusText(deviceStatus, "Coletando...", pdfColorPrimary, pdfColorTextLight),
                          ]
                      )
                  ),
                ],
              ),
            )
          ];
        },
      ),
    );

    // --- Salva e Compartilha o PDF (Mantido) ---
    try {
      final outputDir = await getTemporaryDirectory();
      final outputFile = File("${outputDir.path}/diagnostico_rede.pdf");
      await outputFile.writeAsBytes(await pdf.save());
      final xfile = XFile(outputFile.path, mimeType: 'application/pdf');
      if (!context.mounted) return;
      await Share.shareXFiles(
          [xfile], text: 'Segue o relatório de diagnóstico de rede:');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar ou compartilhar PDF: $e')),
      );
    }
  }

  // =========================================================================
  // ===================== HELPERS DO PDF (WIDGETS) ==========================
  // =========================================================================

  /// Constrói um Card customizado para o PDF
  static pw.Widget _buildPdfCard({
    required pw.Widget child,
    required pdfLib.PdfColor pdfColorCard,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: pdfColorCard,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      child: child,
    );
  }

  /// Constrói um Header de status para o PDF
  static pw.Widget _buildPdfHeader(
      String label,
      TestStatus status,
      pdfLib.PdfColor pdfColorGreen,
      pdfLib.PdfColor pdfColorRed,
      pdfLib.PdfColor pdfColorPrimary,
      pdfLib.PdfColor pdfColorTextLight,
      ) {
    pdfLib.PdfColor color;
    switch (status) {
      case TestStatus.success:
        color = pdfColorGreen;
        break;
      case TestStatus.error:
        color = pdfColorRed;
        break;
      case TestStatus.running:
        color = pdfColorPrimary;
        break;
      default:
        color = pdfColorTextLight;
    }
    return pw.Text(
      label,
      style: pw.TextStyle(color: color, fontWeight: pw.FontWeight.bold, fontSize: 16),
    );
  }

  /// Constrói um texto de status (Pendente/Executando) para o PDF
  static pw.Widget _buildPdfStatusText(
      TestStatus status,
      String result,
      pdfLib.PdfColor pdfColorPrimary,
      pdfLib.PdfColor pdfColorTextLight,
      ) {
    String text;
    pdfLib.PdfColor color;
    if (status == TestStatus.running) {
      text = result.isNotEmpty ? result.split('\n').last.trim() : "Executando...";
      color = pdfColorPrimary;
    } else {
      text = "Pendente";
      color = pdfColorTextLight;
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16.0),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: color, fontStyle: pw.FontStyle.italic),
        textAlign: pw.TextAlign.center,
      ),
    );
  }


  /// Constrói uma linha de info (Label: Value) para o PDF
  static pw.Widget _buildPdfInfoRow(
      String label,
      String value,
      pdfLib.PdfColor pdfColorText,
      pdfLib.PdfColor pdfColorTextLight, {
        bool isLast = false
      }) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: 2.0, bottom: isLast && value.length > 25 ? 8.0 : 0),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(color: pdfColorTextLight, fontSize: 10, height: 1.5),
          ),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(color: pdfColorText, fontSize: 10, fontWeight: pw.FontWeight.bold, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói uma linha de info (em coluna) para o PDF
  static pw.Widget _buildPdfDeviceInfoRow(
      String title,
      String value,
      pdfLib.PdfColor pdfColorText,
      pdfLib.PdfColor pdfColorTextLight,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(color: pdfColorTextLight, fontSize: 10)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(color: pdfColorText, fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }


  /// Constrói um passo da "Jornada" para o PDF
  static pw.Widget _buildPdfJourneyStep({
    required String title,
    required TestStatus status,
    required List<pw.Widget> children,
    required pdfLib.PdfColor pdfColorGreen,
    required pdfLib.PdfColor pdfColorRed,
    required pdfLib.PdfColor pdfColorPrimary,
    required pdfLib.PdfColor pdfColorTextLight,
    bool isLastStep = false,
  }) {
    pdfLib.PdfColor statusColor;
    switch (status) {
      case TestStatus.success: statusColor = pdfColorGreen; break;
      case TestStatus.error: statusColor = pdfColorRed; break;
      case TestStatus.running: statusColor = pdfColorPrimary; break;
      default: statusColor = pdfColorTextLight;
    }

    // O Padding externo usa argumento nomeado 'padding:'.
    return pw.Padding(
        padding: pw.EdgeInsets.only(bottom: isLastStep ? 0 : 16.0),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Coluna 1: Bullet e Linha (Timeline)
            // Usando Container com padding.
            pw.Container(
              padding: const pw.EdgeInsets.only(right: 8),
              child: pw.SizedBox(
                width: 16,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Bullet(style: pw.TextStyle(color: statusColor, fontSize: 14)),
                    if (!isLastStep)
                      pw.Container(
                        width: 1,
                        height: 6 + (children.length * 12.0),
                        color: const pdfLib.PdfColor(0.69, 0.69, 0.69, 0.2),
                        margin: const pw.EdgeInsets.only(top: 4.0),
                      ),
                  ],
                ),
              ),
            ),

            // Coluna 2: Conteúdo (Título e Dados)
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold, color: statusColor,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  ...children,
                ],
              ),
            ),
          ],
        )
    );
  }


  /// Constrói um bloco de estatísticas de velocidade para o PDF
  static pw.Widget _buildPdfSpeedStat({
    required String label,
    required TestStatus status,
    required String? latency,
    required String download,
    required String upload,
    required pdfLib.PdfColor pdfColorGreen,
    required pdfLib.PdfColor pdfColorRed,
    required pdfLib.PdfColor pdfColorPrimary,
    required pdfLib.PdfColor pdfColorText,
    required pdfLib.PdfColor pdfColorTextLight,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPdfHeader(label, status, pdfColorGreen, pdfColorRed, pdfColorPrimary, pdfColorTextLight),
        if (status != TestStatus.pending && status != TestStatus.running) ...[
          if (latency != null)
            pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 12.0),
                  child: pw.Text(
                      "Latência do Servidor: $latency",
                      style: pw.TextStyle(color: latency == "Falha" ?
                      pdfColorRed : pdfColorPrimary, fontSize: 10, fontWeight: pw.FontWeight.bold)
                  ),
                )
            ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 12.0),
            // Tabela de 2 colunas para Download/Upload
            child: pw.Row(
                children: [
                  pw.Expanded(
                      child: pw.Column(
                          children: [
                            pw.Text("Download", style: pw.TextStyle(color: pdfColorTextLight, fontSize: 11)),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              download.replaceAll('Mbps', '').trim(),
                              style: pw.TextStyle(color: pdfColorText, fontSize: 24, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text("Mbps", style: pw.TextStyle(color: pdfColorTextLight, fontSize: 10)),
                          ]
                      )
                  ),
                  pw.Container(width: 1, height: 40, color: pdfLib.PdfColor.fromHex('333333')),
                  pw.Expanded(
                      child: pw.Column(
                          children: [
                            pw.Text("Upload", style: pw.TextStyle(color: pdfColorTextLight, fontSize: 11)),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              upload.replaceAll('Mbps', '').trim(),
                              style: pw.TextStyle(color: pdfColorText, fontSize: 24, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text("Mbps", style: pw.TextStyle(color: pdfColorTextLight, fontSize: 10)),
                          ]
                      )
                  ),
                ]
            ),
          )
        ] else
          _buildPdfStatusText(status, "Testando...", pdfColorPrimary, pdfColorTextLight),
      ],
    );
  }
}
