import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'session_token_store.dart';

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

/// Consulta os avisos de instabilidade ativos do provedor via API REST (`GET /subscriber/incidents`).
class IncidentService {
  const IncidentService();

  /// Consulta a API (`GET /subscriber/incidents`). Best-effort: nunca lança.
  static Future<ProviderIncident?> fetchActiveFromApi(
    String? apiUrl, {
    http.Client? client,
  }) async {
    final base = apiUrl?.trim().replaceAll(RegExp(r'/+$'), '') ?? '';
    if (base.isEmpty) return null;
    try {
      final token = await SessionTokenStore.instance.getToken();
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

  Future<ProviderIncident?> activeIncident(String providerId, {String? apiUrl}) =>
      fetchActiveFromApi(apiUrl);
}
