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
      case 'layout_06':
        return const l06_cons.ConsumoPage();
      case 'layout_07':
        return const l07_cons.ConsumoPage();
      default:
        return const l06_cons.ConsumoPage();
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
