import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/in_app_notification.dart';

class NotificationService with ChangeNotifier {
  List<InAppNotification> _notifications = [];
  bool _isLoading = true;
  static const String _storageKey = 'notifications_v1';

  List<InAppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount =>
      _notifications.where((n) => !n.read && !n.isExpired).length;

  List<InAppNotification> get activeNotifications =>
      _notifications.where((n) => !n.isExpired).toList();

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _notifications = jsonList
            .map((json) => InAppNotification.fromJson(json))
            .where((n) => !n.isExpired) // Filter expired on load
            .toList();
      } else {
        // First run: Add Welcome Notification
        _notifications = [
          InAppNotification(
            id: 'welcome_001',
            type: NotificationType.info,
            title: 'Bem-vindo!',
            message:
                'Obrigado por usar nosso aplicativo. Explore todas as funcionalidades!',
            createdAt: DateTime.now(),
            read: false,
          ),
        ];
        await _saveToPrefs();
      }
    } catch (e) {
      debugPrint('Erro ao carregar notificações: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    _saveToPrefs();
  }

  Future<void> addNotification(InAppNotification notification) async {
    _notifications.insert(0, notification);
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Erro ao salvar notificações: $e');
    }
  }
}
