import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logLogin() async {
    try {
      await _analytics.logLogin(loginMethod: 'cpf');
      debugPrint('Analytics: Login Logged');
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      debugPrint('Analytics: Screen View $screenName');
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      debugPrint('Analytics: Event $name logged');
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }
}
