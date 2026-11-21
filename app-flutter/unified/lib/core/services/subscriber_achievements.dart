import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AchievementEvent {
  firstAccess,
  diagnostic,
  speed,
  wifi,
  trace,
  noticesRead
}

/// Eventos registrados neste dispositivo para a conta autenticada.
class SubscriberAchievements {
  static const prefix = 'subscriber_achievements_v1_';
  static final Map<String, Future<void>> _writes = {};

  static String _key(String providerId, String cpfCnpj) =>
      '$prefix${sha256.convert(utf8.encode('$providerId:${cpfCnpj.replaceAll(RegExp(r'[^0-9]'), '')}'))}';

  static Future<Map<String, DateTime>> load(
      String providerId, String cpfCnpj) async {
    final key = _key(providerId, cpfCnpj);
    await _writes[key];
    final prefs = await SharedPreferences.getInstance();
    try {
      final data = jsonDecode(prefs.getString(key) ?? '{}');
      if (data is! Map) return {};
      final result = <String, DateTime>{};
      for (final entry in data.entries) {
        final date = DateTime.tryParse(entry.value.toString());
        if (date != null) result[entry.key.toString()] = date;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<void> record(
      String providerId, String cpfCnpj, AchievementEvent event) {
    if (providerId.isEmpty ||
        cpfCnpj.replaceAll(RegExp(r'[^0-9]'), '').isEmpty) {
      return Future.value();
    }
    final key = _key(providerId, cpfCnpj);
    final previous = _writes[key] ?? Future<void>.value();
    final write = previous.catchError((_) {}).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> data;
      try {
        final parsed = jsonDecode(prefs.getString(key) ?? '{}');
        data = parsed is Map ? Map<String, dynamic>.from(parsed) : {};
      } catch (_) {
        data = {};
      }
      data.putIfAbsent(event.name, () => DateTime.now().toIso8601String());
      await prefs.setString(key, jsonEncode(data));
    });
    _writes[key] = write;
    return write.whenComplete(() {
      if (identical(_writes[key], write)) _writes.remove(key);
    });
  }
}
