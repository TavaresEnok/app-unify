
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/diagnostic_report.dart';
import '../models/provider_config.dart';
import '../utils/pdf_generator_service.dart';
import 'diagnostic_verdict.dart';

class ReportDeliveryException implements Exception {
  final String message;
  ReportDeliveryException(this.message);
  @override
  String toString() => message;
}

/// Orquestra o que acontece DEPOIS que o diagnóstico termina: gerar o PDF,
/// publicá-lo, levá-lo ao atendimento do provedor e guardar o histórico.
///
/// Regra de ouro do WhatsApp: um deep link (`wa.me`) só carrega TEXTO — não é
/// possível anexar arquivo programaticamente a um contato específico. Por isso o
/// PDF é enviado ao Storage e o que segue na mensagem é o link.
class DiagnosticReportService {
  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PdfGeneratorService _pdf;

  DiagnosticReportService({
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    PdfGeneratorService? pdfGenerator,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _pdf = pdfGenerator ?? PdfGeneratorService();

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

  /// Sobe o PDF e devolve a URL de download.
  Future<String> uploadReport(
    DiagnosticReport report,
    Uint8List pdfBytes,
  ) async {
    final uid = _auth.currentUser?.uid ?? 'anonimo';
    final stamp = report.generatedAt.millisecondsSinceEpoch;
    final path =
        'providers/${report.provider.id}/diagnostic_reports/${uid}_$stamp.pdf';

    try {
      final ref = _storage.ref().child(path);
      await ref.putData(
        pdfBytes,
        SettableMetadata(
          contentType: 'application/pdf',
          customMetadata: {
            'contractId': report.customer.contractId?.toString() ?? '',
            'severity': '',
          },
        ),
      );
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw ReportDeliveryException(
          'Não foi possível enviar o relatório (${e.code}). Verifique sua conexão e tente novamente.');
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
    final uri = Uri.parse(
        'https://wa.me/$number?text=${Uri.encodeComponent(text)}');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw ReportDeliveryException(
          'Não foi possível abrir o WhatsApp neste aparelho.');
    }
  }

  // ── Chamado ───────────────────────────────────────────────────────────────

  /// Abre um chamado no provedor já com o link do relatório no corpo.
  ///
  /// Usa a fila `function_requests`/`function_responses` (a Cloud Function é
  /// quem escreve o ticket). O link vai no texto porque o contrato de
  /// CREATE_TICKET só tem `imageUrl`, que o painel renderiza como imagem.
  Future<String> openSupportTicket({
    required DiagnosticReport report,
    required DiagnosticVerdict verdict,
    required String reportUrl,
    String? userEmail,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
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

    final requestId = _firestore.collection('function_requests').doc().id;
    final requestRef = _firestore.collection('function_requests').doc(requestId);
    final responseRef =
        _firestore.collection('function_responses').doc(requestId);

    await requestRef.set({
      'type': 'CREATE_TICKET',
      'requesterUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'payload': {
        'subject': 'Diagnóstico de rede — ${verdict.headline}',
        'message': message.toString(),
        'providerId': report.provider.id,
        'providerName': report.provider.name,
        'userEmail': userEmail,
        'requesterUid': uid,
      },
    });

    try {
      final snapshot = await responseRef
          .snapshots()
          .firstWhere((snap) => snap.exists)
          .timeout(const Duration(seconds: 60));
      final data = snapshot.data();
      final error = data?['error'];
      if (error != null) throw ReportDeliveryException(error.toString());
      final ticketId = data?['result']?['ticketId'];
      if (ticketId == null) {
        throw ReportDeliveryException('O servidor não confirmou o chamado.');
      }
      return ticketId.toString();
    } on ReportDeliveryException {
      rethrow;
    } catch (_) {
      throw ReportDeliveryException(
          'O servidor demorou para responder. Verifique seus chamados em instantes.');
    }
  }

  // ── Histórico ─────────────────────────────────────────────────────────────

  /// Persiste o resultado em `provedores/{id}/diagnostic_results` e devolve o id
  /// do documento (ou null em falha).
  ///
  /// Deve ser chamado UMA vez por diagnóstico, assim que o resultado é
  /// apresentado — inclusive quando o cliente auto-resolve e não aciona o
  /// suporte. É isso que faz a métrica de deflexão do painel refletir a
  /// realidade (§ estudo 4.4). Falha aqui é silenciosa: histórico é acessório.
  Future<String?> persistResult({
    required DiagnosticReport report,
    required DiagnosticVerdict verdict,
    String? reportUrl,
  }) async {
    try {
      final ref = await _firestore
          .collection('provedores')
          .doc(report.provider.id)
          .collection('diagnostic_results')
          .add({
        'createdAt': FieldValue.serverTimestamp(),
        'createdByUid': _auth.currentUser?.uid,
        'contractId': report.customer.contractId,
        'planName': report.customer.planName,
        'severity': verdict.severity.name,
        'headline': verdict.headline,
        'needsProviderSupport': verdict.needsProviderSupport,
        'findings': verdict.findings.map((f) => f.toJson()).toList(),
        'measurements': report.toJson(),
        if (reportUrl != null) 'reportUrl': reportUrl,
      });
      return ref.id;
    } catch (e) {
      debugPrint('[Diagnóstico] Falha ao salvar histórico: $e');
      return null;
    }
  }

  /// Anexa a URL do PDF ao registro já persistido (quando o cliente publica o
  /// relatório após o diagnóstico). Evita gravar um segundo documento.
  Future<void> attachReportUrl({
    required String providerId,
    required String resultId,
    required String reportUrl,
  }) async {
    try {
      await _firestore
          .collection('provedores')
          .doc(providerId)
          .collection('diagnostic_results')
          .doc(resultId)
          .set({'reportUrl': reportUrl}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Diagnóstico] Falha ao anexar URL ao histórico: $e');
    }
  }

  // ── Fluxo completo ────────────────────────────────────────────────────────

  /// Gera o PDF e o publica no Storage, devolvendo a URL. NÃO grava histórico —
  /// a persistência acontece uma vez na abertura da folha; aqui só atualizamos a
  /// URL via [attachReportUrl] quando aplicável.
  Future<String> publishReport({
    required DiagnosticReport report,
    required DiagnosticVerdict verdict,
    Uint8List? providerLogo,
  }) async {
    final bytes = await buildPdf(report, verdict, providerLogo: providerLogo);
    return uploadReport(report, bytes);
  }
}
