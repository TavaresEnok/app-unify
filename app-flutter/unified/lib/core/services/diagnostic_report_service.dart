import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/diagnostic_report.dart';
import '../models/provider_config.dart';
import '../utils/pdf_generator_service.dart';
import 'diagnostic_verdict.dart';
import 'session_token_store.dart';

class ReportDeliveryException implements Exception {
  final String message;
  ReportDeliveryException(this.message);
  @override
  String toString() => message;
}

/// Orquestra o que acontece DEPOIS que o diagnóstico termina: gerar o PDF,
/// publicá-lo no backend self-hosted, levá-lo ao atendimento do provedor e guardar o histórico.
class DiagnosticReportService {
  final String? _apiUrl;
  final http.Client _client;
  final PdfGeneratorService _pdf;

  DiagnosticReportService({
    String? apiUrl,
    http.Client? client,
    PdfGeneratorService? pdfGenerator,
  })  : _apiUrl = apiUrl,
        _client = client ?? http.Client(),
        _pdf = pdfGenerator ?? PdfGeneratorService();

  String? get _base {
    final trimmed = _apiUrl?.trim().replaceAll(RegExp(r'/+$'), '') ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _opaqueId(String prefix) {
    final rng = math.Random.secure();
    final rand =
        List.generate(8, (_) => rng.nextInt(36).toRadixString(36)).join();
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_$rand';
  }

  // ── PDF ───────────────────────────────────────────────────────────────────

  Future<Uint8List> buildPdf(
    DiagnosticReport report,
    DiagnosticVerdict verdict, {
    Uint8List? providerLogo,
  }) =>
      _pdf.buildPdfBytes(report, verdict, providerLogo: providerLogo);

  /// Abre a folha de compartilhamento do sistema com o PDF anexado.
  Future<void> sharePdf(
    DiagnosticReport report,
    DiagnosticVerdict verdict, {
    Uint8List? providerLogo,
  }) =>
      _pdf.sharePdf(report, verdict, providerLogo: providerLogo);

  // ── Publicação ────────────────────────────────────────────────────────────

  /// Sobe o PDF no backend self-hosted e devolve a URL privada do anexo.
  Future<String> uploadReport(
    DiagnosticReport report,
    Uint8List pdfBytes, {
    String? resultId,
  }) async {
    final base = _base;
    final token = await SessionTokenStore.instance.getToken();
    if (base == null || token == null || token.isEmpty) {
      throw ReportDeliveryException(
          'Sessão indisponível para publicar o relatório.');
    }
    final resId =
        (resultId != null && resultId.isNotEmpty) ? resultId : _opaqueId('res');
    final attId = _opaqueId('rep');
    final path =
        '$base/private/providers/${Uri.encodeComponent(report.provider.id)}/results/${Uri.encodeComponent(resId)}/reports/${Uri.encodeComponent(attId)}';

    try {
      final response = await _client
          .put(
            Uri.parse(path),
            headers: {
              'Content-Type': 'application/pdf',
              'Authorization': 'Bearer $token',
            },
            body: pdfBytes,
          )
          .timeout(const Duration(seconds: 25));
      if (response.statusCode >= 400) {
        throw ReportDeliveryException(
            'Não foi possível enviar o relatório (HTTP ${response.statusCode}).');
      }
      return path;
    } on ReportDeliveryException {
      rethrow;
    } catch (_) {
      throw ReportDeliveryException(
          'Não foi possível enviar o relatório. Verifique sua conexão e tente novamente.');
    }
  }

  // ── WhatsApp do provedor ──────────────────────────────────────────────────

  /// Número de WhatsApp do suporte, extraído de `supportContacts`.
  /// Aceita tanto `type == 'whatsapp'` quanto o nome contendo "whatsapp",
  /// espelhando a convenção já usada na tela de suporte.
  static String? whatsappNumber(ProviderConfig? config) {
    final contacts = config?.config.supportContacts ?? const [];
    SupportContactItem? match;
    for (final c in contacts) {
      if (c.type.toLowerCase() == 'whatsapp' && c.value.trim().isNotEmpty) {
        match = c;
        break;
      }
    }
    match ??= contacts.cast<SupportContactItem?>().firstWhere(
          (c) =>
              c != null &&
              c.name.toLowerCase().contains('whatsapp') &&
              c.value.trim().isNotEmpty,
          orElse: () => null,
        );
    if (match == null) return null;

    var digits = match.value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    // Número local (DDD + número) — prefixa o código do Brasil.
    if (digits.length <= 11) digits = '55$digits';
    return digits;
  }

  /// Mensagem enviada ao suporte. Curta e objetiva: o técnico precisa saber de
  /// quem é, qual o veredito e onde está o relatório completo.
  static String buildWhatsappMessage({
    required DiagnosticReport report,
    required DiagnosticVerdict verdict,
    required String reportUrl,
  }) {
    final c = report.customer;
    final buffer = StringBuffer()
      ..writeln('Olá! Fiz um diagnóstico de rede pelo aplicativo.')
      ..writeln()
      ..writeln('Cliente: ${c.name}')
      ..writeln('Contrato: ${c.contractId ?? '---'}')
      ..writeln('Plano: ${c.planName}')
      ..writeln()
      ..writeln('Resultado: ${verdict.headline}');

    final top = verdict.findings.take(3);
    if (top.isNotEmpty) {
      buffer.writeln();
      for (final f in top) {
        buffer.writeln('• ${f.title}');
      }
    }

    buffer
      ..writeln()
      ..writeln('Relatório completo (PDF):')
      ..writeln(reportUrl);

    return buffer.toString();
  }

  /// Abre o WhatsApp do provedor com a mensagem pronta.
  Future<void> openWhatsappWithReport({
    required ProviderConfig? config,
    required DiagnosticReport report,
    required DiagnosticVerdict verdict,
    required String reportUrl,
  }) async {
    final number = whatsappNumber(config);
    if (number == null) {
      throw ReportDeliveryException(
          'Este provedor não tem um número de WhatsApp cadastrado para suporte.');
    }

    final text = buildWhatsappMessage(
      report: report,
      verdict: verdict,
      reportUrl: reportUrl,
    );
    final uri =
        Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(text)}');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw ReportDeliveryException(
          'Não foi possível abrir o WhatsApp neste aparelho.');
    }
  }

  // ── Chamado ───────────────────────────────────────────────────────────────

  /// Abre um chamado no provedor já com o link do relatório no corpo.
  Future<String> openSupportTicket({
    required DiagnosticReport report,
    required DiagnosticVerdict verdict,
    required String reportUrl,
    String? userEmail,
  }) async {
    final base = _base;
    final token = await SessionTokenStore.instance.getToken();
    if (base == null || token == null || token.isEmpty) {
      throw ReportDeliveryException(
          'Você precisa estar conectado para abrir um chamado.');
    }

    final message = StringBuffer()
      ..writeln(verdict.headline)
      ..writeln()
      ..writeln(verdict.summary);

    if (verdict.findings.isNotEmpty) {
      message.writeln();
      for (final f in verdict.findings) {
        message.writeln('• ${f.title}: ${f.detail}');
      }
    }

    message
      ..writeln()
      ..writeln('Contrato: ${report.customer.contractId ?? '---'}')
      ..writeln('Plano: ${report.customer.planName}')
      ..writeln()
      ..writeln('Relatório completo (PDF): $reportUrl');

    try {
      final response = await _client
          .post(
            Uri.parse('$base/subscriber/tickets'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'subject': 'Diagnóstico de rede — ${verdict.headline}',
              'message': message.toString(),
              'providerName': report.provider.name,
              if (userEmail != null && userEmail.isNotEmpty)
                'userEmail': userEmail,
            }),
          )
          .timeout(const Duration(seconds: 25));

      final body = jsonDecode(response.body);
      if (response.statusCode >= 400) {
        final msg = body is Map && body['error'] is Map
            ? body['error']['message']?.toString()
            : null;
        throw ReportDeliveryException(
            msg ?? 'Não foi possível abrir o chamado.');
      }
      final ticketId = body is Map ? body['ticketId']?.toString() : null;
      if (ticketId == null || ticketId.isEmpty) {
        throw ReportDeliveryException('O servidor não confirmou o chamado.');
      }
      return ticketId;
    } on ReportDeliveryException {
      rethrow;
    } catch (_) {
      throw ReportDeliveryException(
          'O servidor demorou para responder. Verifique seus chamados em instantes.');
    }
  }

  // ── Histórico ─────────────────────────────────────────────────────────────

  /// Persiste o resultado via `POST /diagnostic/results` e devolve o id (ou null).
  Future<String?> persistResult({
    required DiagnosticReport report,
    required DiagnosticVerdict verdict,
    String? reportUrl,
  }) async {
    final base = _base;
    final token = await SessionTokenStore.instance.getToken();
    if (base == null || token == null || token.isEmpty) return null;
    try {
      final response = await _client
          .post(
            Uri.parse('$base/diagnostic/results'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'providerId': report.provider.id,
              'contractId': report.customer.contractId,
              'planName': report.customer.planName,
              'verdict': verdict.severity.name,
              'cause': verdict.headline,
              'needsProviderSupport': verdict.needsProviderSupport,
              'findings': verdict.findings.map((f) => f.toJson()).toList(),
              'summary': report.toJson(),
              if (reportUrl != null) 'reportUrl': reportUrl,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode >= 400) return null;
      final body = jsonDecode(response.body);
      if (body is Map && body['data'] is Map) {
        return body['data']['id']?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('[Diagnóstico] Falha ao salvar histórico: $e');
      return null;
    }
  }

  /// Anexa a URL do PDF ao registro já persistido (vinculado via `resultId`).
  Future<void> attachReportUrl({
    required String providerId,
    required String resultId,
    required String reportUrl,
  }) async {
    // O anexo privado já fica vinculado a `resultId` via PUT /private/.../reports/:attachmentId.
  }

  // ── Fluxo completo ────────────────────────────────────────────────────────

  Future<String> publishReport({
    required DiagnosticReport report,
    required DiagnosticVerdict verdict,
    Uint8List? providerLogo,
    String? resultId,
  }) async {
    final bytes = await buildPdf(report, verdict, providerLogo: providerLogo);
    return uploadReport(report, bytes, resultId: resultId);
  }
}
