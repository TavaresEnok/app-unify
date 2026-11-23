import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Um aviso de instabilidade/manutenção publicado pelo provedor.
@immutable
class ProviderIncident {
  final String id;
  final String title;
  final String message;
  final String? area;
  final String severity;
  final String? estimatedResolution;
  final bool matchesArea;

  const ProviderIncident({
    required this.id,
    required this.title,
    required this.message,
    this.area,
    this.severity = 'warning',
    this.estimatedResolution,
    this.matchesArea = true,
  });

  factory ProviderIncident.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return ProviderIncident(
      id: doc.id,
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? data['title'] as String
          : 'Instabilidade identificada',
      message: (data['message'] as String?)?.trim() ??
          'Nossa equipe já está atuando para normalizar.',
      area: (data['area'] as String?)?.trim().isNotEmpty == true
          ? data['area'] as String
          : null,
      severity: (data['severity'] as String?)?.trim().isNotEmpty == true
          ? data['severity'] as String
          : 'warning',
      estimatedResolution:
          (data['estimatedResolution'] as String?)?.trim().isNotEmpty == true
              ? data['estimatedResolution'] as String
              : null,
    );
  }

  factory ProviderIncident.fromJson(Map<String, dynamic> data) {
    final title = data['title']?.toString().trim() ?? '';
    final message = data['message']?.toString().trim() ?? '';
    final area = data['area']?.toString().trim() ?? '';
    final est = data['estimatedResolution']?.toString().trim() ?? '';
    return ProviderIncident(
      id: data['id']?.toString() ?? '',
      title: title.isNotEmpty ? title : 'Aviso de rede',
      message: message.isNotEmpty
          ? message
          : 'Nossa equipe já está atuando para normalizar.',
      area: area.isNotEmpty ? area : null,
      severity: data['severity']?.toString().trim().isNotEmpty == true
          ? data['severity'].toString().trim()
          : 'warning',
      estimatedResolution: est.isNotEmpty ? est : null,
      matchesArea: data['matchesArea'] != false,
    );
  }
}

/// Consulta os avisos de instabilidade ativos do provedor.
///
/// Prefere a API do servidor (`GET /subscriber/incidents`, com cache de 30s e
/// correspondência de OLT/bairro via PostgreSQL), evitando tempestade de
/// leituras no Firestore durante quedas em massa.
class IncidentService {
  final FirebaseFirestore? _firestore;

  IncidentService({FirebaseFirestore? firestore}) : _firestore = firestore;

  /// Consulta a API (`GET /subscriber/incidents`). Best-effort: nunca lança.
  static Future<ProviderIncident?> fetchActiveFromApi(
    String? apiUrl, {
    http.Client? client,
  }) async {
    final base = apiUrl?.trim().replaceAll(RegExp(r'/+$'), '') ?? '';
    if (base.isEmpty) return null;
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null || token.isEmpty) return null;
      final httpClient = client ?? http.Client();
      try {
        final response = await httpClient
            .get(
              Uri.parse('$base/subscriber/incidents'),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(const Duration(seconds: 6));
        if (response.statusCode != 200) return null;
        final decoded = jsonDecode(response.body);
        final list = decoded is Map ? decoded['data'] : null;
        if (list is! List || list.isEmpty) return null;
        final items = list
            .whereType<Map>()
            .map((m) => ProviderIncident.fromJson(Map<String, dynamic>.from(m)))
            .where((i) => i.id.isNotEmpty)
            .toList();
        if (items.isEmpty) return null;
        return items.firstWhere((i) => i.matchesArea, orElse: () => items.first);
      } finally {
        if (client == null) httpClient.close();
      }
    } catch (e) {
      debugPrint('[Instabilidade] Falha ao consultar API de avisos: $e');
      return null;
    }
  }

  /// Fallback direto no Firestore (mantido para compatibilidade de testes).
  Future<ProviderIncident?> activeIncident(String providerId) async {
    try {
      final db = _firestore ?? FirebaseFirestore.instance;
      final snapshot = await db
          .collection('provedores')
          .doc(providerId)
          .collection('incidents')
          .where('active', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return ProviderIncident.fromDoc(snapshot.docs.first);
    } catch (e) {
      debugPrint('[Instabilidade] Falha ao consultar avisos: $e');
      return null;
    }
  }
}
