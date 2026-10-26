import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/diagnostic_report.dart';
import '../services/diagnostic_verdict.dart';

/// Gera o relatório de diagnóstico em PDF a partir de dados TIPADOS
/// ([DiagnosticReport] + [DiagnosticVerdict]).
///
/// Antes esta classe recebia o `DiagnosticoState` cru e reparseava com regex o
/// texto que o próprio serviço tinha acabado de formatar. Agora recebe o modelo
/// já estruturado, o que elimina o reparse e permite incluir laudo,
/// identificação do contrato e marca do provedor.
class PdfGeneratorService {
  // ── Paleta ────────────────────────────────────────────────────────────────
  static const _blue = PdfColor.fromInt(0xFF1E40AF);
  static const _blueDark = PdfColor.fromInt(0xFF1E3A8A);
  static const _blueLight = PdfColor.fromInt(0xFFDBEAFE);
  static const _cyan = PdfColor.fromInt(0xFF0891B2);
  static const _cyanLight = PdfColor.fromInt(0xFFCFFAFE);
  static const _green = PdfColor.fromInt(0xFF16A34A);
  static const _greenLight = PdfColor.fromInt(0xFFDCFCE7);
  static const _yellow = PdfColor.fromInt(0xFFD97706);
  static const _yellowLight = PdfColor.fromInt(0xFFFEF3C7);
  static const _red = PdfColor.fromInt(0xFFDC2626);
  static const _redLight = PdfColor.fromInt(0xFFFEE2E2);
  static const _grey = PdfColor.fromInt(0xFF64748B);
  static const _greyLight = PdfColor.fromInt(0xFFF1F5F9);
  static const _greyBorder = PdfColor.fromInt(0xFFE2E8F0);
  static const _dark = PdfColor.fromInt(0xFF0F172A);
  static const _white = PdfColors.white;

  // ── API pública ───────────────────────────────────────────────────────────

  /// Constrói os bytes do PDF. Não faz IO de rede nem compartilha — quem chama
  /// decide se salva, sobe para o Storage ou compartilha.
  Future<Uint8List> buildPdfBytes(
    DiagnosticReport report,
    DiagnosticVerdict verdict, {
    Uint8List? providerLogo,
  }) async {
    final pdf = pw.Document();
    final dateStr = _formatDate(report.generatedAt);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
        ),
        footer: (ctx) => _footer(ctx, report),
        build: (pw.Context ctx) => [
          _header(report, dateStr, providerLogo),
          pw.SizedBox(height: 12),
          _customerCard(report),
          pw.SizedBox(height: 12),
          _verdictCard(verdict),
          pw.SizedBox(height: 12),
          _summaryBadges(report),
          pw.SizedBox(height: 12),
          if (report.speed != null) ...[
            _speedCard(report),
            pw.SizedBox(height: 10),
          ],
          if (report.wifi != null) ...[
            _wifiCard(report),
            pw.SizedBox(height: 10),
          ],
          _externalCard(report),
          pw.SizedBox(height: 10),
          if (report.onu != null) ...[
            _onuCard(report.onu!),
            pw.SizedBox(height: 10),
          ],
          if (report.device != null) ...[
            _deviceCard(report.device!),
            pw.SizedBox(height: 10),
          ],
          if (report.traceroute.isNotEmpty) _tracerouteCard(report.traceroute),
        ],
      ),
    );

    return Uint8List.fromList(await pdf.save());
  }

  /// Grava o PDF em arquivo temporário e devolve o caminho.
  Future<File> writeToTempFile(Uint8List bytes, DiagnosticReport report) async {
    final dir = await getTemporaryDirectory();
    final stamp = report.generatedAt.millisecondsSinceEpoch;
    final file = File('${dir.path}/diagnostico_$stamp.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Gera e abre a folha de compartilhamento do sistema.
  ///
  /// Diferente da versão anterior, os erros propagam para quem chamou — antes
  /// eram engolidos num `debugPrint` e o usuário ficava sem qualquer retorno.
  Future<void> sharePdf(
    DiagnosticReport report,
    DiagnosticVerdict verdict, {
    Uint8List? providerLogo,
  }) async {
    final bytes = await buildPdfBytes(report, verdict, providerLogo: providerLogo);
    final file = await writeToTempFile(bytes, report);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Relatório de diagnóstico de rede — ${_formatDate(report.generatedAt)}',
    );
  }

  // ── Cabeçalho ─────────────────────────────────────────────────────────────
  pw.Widget _header(DiagnosticReport r, String dateStr, Uint8List? logo) {
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
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Relatório de Diagnóstico de Rede',
                    style: pw.TextStyle(
                        fontSize: 17,
                        fontWeight: pw.FontWeight.bold,
                        color: _white)),
                pw.SizedBox(height: 3),
                pw.Text(r.provider.name,
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFFBAE6FD))),
                pw.SizedBox(height: 2),
                pw.Text('Emitido em $dateStr',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColor.fromInt(0xFFBAE6FD))),
              ],
            ),
          ),
          if (logo != null)
            pw.Container(
              width: 54,
              height: 54,
              padding: const pw.EdgeInsets.all(5),
              decoration: const pw.BoxDecoration(
                color: _white,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Image(pw.MemoryImage(logo), fit: pw.BoxFit.contain),
            )
          else
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

  // ── Identificação do cliente ──────────────────────────────────────────────
  pw.Widget _customerCard(DiagnosticReport r) {
    final c = r.customer;
    final contracted = c.contractedDownloadMbps;
    return _card(
      title: 'IDENTIFICAÇÃO DO CLIENTE',
      color: _blue,
      bgColor: _blueLight,
      child: pw.Column(children: [
        pw.Row(children: [
          pw.Expanded(flex: 2, child: _infoCell('Cliente', c.name)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('CPF/CNPJ', c.maskedDocument)),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _infoCell(
                  'Contrato', c.contractId?.toString() ?? '---')),
        ]),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Expanded(flex: 2, child: _infoCell('Plano contratado', c.planName)),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _infoCell(
                  'Velocidade contratada',
                  contracted == null
                      ? '---'
                      : '${contracted.toStringAsFixed(0)} Mbps')),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('Provedor', r.provider.name)),
        ]),
      ]),
    );
  }

  // ── Laudo ─────────────────────────────────────────────────────────────────
  pw.Widget _verdictCard(DiagnosticVerdict v) {
    final color = _severityColor(v.severity);
    final bg = _severityBg(v.severity);

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: color, width: 1.2),
      ),
      padding: const pw.EdgeInsets.all(14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(children: [
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(_severityLabel(v.severity),
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _white)),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Text(v.headline,
                  style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: _dark)),
            ),
          ]),
          pw.SizedBox(height: 6),
          pw.Text(v.summary,
              style: const pw.TextStyle(fontSize: 9.5, color: _dark)),
          if (v.findings.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            ...v.findings.map(_findingBlock),
          ],
        ],
      ),
    );
  }

  pw.Widget _findingBlock(VerdictFinding f) {
    final color = _severityColor(f.severity);
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border(left: pw.BorderSide(color: color, width: 3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(f.title,
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 3),
          pw.Text(f.detail,
              style: const pw.TextStyle(fontSize: 9, color: _dark)),
          pw.SizedBox(height: 3),
          pw.Text('O que fazer: ${f.recommendation}',
              style: pw.TextStyle(
                  fontSize: 8.5,
                  color: _grey,
                  fontStyle: pw.FontStyle.italic)),
        ],
      ),
    );
  }

  PdfColor _severityColor(VerdictSeverity s) {
    switch (s) {
      case VerdictSeverity.ok:
        return _green;
      case VerdictSeverity.attention:
        return _yellow;
      case VerdictSeverity.critical:
        return _red;
    }
  }

  PdfColor _severityBg(VerdictSeverity s) {
    switch (s) {
      case VerdictSeverity.ok:
        return _greenLight;
      case VerdictSeverity.attention:
        return _yellowLight;
      case VerdictSeverity.critical:
        return _redLight;
    }
  }

  String _severityLabel(VerdictSeverity s) {
    switch (s) {
      case VerdictSeverity.ok:
        return 'TUDO OK';
      case VerdictSeverity.attention:
        return 'ATENÇÃO';
      case VerdictSeverity.critical:
        return 'CRÍTICO';
    }
  }

  // ── Resumo em badges ──────────────────────────────────────────────────────
  pw.Widget _summaryBadges(DiagnosticReport r) {
    final items = <(String, bool?)>[
      ('Wi-Fi', r.wifi == null ? null : true),
      ('Fibra / ONU', r.onu?.isOnline),
      ('Roteador', r.gatewayPing?.reachable),
      ('Internet', r.externalPing?.reachable),
      ('Velocidade', r.speed == null ? null : r.speed!.downloadMbps > 0),
      ('Traceroute', r.traceroute.isEmpty ? null : true),
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
            children: items.map((i) => _badge(i.$1, i.$2)).toList(),
          ),
        ],
      ),
    );
  }

  pw.Widget _badge(String label, bool? ok) {
    final color = ok == null ? _grey : (ok ? _green : _red);
    final text = ok == null ? 'N/A' : (ok ? 'OK' : 'FALHA');
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
            decoration:
                pw.BoxDecoration(color: color, shape: pw.BoxShape.circle)),
        pw.SizedBox(width: 5),
        pw.Text('$label  ',
            style: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold, color: _dark)),
        pw.Text(text, style: pw.TextStyle(fontSize: 8, color: color)),
      ]),
    );
  }

  // ── Velocidade ────────────────────────────────────────────────────────────
  pw.Widget _speedCard(DiagnosticReport r) {
    final s = r.speed!;
    final contracted = r.customer.contractedDownloadMbps;
    final ratio =
        contracted == null || contracted <= 0 ? null : s.downloadMbps / contracted;

    return _card(
      title: 'VELOCIDADE DE INTERNET',
      color: _blue,
      bgColor: _blueLight,
      child: pw.Column(children: [
        pw.Row(children: [
          pw.Expanded(
              child: _metricBox('Download',
                  '${s.downloadMbps.toStringAsFixed(1)} Mbps', _speedColor(s.downloadMbps))),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _metricBox('Upload',
                  '${s.uploadMbps.toStringAsFixed(1)} Mbps', _speedColor(s.uploadMbps * 2))),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _metricBox(
                  'Ping (Servidor)',
                  s.pingMs == null ? '---' : '${s.pingMs!.toStringAsFixed(0)} ms',
                  _pingColor(s.pingMs ?? 0))),
        ]),
        if (ratio != null) ...[
          pw.SizedBox(height: 8),
          _infoRow(
            'Percentual do plano contratado (${contracted!.toStringAsFixed(0)} Mbps)',
            '${(ratio * 100).toStringAsFixed(0)}%',
            highlight: true,
          ),
        ],
        if (s.referenceDownloadMbps != null) ...[
          pw.SizedBox(height: 6),
          _infoRow('Referência externa (Fast.com)',
              '${s.referenceDownloadMbps!.toStringAsFixed(1)} Mbps'),
        ],
      ]),
    );
  }

  // ── Wi-Fi ─────────────────────────────────────────────────────────────────
  pw.Widget _wifiCard(DiagnosticReport r) {
    final w = r.wifi!;
    final gw = r.gatewayPing;

    return _card(
      title: 'REDE WI-FI',
      color: _cyan,
      bgColor: _cyanLight,
      child: pw.Column(children: [
        pw.Row(children: [
          pw.Expanded(child: _infoCell('Rede (SSID)', w.ssid)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('Frequência', w.frequency)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('Força do Sinal', w.signalStrength)),
        ]),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Expanded(child: _infoCell('IP do Dispositivo', w.ip)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('Gateway (Roteador)', w.gateway)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('Canal', w.channel)),
        ]),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Expanded(child: _infoCell('Segurança', w.security)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('DNS', w.dns)),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _infoCell(
                  'Resposta do DNS',
                  w.dnsTimeMs == null
                      ? '---'
                      : '${w.dnsTimeMs!.toStringAsFixed(0)} ms')),
        ]),
        if (gw != null) ...[
          pw.SizedBox(height: 8),
          _infoRow('Ping ao roteador', _pingSummary(gw), highlight: true),
        ],
      ]),
    );
  }

  // ── Conectividade externa ─────────────────────────────────────────────────
  pw.Widget _externalCard(DiagnosticReport r) {
    final ip = r.publicIp;
    final google = r.googlePing;
    final cloud = r.cloudflarePing;

    return _card(
      title: 'CONECTIVIDADE EXTERNA',
      color: _green,
      bgColor: _greenLight,
      child: pw.Column(children: [
        pw.Row(children: [
          pw.Expanded(child: _infoCell('IPv4 Público', ip?.ipv4 ?? '---')),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('IPv6', ip?.ipv6 ?? '---')),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('Provedor (ISP)', ip?.isp ?? '---')),
        ]),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Expanded(
              child: _infoCell('Google (8.8.8.8)',
                  google == null ? '---' : _pingSummary(google))),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _infoCell('Cloudflare (1.1.1.1)',
                  cloud == null ? '---' : _pingSummary(cloud))),
        ]),
        if (r.lanDeviceCount != null) ...[
          pw.SizedBox(height: 8),
          _infoRow('Dispositivos detectados na rede local',
              r.lanDeviceCount.toString()),
        ],
      ]),
    );
  }

  String _pingSummary(PingMetrics p) {
    if (!p.reachable) return 'Sem resposta (perda 100%)';
    final parts = <String>[];
    if (p.latencyMs != null) parts.add('${p.latencyMs!.toStringAsFixed(0)} ms');
    if (p.jitterMs != null) {
      parts.add('jitter ${p.jitterMs!.toStringAsFixed(0)} ms');
    }
    parts.add('perda ${p.lossPercent.toStringAsFixed(0)}%');
    return parts.join(' · ');
  }

  // ── ONU ───────────────────────────────────────────────────────────────────
  pw.Widget _onuCard(OnuMetrics o) {
    final rx = o.rxPower;
    final tx = o.txPower;
    final rxColor = rx == null
        ? _grey
        : (rx >= -20 ? _green : (rx >= -25 ? _yellow : _red));
    final txColor = tx == null
        ? _grey
        : (tx >= 1 ? _green : (tx >= 0 ? _yellow : _red));

    return _card(
      title: 'FIBRA ÓPTICA / ONU',
      color: _cyan,
      bgColor: _cyanLight,
      child: pw.Column(children: [
        pw.Row(children: [
          pw.Expanded(
              child: _metricBox(
                  'Status', o.status, o.isOnline ? _green : _red)),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _metricBox('Qualidade', o.signalQuality,
                  o.signalQuality.contains('Exc') || o.signalQuality.contains('Boa')
                      ? _green
                      : _yellow)),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _metricBox('Sinal RX',
                  rx == null ? '---' : '${rx.toStringAsFixed(1)} dBm', rxColor)),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _metricBox('Sinal TX',
                  tx == null ? '---' : '${tx.toStringAsFixed(1)} dBm', txColor)),
        ]),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Expanded(child: _infoCell('Modelo ONU', o.model)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('Número de Série', o.serialNumber)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('OLT', o.oltName)),
        ]),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Expanded(
              child: _infoCell(
                  'Slot / PON / ONU ID', '${o.slot} / ${o.pon} / ${o.onuId}')),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('Modo', o.mode)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('VLAN', o.vlan)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('Atualizado em', o.lastUpdate)),
        ]),
      ]),
    );
  }

  // ── Dispositivo ───────────────────────────────────────────────────────────
  pw.Widget _deviceCard(DeviceMetrics d) {
    return _card(
      title: 'DISPOSITIVO',
      color: _grey,
      bgColor: _greyLight,
      child: pw.Column(children: [
        pw.Row(children: [
          pw.Expanded(child: _infoCell('Dispositivo', d.model)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('Sistema Operacional', d.os)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('Tipo de Conexão', d.connectionType)),
        ]),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Expanded(child: _infoCell('Versão do App', d.appVersion)),
          pw.SizedBox(width: 8),
          pw.Expanded(
              child: _infoCell('Nível de Bateria',
                  d.batteryLevel == null ? '---' : '${d.batteryLevel}%')),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoCell('Estado da Bateria', d.batteryState)),
        ]),
      ]),
    );
  }

  // ── Traceroute ────────────────────────────────────────────────────────────
  pw.Widget _tracerouteCard(List<TracerouteHop> hops) {
    return _card(
      title: 'ROTA DE REDE (TRACEROUTE → 8.8.8.8)',
      color: _grey,
      bgColor: _greyLight,
      child: pw.Table(
        border: pw.TableBorder.all(color: _greyBorder, width: 0.5),
        columnWidths: {
          0: const pw.FixedColumnWidth(32),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FlexColumnWidth(2),
        },
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _greyLight),
            children: [
              _tableHeader('#'),
              _tableHeader('IP / Host'),
              _tableHeader('Latência'),
            ],
          ),
          ...hops.take(15).map((h) => pw.TableRow(
                decoration:
                    pw.BoxDecoration(color: h.hop.isEven ? _greyLight : _white),
                children: [
                  _tableCell(h.hop.toString(), centered: true),
                  _tableCell(h.host),
                  _tableCell(h.latency),
                ],
              )),
        ],
      ),
    );
  }

  // ── Rodapé ────────────────────────────────────────────────────────────────
  pw.Widget _footer(pw.Context ctx, DiagnosticReport r) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _greyBorder, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Relatório gerado pelo aplicativo ${r.provider.name}',
              style: const pw.TextStyle(fontSize: 8, color: _grey)),
          pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: _grey)),
        ],
      ),
    );
  }

  // ── Componentes reutilizáveis ─────────────────────────────────────────────
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
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
          pw.Padding(padding: const pw.EdgeInsets.all(14), child: child),
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
                  fontSize: 13, fontWeight: pw.FontWeight.bold, color: color),
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
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold, color: _dark),
            maxLines: 2,
            overflow: pw.TextOverflow.clip),
      ],
    );
  }

  pw.Widget _infoRow(String label, String value, {bool highlight = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: highlight ? _blueLight : _greyLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
              child: pw.Text(label,
                  style: const pw.TextStyle(fontSize: 9, color: _grey))),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold, color: _dark)),
        ],
      ),
    );
  }

  pw.Widget _tableHeader(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _grey)),
      );

  pw.Widget _tableCell(String text, {bool centered = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Text(text,
            style: const pw.TextStyle(fontSize: 9, color: _dark),
            textAlign: centered ? pw.TextAlign.center : pw.TextAlign.left,
            maxLines: 1),
      );

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

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
