import 'package:flutter/material.dart';
import '../models/in_app_notification.dart';

class NotificationService with ChangeNotifier {
  List<InAppNotification> _notifications = [];
  bool _isLoading = true;

  List<InAppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount =>
      _notifications.where((n) => !n.read && !n.isExpired).length;

  List<InAppNotification> get activeNotifications =>
      _notifications.where((n) => !n.isExpired).toList();

  Future<void> loadNotifications() async {
    try {
      _isLoading = true;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));

      _notifications = [
        InAppNotification(
          id: 'welcome_001',
          type: NotificationType.info,
          title: 'Bem-vindo!',
          message:
              'Obrigado por usar nosso aplicativo. Explore todas as funcionalidades!',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          read: false,
        ),
      ];
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
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
    notifyListeners();
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}
