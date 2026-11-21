/// Preserve reverse-proxy prefixes (for example /api) when joining routes.
/// Some legacy callers supply an invoice endpoint instead of the API root.
Uri apiEndpoint(String configuredUrl, String route) {
  final uri = Uri.parse(configuredUrl.trim());
  if (!uri.hasAuthority ||
      !['http', 'https'].contains(uri.scheme) ||
      uri.userInfo.isNotEmpty) {
    throw const FormatException('Endereço da API inválido.');
  }
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  const legacyEndpoints = {
    'get-invoices',
    'getInvoices',
    'getClientData',
    'get-consumption-data',
    'getConsumptionData'
  };
  if (segments.isNotEmpty && legacyEndpoints.contains(segments.last))
    segments.removeLast();
  return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      pathSegments: [
        ...segments,
        ...route.split('/').where((s) => s.isNotEmpty)
      ]);
}
