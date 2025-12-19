class ProviderModel {
  final String id;
  final String name;
  final String? logoUrl;
  final String? themeColor;
  final String? apiUrl;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? details;
  final Map<String, dynamic>? features;
  final Map<String, dynamic>? notifications;
  final Map<String, dynamic>? appConfig;

  ProviderModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.themeColor,
    this.apiUrl,
    this.active = true,
    this.createdAt,
    this.updatedAt,
    this.details,
    this.features,
    this.notifications,
    this.appConfig,
  });

  factory ProviderModel.fromMap(Map<String, dynamic> map, String id) {
    return ProviderModel(
      id: id,
      name: map['name'] ?? 'Sem nome',
      logoUrl: map['logoUrl'],
      themeColor: map['themeColor'],
      apiUrl: map['apiUrl'],
      active: map['active'] ?? true,
      createdAt: map['createdAt'] is String
          ? DateTime.tryParse(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] is String
          ? DateTime.tryParse(map['updatedAt'])
          : null,
      details: map['details'],
      features: map['features'],
      notifications: map['notifications'],
      appConfig: map['config'] ?? map['appConfig'], // Read from 'config' first
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'themeColor': themeColor,
      'apiUrl': apiUrl,
      'active': active,
      'details': details,
      'features': features,
      'notifications': notifications,
      'config': appConfig, // Save to 'config' to match Web Admin
    };
  }

  ProviderModel copyWith({
    String? name,
    String? logoUrl,
    String? themeColor,
    String? apiUrl,
    bool? active,
    Map<String, dynamic>? details,
    Map<String, dynamic>? features,
    Map<String, dynamic>? notifications,
    Map<String, dynamic>? appConfig,
  }) {
    return ProviderModel(
      id: id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      themeColor: themeColor ?? this.themeColor,
      apiUrl: apiUrl ?? this.apiUrl,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: updatedAt,
      details: details ?? this.details,
      features: features ?? this.features,
      notifications: notifications ?? this.notifications,
      appConfig: appConfig ?? this.appConfig,
    );
  }
}
