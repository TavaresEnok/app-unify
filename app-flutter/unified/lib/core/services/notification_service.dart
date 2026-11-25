import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/in_app_notification.dart';
import '../models/usuario.dart';
import 'session_token_store.dart';

class NotificationService with ChangeNotifier {
  List<InAppNotification> _notifications = [];
  bool _isLoading = true;
  String? _storageKey;
  String? _apiUrl;
  Set<String> _dismissed = {};
  int _generation = 0;

  void configureApiUrl(String? apiUrl) {
    final trimmed = apiUrl?.trim();
    _apiUrl = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  List<InAppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount =>
      _notifications.where((n) => !n.read && !n.isExpired).length;

  List<InAppNotification> get activeNotifications =>
      _notifications.where((n) => !n.isExpired).toList();

  String _accountKey(String providerId, String cpfCnpj) {
    final account = '$providerId:${cpfCnpj.replaceAll(RegExp(r'\D'), '')}';
    return 'notifications_v2_${base64Url.encode(utf8.encode(account))}';
  }

  Future<void> setAccount(String providerId, String cpfCnpj) async {
    final key = _accountKey(providerId, cpfCnpj);
    if (_storageKey == key) return;
    _storageKey = key;
    _generation++;
    _notifications = [];
    _dismissed = {};
    await loadNotifications();
  }

  void clearAccount() {
    _generation++;
    _storageKey = null;
    _notifications = [];
    _dismissed = {};
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    final key = _storageKey;
    final generation = _generation;
    if (key == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(key);
      final dismissed = prefs.getStringList('${key}_dismissed') ?? [];
      if (generation != _generation) return;
      _dismissed = dismissed.toSet();

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _notifications = jsonList
            .map((json) => InAppNotification.fromJson(json))
            .where((n) => !n.isExpired) // Filter expired on load
            .toList();
      } else {
        _notifications = [];
      }
    } catch (e) {
      debugPrint('Erro ao carregar notificações: $e');
    } finally {
      if (generation == _generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Syncs notifications from API (PostgreSQL, sem custo de leitura no Firestore)
  /// com fallback para o Firestore legado caso a API não seja informada/indisponível.
  Future<void> syncRemoteNotifications(Usuario user, String providerId) async {
    if (_storageKey != _accountKey(providerId, user.cpfCnpj)) return;
    final generation = _generation;

    final apiUrl = _apiUrl;
    if (apiUrl == null || apiUrl.isEmpty) return;
    await _syncFromApi(apiUrl, generation);
  }

  Future<bool> _syncFromApi(
    String apiUrl,
    int generation, {
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final ownsClient = client == null;
    try {
      final idToken = await SessionTokenStore.instance.getToken();
      if (idToken == null || idToken.isEmpty) return false;
      final base = apiUrl.replaceAll(RegExp(r'/+$'), '');
      final response = await httpClient.get(
        Uri.parse('$base/subscriber/notifications?limit=30'),
        headers: {'Authorization': 'Bearer $idToken'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return false;
      if (generation != _generation) return true;

      final decoded = jsonDecode(response.body);
      final items = decoded is Map ? decoded['data'] : null;
      if (items is! List) return true;

      bool changed = false;
      for (final raw in items.whereType<Map>()) {
        final nId = raw['id']?.toString() ?? '';
        if (nId.isEmpty ||
            _dismissed.contains(nId) ||
            _notifications.any((n) => n.id == nId)) {
          continue;
        }
        final createdAt =
            DateTime.tryParse(raw['createdAt']?.toString() ?? '') ??
                DateTime.now();
        final cat = raw['category']?.toString().toLowerCase() ?? 'info';
        final type = cat == 'urgent'
            ? NotificationType.warning
            : cat == 'promo'
                ? NotificationType.promotion
                : NotificationType.info;
        final route = raw['route']?.toString();
        _notifications.insert(
          0,
          InAppNotification(
            id: nId,
            type: type,
            title: raw['title']?.toString() ?? 'Nova Notificação',
            message: raw['body']?.toString() ?? '',
            createdAt: createdAt,
            read: false,
            actionUrl: (route != null && route.isNotEmpty) ? route : null,
          ),
        );
        changed = true;
      }

      if (changed) {
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
        await _saveToPrefs();
      }
      return true;
    } catch (e) {
      debugPrint('ℹ️  Fallback para Firestore ao sincronizar notificações: $e');
      return false;
    } finally {
      if (ownsClient) httpClient.close();
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      notifyListeners();
      await _saveToPrefs();
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
    notifyListeners();
    await _saveToPrefs();
  }

  void deleteNotification(String id) {
    if (_storageKey == null) return;
    _dismissed.add(id);
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    _saveToPrefs();
  }

  Future<void> addNotification(InAppNotification notification) async {
    if (_storageKey == null || _dismissed.contains(notification.id)) return;
    if (_notifications.any((n) => n.id == notification.id)) {
      return; // Avoid duplicates
    }
    _notifications.insert(0, notification);
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    final key = _storageKey;
    if (key == null) return;
    final jsonList = _notifications.map((n) => n.toJson()).toList();
    final dismissed = _dismissed.toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(jsonList));
      await prefs.setStringList('${key}_dismissed', dismissed);
    } catch (e) {
      debugPrint('Erro ao salvar notificações: $e');
    }
  }
}
