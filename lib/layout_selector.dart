import 'package:flutter/material.dart';

// Imports dos Dashboards
import 'layouts/layout_02/dashboard_page.dart' as l02;
import 'layouts/layout_03/dashboard_page.dart' as l03;
import 'layouts/layout_06/dashboard_page.dart' as l06;
import 'layouts/layout_07/dashboard_page.dart' as l07;

// Imports dos Logins
import 'layouts/layout_02/login_page.dart' as l02_login;
import 'layouts/layout_03/login_page.dart' as l03_login;
import 'layouts/layout_06/login_page.dart' as l06_login;
import 'layouts/layout_07/login_page.dart' as l07_login;

// Imports do Financeiro
import 'layouts/layout_02/financeiro_page.dart' as l02_fin;
import 'layouts/layout_03/financeiro_page.dart' as l03_fin;
import 'layouts/layout_06/financeiro_page.dart' as l06_fin;
import 'layouts/layout_07/financeiro_page.dart' as l07_fin;

// Imports do Suporte
import 'layouts/layout_02/suporte_page.dart' as l02_sup;
import 'layouts/layout_03/suporte_page.dart' as l03_sup;
import 'layouts/layout_06/suporte_page.dart' as l06_sup;
import 'layouts/layout_07/suporte_page.dart' as l07_sup;

// Imports do Diagnóstico
import 'layouts/layout_02/diagnostico_page.dart' as l02_diag;
import 'layouts/layout_03/diagnostico_page.dart' as l03_diag;
import 'layouts/layout_06/diagnostico_page.dart' as l06_diag;
import 'layouts/layout_07/diagnostico_page.dart' as l07_diag;

// Imports do Consumo
import 'layouts/layout_02/consumo_page.dart' as l02_cons;
import 'layouts/layout_03/consumo_page.dart' as l03_cons;
import 'layouts/layout_06/consumo_page.dart' as l06_cons;
import 'layouts/layout_07/consumo_page.dart' as l07_cons;

// Imports do Meu IP
import 'layouts/layout_02/meu_ip_page.dart' as l02_ip;
import 'layouts/layout_03/meu_ip_page.dart' as l03_ip;
import 'layouts/layout_06/meu_ip_page.dart' as l06_ip;
import 'layouts/layout_07/meu_ip_page.dart' as l07_ip;

// Imports do FAQ
import 'layouts/layout_02/faq_page.dart' as l02_faq;
import 'layouts/layout_03/faq_page.dart' as l03_faq;
import 'layouts/layout_06/faq_page.dart' as l06_faq;
import 'layouts/layout_07/faq_page.dart' as l07_faq;

// Imports do Contrato
import 'layouts/layout_02/contrato_page.dart' as l02_cont;
import 'layouts/layout_03/contrato_page.dart' as l03_cont;
// Imports do Layout 05
import 'layouts/layout_05/dashboard_page.dart' as l05;
import 'layouts/layout_05/login_page.dart' as l05_login;
import 'layouts/layout_05/financeiro_page.dart' as l05_fin;
import 'layouts/layout_05/suporte_page.dart' as l05_sup;
import 'layouts/layout_05/diagnostico_page.dart' as l05_diag;
import 'layouts/layout_05/consumo_page.dart' as l05_cons;
import 'layouts/layout_05/meu_ip_page.dart' as l05_ip;
import 'layouts/layout_05/faq_page.dart' as l05_faq;
import 'layouts/layout_05/contrato_page.dart' as l05_cont;
import 'layouts/layout_05/wifi_page.dart' as l05_wifi;

import 'layouts/layout_06/contrato_page.dart' as l06_cont;
import 'layouts/layout_07/contrato_page.dart' as l07_cont;

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
      case 'layout_04':
        // Layout 04 Aurora uses layout_06 login
        return const l06_login.LoginPage();
      case 'layout_06':
        return const l06_login.LoginPage();
      case 'layout_07':
        return const l07_login.LoginPage();
      default:
        return const l06_login.LoginPage();
    }
  }

  /// Retorna o widget de Financeiro (Faturas) correto para o layout especificado
  static Widget getFinanceiroPage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_02':
        return const l02_fin.FinanceiroPage();
      case 'layout_03':
        return const l03_fin.FinanceiroPage();

      case 'layout_05':
        return const l05_fin.FinanceiroPage();

      case 'layout_06':
        return const l06_fin.FinanceiroPage();
      case 'layout_07':
        return const l07_fin.FinanceiroPage();
      default:
        return const l06_fin.FinanceiroPage();
    }
  }

  /// Retorna o widget de Suporte correto para o layout especificado
  static Widget getSuportePage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_02':
        return const l02_sup.SuportePage();
      case 'layout_03':
        return const l03_sup.SuportePage();

      case 'layout_05':
        return const l05_sup.SuportePage();

      case 'layout_06':
        return const l06_sup.SuportePage();
      case 'layout_07':
        return const l07_sup.SuportePage();
      default:
        return const l06_sup.SuportePage();
    }
  }

  /// Retorna o widget de Diagnóstico correto para o layout especificado
  static Widget getDiagnosticoPage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_02':
        return const l02_diag.DiagnosticoPage();
      case 'layout_03':
        return const l03_diag.DiagnosticoPage();

      case 'layout_05':
        return const l05_diag.DiagnosticoPage();

      case 'layout_06':
        return const l06_diag.DiagnosticoPage();
      case 'layout_07':
        return const l07_diag.DiagnosticoPage();
      default:
        return const l06_diag.DiagnosticoPage();
    }
  }

  /// Retorna o widget de Consumo correto para o layout especificado
  static Widget getConsumoPage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_02':
        return const l02_cons.ConsumoPage();
      case 'layout_03':
        return const l03_cons.ConsumoPage();

      case 'layout_05':
        return const l05_cons.ConsumoPage();

      case 'layout_06':
        return const l06_cons.ConsumoPage();
      case 'layout_07':
        return const l07_cons.ConsumoPage();
      default:
        return const l06_cons.ConsumoPage();
    }
  }

  /// Retorna o widget de Meu IP correto para o layout especificado
  static Widget getMeuIpPage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_02':
        return const l02_ip.MeuIpPage();
      case 'layout_03':
        return const l03_ip.MeuIpPage();

      case 'layout_05':
        return const l05_ip.MeuIpPage();

      case 'layout_06':
        return const l06_ip.MeuIpPage();
      case 'layout_07':
        return const l07_ip.MeuIpPage();
      default:
        return const l06_ip.MeuIpPage();
    }
  }

  /// Retorna o widget de FAQ correto para o layout especificado
  static Widget getFaqPage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_02':
        return const l02_faq.FaqPage();
      case 'layout_03':
        return const l03_faq.FaqPage();

      case 'layout_05':
        return const l05_faq.FaqPage();

      case 'layout_06':
        return const l06_faq.FaqPage();
      case 'layout_07':
        return const l07_faq.FaqPage();
      default:
        return const l06_faq.FaqPage();
    }
  }

  /// Retorna o widget de Contrato correto para o layout especificado
  static Widget getContratoPage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_02':
        return const l02_cont.ContratoPage();
      case 'layout_03':
        return const l03_cont.ContratoPage();

      case 'layout_05':
        return const l05_cont.ContratoPage();

      case 'layout_06':
        return const l06_cont.ContratoPage();
      case 'layout_07':
        return const l07_cont.ContratoPage();
      default:
        return const l06_cont.ContratoPage();
    }
  }

  /// Retorna o widget de Wifi correto para o layout especificado
  static Widget getWifiPage({required String layoutType}) {
    switch (layoutType) {
      case 'layout_05':
        return const l05_wifi.WifiPage();
      default:
        // Se outros layouts não tiverem WifiPage, retornar placeholder ou Layout 05 como fallback
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
