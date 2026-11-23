import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/onu_wifi_service.dart';
import '../services/tr069_service.dart';
import 'providers.dart';

/// A rede gerenciável é anunciada quando a integração TR-069/ACS (GenieACS,
/// Anlix Flashman ou SGP CPE Manager) está ativa para o provedor ou quando o
/// contrato responde com redes Wi-Fi gerenciáveis.
final wifiManagementAvailableProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final config = ref.watch(configurationProvider).providerConfig;
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (config == null || user == null) return false;

  final tr069 = Tr069Service(apiUrl: config.apiUrl);
  ref.onDispose(tr069.dispose);
  try {
    final caps = await tr069.fetchCapabilities();
    if (caps.enabled) return true;
  } catch (_) {}

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
