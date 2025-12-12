import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:app_provedor/models/provider_config.dart';
import 'package:app_provedor/configuration_provider.dart';

// Páginas do App
import 'painel.dart';
import 'financeiro_page.dart';
import 'suporte.dart';
// import 'consumo_page.dart'; // Alterado para usar a versão nativa com Service
import 'abrir_chamado_page.dart';
import 'diagnostico_page.dart';
import 'speed_test_page.dart';
import 'promessa_pagamento.dart';
import 'dicasuteis.dart';
import 'meu_ip_page.dart';
import 'DownDetectorPage.dart';
import 'services/auth_service.dart';

class PageMapper {
  static Future<void> navigateTo(BuildContext context, String itemKey) async {
    // 1. Obter a configuração
    final config = context.read<ConfigurationProvider>().providerConfig!;
    final itemDetails = config.menuConfig.items[itemKey];

    // Se o item não existir ou estiver desabilitado, não faz nada
    if (itemDetails == null || !itemDetails.enabled) {
      // Fallback para itens hardcoded no dashboard
      if (!['invoices', 'network_diagnostic', 'speed_test'].contains(itemKey)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Funcionalidade "$itemKey" não disponível.')),
        );
        return;
      }
    }

    // 2. Verificar o tipo de ação
    final type = itemDetails?.type ?? 'internal';
    final url = itemDetails?.url;

    switch (type) {
      case 'internal':
        final page = _getPageForKey(context, itemKey, config);
        if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Página interna "$itemKey" não implementada.')),
          );
        }
        break;

      case 'webview':
      case 'external':
        if (url != null && url.isNotEmpty) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: type == 'webview'
                  ? LaunchMode.inAppWebView
                  : LaunchMode.externalApplication,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Não foi possível abrir o link.')),
            );
          }
        }
        break;

      default:
        break;
    }
  }

  static Widget? _getPageForKey(
      BuildContext context, String key, ProviderConfig config) {
    final authService = context.read<AuthService>();
    final user = authService.usuario;

    // Dados necessários para algumas páginas
    final cpfCnpj = user?.cpfCnpj ?? '';
    final senha = user?.senha ?? '';

    // [CORREÇÃO] Passando os parâmetros com as chaves corretas para os Services
    // final sgpParams = {
    //   'token': config.config.integrations.apiToken,
    //   'app': config.config.integrations.appName,
    //   'sgpBaseUrl': config.config.integrations.sgpBaseUrl,
    // };

    switch (key) {
      case 'dashboard':
        return const PainelPage();
      case 'invoices':
      case 'financeiro':
        return FinanceiroPage(
          cpfCnpj: cpfCnpj,
          senha: senha,
          // sgpParams: sgpParams, // Removido pois FinanceiroPage pega do Provider
        );
      case 'consumo':
        // Agora usa a ConsumoPage nativa (consumo_page.dart)
        // return ConsumoPage(
        //   cpfCnpj: cpfCnpj,
        //   senha: senha,
        // );
        return const Scaffold(body: Center(child: Text('Em manutenção')));
      case 'suporte':
        return SuportePage(
          cpfCnpj: cpfCnpj,
          senha: senha,
          status: user?.status ?? 'Desconhecido',
          clientName: user?.nome ?? 'Cliente',
        );
      case 'abrir_chamado':
        return AbrirChamadoPage(cpfCnpj: cpfCnpj);
      case 'network_diagnostic':
      case 'diagnostico':
        return const DiagnosticoPage();
      case 'speed_test':
      case 'velocidade':
        return const SpeedTestPage();
      case 'promessa_pagamento':
        return PromessaPagamentoPage(cpfCnpj: cpfCnpj);
      case 'dicas':
        return const DicasUteisPage();
      case 'meu_ip':
        return const MeuIpPage();
      case 'status_servicos':
        return const DownDetectorPage();
      default:
        return null;
    }
  }
}
