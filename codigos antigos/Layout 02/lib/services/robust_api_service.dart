import 'package:flutter/foundation.dart';

/// RobustApiService - API calls with automatic retry logic
///
/// Features:
/// - Automatic retry on failure
/// - Exponential backoff
/// - Timeout handling
/// - Error logging
class RobustApiService {
  static const int maxRetries = 3;
  static const Duration initialDelay = Duration(seconds: 1);
  static const Duration timeout = Duration(seconds: 30);

  /// Execute operation with retry logic
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int retries = maxRetries,
    Duration? customTimeout,
  }) async {
    int attempt = 0;

    while (attempt < retries) {
      try {
        debugPrint('🔄 Tentativa ${attempt + 1}/$retries');

        return await operation().timeout(customTimeout ?? timeout);
      } catch (e) {
        attempt++;

        if (attempt >= retries) {
          debugPrint('❌ Falhou após $retries tentativas: $e');
          rethrow;
        }

        // Exponential backoff
        final delay = initialDelay * (1 << (attempt - 1));
        debugPrint('⏳ Aguardando ${delay.inSeconds}s antes de retentar...');

        await Future.delayed(delay);
      }
    }

    throw Exception('Operação falhou após $retries tentativas');
  }

  /// Execute multiple operations in parallel with retry
  static Future<List<T>> executeMultipleWithRetry<T>(
    List<Future<T> Function()> operations,
  ) async {
    return await Future.wait(
      operations.map((op) => executeWithRetry(op)),
    );
  }
}
