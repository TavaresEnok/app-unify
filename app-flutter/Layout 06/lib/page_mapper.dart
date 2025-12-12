// FILE: lib/page_mapper.dart (Force Rebuild)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:app_provedor/configuration_provider.dart';

import 'consumo_page.dart' deferred as consumo_page;
import 'financeiro_page.dart' deferred as financeiro_page;
import 'meu_ip_page.dart' deferred as meu_ip_page;
import 'notificacoes.dart' deferred as notificacoes_page;
import 'promessa_pagamento.dart' deferred as promessa_page;
import 'speed_test_page.dart' deferred as speed_test_page;
import 'suporte.dart' deferred as suporte_page;
import 'dicasuteis.dart' deferred as dicas_uteis_page;
import 'faq_page.dart' deferred as faq_page;
import 'DownDetectorPage.dart' deferred as down_detector_page;
import 'diagnostico_page.dart' deferred as diagnostico_page;

void _showLoadingDialog(BuildContext context) {
  showDialog(context: context, barrierDismissible: false, builder: (BuildContext context) => const Center(child: CircularProgressIndicator()));
}

void _hideLoadingDialog(BuildContext context) {
  if (Navigator.of(context, rootNavigator: true).canPop()) Navigator.of(context, rootNavigator: true).pop();
}

Future<void> _loadAndPush(BuildContext context, Future<void> loadLibraryFuture, Widget Function() pageBuilder) async {
  _showLoadingDialog(context);
  try {
    await loadLibraryFuture;
    _hideLoadingDialog(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => pageBuilder()));
  } catch (e) {
    _hideLoadingDialog(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar módulo: $e')));
  }
}

void navigateToPageById({
  required BuildContext context,
  required String pageId,
  String? cpfCnpj,
  String? senha,
  String? status,
  String? clientName,
}) async {
  final config = context.read<ConfigurationProvider>().providerConfig!;

  final sgpParams = {
      'token': config.config.integrations.apiToken,
      'app': config.config.integrations.appName,
      'sgpBaseUrl': config.config.integrations.sgpBaseUrl, // ADICIONADO: Faltava este parâmetro
  };

  switch (pageId) {
    case 'internet_usage':
      await _loadAndPush(context, consumo_page.loadLibrary(), () => consumo_page.ConsumoPage(cpfCnpj: cpfCnpj!, senha: senha!));
      break;
    case 'support':
      await _loadAndPush(context, suporte_page.loadLibrary(), () => suporte_page.SuportePage(cpfCnpj: cpfCnpj!, senha: senha!, status: status!, clientName: clientName!));
      break;
    case 'invoices':
      await _loadAndPush(context, financeiro_page.loadLibrary(), () => financeiro_page.FinanceiroPage(cpfCnpj: cpfCnpj!, senha: senha!, sgpParams: sgpParams));
      break;
    case 'speed_test':
      await _loadAndPush(context, speed_test_page.loadLibrary(), () => speed_test_page.SpeedTestPage());
      break;
    case 'my_ip':
      await _loadAndPush(context, meu_ip_page.loadLibrary(), () => meu_ip_page.MeuIpPage());
      break;
    case 'useful_tips':
      await _loadAndPush(context, dicas_uteis_page.loadLibrary(), () => dicas_uteis_page.DicasUteisPage());
      break;
    case 'faq':
      await _loadAndPush(context, faq_page.loadLibrary(), () => faq_page.FaqPage());
      break;
    case 'notifications':
      await _loadAndPush(context, notificacoes_page.loadLibrary(), () => notificacoes_page.NotificacoesPage());
      break;
    case 'payment_promise':
      await _loadAndPush(context, promessa_page.loadLibrary(), () => promessa_page.PromessaPage(status: status!, cpfCnpj: cpfCnpj!));
      break;
    case 'down_detector':
      await _loadAndPush(context, down_detector_page.loadLibrary(), () => down_detector_page.DownDetectorPage());
      break;
    case 'network_diagnostic':
      await _loadAndPush(context, diagnostico_page.loadLibrary(), () => diagnostico_page.DiagnosticoPage());
      break;
    default:
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Funcionalidade "$pageId" não implementada.')));
  }
}

// Ícones e Nomes (sem alteração)
const Map<String, IconData> pageIcons = {
  'home': Icons.home_outlined, 'internet_usage': Icons.data_usage_outlined, 'support': Icons.support_agent_outlined,
  'invoices': FontAwesomeIcons.fileInvoiceDollar, 'payment_promise': FontAwesomeIcons.lockOpen, 'notifications': FontAwesomeIcons.solidBell,
  'whatsapp': FontAwesomeIcons.whatsapp, 'down_detector': FontAwesomeIcons.triangleExclamation, 'speed_test': FontAwesomeIcons.tachometerAlt,
  'my_ip': FontAwesomeIcons.networkWired, 'useful_tips': FontAwesomeIcons.lightbulb, 'faq': FontAwesomeIcons.questionCircle,
  'external_link': FontAwesomeIcons.link, 'network_diagnostic': Icons.network_check, 'default': Icons.grid_view_outlined,
};
const Map<String, String> pageNames = {
  'home': 'Início', 'internet_usage': 'Consumo', 'support': 'Suporte', 'invoices': 'Faturas', 'payment_promise': 'Promessa de Pagamento',
  'notifications': 'Notificações', 'whatsapp': 'WhatsApp', 'down_detector': 'Verificar Conexão', 'speed_test': 'Teste de Velocidade',
  'my_ip': 'Meu IP', 'useful_tips': 'Dicas Úteis', 'faq': 'Perguntas Frequentes', 'external_link': 'Link Externo', 'network_diagnostic': 'Diagnóstico de Rede',
  'default': 'Menu',
};
