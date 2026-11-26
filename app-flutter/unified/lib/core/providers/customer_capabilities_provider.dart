import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/onu_wifi_service.dart';
import 'equipment_status_provider.dart';
import 'providers.dart';

/// A rede gerenciável é anunciada quando a integração TR-069/ACS (GenieACS,
/// Anlix Flashman ou SGP CPE Manager) está ativa para o provedor e o serviço
/// do assinante tem roteador gerenciado (`deviceManaged`). Só quando a
/// consulta de recursos falha é que se tenta a lista de redes do contrato.
///
/// - Fica viva durante a sessão: trocar de aba não refaz a consulta (cada
///   consulta pode custar uma ida ao ERP).
/// - Só recalcula quando muda o provedor, a URL da API ou a conta, e no
///   "puxar para atualizar" / abertura do app ([refreshWifiAvailability]).
/// - A última resposta da conta fica guardada no aparelho e aparece na hora;
///   a resposta nova a substitui quando chega. Assim a linha "Minha rede
///   Wi‑Fi" não surge do nada a cada visita.
final wifiManagementAvailableProvider = FutureProvider<bool>((ref) async {
  final config = ref.watch(configurationProvider.select((c) {
    final p = c.providerConfig;
    return p == null ? null : (id: p.id, apiUrl: p.apiUrl);
  }));
  final account = ref.watch(authNotifierProvider.select((a) {
    final u = a.valueOrNull;
    return u == null ? null : (cpf: u.cpfCnpj, contrato: u.contratoId);
  }));
  if (config == null || account == null) return false;

  var disposed = false;
  ref.onDispose(() => disposed = true);

  final key =
      'wifi_mgmt_available.${sha256.convert(utf8.encode('${config.id}|${account.contrato ?? ''}|${account.cpf}')).toString().substring(0, 24)}';
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {}
  final remembered = prefs?.getBool(key);

  Future<bool> check() async {
    final tr069 = ref.read(tr069ServiceFactoryProvider)(config.apiUrl);
    ref.onDispose(tr069.dispose);
    final caps = await tr069.fetchCapabilitiesOrNull(
        contratoId: account.contrato?.toString());
    // O servidor respondeu: vale o que ele diz. Com o gerenciador ligado,
    // só aparece para quem tem roteador gerenciado no próprio serviço
    // (deviceManaged ausente = servidor antigo, segue como antes). Sem
    // gerenciador, a consulta direta ao CPE do ERP sempre falharia.
    if (caps != null) return caps.manageable;

    final service = OnuWifiService(
      apiUrl: config.apiUrl,
      cpfCnpj: account.cpf,
      contrato: account.contrato?.toString(),
      providerId: config.id,
    );
    ref.onDispose(service.dispose);
    try {
      return (await service.fetchWifiNetworks()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  final fresh = check().then((value) {
    unawaited(prefs?.setBool(key, value).catchError((_) => false));
    return value;
  });
  if (remembered == null) return fresh;
  unawaited(fresh.then((value) {
    if (!disposed && value != remembered) ref.state = AsyncData(value);
  }, onError: (_) {}));
  return remembered;
});

/// Refaz a consulta (abertura do app e "puxar para atualizar").
void refreshWifiAvailability(WidgetRef ref) =>
    ref.invalidate(wifiManagementAvailableProvider);
