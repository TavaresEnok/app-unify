import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'push_notification_service.dart';

/// Links `provedorapp://faturas` (e `provedorapp://suporte`, etc.) abrem a
/// mesma tela que o toque numa notificação com essa rota.
class DeepLinkService {
  final AppLinks _appLinks = AppLinks();

  Future<void> init() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleDeepLink(initialUri);
      _appLinks.uriLinkStream.listen(_handleDeepLink, onError: (err) {
        debugPrint('DeepLink Error: $err');
      });
    } catch (e) {
      debugPrint('DeepLink Init Error: $e');
    }
  }

  /// `provedorapp://faturas` → `/faturas`.
  static String? routeFor(Uri uri) {
    if (uri.scheme != 'provedorapp') return null;
    final route = '/${uri.host}${uri.path}'.replaceAll(RegExp(r'/+$'), '');
    return route == '/' || route.isEmpty ? null : route;
  }

  void _handleDeepLink(Uri uri) {
    final route = routeFor(uri);
    if (route == null) return;
    PushNotificationService().openRoute(route);
  }
}
