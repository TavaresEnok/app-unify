import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../services/diagnostico_service.dart';
import '../services/onu_wifi_service.dart';

/// Lifecycle shared by every diagnostic design. Rebinds when the account,
/// contract or API changes, including configuration arriving after first paint.
class DiagnosticBinding {
  final WidgetRef ref;
  final BuildContext context;
  final void Function(DiagnosticoService?, OnuWifiService?) onChanged;
  final List<ProviderSubscription<dynamic>> _subscriptions = [];
  DiagnosticoService? _service;
  OnuWifiService? _onu;
  Object? _identity;
  bool _disposed = false;
  bool _scheduled = false;

  DiagnosticBinding(this.ref, this.context, this.onChanged) {
    _subscriptions
        .add(ref.listenManual(configurationProvider, (_, __) => _schedule()));
    _subscriptions
        .add(ref.listenManual(authNotifierProvider, (_, __) => _schedule()));
    _schedule();
  }

  void _schedule() {
    if (_disposed || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (_disposed || !context.mounted) return;
      final config = ref.read(configurationProvider).providerConfig;
      final user = ref.read(authNotifierProvider).valueOrNull;
      final identity =
          (config?.id, config?.apiUrl, user?.cpfCnpj, user?.contratoId);
      if (identity == _identity) return;
      _identity = identity;
      _service?.dispose();
      _onu?.dispose();
      _service = null;
      _onu = null;
      if (config != null && user != null) {
        _onu = OnuWifiService(
            apiUrl: config.apiUrl,
            cpfCnpj: user.cpfCnpj,
            contrato: user.contratoId?.toString(),
            providerId: config.id);
        _service = DiagnosticoService(
            providerConfig: config, context: context, onuService: _onu);
      }
      onChanged(_service, _onu);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  bool ensureReady() {
    if (_service?.canStart == true) return true;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_service == null
              ? 'Aguarde a configuração e entre com sua conta para iniciar.'
              : 'Aguarde o teste atual encerrar.')));
    }
    return false;
  }

  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      subscription.close();
    }
    _service?.dispose();
    _onu?.dispose();
  }
}
