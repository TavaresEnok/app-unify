// ARQUIVO: lib/local_notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static void initialize() {
    // O nome 'ic_stat_notification' deve ser o mesmo nome do seu arquivo de ícone
    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings("@drawable/ic_stat_notification"),
    );
    _notificationsPlugin.initialize(initializationSettings);
  }

  static void showNotification(RemoteMessage message) {
    if (message.notification != null) {
      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          "app_provedor_channel_id", // ID do Canal
          "Notificações do App",     // Nome do Canal
          channelDescription: "Canal para notificações gerais do app",
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      );

      _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch % 2147483647,
        message.notification!.title,
        message.notification!.body,
        notificationDetails,
      );
    }
  }
}
