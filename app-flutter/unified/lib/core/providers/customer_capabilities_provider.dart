import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/onu_wifi_service.dart';
import 'providers.dart';

/// A rede gerenciável só é anunciada quando a integração respondeu com redes
/// para o contrato selecionado. Falhas deixam o atalho oculto e podem ser
/// consultadas novamente ao atualizar a tela ou trocar de contrato.
final wifiManagementAvailableProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final config = ref.watch(configurationProvider).providerConfig;
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (config == null || user == null) return false;

  final service = OnuWifiService(
    apiUrl: config.apiUrl,
    cpfCnpj: user.cpfCnpj,
    contrato: user.contratoId?.toString(),
    providerId: config.id,
  );
  ref.onDispose(service.dispose);
  try {
    return (await service.fetchWifiNetworks()).isNotEmpty;
  } catch (_) {
    return false;
  }
});
