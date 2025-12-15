import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/provider_model.dart';

final apiServiceProvider = Provider((ref) => ApiService());

class ApiService {
  static const String _baseUrlKey = 'api_base_url';

  // Default URL
  String _baseUrl = kIsWeb
      ? 'http://localhost:9136'
      : (Platform.isAndroid ? 'http://10.0.2.2:9136' : 'http://localhost:9136');

  String get baseUrl => _baseUrl;

  ApiService() {
    _loadBaseUrl();
  }

  Future<void> _loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_baseUrlKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
    }
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
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
    await _loadBaseUrl(); // Ensure URL is loaded before request
    final response = await http
        .post(
          Uri.parse('$baseUrl/admin/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));

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
    await _loadBaseUrl();
    final response = await http
        .get(Uri.parse('$baseUrl/admin/providers'), headers: _headers)
        .timeout(const Duration(seconds: 10));

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
    await _loadBaseUrl();
    final response = await http
        .post(
          Uri.parse('$baseUrl/admin/providers'),
          headers: _headers,
          body: jsonEncode(provider.toMap()),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(_parseError(response));
    }
  }

  // --- Tickets ---

  Future<List<Map<String, dynamic>>> getTickets() async {
    await _loadBaseUrl();
    final response = await http
        .get(Uri.parse('$baseUrl/admin/tickets'), headers: _headers)
        .timeout(const Duration(seconds: 10));

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
    await _loadBaseUrl();
    final response = await http
        .post(
          Uri.parse('$baseUrl/admin/tickets/$ticketId/reply'),
          headers: _headers,
          body: jsonEncode({
            'message': message,
            'authorId': authorId,
            'authorName': authorName,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(_parseError(response));
    }
  }

  Future<List<Map<String, dynamic>>> getTicketMessages(String ticketId) async {
    await _loadBaseUrl();
    final response = await http
        .get(
          Uri.parse('$baseUrl/admin/tickets/$ticketId/messages'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception(_parseError(response));
    }
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    await _loadBaseUrl();
    final response = await http
        .patch(
          Uri.parse('$baseUrl/admin/tickets/$ticketId'),
          headers: _headers,
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(_parseError(response));
    }
  }

  // --- Dashboard ---

  Future<Map<String, dynamic>> getDashboardStats() async {
    await _loadBaseUrl();
    final response = await http
        .get(Uri.parse('$baseUrl/admin/dashboard'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception(_parseError(response));
    }
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    await _loadBaseUrl();
    final response = await http
        .get(Uri.parse('$baseUrl/admin/users'), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
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
