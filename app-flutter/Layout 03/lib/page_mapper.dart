import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:layout01/models/provider_config.dart';
import 'package:layout01/configuration_provider.dart';

// Páginas do App
import 'painel.dart';
import 'financeiro_page.dart';
import 'suporte.dart';
import 'consumo_page.dart'; // Alterado para usar a versão nativa com Service
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
    print('PageMapper: Tentando navegar para "$itemKey"'); // DEBUG LOG

    // 1. Obter a configuração
    final configProvider = context.read<ConfigurationProvider>();
    final config = configProvider.providerConfig;

    if (config == null) {
      print('PageMapper: Configuração é nula!');
      return;
    }

    final itemDetails = config.menuConfig.items[itemKey];
    print('PageMapper: Detalhes do item: $itemDetails'); // DEBUG LOG

    // Lista de chaves permitidas (whitelist) expandida
    final allowedKeys = [
      'invoices',
      'financeiro',
      'network_diagnostic',
      'diagnostico',
      'speed_test',
      'velocidade',
      'support',
      'suporte',
      'contract',
      'contrato',
      'my_ip',
      'meu_ip',
      'consumo',
      'internet_usage',
      'abrir_chamado',
      'promessa_pagamento',
      'dicas',
      'useful_tips',
      'status_servicos',
      'notifications'
    ];

    // Se o item não existir ou estiver desabilitado, verifica se é um item padrão permitido
    if (itemDetails == null || !itemDetails.enabled) {
      if (!allowedKeys.contains(itemKey)) {
        print('PageMapper: Item "$itemKey" não permitido e não configurado.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Funcionalidade "$itemKey" não disponível.')),
        );
        return;
      } else {
        print('PageMapper: Item "$itemKey" permitido pela whitelist.');
      }
    }

    // 2. Verificar o tipo de ação
    final type = itemDetails?.type ?? 'internal';
    final url = itemDetails?.url;
    print('PageMapper: Tipo de ação: $type, URL: $url'); // DEBUG LOG

    try {
      switch (type) {
        case 'internal':
          final page = _getPageForKey(context, itemKey, config);
          if (page != null) {
            print('PageMapper: Navegando para página interna.');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          } else {
            print('PageMapper: Página interna não encontrada para "$itemKey".');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Página interna "$itemKey" não implementada.')),
            );
          }
          break;

        case 'webview':
        case 'external':
        case 'external_link':
          if (url != null && url.isNotEmpty) {
            print('PageMapper: Abrindo URL externa: $url');
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(
                uri,
                mode: type == 'webview'
                    ? LaunchMode.inAppWebView
                    : LaunchMode.externalApplication,
              );
            } else {
              print('PageMapper: Falha ao abrir URL.');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Não foi possível abrir o link.')),
              );
            }
          } else {
            print('PageMapper: URL vazia para tipo externo.');
          }
          break;

        default:
          print('PageMapper: Tipo desconhecido "$type".');
          break;
      }
    } catch (e) {
      print('PageMapper: Erro ao navegar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao navegar: $e')),
      );
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
    final sgpParams = {
      'token': config.config.integrations.apiToken,
      'app': config.config.integrations.appName,
      'sgpBaseUrl': config.config.integrations.sgpBaseUrl,
    };

    switch (key) {
      case 'dashboard':
        return const PainelPage();
      case 'invoices':
      case 'financeiro':
        return FinanceiroPage(
          cpfCnpj: cpfCnpj,
          senha: senha,
          sgpParams: sgpParams,
        );
      case 'consumo':
      case 'internet_usage':
        return ConsumoPage(
          cpfCnpj: cpfCnpj,
          senha: senha,
        );
      case 'suporte':
      case 'support':
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
      case 'useful_tips':
        return const DicasUteisPage();
      case 'meu_ip':
      case 'my_ip':
        return const MeuIpPage();
      case 'status_servicos':
        return const DownDetectorPage();
      case 'contract':
      case 'contrato':
        return Scaffold(
            appBar: AppBar(title: const Text("Contrato")),
            body: const Center(
                child: Text("Visualização de contrato em breve.")));
      case 'notifications':
        return Scaffold(
            appBar: AppBar(title: const Text("Notificações")),
            body: const Center(child: Text("Sem notificações.")));
      default:
        return null;
    }
  }
}
