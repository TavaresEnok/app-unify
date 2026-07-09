import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/diagnostico_state.dart';

class PdfGeneratorService {
  // ──────────────────────────────────────────────────────────────────────────
  // Paleta
  // ──────────────────────────────────────────────────────────────────────────
  static const _blue = PdfColor.fromInt(0xFF1E40AF);
  static const _blueDark = PdfColor.fromInt(0xFF1E3A8A);
  static const _blueLight = PdfColor.fromInt(0xFFDBEAFE);
  static const _cyan = PdfColor.fromInt(0xFF0891B2);
  static const _cyanLight = PdfColor.fromInt(0xFFCFFAFE);
  static const _green = PdfColor.fromInt(0xFF16A34A);
  static const _greenLight = PdfColor.fromInt(0xFFDCFCE7);
  static const _yellow = PdfColor.fromInt(0xFFD97706);
  static const _yellowLight = PdfColor.fromInt(0xFFFEF9C3);
  static const _red = PdfColor.fromInt(0xFFDC2626);
  static const _redLight = PdfColor.fromInt(0xFFFEE2E2);
  static const _grey = PdfColor.fromInt(0xFF64748B);
  static const _greyLight = PdfColor.fromInt(0xFFF1F5F9);
  static const _greyBorder = PdfColor.fromInt(0xFFE2E8F0);
  static const _dark = PdfColor.fromInt(0xFF0F172A);
  static const _white = PdfColors.white;

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers de extração
  // ──────────────────────────────────────────────────────────────────────────
  String _str(dynamic v, {String fallback = '---'}) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty || s == 'null' ? fallback : s;
  }

  String _parseResult(Map<String, dynamic>? data) {
    if (data == null) return '---';
    final r = data['result'];
    if (r == null) return data['displayText'] as String? ?? '---';
    if (r is String) return r.isEmpty ? '---' : r;
    if (r is Map) {
      return r['display'] as String? ??
          r['displayText'] as String? ??
          r['stateStr'] as String? ??
          '---';
    }
    return '---';
  }

  Map<String, dynamic>? _resultMap(Map<String, dynamic>? data) {
    final r = data?['result'];
    return r is Map ? Map<String, dynamic>.from(r) : null;
  }

  PdfColor _statusColor(Map<String, dynamic>? data) {
    final s = data?['status']?.toString() ?? '';
    if (s.contains('success')) return _green;
    if (s.contains('error')) return _red;
    if (s.contains('running')) return _yellow;
    return _grey;
  }

  bool _isOk(Map<String, dynamic>? data) =>
      data?['status']?.toString().contains('success') == true;

  String _statusLabel(Map<String, dynamic>? data) {
    final s = data?['status']?.toString() ?? '';
    if (s.contains('success')) return 'OK';
    if (s.contains('error')) return 'FALHA';
    if (s.contains('running')) return 'EM ANDAMENTO';
    return 'N/A';
  }

  PdfColor _speedColor(double mbps) {
    if (mbps >= 50) return _green;
    if (mbps >= 10) return _yellow;
    return _red;
  }

  PdfColor _pingColor(double ms) {
    if (ms <= 20) return _green;
    if (ms <= 80) return _yellow;
    return _red;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // API pública
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> stopAndSharePdf(DiagnosticoState state) async {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}  '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final d = state.testResultsDisplay;
    final onuMap = _resultMap(d['onuInfo']);
    final wifiMap = _resultMap(d['wifiInfo']);
    final batteryMap = _resultMap(d['batteryInfo']);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
        ),
        build: (pw.Context ctx) => [
          _header(dateStr),
          pw.SizedBox(height: 14),
          _summaryBadges(d),
          pw.SizedBox(height: 14),
          _speedCard(state),
          pw.SizedBox(height: 10),
          _wifiCard(wifiMap, d['pingGateway']),
          pw.SizedBox(height: 10),
          _externalCard(d),
          pw.SizedBox(height: 10),
          if (onuMap != null) ...[
            _onuCard(onuMap),
            pw.SizedBox(height: 10),
          ],
          _deviceCard(d, batteryMap),
          pw.SizedBox(height: 10),
          _tracerouteCard(d['traceroute']),
          pw.SizedBox(height: 14),
          _footer(),
        ],
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file =
          File('${output.path}/diagnostico_${now.millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Relatório de diagnóstico de rede — $dateStr',
      );
    } catch (e) {
      debugPrint('Erro ao gerar/compartilhar PDF: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Header
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _header(String dateStr) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [_blueDark, _cyan],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Relatório de Diagnóstico de Rede',
                style: pw.TextStyle(
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                    color: _white)),
            pw.SizedBox(height: 3),
            pw.Text('Emitido em $dateStr',
                style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColor.fromInt(0xFFBAE6FD))),
          ]),
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: const pw.BoxDecoration(
              color: _white,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(20)),
            ),
            child: pw.Text('DIAGNÓSTICO',
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _blue)),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Badges de resumo
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _summaryBadges(Map<String, Map<String, dynamic>> d) {
    final items = [
      ('Wi-Fi', d['wifiInfo']),
      ('Fibra / ONU', d['onuInfo']),
      ('Roteador', d['pingGateway']),
      ('IP Público', d['publicIp']),
      ('Velocidade', d['speedTestCustom']),
      ('Traceroute', d['traceroute']),
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _greyLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _greyBorder),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('RESUMO GERAL',
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.2,
                  color: _grey)),
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items
                .map((item) => _badge(item.$1, item.$2))
                .toList(),
          ),
        ],
      ),
    );
  }

  pw.Widget _badge(String label, Map<String, dynamic>? data) {
    final color = _statusColor(data);
    final lbl = _statusLabel(data);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
        border: pw.Border.all(color: color, width: 1),
      ),
      child: pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
        pw.Container(
            width: 7,
            height: 7,
            decoration: pw.BoxDecoration(
                color: color,
                shape: pw.BoxShape.circle)),
        pw.SizedBox(width: 5),
        pw.Text('$label  ',
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _dark)),
        pw.Text(lbl,
            style: pw.TextStyle(fontSize: 8, color: color)),
      ]),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Card Velocidade
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _speedCard(DiagnosticoState state) {
    final dl = state.customDownloadResultMbps;
    final ul = state.customUploadResultMbps;
    final ping = state.speedTestPingLatency ?? 0.0;

    return _card(
      title: 'VELOCIDADE DE INTERNET',
      color: _blue,
      bgColor: _blueLight,
      child: pw.Row(children: [
        pw.Expanded(
            child: _metricBox(
                'Download',
                '${dl.toStringAsFixed(1)} Mbps',
                _speedColor(dl))),
        pw.SizedBox(width: 8),
        pw.Expanded(
            child: _metricBox(
                'Upload',
                '${ul.toStringAsFixed(1)} Mbps',
                _speedColor(ul * 2))),
        pw.SizedBox(width: 8),
        pw.Expanded(
            child: _metricBox(
                'Ping (Servidor)',
                '${ping.toStringAsFixed(0)} ms',
                _pingColor(ping))),
      ]),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Card Wi-Fi
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _wifiCard(
      Map<String, dynamic>? wm, Map<String, dynamic>? gw) {
    final gwResult = _parseResult(gw);

    return _card(
      title: 'REDE WI-FI',
      color: _cyan,
      bgColor: _cyanLight,
      child: pw.Column(children: [
        pw.Row(children: [
          pw.Expanded(
              child: _infoCell('Rede (SSID)',
                  _str(wm?['ssid']))),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _infoCell('Frequência',
                  _str(wm?['frequency']))),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _infoCell('Força do Sinal',
                  _str(wm?['signalStrength']))),
        ]),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Expanded(
              child: _infoCell('IP do Dispositivo',
                  _str(wm?['ip']))),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _infoCell('Gateway (Roteador)',
                  _str(wm?['gateway']))),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _infoCell('BSSID',
                  _str(wm?['bssid']))),
        ]),
        if (gwResult != '---') ...[
          pw.SizedBox(height: 8),
          _infoRow('Ping Roteador (Latência)', gwResult,
              highlight: true),
        ],
      ]),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Card Conectividade Externa
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _externalCard(Map<String, Map<String, dynamic>> d) {
    final ipR = _parseResult(d['publicIp']);
    final googleR = _parseResult(d['pingGoogle']);
    final cloudR = _parseResult(d['pingCloudflare']);

    // Extrair campos do IP
    String ipv4 = '---', ipv6 = '---', isp = '---';
    for (final line in ipR.split('\n')) {
      if (line.startsWith('IPv4:')) ipv4 = line.replaceFirst('IPv4:', '').trim();
      if (line.startsWith('IPv6:')) ipv6 = line.replaceFirst('IPv6:', '').trim();
      if (line.startsWith('Provedor:')) {
        isp = line.replaceFirst('Provedor:', '').trim();
      }
    }

    return _card(
      title: 'CONECTIVIDADE EXTERNA',
      color: _green,
      bgColor: _greenLight,
      child: pw.Column(children: [
        pw.Row(children: [
          pw.Expanded(child: _infoCell('IPv4 Público', ipv4)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('IPv6', ipv6)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('Provedor (ISP)', isp)),
        ]),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Expanded(
              child: _infoCell('Ping Google (8.8.8.8)', googleR)),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _infoCell('Ping Cloudflare (1.1.1.1)', cloudR)),
        ]),
      ]),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Card Fibra / ONU
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _onuCard(Map<String, dynamic> m) {
    final rx = _str(m['rxPower']);
    final tx = _str(m['txPower']);
    final quality = _str(m['signalQuality']);
    final status = _str(m['status']);
    final model = _str(m['model']);
    final serial = _str(m['serialNumber']);
    final olt = _str(m['oltName']);
    final slot = _str(m['slot']);
    final pon = _str(m['pon']);
    final onuId = _str(m['onuId']);
    final mode = _str(m['mode']);
    final vlan = _str(m['vlan']);
    final lastUpdate = _str(m['lastUpdate']);

    final rxVal = double.tryParse(rx) ?? 0.0;
    final txVal = double.tryParse(tx) ?? 0.0;
    final rxColor =
        rxVal >= -20 ? _green : (rxVal >= -25 ? _yellow : _red);
    final txColor =
        txVal >= 1 ? _green : (txVal >= 0 ? _yellow : _red);

    return _card(
      title: 'FIBRA ÓPTICA / ONU',
      color: _cyan,
      bgColor: _cyanLight,
      child: pw.Column(children: [
        // Status + qualidade do sinal
        pw.Row(children: [
          pw.Expanded(
              child: _metricBox(
                  'Status',
                  status,
                  status == 'Online' ? _green : _red)),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _metricBox(
                  'Qualidade do Sinal',
                  quality,
                  quality == 'Excelente' || quality == 'Boa'
                      ? _green
                      : _yellow)),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _metricBox('Sinal RX', '$rx dBm', rxColor)),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _metricBox('Sinal TX', '$tx dBm', txColor)),
        ]),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Expanded(child: _infoCell('Modelo ONU', model)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('Número de Série', serial)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('OLT', olt)),
        ]),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Expanded(child: _infoCell('Slot / PON / ONU ID',
              '$slot / $pon / $onuId')),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('Modo', mode)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('VLAN', vlan)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('Última atualização', lastUpdate)),
        ]),
      ]),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Card Dispositivo + Bateria
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _deviceCard(
      Map<String, Map<String, dynamic>> d,
      Map<String, dynamic>? batteryMap) {
    final devResult = _parseResult(d['deviceInfo']);
    final batteryText = d['batteryInfo']?['displayText'] as String? ??
        (batteryMap != null
            ? 'Nível: ${batteryMap['batteryLevel'] ?? '---'}%\n'
                'Estado: ${batteryMap['stateStr'] ?? '---'}'
            : _parseResult(d['batteryInfo']));

    // Parse deviceInfo lines
    String connection = '---',
        device = '---',
        os = '---',
        appVer = '---';
    for (final line in devResult.split('\n')) {
      if (line.startsWith('Conexão:')) {
        connection = line.replaceFirst('Conexão:', '').trim();
      }
      if (line.startsWith('Dispositivo:')) {
        device = line.replaceFirst('Dispositivo:', '').trim();
      }
      if (line.startsWith('Versão OS:')) {
        os = line.replaceFirst('Versão OS:', '').trim();
      }
      if (line.startsWith('Versão do App:')) {
        appVer = line.replaceFirst('Versão do App:', '').trim();
      }
    }

    // Parse battery
    String batLevel = '---', batState = '---';
    for (final line in batteryText.split('\n')) {
      if (line.startsWith('Nível:')) {
        batLevel = line.replaceFirst('Nível:', '').trim();
      }
      if (line.startsWith('Estado:')) {
        batState = line.replaceFirst('Estado:', '').trim();
      }
    }

    return _card(
      title: 'DISPOSITIVO',
      color: _grey,
      bgColor: _greyLight,
      child: pw.Column(children: [
        pw.Row(children: [
          pw.Expanded(child: _infoCell('Dispositivo', device)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('Sistema Operacional', os)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('Tipo de Conexão', connection)),
        ]),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Expanded(child: _infoCell('Versão do App', appVer)),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _infoCell('Nível de Bateria', batLevel)),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _infoCell('Estado da Bateria', batState)),
        ]),
      ]),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Card Traceroute
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _tracerouteCard(Map<String, dynamic>? traceData) {
    final result = _parseResult(traceData);
    if (result == '---' || result.isEmpty) return pw.SizedBox();

    final hops = result
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .take(15)
        .toList();

    return _card(
      title: 'ROTA DE REDE (TRACEROUTE  →  8.8.8.8)',
      color: _grey,
      bgColor: _greyLight,
      child: pw.Table(
        border: pw.TableBorder.all(color: _greyBorder, width: 0.5),
        columnWidths: {
          0: const pw.FixedColumnWidth(32),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(3),
        },
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          // Header row
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _greyLight),
            children: [
              _tableHeader('#'),
              _tableHeader('IP / Host'),
              _tableHeader('Latência'),
            ],
          ),
          // Data rows
          ...hops.map((hop) {
            // formato: "1: 172.21.0.1 (0.004 ms)"
            final colonIdx = hop.indexOf(':');
            if (colonIdx < 0) {
              return pw.TableRow(children: [
                _tableCell('?'),
                _tableCell(hop),
                _tableCell('---'),
              ]);
            }
            final num = hop.substring(0, colonIdx).trim();
            final rest = hop.substring(colonIdx + 1).trim();
            // Separar IP da latência entre parênteses
            final parenStart = rest.lastIndexOf('(');
            final parenEnd = rest.lastIndexOf(')');
            String ip = rest;
            String latency = '---';
            if (parenStart >= 0 && parenEnd > parenStart) {
              ip = rest.substring(0, parenStart).trim();
              latency = rest.substring(parenStart + 1, parenEnd).trim();
            }
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                  color: int.tryParse(num) != null && int.parse(num) % 2 == 0
                      ? _greyLight
                      : _white),
              children: [
                _tableCell(num, centered: true),
                _tableCell(ip),
                _tableCell(latency),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Footer
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _footer() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            top: pw.BorderSide(color: _greyBorder, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
              'Relatório gerado automaticamente pelo App Provedor',
              style: const pw.TextStyle(fontSize: 8, color: _grey)),
          pw.Text('Diagnóstico de Rede  •  Confidencial',
              style: const pw.TextStyle(fontSize: 8, color: _grey)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Componentes reutilizáveis
  // ──────────────────────────────────────────────────────────────────────────

  pw.Widget _card({
    required String title,
    required PdfColor color,
    required PdfColor bgColor,
    required pw.Widget child,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _greyBorder),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Title bar
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: pw.BoxDecoration(
              color: bgColor,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
              border: pw.Border(
                  bottom: pw.BorderSide(color: color.shade(0.3), width: 1.5)),
            ),
            child: pw.Row(children: [
              pw.Container(
                  width: 4,
                  height: 14,
                  decoration: pw.BoxDecoration(
                      color: color,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(2)))),
              pw.SizedBox(width: 8),
              pw.Text(title,
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.8,
                      color: _dark)),
            ]),
          ),
          // Content
          pw.Padding(
            padding: const pw.EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }

  pw.Widget _metricBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: color.shade(0.35), width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: color),
              maxLines: 1),
          pw.SizedBox(height: 3),
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 8, color: _grey),
              maxLines: 1),
        ],
      ),
    );
  }

  pw.Widget _infoCell(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 7.5, color: _grey),
            maxLines: 1),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _dark),
          maxLines: 2,
          overflow: pw.TextOverflow.clip,
        ),
      ],
    );
  }

  pw.Widget _infoRow(String label, String value,
      {bool highlight = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: highlight ? _blueLight : _greyLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 9, color: _grey)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _dark),
              maxLines: 1),
        ],
      ),
    );
  }

  pw.Widget _tableHeader(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: _grey)),
      );

  pw.Widget _tableCell(String text, {bool centered = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Text(
          text,
          style: const pw.TextStyle(fontSize: 9, color: _dark),
          textAlign:
              centered ? pw.TextAlign.center : pw.TextAlign.left,
          maxLines: 1,
        ),
      );
}
