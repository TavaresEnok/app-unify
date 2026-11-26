import '../models/provider_config.dart';

/// Stable destinations across themes and old provider configurations.
abstract final class CustomerRoutes {
  static String normalize(String route) {
    // Rotas de push podem vir com detalhe ("/suporte/chamado/123") ou
    // parâmetros ("/faturas?id=1"): vale o primeiro trecho conhecido.
    var cleaned = route.trim().split(RegExp(r'[?#]')).first;
    cleaned = cleaned.replaceFirst(RegExp(r'^/+'), '');
    final direct = _alias(cleaned);
    if (direct != cleaned || !cleaned.contains('/')) return direct;
    return _alias(cleaned.split('/').first);
  }

  static String _alias(String cleaned) {
    return const {
          'home': 'dashboard',
          'inicio': 'dashboard',
          'financeiro': 'invoices',
          'financial': 'invoices',
          'payment_promise': 'trust_unlock',
          'faturas': 'invoices',
          'fatura': 'invoices',
          'invoice': 'invoices',
          'boleto': 'invoices',
          'diagnostico': 'network_diagnostic',
          'diagnostics': 'network_diagnostic',
          'speedtest': 'speed_test',
          'speedTest': 'speed_test',
          'velocidade': 'speed_test',
          'suporte': 'support',
          // Respostas de chamado chegam por push; a conversa fica com o
          // atendimento do provedor, então o toque abre o Suporte.
          'chamado': 'support',
          'chamados': 'support',
          'ticket': 'support',
          'tickets': 'support',
          'notificacoes': 'notifications',
          'perfil': 'account',
          'profile': 'account',
          'planos': 'support',
          'consumo': 'internet_usage',
          'consumption': 'internet_usage',
          'tracert': 'trace_route',
          'router': 'wifi',
          'contrato': 'contract',
          'promocoes': 'promotions',
          'ofertas': 'promotions',
          'history': 'history',
        }[cleaned] ??
        cleaned;
  }

  /// Destinos que o app sabe abrir (abas e páginas). Fora desta lista, um
  /// toque cairia na página "Recurso indisponível".
  static const known = {
    'dashboard',
    'invoices',
    'trust_unlock',
    'connection',
    'support',
    'promotions',
    'services',
    'account',
    'network_diagnostic',
    'wifi',
    'speed_test',
    'ping',
    'trace_route',
    'my_ip',
    'internet_usage',
    'contract',
    'notifications',
    'faq',
    'history',
    'achievements',
  };

  static bool enabled(ProviderConfig config, String route) {
    final normalized = normalize(route);
    if ((normalized == 'invoices' || normalized == 'trust_unlock') &&
        !config.features.invoices) {
      return false;
    }
    if (normalized == 'support' && !config.features.support) return false;
    if (normalized == 'internet_usage' && !config.features.consumption) {
      return false;
    }
    for (final entry in config.menuConfig.items.entries) {
      final itemRoute = normalize(entry.key);
      if ((itemRoute == normalized ||
              (normalized == 'trust_unlock' && itemRoute == 'invoices')) &&
          !entry.value.enabled) {
        return false;
      }
    }
    return true;
  }
}
