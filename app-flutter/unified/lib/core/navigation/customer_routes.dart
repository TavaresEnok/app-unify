import '../models/provider_config.dart';

/// Stable destinations across themes and old provider configurations.
abstract final class CustomerRoutes {
  static String normalize(String route) =>
      const {
        'home': 'dashboard',
        'financeiro': 'invoices',
        'financial': 'invoices',
        'payment_promise': 'trust_unlock',
        'faturas': 'invoices',
        'diagnostico': 'network_diagnostic',
        'diagnostics': 'network_diagnostic',
        'speedtest': 'speed_test',
        'speedTest': 'speed_test',
        'suporte': 'support',
        'notificacoes': 'notifications',
        'perfil': 'account',
        'profile': 'account',
        'planos': 'support',
        'consumo': 'internet_usage',
        'consumption': 'internet_usage',
        'tracert': 'trace_route',
        'router': 'wifi',
        'history': 'history',
      }[route] ??
      route;

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
