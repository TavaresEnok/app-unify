// ARQUIVO: lib/core/services/suporte_service.dart
// DESCRIÇÃO: Serviço para criar e acompanhar tickets de suporte via API REST

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'session_token_store.dart';

class SuporteService {
  final http.Client _client;
  final String? apiUrl;

  SuporteService({this.apiUrl, http.Client? client})
      : _client = client ?? http.Client();

  String? _normalizedBase(String? override) {
    final candidate = (override ?? apiUrl)?.trim().replaceAll(RegExp(r'/+$'), '');
    return (candidate == null || candidate.isEmpty) ? null : candidate;
  }

  Future<String> _requireToken() async {
    final token = await SessionTokenStore.instance.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sessão expirada. Entre novamente para abrir um chamado.');
    }
    return token;
  }

  /// Cria um ticket de suporte e faz upload opcional da imagem como anexo privado.
  Future<String> createTicket({
    required String subject,
    required String message,
    required XFile? imageFile,
    required String providerId,
    required String providerName,
    required String userEmail,
    String? overrideApiUrl,
  }) async {
    final base = _normalizedBase(overrideApiUrl);
    if (base == null) {
      throw Exception('URL da API indisponível para abrir chamado.');
    }
    final token = await _requireToken();

    final response = await _client
        .post(
          Uri.parse('$base/subscriber/tickets'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'subject': subject,
            'message': message,
            'providerId': providerId,
            'providerName': providerName,
            if (userEmail.isNotEmpty) 'userEmail': userEmail,
          }),
        )
        .timeout(const Duration(seconds: 25));

    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final err = decoded is Map && decoded['error'] is Map
          ? decoded['error']['message']?.toString()
          : null;
      throw Exception(err ?? 'Não foi possível criar o chamado.');
    }

    final ticketId = decoded is Map
        ? (decoded['ticketId']?.toString() ?? decoded['data']?['id']?.toString())
        : null;
    if (ticketId == null || ticketId.isEmpty) {
      throw Exception('Resposta incompleta do servidor ao abrir chamado.');
    }

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final attId = 'att_${DateTime.now().millisecondsSinceEpoch}';
      final lower = imageFile.name.toLowerCase();
      final mime = lower.endsWith('.png') ? 'image/png' : 'image/jpeg';
      await _client
          .put(
            Uri.parse(
                '$base/private/tickets/${Uri.encodeComponent(ticketId)}/attachments/${Uri.encodeComponent(attId)}'),
            headers: {
              'Content-Type': mime,
              'Authorization': 'Bearer $token',
            },
            body: bytes,
          )
          .timeout(const Duration(seconds: 25));
    }

    return ticketId;
  }

  Future<List<Map<String, dynamic>>> listTickets({String? overrideApiUrl}) async {
    final base = _normalizedBase(overrideApiUrl);
    if (base == null) return const [];
    final token = await _requireToken();
    final response = await _client.get(
      Uri.parse('$base/subscriber/tickets'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode >= 400) return const [];
    final decoded = jsonDecode(response.body);
    final items = decoded is Map ? decoded['data'] : null;
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Stream<List<Map<String, dynamic>>> watchTickets({
    String? overrideApiUrl,
    Duration interval = const Duration(seconds: 8),
  }) async* {
    yield await listTickets(overrideApiUrl: overrideApiUrl);
    await for (final _ in Stream<void>.periodic(interval)) {
      yield await listTickets(overrideApiUrl: overrideApiUrl);
    }
  }
}
