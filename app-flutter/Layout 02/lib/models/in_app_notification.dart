import 'package:flutter/material.dart';

enum NotificationType {
  info,
  warning,
  success,
  error,
  maintenance,
}

class InAppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool read;
  final String? actionUrl;
  final IconData? icon;

  InAppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.expiresAt,
    this.read = false,
    this.actionUrl,
    this.icon,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  InAppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? read,
    String? actionUrl,
    IconData? icon,
  }) {
    return InAppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      read: read ?? this.read,
      actionUrl: actionUrl ?? this.actionUrl,
      icon: icon ?? this.icon,
    );
  }

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    return InAppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: NotificationType.values.byName(json['type'] as String),
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
      'title': title,
      'message': message,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'read': read,
      'actionUrl': actionUrl,
    };
  }
}
