import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message, [dynamic error]) {
    if (kDebugMode) {
      print("📝 $message");
      if (error != null) {
        print("🔴 ERRO: $error");
      }
    }
  }
}
