import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/tr069_service.dart';
import 'providers.dart';

/// Cria o cliente TR-069 (trocado nos testes).
final tr069ServiceFactoryProvider = Provider<Tr069Service Function(String?)>(
    (ref) => (apiUrl) => Tr069Service(apiUrl: apiUrl));

/// Estado do equipamento do assinante (fibra e roteador) para o cartão
/// "Seu equipamento".
class EquipmentStatus {
  final Tr069Overview? overview;

  /// A consulta falhou: o cartão diz que o status está indisponível, em vez
  /// de mostrar um "Online" que ninguém confirmou.
  final bool failed;

  const EquipmentStatus({this.overview, this.failed = false});

  Tr069Fiber? get fiber => overview?.fiber;
}

/// Só existe para provedores com gerenciador TR-069 ligado. `null` quando
/// não há o que mostrar (sem gerenciador, ou sem fibra nem roteador).
final equipmentStatusProvider =
    FutureProvider.autoDispose<EquipmentStatus?>((ref) async {
  final config = ref.watch(configurationProvider.select((c) {
    final p = c.providerConfig;
    return p == null ? null : (id: p.id, apiUrl: p.apiUrl);
  }));
  final contrato = ref.watch(authNotifierProvider
      .select((a) => a.valueOrNull?.contratoId?.toString()));
  final logged =
      ref.watch(authNotifierProvider.select((a) => a.valueOrNull != null));
  if (config == null || !logged) return null;

  final tr069 = ref.read(tr069ServiceFactoryProvider)(config.apiUrl);
  ref.onDispose(tr069.dispose);
  final caps = await tr069.fetchCapabilitiesOrNull(contratoId: contrato);
  if (caps == null || !caps.enabled) return null;
  try {
    final overview = await tr069.fetchStatus(contratoId: contrato);
    if (overview == null) return null;
    if (overview.fiber == null && !overview.hasRouter) return null;
    return EquipmentStatus(overview: overview);
  } on Tr069Exception catch (e) {
    // Sem roteador gerenciado e sem dados da fibra: nada a mostrar.
    if (e.unmanaged) return null;
    return const EquipmentStatus(failed: true);
  } catch (_) {
    return const EquipmentStatus(failed: true);
  }
});
