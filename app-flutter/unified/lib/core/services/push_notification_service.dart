import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Callback para navegação (será setado pelo app)
  Function(String? route)? onNotificationTap;

  // Rota pendente quando o app é aberto pelo toque em uma notificação (cold start)
  // antes de o PainelPage registrar o callback de navegação.
  String? _pendingRoute;

  /// Registra (ou limpa) o handler de navegação ao tocar em notificações.
  /// Se houver uma rota pendente de abertura a frio, dispara imediatamente.
  void setOnNotificationTap(void Function(String? route)? handler) {
    onNotificationTap = handler;
    if (handler != null && _pendingRoute != null) {
      final route = _pendingRoute;
      _pendingRoute = null;
      Future.microtask(() => handler(route));
    }
  }

  /// Abre uma rota do app (links provedorapp://). Antes do login, fica
  /// guardada até a tela principal assumir a navegação.
  void openRoute(String route) => _dispatchRoute(route);

  void _dispatchRoute(String? rawRoute) {
    final route = rawRoute?.trim();
    final effectiveRoute =
        (route == null || route.isEmpty) ? '/notificacoes' : route;
    if (onNotificationTap != null) {
      onNotificationTap!(effectiveRoute);
    } else {
      _pendingRoute = effectiveRoute;
    }
  }

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

      // A permissão de notificações não é pedida aqui (abertura do app):
      // ver [requestPermissionOnce], chamada no fim da apresentação ou
      // depois do primeiro login.

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
        // Mesmo id do aviso que a sincronização traz da API (campanha):
        // assim o aviso não aparece duas vezes na lista.
        id: foregroundNotificationId(message.data, message.messageId),
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

  /// Id do aviso no histórico: o da campanha quando existe.
  @visibleForTesting
  static String? foregroundNotificationId(
      Map<String, dynamic> data, String? messageId) {
    final campaign = data['campaignId']?.toString().trim();
    if (campaign != null && campaign.isNotEmpty) return campaign;
    return messageId;
  }

  /// Handle quando usuário toca na notificação (app em background ou terminado)
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔔 App aberto via notificação: ${message.data}');
    final route = message.data['route']?.toString();
    _dispatchRoute(route);
  }

  /// Handle quando usuário toca na notificação local
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notificação local clicada: ${response.payload}');
    _dispatchRoute(response.payload);
  }

  static const _permissionAskedKey = 'push_permission_asked_v1';

  /// Já mostramos o pedido de permissão (ou o assinante disse "Agora não").
  static Future<bool> permissionAlreadyAsked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_permissionAskedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markPermissionAsked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_permissionAskedKey, true);
    } catch (_) {}
  }

  /// Pede a permissão de notificações uma única vez, no momento certo
  /// (fim da apresentação ou após o primeiro login), nunca na abertura.
  Future<void> requestPermissionOnce() async {
    if (await permissionAlreadyAsked()) return;
    await markPermissionAsked();
    try {
      await _messaging
          .requestPermission(alert: true, badge: true, sound: true)
          .timeout(const Duration(minutes: 2));
    } catch (e) {
      debugPrint('ℹ️ Permissão de notificações indisponível: $e');
    }
  }

  /// Obtém o token FCM atual
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Inscreve em um tópico para notificações broadcast. Nunca falha nem
  /// segura quem chama: sem rede ou sem Google Play services o FCM pode
  /// ficar pendente indefinidamente.
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging
          .subscribeToTopic(topic)
          .timeout(const Duration(seconds: 10));
      debugPrint('🔔 Inscrito no tópico: $topic');
    } catch (e) {
      debugPrint('ℹ️ Tópico $topic não inscrito agora: $e');
    }
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
