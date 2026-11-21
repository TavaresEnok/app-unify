import 'package:flutter/material.dart';
import '../services/onu_wifi_service.dart';

class WifiState {
  final bool isLoading;
  final String? error;
  final List<WifiNetwork> networks;
  WifiState({this.isLoading = false, this.error, this.networks = const []});
}

class WifiManagementController extends ValueNotifier<WifiState> {
  final OnuWifiService? _service;
  bool _disposed = false;
  Future<void>? _fetch;
  bool _updating = false;
  WifiManagementController(this._service) : super(WifiState());

  void _publish(WifiState state) {
    if (!_disposed) value = state;
  }

  Future<void> fetchNetworks() {
    if (_disposed) return Future.value();
    return _fetch ??= _load().whenComplete(() => _fetch = null);
  }

  Future<void> _load() async {
    if (_service == null) {
      _publish(WifiState(
          error:
              'Aguarde a configuração e entre com sua conta para consultar o Wi-Fi.'));
      return;
    }
    _publish(WifiState(isLoading: true, networks: value.networks));
    try {
      final networks = await _service.fetchWifiNetworks();
      _publish(WifiState(networks: networks));
    } catch (e) {
      _publish(WifiState(error: e.toString(), networks: value.networks));
    }
  }

  Future<bool> updateWifi(
      BuildContext context, String wifiId, String ssid, String password) async {
    if (_disposed || _updating || _service == null) return false;
    _updating = true;
    _publish(WifiState(isLoading: true, networks: value.networks));
    try {
      // Finish an earlier read before refreshing the result of this mutation.
      await _fetch;
      final updated = await _service.updateWifi(
          wifiId: wifiId, ssid: ssid, password: password);
      if (!updated) {
        throw StateError('O equipamento não confirmou a alteração.');
      }
      if (_disposed) return false;
      await fetchNetworks();
      if (context.mounted && !_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(value.error == null
                ? 'Wi-Fi atualizado com sucesso!'
                : 'Alteração enviada. Não foi possível atualizar a lista; consulte novamente.')));
      }
      return true;
    } catch (e) {
      _publish(WifiState(error: e.toString(), networks: value.networks));
      if (context.mounted && !_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Não conseguimos confirmar a alteração do Wi-Fi. Consulte a rede novamente antes de tentar alterar.')));
      }
      return false;
    } finally {
      _updating = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
