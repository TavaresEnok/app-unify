import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Account-scoped summaries only. Raw network details and credentials are never stored here.
class DiagnosticHistoryStore {
  final String _key;
  static Future<void> _writes = Future.value();
  DiagnosticHistoryStore(String provider, String account)
      : _key =
            'diagnostics.v2.${base64Url.encode(utf8.encode('$provider|$account'))}';

  Future<List<Map<String, dynamic>>> read() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = jsonDecode(prefs.getString(_key) ?? '[]');
      return (value as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(Map<String, dynamic> entry) {
    final task = _writes.then((_) async {
      final items = await read();
      items.removeWhere((e) => e['id'] == entry['id']);
      items.insert(0, entry);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(items.take(20).toList()));
    });
    _writes = task.catchError((Object _) {});
    return task;
  }

  Future<void> clear() async {
    await _writes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
