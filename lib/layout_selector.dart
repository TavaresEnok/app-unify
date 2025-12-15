import 'package:flutter/material.dart';

// Imports dos Dashboards (diferentes por layout)
import 'layouts/layout_02/dashboard_page.dart' as l02;
import 'layouts/layout_03/dashboard_page.dart' as l03;
import 'layouts/layout_05/dashboard_page.dart' as l05;
import 'layouts/layout_06/dashboard_page.dart' as l06;
import 'layouts/layout_07/dashboard_page.dart' as l07;

// Imports dos Logins (diferentes por layout)
import 'layouts/layout_02/login_page.dart' as l02_login;
import 'layouts/layout_03/login_page.dart' as l03_login;
import 'layouts/layout_05/login_page.dart' as l05_login;
import 'layouts/layout_06/login_page.dart' as l06_login;
import 'layouts/layout_07/login_page.dart' as l07_login;

// ============================================
// PÁGINAS COMPARTILHADAS (idênticas entre layouts 02/03/06/07)
// ============================================
import 'core/pages/shared_financeiro_page.dart' as shared_fin;
import 'core/pages/shared_suporte_page.dart' as shared_sup;
import 'core/pages/shared_diagnostico_page.dart' as shared_diag;
import 'core/pages/shared_consumo_page.dart' as shared_cons;
import 'core/pages/shared_meu_ip_page.dart' as shared_ip;
import 'core/pages/shared_speed_test_page.dart' as shared_speed;
import 'core/pages/shared_traceroute_page.dart' as shared_trace;

// Layout 05 tem implementações próprias
import 'layouts/layout_05/financeiro_page.dart' as l05_fin;
import 'layouts/layout_05/suporte_page.dart' as l05_sup;
// import 'layouts/layout_05/diagnostico_page.dart' as l05_diag; // REMOVIDO: Usa shared agora
import 'layouts/layout_05/consumo_page.dart' as l05_cons;
import 'layouts/layout_05/meu_ip_page.dart' as l05_ip;
import 'layouts/layout_05/faq_page.dart' as l05_faq;
import 'layouts/layout_05/contrato_page.dart' as l05_cont;
import 'layouts/layout_05/wifi_page.dart' as l05_wifi;

// Imports do FAQ e Contrato (também compartilhados)
import 'core/pages/shared_faq_page.dart' as shared_faq;
import 'core/pages/shared_contrato_page.dart' as shared_cont;

/// Classe utilitária que seleciona o layout correto baseado na configuração
/// carregada do Firestore (campo `layoutType`).
///
/// Uso:
/// ```dart
/// final layoutType = configProvider.providerConfig?.layoutType ?? 'layout_06';
/// return LayoutSelector.getLoginPage(layoutType: layoutType);
/// ```
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
  }) {
    switch (layoutType) {
      case 'layout_02':
        return l02.ProviderDashboardPage(
          customerName: customerName,
          planName: planName,
          connectionStatus: connectionStatus,
          billAmount: billAmount,
          billDueDate: billDueDate,
          usedGb: usedGb,
          totalGb: totalGb,
          downloadMbps: downloadMbps,
          uploadMbps: uploadMbps,
          onNavigate: onNavigate,
          menuItems: menuItems,
          customCardBg: customCardBg,
          customCardText: customCardText,
          invoiceColor: invoiceColor,
          actionColor: actionColor,
        );

      case 'layout_03':
        return l03.ProviderDashboardPage(
          customerName: customerName,
          planName: planName,
          connectionStatus: connectionStatus,
          billAmount: billAmount,
          billDueDate: billDueDate,
          usedGb: usedGb,
          totalGb: totalGb,
          downloadMbps: downloadMbps,
          uploadMbps: uploadMbps,
          onNavigate: onNavigate,
          menuItems: menuItems,
          customCardBg: customCardBg,
          customCardText: customCardText,
          invoiceColor: invoiceColor,
          actionColor: actionColor,
        );

      case 'layout_05':
        return l05.DashboardPage(
          customerName: customerName,
          planName: planName,
          connectionStatus: connectionStatus,
          billAmount: billAmount,
          billDueDate: billDueDate,
          usedGb: usedGb,
          totalGb: totalGb,
          downloadMbps: downloadMbps,
          uploadMbps: uploadMbps,
          onNavigate: onNavigate,
        );

      case 'layout_06':
        return l06.ProviderDashboardPage(
          customerName: customerName,
          planName: planName,
          connectionStatus: connectionStatus,
          billAmount: billAmount,
          billDueDate: billDueDate,
          usedGb: usedGb,
          totalGb: totalGb,
          downloadMbps: downloadMbps,
          uploadMbps: uploadMbps,
          onNavigate: onNavigate,
        );

      case 'layout_07':
        return l07.ProviderDashboardPage(
          customerName: customerName,
          planName: planName,
          connectionStatus: connectionStatus,
          billAmount: billAmount,
          billDueDate: billDueDate,
          usedGb: usedGb,
          totalGb: totalGb,
          downloadMbps: downloadMbps,
          uploadMbps: uploadMbps,
          onNavigate: onNavigate,
        );

      default:
        // Layout 06 como padrão (mais moderno)
        return l06.ProviderDashboardPage(
          customerName: customerName,
          planName: planName,
          connectionStatus: connectionStatus,
          billAmount: billAmount,
          billDueDate: billDueDate,
          usedGb: usedGb,
          totalGb: totalGb,
          downloadMbps: downloadMbps,
          uploadMbps: uploadMbps,
          onNavigate: onNavigate,
        );
    }
  }

  /// Retorna o widget de Login correto para o layout especificado
  static Widget getLoginPage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_02':
        return const l02_login.LoginPage();
      case 'layout_03':
        return const l03_login.LoginPage();
      case 'layout_05':
        return const l05_login.LoginPage();
      case 'layout_06':
        return const l06_login.LoginPage();
      case 'layout_07':
        return const l07_login.LoginPage();
      default:
        return const l06_login.LoginPage();
    }
  }

  /// Retorna o widget de Financeiro (Faturas) - COMPARTILHADO entre layouts
  static Widget getFinanceiroPage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_05':
        return const l05_fin.FinanceiroPage();
      case 'layout_02':
      case 'layout_03':
      case 'layout_06':
      case 'layout_07':
      default:
        return const shared_fin.FinanceiroPage();
    }
  }

  /// Retorna o widget de Suporte - COMPARTILHADO entre layouts
  static Widget getSuportePage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_05':
        return const l05_sup.SuportePage();
      case 'layout_02':
      case 'layout_03':
      case 'layout_06':
      case 'layout_07':
      default:
        return const shared_sup.SuportePage();
    }
  }

  /// Retorna o widget de Diagnóstico - COMPARTILHADO entre layouts
  static Widget getDiagnosticoPage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_05': // Unificado para usar a página completa compartilhada
        return const shared_diag.DiagnosticoPage();
      case 'layout_02':
      case 'layout_03':
      case 'layout_06':
      case 'layout_07':
      default:
        return const shared_diag.DiagnosticoPage();
    }
  }

  /// Retorna o widget de Consumo - COMPARTILHADO entre layouts
  static Widget getConsumoPage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_05':
        return const l05_cons.ConsumoPage();
      case 'layout_02':
      case 'layout_03':
      case 'layout_06':
      case 'layout_07':
      default:
        return const shared_cons.ConsumoPage();
    }
  }

  /// Retorna o widget de Meu IP - COMPARTILHADO entre layouts
  static Widget getMeuIpPage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_05':
        return const l05_ip.MeuIpPage();
      case 'layout_02':
      case 'layout_03':
      case 'layout_06':
      case 'layout_07':
      default:
        return const shared_ip.MeuIpPage();
    }
  }

  /// Retorna o widget de Teste de Velocidade - COMPARTILHADO (por enquanto)
  static Widget getSpeedTestPage({required String layoutType}) {
    // Por enquanto todos usam o shared.
    // Se no futuro o layout_05 quiser um design diferente, cria-se l05_speed.
    return const shared_speed.SharedSpeedTestPage();
  }

  static Widget getTraceRoutePage({required String layoutType}) {
    return const shared_trace.SharedTraceRoutePage();
  }

  /// Retorna o widget de FAQ - COMPARTILHADO entre layouts
  static Widget getFaqPage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_05':
        return const l05_faq.FaqPage();
      case 'layout_02':
      case 'layout_03':
      case 'layout_06':
      case 'layout_07':
      default:
        return const shared_faq.FaqPage();
    }
  }

  /// Retorna o widget de Contrato - COMPARTILHADO entre layouts
  static Widget getContratoPage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_05':
        return const l05_cont.ContratoPage();
      case 'layout_02':
      case 'layout_03':
      case 'layout_06':
      case 'layout_07':
      default:
        return const shared_cont.ContratoPage();
    }
  }

  /// Retorna o widget de Wifi correto para o layout especificado
  static Widget getWifiPage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_05':
        return const l05_wifi.WifiPage();
      // Enable WifiPage for Layout 02 too, reusing Layout 05's implementation
      case 'layout_02':
        return const l05_wifi.WifiPage();
      default:
        return const Center(
            child: Text('Funcionalidade não disponível neste layout'));
    }
  }

  /// Lista de layouts disponíveis (útil para UI de seleção)
  static const List<Map<String, String>> availableLayouts = [
    {
      'id': 'layout_02',
      'name': 'Clássico',
      'description': 'Gradiente roxo, grid de serviços'
    },
    {
      'id': 'layout_03',
      'name': 'Minimalista',
      'description': 'Cards brancos, ações rápidas'
    },
    {
      'id': 'layout_05',
      'name': 'Neo Digital',
      'description': 'Estilo futurista com efeitos neon e vidro'
    },
    {
      'id': 'layout_06',
      'name': 'Premium Dark',
      'description': 'Tema escuro profissional'
    },
    {
      'id': 'layout_07',
      'name': 'Clean Light',
      'description': 'Tema claro e limpo'
    },
  ];
}
