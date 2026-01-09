// Achievement Service
// Manages unlocking and tracking of achievements

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import '../models/test_history.dart';

class AchievementService {
  static const String _key = 'achievements';

  // Check and unlock achievements based on test result
  Future<List<Achievement>> checkAchievements(
    List<TestHistoryEntry> history,
  ) async {
    final unlocked = <Achievement>[];
    final current = await getUnlockedAchievements();
    final currentTypes = current.map((a) => a.type).toSet();

    // First test
    if (!currentTypes.contains(AchievementType.firstTest) &&
        history.isNotEmpty) {
      unlocked.add(await _unlockAchievement(AchievementType.firstTest));
    }

    // Test count milestones
    if (!currentTypes.contains(AchievementType.tests5) && history.length >= 5) {
      unlocked.add(await _unlockAchievement(AchievementType.tests5));
    }
    if (!currentTypes.contains(AchievementType.tests10) &&
        history.length >= 10) {
      unlocked.add(await _unlockAchievement(AchievementType.tests10));
    }
    if (!currentTypes.contains(AchievementType.tests30) &&
        history.length >= 30) {
      unlocked.add(await _unlockAchievement(AchievementType.tests30));
    }

    if (history.isNotEmpty) {
      final latest = history.first;

      // Speed milestones
      if (!currentTypes.contains(AchievementType.speed100) &&
          latest.downloadSpeed >= 100) {
        unlocked.add(await _unlockAchievement(AchievementType.speed100));
      }
      if (!currentTypes.contains(AchievementType.speed500) &&
          latest.downloadSpeed >= 500) {
        unlocked.add(await _unlockAchievement(AchievementType.speed500));
      }

      // Perfect score
      if (!currentTypes.contains(AchievementType.perfectScore) &&
          latest.healthScore == 100) {
        unlocked.add(await _unlockAchievement(AchievementType.perfectScore));
      }

      // Time-based achievements
      final hour = latest.timestamp.hour;
      if (!currentTypes.contains(AchievementType.earlyBird) && hour < 6) {
        unlocked.add(await _unlockAchievement(AchievementType.earlyBird));
      }
      if (!currentTypes.contains(AchievementType.nightOwl) && hour >= 23) {
        unlocked.add(await _unlockAchievement(AchievementType.nightOwl));
      }
    }

    // Consistency check (5 days in a row)
    if (!currentTypes.contains(AchievementType.consistent)) {
      if (_checkConsistency(history)) {
        unlocked.add(await _unlockAchievement(AchievementType.consistent));
      }
    }

    return unlocked;
  }

  bool _checkConsistency(List<TestHistoryEntry> history) {
    if (history.length < 5) return false;

    final dates = history
        .map((e) {
          final dt = e.timestamp;
          return DateTime(dt.year, dt.month, dt.day);
        })
        .toSet()
        .toList()
      ..sort();

    int consecutiveDays = 1;
    for (int i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        consecutiveDays++;
        if (consecutiveDays >= 5) return true;
      } else {
        consecutiveDays = 1;
      }
    }
    return false;
  }

  Future<Achievement> _unlockAchievement(AchievementType type) async {
    final achievement = Achievement.fromType(type, unlockedAt: DateTime.now());
    final current = await getUnlockedAchievements();
    current.add(achievement);
    await _saveAchievements(current);
    return achievement;
  }

  Future<List<Achievement>> getUnlockedAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => Achievement.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Achievement>> getAllAchievements() async {
    final unlocked = await getUnlockedAchievements();
    final unlockedTypes = unlocked.map((a) => a.type).toSet();

    return AchievementType.values.map((type) {
      final existing = unlocked.firstWhere(
        (a) => a.type == type,
        orElse: () => Achievement.fromType(type),
      );
      return existing;
    }).toList();
  }

  Future<void> _saveAchievements(List<Achievement> achievements) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = achievements.map((a) => a.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  Future<int> getUnlockedCount() async {
    final unlocked = await getUnlockedAchievements();
    return unlocked.length;
  }
}
