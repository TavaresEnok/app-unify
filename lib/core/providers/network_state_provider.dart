import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// Estado da conexão de rede
enum NetworkConnectionStatus {
  unknown,
  wifi,
  mobileData,
  ethernet,
  disconnected,
}

/// Informações da conexão de rede
class NetworkState {
  final NetworkConnectionStatus status;
  final String? wifiName; // SSID
  final String? wifiIP;
  final bool isConnectedToInternet;

  const NetworkState({
    this.status = NetworkConnectionStatus.unknown,
    this.wifiName,
    this.wifiIP,
    this.isConnectedToInternet = false,
  });

  bool get isWifi => status == NetworkConnectionStatus.wifi;
  bool get isMobileData => status == NetworkConnectionStatus.mobileData;
  bool get isOffline => status == NetworkConnectionStatus.disconnected;

  /// Verifica se está em Wi-Fi externo (não do provedor)
  /// Critério simples: se não contiver o nome do provedor no SSID
  bool isExternalWifi(String? providerName) {
    if (!isWifi || wifiName == null || providerName == null) return false;
    return !wifiName!.toLowerCase().contains(providerName.toLowerCase());
  }

  NetworkState copyWith({
    NetworkConnectionStatus? status,
    String? wifiName,
    String? wifiIP,
    bool? isConnectedToInternet,
  }) {
    return NetworkState(
      status: status ?? this.status,
      wifiName: wifiName ?? this.wifiName,
      wifiIP: wifiIP ?? this.wifiIP,
      isConnectedToInternet:
          isConnectedToInternet ?? this.isConnectedToInternet,
    );
  }
}

/// Provider para o estado de conectividade da rede
class NetworkStateNotifier extends StateNotifier<NetworkState> {
  StreamSubscription<ConnectivityResult>? _subscription;
  final NetworkInfo _networkInfo = NetworkInfo();

  NetworkStateNotifier() : super(const NetworkState()) {
    _init();
  }

  void _init() {
    // Verifica estado inicial
    _checkConnectivity();

    // Escuta mudanças - connectivity_plus listener recebe ConnectivityResult
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      _updateStateFromResult(result);
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      await _updateStateFromResult(result);
    } catch (e) {
      state = const NetworkState(
        status: NetworkConnectionStatus.unknown,
        isConnectedToInternet: false,
      );
    }
  }

  Future<void> _updateStateFromResult(ConnectivityResult result) async {
    NetworkConnectionStatus status;
    String? wifiName;
    String? wifiIP;

    switch (result) {
      case ConnectivityResult.wifi:
        status = NetworkConnectionStatus.wifi;
        try {
          wifiName = await _networkInfo.getWifiName();
          wifiIP = await _networkInfo.getWifiIP();
          wifiName = wifiName?.replaceAll('"', '');
        } catch (_) {}
        break;
      case ConnectivityResult.mobile:
        status = NetworkConnectionStatus.mobileData;
        break;
      case ConnectivityResult.ethernet:
        status = NetworkConnectionStatus.ethernet;
        break;
      case ConnectivityResult.none:
        status = NetworkConnectionStatus.disconnected;
        break;
      default:
        status = NetworkConnectionStatus.unknown;
    }

    state = NetworkState(
      status: status,
      wifiName: wifiName,
      wifiIP: wifiIP,
      isConnectedToInternet: status != NetworkConnectionStatus.disconnected,
    );
  }

  /// Força uma nova verificação do estado de rede
  Future<void> refresh() => _checkConnectivity();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider global de estado de rede
final networkStateProvider =
    StateNotifierProvider<NetworkStateNotifier, NetworkState>((ref) {
  return NetworkStateNotifier();
});
