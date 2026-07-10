import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/in_app_notification.dart';
import '../models/usuario.dart';

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

  /// Syncs notifications from Firestore (Robust Fallback)
  Future<void> syncRemoteNotifications(Usuario user, String providerId) async {
    try {
      // 1. Fetch recent notifications (last 7 days to avoid fetching excessively)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      // Query 1: Targeted specifically to CPF
      final cpfQuery = await FirebaseFirestore.instance
          .collection('notifications')
          .where('targetCpf', isEqualTo: user.cpfCnpj)
          .where('createdAt', isGreaterThanOrEqualTo: sevenDaysAgo)
          .get();

      final providerQuery = await FirebaseFirestore.instance
          .collection('notifications')
          .where('providerId', isEqualTo: providerId)
          .limit(50)
          .get();

      // Fallback Query: Also fetch 'vibe' if providerId is different
      // This ensures we catch notifications sent via Admin Panel if it uses 'vibe' hardcoded
      var fallbackDocs = <QueryDocumentSnapshot>[];
      if (providerId != 'vibe') {
        final fallbackQuery = await FirebaseFirestore.instance
            .collection('notifications')
            .where('providerId', isEqualTo: 'vibe')
            .limit(50)
            .get();
        fallbackDocs = fallbackQuery.docs;
      }

      final allDocs = [
        ...cpfQuery.docs,
        ...providerQuery.docs,
        ...fallbackDocs
      ];
      // Deduplicate by ID
      final uniqueDocs = {for (var d in allDocs) d.id: d}.values;

      bool changed = false;

      for (var doc in uniqueDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final String nId = doc.id;
        final timestamp = (data['createdAt'] as Timestamp?)?.toDate();

        // Memory Date Filter
        if (timestamp != null && timestamp.isBefore(sevenDaysAgo)) continue;

        // Check if we already have this notification
        if (_notifications.any((n) => n.id == nId)) continue;

        // --- FILTERING LOGIC ---
        bool shouldShow = false;

        // 1. Target All
        if (data['targetAll'] == true) shouldShow = true;

        // 2. Target CPF
        if (data['targetCpf'] == user.cpfCnpj) shouldShow = true;

        // 3. Segmented (Status/Plan)
        if (data['category'] == 'segmented') {
          bool matchesStatus = true;
          bool matchesPlan = true;

          final String? statusFilter = data['statusFilter'];
          final String? planFilter = data['planFilter'];

          if (statusFilter != null && statusFilter != 'all') {
            final userStatus = (user.status).toLowerCase().trim();
            if (!userStatus.contains(statusFilter.toLowerCase().trim())) {
              matchesStatus = false;
            }
          }

          if (planFilter != null && planFilter != 'all') {
            final userPlan = (user.plano).toLowerCase().trim();
            if (!userPlan.contains(planFilter.toLowerCase().trim())) {
              matchesPlan = false;
            }
          }

          if (matchesStatus && matchesPlan) shouldShow = true;
        }

        if (shouldShow) {
          // Add to local list
          _notifications.insert(
              0,
              InAppNotification(
                id: nId,
                type: NotificationType.info,
                title: data['title'] ?? 'Nova Notificação',
                message: data['body'] ?? '',
                createdAt: timestamp ?? DateTime.now(),
                read: false,
                actionUrl: data['route'],
              ));
          changed = true;
        }
      }

      if (changed) {
        // Sort by date desc
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
        await _saveToPrefs();
        debugPrint(
            '✅ Notificações sincronizadas. ${uniqueDocs.length} analisadas.');
      }
    } catch (e) {
      debugPrint('❌ Erro ao sincronizar notificações remotas: $e');
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
    if (_notifications.any((n) => n.id == notification.id)) {
      return; // Avoid duplicates
    }
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
