import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  bool _isEnabled = true;
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      _isInitialized = true;
      debugPrint('📊 Analytics inicializado');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar analytics: $e');
    }
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  void logEvent(String name, {Map<String, dynamic>? parameters}) {
    if (!_isEnabled || !_isInitialized) return;
    debugPrint('📊 Event: $name | Params: $parameters');
  }

  void logScreen(String screenName) {
    if (!_isEnabled || !_isInitialized) return;
    debugPrint('📊 Screen: $screenName');
  }

  void logUnlockTrust(bool success, {String? error}) {
    logEvent('unlock_trust', parameters: {
      'success': success,
      if (error != null) 'error': error,
    });
  }
}
