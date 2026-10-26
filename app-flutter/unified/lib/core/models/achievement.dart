// Achievement Model
// Gamification system for user engagement

import 'package:flutter/material.dart';

enum AchievementType {
  firstTest,
  tests5,
  tests10,
  tests30,
  speed100,
  speed500,
  perfectScore,
  earlyBird,
  nightOwl,
  consistent,
}

class Achievement {
  final AchievementType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final DateTime? unlockedAt;

  const Achievement({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  static Achievement fromType(AchievementType type, {DateTime? unlockedAt}) {
    switch (type) {
      case AchievementType.firstTest:
        return Achievement(
          type: type,
          title: 'Primeiro Passo',
          description: 'Execute seu primeiro diagnóstico',
          icon: Icons.rocket_launch,
          color: const Color(0xFF00F5FF),
          unlockedAt: unlockedAt,
        );
      case AchievementType.tests5:
        return Achievement(
          type: type,
          title: 'Explorador',
          description: 'Complete 5 diagnósticos',
          icon: Icons.explore,
          color: const Color(0xFF8B5CF6),
          unlockedAt: unlockedAt,
        );
      case AchievementType.tests10:
        return Achievement(
          type: type,
          title: 'Expert',
          description: 'Complete 10 diagnósticos',
          icon: Icons.emoji_events,
          color: const Color(0xFFF59E0B),
          unlockedAt: unlockedAt,
        );
      case AchievementType.tests30:
        return Achievement(
          type: type,
          title: 'Mestre',
          description: 'Complete 30 diagnósticos',
          icon: Icons.workspace_premium,
          color: const Color(0xFFFFD700),
          unlockedAt: unlockedAt,
        );
      case AchievementType.speed100:
        return Achievement(
          type: type,
          title: 'Velocidade Raio',
          description: 'Alcance 100+ Mbps',
          icon: Icons.flash_on,
          color: const Color(0xFF00FF88),
          unlockedAt: unlockedAt,
        );
      case AchievementType.speed500:
        return Achievement(
          type: type,
          title: 'Ultra Velocidade',
          description: 'Alcance 500+ Mbps',
          icon: Icons.bolt,
          color: const Color(0xFFFF6B00),
          unlockedAt: unlockedAt,
        );
      case AchievementType.perfectScore:
        return Achievement(
          type: type,
          title: 'Perfeição',
          description: 'Obtenha score 100/100',
          icon: Icons.star,
          color: const Color(0xFFFFD700),
          unlockedAt: unlockedAt,
        );
      case AchievementType.earlyBird:
        return Achievement(
          type: type,
          title: 'Madrugador',
          description: 'Teste antes das 6h',
          icon: Icons.wb_sunny,
          color: const Color(0xFFFFA500),
          unlockedAt: unlockedAt,
        );
      case AchievementType.nightOwl:
        return Achievement(
          type: type,
          title: 'Coruja Noturna',
          description: 'Teste depois das 23h',
          icon: Icons.nightlight,
          color: const Color(0xFF4B0082),
          unlockedAt: unlockedAt,
        );
      case AchievementType.consistent:
        return Achievement(
          type: type,
          title: 'Consistente',
          description: 'Teste 5 dias seguidos',
          icon: Icons.calendar_today,
          color: const Color(0xFF10B981),
          unlockedAt: unlockedAt,
        );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = AchievementType.values.firstWhere(
      (e) => e.toString() == typeStr,
    );
    final unlockedAt = json['unlockedAt'] != null
        ? DateTime.parse(json['unlockedAt'] as String)
        : null;
    return Achievement.fromType(type, unlockedAt: unlockedAt);
  }
}
