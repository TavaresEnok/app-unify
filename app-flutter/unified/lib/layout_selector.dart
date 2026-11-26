import 'package:flutter/material.dart';
import 'core/services/diagnostico_service.dart';

import 'core/pages/customer/customer_home_page.dart';

// Imports dos Logins (diferentes por layout)

// ============================================
// PÁGINAS COMPARTILHADAS (idênticas entre layouts)
// ============================================
import 'core/pages/unified_login_page.dart';
import 'core/pages/shared_financeiro_page.dart' as shared_fin;
import 'core/pages/shared_diagnostico_page.dart' as shared_diag;
import 'core/pages/shared_consumo_page.dart' as shared_cons;
import 'core/pages/shared_meu_ip_page.dart' as shared_ip;
import 'core/pages/shared_traceroute_page.dart' as shared_trace;

// Layout 03 implementações próprias (Wifi)
import 'layouts/layout_03/wifi_page.dart' as l03_wifi;

// Imports do FAQ e Contrato (também compartilhados)
import 'core/pages/shared_faq_page.dart' as shared_faq;
import 'core/pages/shared_contrato_page.dart' as shared_cont;
import 'core/pages/shared_notification_page.dart' as shared_notif;

// Imports das páginas de diagnóstico selecionáveis
import 'core/pages/diagnostics/diagnostic_02_page.dart' as diag02;
import 'core/pages/diagnostics/diagnostic_03_page.dart' as diag03;
import 'core/pages/diagnostics/diagnostic_05_page.dart' as diag05;
import 'core/pages/diagnostics/diagnostic_06_page.dart' as diag06;
import 'core/pages/diagnostics/diagnostic_07_page.dart' as diag07;

/// Classe utilitária que seleciona o layout correto baseado na configuração
class LayoutSelector {
  /// Retorna o widget de Dashboard correto para o layout especificado
  static Widget getDashboard({
    required String layoutType,
    required String customerName,
    required String planName,
    required String connectionStatus,
    required double billAmount,
    required DateTime billDueDate,
    required double usedGb,
    required double totalGb,
    required double downloadMbps,
    required double uploadMbps,
    required Function(String) onNavigate,
    List<Map<String, dynamic>>? menuItems,
    Color? customCardBg,
    Color? customCardText,
    Color? invoiceColor,
    Color? actionColor,
    Future<void> Function()? onRefresh,
  }) {
    return CustomerHomePage(
        layoutType: layoutType, onNavigate: onNavigate, onRefresh: onRefresh);
  }

  /// Retorna o widget de Login correto para o layout especificado
  static Widget getLoginPage(
      {required String layoutType, Map<String, dynamic>? arguments}) {
    // Login unificado: a aparência vem dos tokens do layout (LayoutTokens),
    // não de uma tela por layout.
    return const UnifiedLoginPage();
  }

  /// Retorna o widget de Financeiro (Faturas) - COMPARTILHADO entre layouts
  static Widget getFinanceiroPage({required String layoutType}) {
    return const shared_fin.FinanceiroPage();
  }

  /// Retorna o widget de Diagnóstico - COMPARTILHADO entre layouts
  static Widget getDiagnosticoPage({required String layoutType}) {
    return const shared_diag.DiagnosticoPage();
  }

  /// Retorna diagnóstico com estilo selecionável
  /// [diagnosticStyle] define qual página de diagnóstico usar
  /// Se 'default', usa padrão baseado no tema do layout (light/dark)
  static Widget getDiagnosticByStyle({
    required String layoutType,
    String diagnosticStyle = 'default',
  }) {
    switch (diagnosticStyle) {
      case 'diagnostic_02':
        return const diag02.Diagnostic02Page();
      case 'diagnostic_03':
        return const diag03.Diagnostic03Page();
      case 'diagnostic_05':
        return const diag05.Diagnostic05Page();
      case 'diagnostic_06':
        return const diag06.Diagnostic06Page();
      case 'diagnostic_07':
        return const diag07.Diagnostic07Page();
      default:
        // Seleciona padrão baseado no tema do layout
        // Dark layouts (04, 05, 06) -> diagnostic_02 ou diagnostic_03
        // Light layouts (02, 03) -> diagnostic_05 ou diagnostic_06
        switch (layoutType) {
          case 'layout_02':
            return const diag05.Diagnostic05Page(); // Light
          case 'layout_03':
            return const diag06.Diagnostic06Page(); // Light Neumorphic
          case 'layout_04':
            return const diag02.Diagnostic02Page(); // Dark Obsidian
          case 'layout_05':
            return const diag03.Diagnostic03Page(); // Dark Cyber
          case 'layout_06':
            return const diag07.Diagnostic07Page(); // Dark Clean
          default:
            return const shared_diag.DiagnosticoPage();
        }
    }
  }

  /// Retorna o widget de Consumo - COMPARTILHADO entre layouts
  static Widget getConsumoPage({required String layoutType}) {
    return const shared_cons.ConsumoPage();
  }

  /// Retorna o widget de Meu IP - COMPARTILHADO entre layouts
  static Widget getMeuIpPage({required String layoutType}) {
    return const shared_ip.MeuIpPage();
  }

  /// Retorna o widget de Teste de Velocidade
  static Widget getSpeedTestPage({
    required String layoutType,
    required DiagnosticoService diagnosticoService,
    required VoidCallback onBack,
  }) {
    return const shared_diag.DiagnosticoPage(speedOnly: true);
  }

  static Widget getTraceRoutePage({required String layoutType}) {
    return const shared_trace.SharedTraceRoutePage();
  }

  /// Retorna o widget de FAQ - COMPARTILHADO entre layouts
  static Widget getFaqPage(
      {required String layoutType, ValueChanged<String>? onNavigate}) {
    return shared_faq.FaqPage(onNavigate: onNavigate);
  }

  /// Retorna o widget de Contrato - COMPARTILHADO entre layouts
  static Widget getContratoPage(
      {required String layoutType, ValueChanged<String>? onNavigate}) {
    return shared_cont.ContratoPage(onNavigate: onNavigate);
  }

  /// Retorna o widget de Notificações - COMPARTILHADO
  static Widget getNotificationPage({required String layoutType}) {
    return const shared_notif.SharedNotificationPage();
  }

  /// Retorna o widget de Wifi correto para o layout especificado
  static Widget getWifiPage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_03':
        return const l03_wifi.WifiPage();
      case 'layout_04':
        return const l03_wifi.WifiPage();
      case 'layout_05':
        return const l03_wifi.WifiPage();
      case 'layout_06':
        return const l03_wifi.WifiPage();

      default:
        return const l03_wifi.WifiPage();
    }
  }

  /// Lista de layouts disponíveis (útil para UI de seleção)
  static const List<Map<String, String>> availableLayouts = [
    {
      'id': 'layout_02',
      'name': 'Histórico na folha',
      'description': 'Fatura no topo e serviços na folha'
    },
    {
      'id': 'layout_03',
      'name': 'Dock de serviços',
      'description': 'Serviços em destaque'
    },
    {
      'id': 'layout_04',
      'name': 'Blocos escuros',
      'description': 'Fatura e serviços em blocos'
    },
    {
      'id': 'layout_05',
      'name': 'Faixa e fatura',
      'description': 'Faixa de marca e cartão da fatura'
    },
    {
      'id': 'layout_06',
      'name': 'Topo centralizado',
      'description': 'Identidade centralizada e resumo da conta'
    },
  ];
}
