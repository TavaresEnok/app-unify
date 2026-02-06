import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/in_app_notification.dart';
import 'notification_service.dart';

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

  // Serviço de notificações in-app (injetado)
  NotificationService? _notificationService;

  /// Inicializa o serviço de notificações
  Future<void> initialize({NotificationService? notificationService}) async {
    if (_isInitialized) {
      // Allow re-updating the notification service even if initialized
      if (notificationService != null) {
        _notificationService = notificationService;
      }
      return;
    }

    _notificationService = notificationService;

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

      // Request permission (Critical for Android 13+)
      await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
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

  /// Helper to save notification to history
  void _addToHistory({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    String? id,
    String? actionUrl,
  }) {
    if (_notificationService == null) return;

    final nId = id ?? DateTime.now().millisecondsSinceEpoch.toString();

    _notificationService!.addNotification(
      InAppNotification(
        id: nId,
        type: type,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        read: false,
        actionUrl: actionUrl,
      ),
    );
  }

  /// Handle mensagens quando app está em foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Mensagem em foreground: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // Salva no histórico in-app
    if (notification.title != null && notification.body != null) {
      _addToHistory(
        id: message.messageId,
        title: notification.title!,
        message: notification.body!,
        type: NotificationType.info, // Default info for regular push
        actionUrl: message.data['route'],
      );
    }

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

    // Note: Notification will already be in history if it was received while in foreground or background via system tray.
    // If the user taps it, we just navigate.

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
    const title = '💰 Fatura Próxima do Vencimento';
    final message =
        'Sua fatura de R\$ ${value.toStringAsFixed(2)} vence em $dueDate';

    _addToHistory(
      id: 'invoice_$invoiceId',
      title: title,
      message: message,
      type: NotificationType.warning,
      actionUrl: '/faturas',
    );

    await _localNotifications.show(
      invoiceId.hashCode,
      title,
      message,
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
    const title = '✅ Conexão Restaurada';
    const message = 'Sua internet foi liberada com sucesso!';

    _addToHistory(
      title: title,
      message: message,
      type: NotificationType.success,
    );

    await _localNotifications.show(
      'connection_restored'.hashCode,
      title,
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

  /// Mostra notificação de liberação por confiança
  Future<void> showTrustUnlockNotification() async {
    const title = '🔓 Internet Liberada';
    const message =
        'Sua internet foi liberada por 24 horas. Regularize sua situação.';

    _addToHistory(
      title: title,
      message: message,
      type: NotificationType.info,
      actionUrl: '/faturas',
    );

    await _localNotifications.show(
      'trust_unlock'.hashCode,
      title,
      message,
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
    _addToHistory(
      title: '🔧 $title',
      message: message,
      type: NotificationType.warning,
    );

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
