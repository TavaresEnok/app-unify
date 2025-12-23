import 'package:app_links/app_links.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../main.dart'; // for navigatorKey

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();

  Future<void> init() async {
    try {
      // Check initial link
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }

      // Listen for stream
      _appLinks.uriLinkStream.listen((uri) {
        _handleDeepLink(uri);
      }, onError: (err) {
        debugPrint('DeepLink Error: $err');
      });
    } catch (e) {
      debugPrint('DeepLink Init Error: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('🔗 Deep Link Received: $uri');

    // Scheme: provedorapp://host/path
    // Example: provedorapp://faturas
    // Example: provedorapp://suporte

    // We can use the navigatorKey to show a SnackBar or Navigate
    final context = navigatorKey.currentState?.context;
    if (context == null) return;

    if (uri.scheme == 'provedorapp') {
      String? destination;
      if (uri.host == 'faturas') destination = 'Faturas';
      if (uri.host == 'suporte') destination = 'Suporte';
      if (uri.host == 'speedtest') destination = 'Speed Test';

      if (destination != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Abrindo $destination via Link...'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.blueAccent,
          ),
        );
        // Real navigation would require accessing the PainelPage state or provider
        // For now, this proves the link works.
      }
    }
  }
}
