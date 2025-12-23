// ARQUIVO: lib/core/services/push_notification_service.dart
// DESCRIÇÃO: Serviço de Push Notifications com Flutter Local Notifications

import 'package:flutter/foundation.dart';

/// Serviço para gerenciar push notifications (sem Firebase)
/// Usa flutter_local_notifications para notificações locais
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  bool _isInitialized = false;

  /// Inicializa o serviço de notificações
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Adicione flutter_local_notifications ao pubspec.yaml:
      // flutter_local_notifications: ^16.0.0

      debugPrint('[PushNotificationService] Inicializado com sucesso');
      _isInitialized = true;
    } catch (e) {
      debugPrint('[PushNotificationService] Erro ao inicializar: $e');
    }
  }

  /// Mostra notificação de fatura vencendo
  Future<void> showInvoiceDueNotification({
    required String invoiceId,
    required String dueDate,
    required double value,
  }) async {
    debugPrint(
        '[Notification] Fatura $invoiceId vence em $dueDate: R\$ $value');
    // Implementar com flutter_local_notifications quando o pacote for adicionado
  }

  /// Mostra notificação de conexão restaurada
  Future<void> showConnectionRestoredNotification() async {
    debugPrint('[Notification] Conexão restaurada');
  }

  /// Mostra notificação de liberação por confiança
  Future<void> showTrustUnlockNotification() async {
    debugPrint('[Notification] Internet liberada por 24h');
  }
}
