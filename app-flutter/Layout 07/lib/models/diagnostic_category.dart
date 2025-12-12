// Categorias de problemas detectados pelo diagnóstico
enum DiagnosticCategory {
  FIBER_ISSUE, // Problema na fibra óptica (sinal ONU)
  WIFI_ISSUE, // Problema no WiFi do cliente
  DEVICE_ISSUE, // Problema no dispositivo (DNS, configuração)
  REGIONAL_ISSUE, // Problema regional (afeta múltiplos clientes)
  BILLING_BLOCK, // Bloqueio por inadimplência
  MAINTENANCE, // Manutenção programada
  OLT_OVERLOAD, // Sobrecarga na OLT
  ALL_GOOD, // Tudo funcionando perfeitamente
  UNKNOWN, // Desconhecido
}

extension DiagnosticCategoryExtension on DiagnosticCategory {
  String get displayName {
    switch (this) {
      case DiagnosticCategory.FIBER_ISSUE:
        return 'Problema na Fibra';
      case DiagnosticCategory.WIFI_ISSUE:
        return 'Problema no WiFi';
      case DiagnosticCategory.DEVICE_ISSUE:
        return 'Problema no Dispositivo';
      case DiagnosticCategory.REGIONAL_ISSUE:
        return 'Problema Regional';
      case DiagnosticCategory.BILLING_BLOCK:
        return 'Bloqueio Financeiro';
      case DiagnosticCategory.MAINTENANCE:
        return 'Manutenção Programada';
      case DiagnosticCategory.OLT_OVERLOAD:
        return 'Sobrecarga na Rede';
      case DiagnosticCategory.ALL_GOOD:
        return 'Tudo OK';
      case DiagnosticCategory.UNKNOWN:
        return 'Indeterminado';
    }
  }

  String get icon {
    switch (this) {
      case DiagnosticCategory.FIBER_ISSUE:
        return '🔌';
      case DiagnosticCategory.WIFI_ISSUE:
        return '📶';
      case DiagnosticCategory.DEVICE_ISSUE:
        return '📱';
      case DiagnosticCategory.REGIONAL_ISSUE:
        return '🌍';
      case DiagnosticCategory.BILLING_BLOCK:
        return '💳';
      case DiagnosticCategory.MAINTENANCE:
        return '🔧';
      case DiagnosticCategory.OLT_OVERLOAD:
        return '⚠️';
      case DiagnosticCategory.ALL_GOOD:
        return '✅';
      case DiagnosticCategory.UNKNOWN:
        return '❓';
    }
  }
}
