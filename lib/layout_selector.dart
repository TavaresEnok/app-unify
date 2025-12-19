import 'package:flutter/material.dart';
import 'core/services/diagnostico_service.dart';

// Imports dos Dashboards (diferentes por layout)
import 'layouts/layout_02/dashboard_page.dart' as l02;
import 'layouts/layout_03/dashboard_page.dart' as l03;
import 'layouts/layout_05/dashboard_page.dart' as l05;
import 'layouts/layout_06/dashboard_page.dart' as l06;
import 'layouts/layout_06/pages/speed_test_page.dart' as l06_speed;
import 'layouts/layout_07/dashboard_page.dart' as l07;
import 'layouts/layout_08/dashboard_page.dart' as l08;
import 'layouts/layout_08/pages/speed_test_page.dart' as l08_speed;
import 'layouts/layout_09/dashboard_page.dart' as l09;
import 'layouts/layout_09/pages/speed_test_page.dart' as l09_speed;
import 'layouts/layout_10/dashboard_page.dart' as l10_dashboard;
import 'layouts/layout_10/pages/speed_test_page.dart' as l10_speed;
import 'layouts/layout_11/dashboard_page.dart' as l11_dashboard;
import 'layouts/layout_11/login_page.dart' as l11_login;

// Imports dos Logins (diferentes por layout)
import 'layouts/layout_02/login_page.dart' as l02_login;
import 'layouts/layout_03/login_page.dart' as l03_login;
import 'layouts/layout_05/login_page.dart' as l05_login;
import 'layouts/layout_06/login_page.dart' as l06_login;
import 'layouts/layout_07/login_page.dart' as l07_login;
import 'layouts/layout_08/login_page.dart' as l08_login;
import 'layouts/layout_09/login_page.dart' as l09_login;
import 'layouts/layout_10/login_page.dart' as l10_login;

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
// Layout 05 implementações próprias (Wifi)
import 'layouts/layout_05/wifi_page.dart' as l05_wifi;

// Imports do FAQ e Contrato (também compartilhados)
import 'core/pages/shared_faq_page.dart' as shared_faq;
import 'core/pages/shared_contrato_page.dart' as shared_cont;
import 'core/pages/shared_notification_page.dart' as shared_notif;

/// Classe utilitária que seleciona o layout correto baseado na configuração
/// carregada do Firestore (campo `layoutType`).
///
/// Uso:
/// ```dart
/// final layoutType = configProvider.providerConfig?.layoutType ?? 'layout_02';
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
    Future<void> Function()? onRefresh,
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
        return l06.DashboardPage(
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
          onRefresh: onRefresh,
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

      case 'layout_08':
        return l08.ProviderDashboardPage(
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
          onRefresh: onRefresh,
        );

      case 'layout_09':
        return l09.ProviderDashboardPage(
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
          onRefresh: onRefresh,
        );

      case 'layout_10':
        return l10_dashboard.ProviderDashboardPage(
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
          onRefresh: onRefresh,
        );

      case 'layout_11':
        return l11_dashboard.DashboardPage(
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
          onRefresh: onRefresh,
        );

      default:
        // Default to Layout 02 if unknown
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
    }
  }

  /// Retorna o widget de Login correto para o layout especificado
  static Widget getLoginPage(
      {required String layoutType, Map<String, dynamic>? arguments}) {
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
      case 'layout_08':
        return const l08_login.LoginPage();
      case 'layout_09':
        return const l09_login.LoginPage();
      case 'layout_10':
        return const l10_login.LoginPage();
      case 'layout_11':
        return const l11_login.LoginPage();

      default:
        return const l02_login.LoginPage();
    }
  }

  /// Retorna o widget de Financeiro (Faturas) - COMPARTILHADO entre layouts
  static Widget getFinanceiroPage({required String layoutType}) {
    // Unificado: Todos usam a página compartilhada com lógica completa
    return const shared_fin.FinanceiroPage();
  }

  /// Retorna o widget de Suporte - COMPARTILHADO entre layouts
  static Widget getSuportePage({required String layoutType}) {
    // Unificado: Todos usam a página compartilhada com lógica completa
    return const shared_sup.SuportePage();
  }

  /// Retorna o widget de Diagnóstico - COMPARTILHADO entre layouts
  static Widget getDiagnosticoPage({required String layoutType}) {
    // Unificado: Todos usam a página compartilhada com lógica completa
    return const shared_diag.DiagnosticoPage();
  }

  /// Retorna o widget de Consumo - COMPARTILHADO entre layouts
  static Widget getConsumoPage({required String layoutType}) {
    // Unificado: Todos usam a página compartilhada com lógica completa
    return const shared_cons.ConsumoPage();
  }

  /// Retorna o widget de Meu IP - COMPARTILHADO entre layouts
  static Widget getMeuIpPage({required String layoutType}) {
    // Unificado: Todos usam a página compartilhada com lógica completa
    return const shared_ip.MeuIpPage();
  }

  /// Retorna o widget de Teste de Velocidade
  static Widget getSpeedTestPage({
    required String layoutType,
    required DiagnosticoService diagnosticoService,
    required VoidCallback onBack,
  }) {
    switch (layoutType) {
      case 'layout_06':
        return const l06_speed.Layout06SpeedTestPage();
      case 'layout_08':
        return const l08_speed.Layout08SpeedTestPage();
      case 'layout_09':
        return const l09_speed.Layout09SpeedTestPage();
      case 'layout_10':
        return const l10_speed.Layout10SpeedTestPage();

      default:
        // Por enquanto shared_speed não aceita esses params, mas podemos atualizar se necessário
        // Ou manter como fallback.
        return const shared_speed.SharedSpeedTestPage();
    }
  }

  static Widget getTraceRoutePage({required String layoutType}) {
    return const shared_trace.SharedTraceRoutePage();
  }

  /// Retorna o widget de FAQ - COMPARTILHADO entre layouts
  static Widget getFaqPage({required String layoutType}) {
    // Unificado: Todos usam a página compartilhada
    return const shared_faq.FaqPage();
  }

  /// Retorna o widget de Contrato - COMPARTILHADO entre layouts
  static Widget getContratoPage({required String layoutType}) {
    // Unificado: Todos usam a página compartilhada
    return const shared_cont.ContratoPage();
  }

  /// Retorna o widget de Notificações - COMPARTILHADO
  static Widget getNotificationPage({required String layoutType}) {
    return const shared_notif.SharedNotificationPage();
  }

  /// Retorna o widget de Wifi correto para o layout especificado
  static Widget getWifiPage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_05':
        return const l05_wifi.WifiPage();
      case 'layout_02':
        return const l05_wifi.WifiPage();

      case 'layout_06':
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
      'description': 'Fintech-style com Cyan/Teal'
    },
    {
      'id': 'layout_07',
      'name': 'Clean Light',
      'description': 'Tema claro e limpo'
    },
    {
      'id': 'layout_08',
      'name': 'Neubrutalism',
      'description': 'Estilo marcante com bordas grossas e cores vibrantes'
    },
    {
      'id': 'layout_09',
      'name': 'Organic / Biomorphic',
      'description': 'Formas suaves e fluidas inspiradas na natureza'
    },
    {
      'id': 'layout_10',
      'name': 'Mesh Gradient & Glassmorphism',
      'description':
          'Design ultra premium com efeitos de vidro e gradientes mesh'
    },
    {
      'id': 'layout_11',
      'name': 'Cyberpunk / Neon',
      'description': 'Tema futurista escuro com detalhes em neon Cyan e Pink'
    },
  ];
}
