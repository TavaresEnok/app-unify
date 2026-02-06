class InAppNotification {
  final String id;
  final String title;
  final String message;
  final String category;
  final String priority;
  final String? icon;
  final String? imageUrl;
  final String? actionLabel;
  final String? actionUrl;
  final bool dismissible;
  final bool read;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const InAppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.priority,
    this.icon,
    this.imageUrl,
    this.actionLabel,
    this.actionUrl,
    required this.dismissible,
    required this.read,
    required this.createdAt,
    this.expiresAt,
  });

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    return InAppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      category: json['category'] ?? 'info',
      priority: json['priority'] ?? 'normal',
      icon: json['icon'],
      imageUrl: json['imageUrl'],
      actionLabel: json['actionLabel'],
      actionUrl: json['actionUrl'],
      dismissible: json['dismissible'] ?? true,
      read: json['read'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isActive => !isExpired && !read;

  InAppNotification copyWith({bool? read}) {
    return InAppNotification(
      id: id,
      title: title,
      message: message,
      category: category,
      priority: priority,
      icon: icon,
      imageUrl: imageUrl,
      actionLabel: actionLabel,
      actionUrl: actionUrl,
      dismissible: dismissible,
      read: read ?? this.read,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }
}
