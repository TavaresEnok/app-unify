/// Enum para tipos de notificação
enum NotificationType {
  info,
  warning,
  error,
  success,
  promotion,
}

/// Modelo para notificações in-app
class InAppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool read;
  final String? actionUrl;

  const InAppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.expiresAt,
    this.read = false,
    this.actionUrl,
  });

  /// Verifica se a notificação expirou
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Retorna uma cópia com os campos alterados
  InAppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? read,
    String? actionUrl,
  }) {
    return InAppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      read: read ?? this.read,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    return InAppNotification(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.info,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      read: json['read'] as bool? ?? false,
      actionUrl: json['actionUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'read': read,
      'actionUrl': actionUrl,
    };
  }
}
