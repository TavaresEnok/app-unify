import 'package:flutter/material.dart';
import '../services/onu_wifi_service.dart';

class WifiState {
  final bool isLoading;
  final String? error;
  final List<WifiNetwork> networks;

  WifiState({
    this.isLoading = false,
    this.error,
    this.networks = const [],
  });
}

class WifiManagementController extends ValueNotifier<WifiState> {
  final OnuWifiService? _service;

  WifiManagementController(this._service) : super(WifiState());

  Future<void> fetchNetworks() async {
    if (_service == null) return;

    value = WifiState(isLoading: true, networks: value.networks);

    try {
      final networks = await _service.fetchWifiNetworks();
      value = WifiState(isLoading: false, networks: networks);
    } catch (e) {
      value = WifiState(
          isLoading: false, error: e.toString(), networks: value.networks);
    }
  }

  Future<void> updateWifi(
      BuildContext context, String wifiId, String ssid, String password) async {
    if (_service == null) return;

    // Optimistic or waiting? Let's wait.
    try {
      await _service.updateWifi(wifiId: wifiId, ssid: ssid, password: password);
      // Refresh list after update
      await fetchNetworks();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WiFi atualizado com sucesso!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar WiFi: $e')),
        );
      }
    }
  }
}
