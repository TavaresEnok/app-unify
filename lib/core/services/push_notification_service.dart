// ARQUIVO: lib/core/services/push_notification_service.dart
// DESCRIÇÃO: Serviço completo de Push Notifications com FCM + Local Notifications

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Serviço para gerenciar push notifications
/// - FCM para receber notificações remotas
/// - flutter_local_notifications para mostrar notificações em foreground
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Callback para navegação (será setado pelo app)
  Function(String? route)? onNotificationTap;

  /// Inicializa o serviço de notificações
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configuração Android
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuração iOS
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Inicializa local notifications
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Cria canal de notificação Android (obrigatório Android 8+)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'Notificações Importantes',
        description: 'Canal para notificações do provedor',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Escuta mensagens em foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle tap quando app está em background (não terminado)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Verifica se app foi aberto via notificação (estado terminado)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      _isInitialized = true;
      debugPrint('🔔 PushNotificationService inicializado com sucesso');
    } catch (e) {
      debugPrint('❌ PushNotificationService erro: $e');
    }
  }

  /// Handle mensagens quando app está em foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Mensagem em foreground: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // Mostra notificação local
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Notificações Importantes',
          channelDescription: 'Canal para notificações do provedor',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['route'],
    );
  }

  /// Handle quando usuário toca na notificação (app em background)
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔔 App aberto via notificação: ${message.data}');
    final route = message.data['route'];
    if (route != null && onNotificationTap != null) {
      onNotificationTap!(route);
    }
  }

  /// Handle quando usuário toca na notificação local
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notificação local clicada: ${response.payload}');
    final route = response.payload;
    if (route != null && onNotificationTap != null) {
      onNotificationTap!(route);
    }
  }

  /// Obtém o token FCM atual
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Inscreve em um tópico para notificações broadcast
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('🔔 Inscrito no tópico: $topic');
  }

  /// Cancela inscrição de um tópico
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('🔔 Desinscrito do tópico: $topic');
  }

  // ============================================
  // NOTIFICAÇÕES LOCAIS PROGRAMADAS
  // ============================================

  /// Mostra notificação de fatura vencendo
  Future<void> showInvoiceDueNotification({
    required String invoiceId,
    required String dueDate,
    required double value,
  }) async {
    await _localNotifications.show(
      invoiceId.hashCode,
      '💰 Fatura Próxima do Vencimento',
      'Sua fatura de R\$ ${value.toStringAsFixed(2)} vence em $dueDate',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Notificações Importantes',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: '/faturas',
    );
  }

  /// Mostra notificação de conexão restaurada
  Future<void> showConnectionRestoredNotification() async {
    await _localNotifications.show(
      'connection_restored'.hashCode,
      '✅ Conexão Restaurada',
      'Sua internet foi liberada com sucesso!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Notificações Importantes',
          importance: Importance.high,
        ),
      ),
    );
  }

  /// Mostra notificação de liberação por confiança
  Future<void> showTrustUnlockNotification() async {
    await _localNotifications.show(
      'trust_unlock'.hashCode,
      '🔓 Internet Liberada',
      'Sua internet foi liberada por 24 horas. Regularize sua situação.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Notificações Importantes',
          importance: Importance.high,
        ),
      ),
      payload: '/faturas',
    );
  }

  /// Mostra notificação de manutenção programada
  Future<void> showMaintenanceNotification({
    required String title,
    required String message,
  }) async {
    await _localNotifications.show(
      'maintenance'.hashCode,
      '🔧 $title',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Notificações Importantes',
          importance: Importance.high,
        ),
      ),
    );
  }
}
