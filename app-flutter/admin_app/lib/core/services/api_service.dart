import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/provider_model.dart';

final apiServiceProvider = Provider((ref) => ApiService());

class ApiService {
  // Use 10.0.2.2 for Android Emulator to access host's localhost
  // Use localhost for Web/Linux
  String get baseUrl {
    if (kIsWeb) return 'http://localhost:9136';
    if (Platform.isAndroid) return 'http://10.0.2.2:9136';
    return 'http://localhost:9136';
  }

  String? _token;
  String? get token => _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // --- Auth ---

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      return data;
    } else {
      throw Exception(_parseError(response));
    }
  }

  // --- Providers ---

  Future<List<ProviderModel>> getProviders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/providers'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((e) => ProviderModel.fromMap(e as Map<String, dynamic>, e['id']))
          .toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  Future<void> saveProvider(ProviderModel provider) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/providers'),
      headers: _headers,
      body: jsonEncode(provider.toMap()),
    );

    if (response.statusCode != 200) {
      throw Exception(_parseError(response));
    }
  }

  // --- Tickets ---

  Future<List<Map<String, dynamic>>> getTickets() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/tickets'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception(_parseError(response));
    }
  }

  Future<void> replyTicket(
    String ticketId,
    String message,
    String authorId,
    String authorName,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/tickets/$ticketId/reply'),
      headers: _headers,
      body: jsonEncode({
        'message': message,
        'authorId': authorId,
        'authorName': authorName,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_parseError(response));
    }
  }

  Future<List<Map<String, dynamic>>> getTicketMessages(String ticketId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/tickets/$ticketId/messages'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception(_parseError(response));
    }
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/admin/tickets/$ticketId'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception(_parseError(response));
    }
  }

  // --- Dashboard ---

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception(_parseError(response));
    }
  }

  String _parseError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body['error'] != null && body['error']['message'] != null) {
        return body['error']['message'];
      }
    } catch (_) {}
    return 'Erro desconhecido (${response.statusCode})';
  }
}
