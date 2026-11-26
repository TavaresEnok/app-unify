import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado da rede do celular.
///
/// - Começa com a leitura atual (o aviso de "sem rede" aparece mesmo quando
///   o app abre sem conexão; o Android só avisa mudanças).
/// - Uma queda para "sem rede" só vale se durar [noneGrace]: na troca do
///   Wi-Fi para os dados móveis o Android avisa "nenhuma" por um instante.
final connectivityStatusProvider = StreamProvider<ConnectivityResult>((ref) {
  final connectivity = Connectivity();
  return seededConnectivity(
    connectivity.checkConnectivity,
    connectivity.onConnectivityChanged,
  );
});

@visibleForTesting
Stream<ConnectivityResult> seededConnectivity(
  Future<ConnectivityResult> Function() check,
  Stream<ConnectivityResult> changes, {
  Duration noneGrace = const Duration(seconds: 2),
}) {
  late StreamController<ConnectivityResult> controller;
  StreamSubscription<ConnectivityResult>? sub;
  Timer? pendingNone;
  ConnectivityResult? last;
  var seeded = false;

  void emit(ConnectivityResult value) {
    if (controller.isClosed || value == last) return;
    last = value;
    controller.add(value);
  }

  controller = StreamController<ConnectivityResult>(
    onListen: () {
      sub = changes.listen((value) {
        seeded = true;
        pendingNone?.cancel();
        if (value == ConnectivityResult.none && last != null) {
          pendingNone = Timer(noneGrace, () => emit(value));
        } else {
          emit(value);
        }
      }, onError: controller.addError);
      check().then((value) {
        // Um evento real que chegou antes vale mais que a leitura inicial.
        if (!seeded) emit(value);
      }).catchError((_) {});
    },
    onCancel: () async {
      pendingNone?.cancel();
      await sub?.cancel();
    },
  );
  return controller.stream;
}

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
