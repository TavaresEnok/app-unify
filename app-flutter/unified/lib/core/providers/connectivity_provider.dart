import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the current connectivity status stream
final connectivityStatusProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Easy check if online
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityStatusProvider);

  return connectivityAsync.when(
    data: (result) {
      if (result == ConnectivityResult.none) return false;
      return true; // WiFi, Mobile, Ethernet, VPN, etc -> Online
    },
    error: (_, __) => true, // Assume online on error to avoid blocking
    loading: () => true, // Assume online while loading
  );
});
