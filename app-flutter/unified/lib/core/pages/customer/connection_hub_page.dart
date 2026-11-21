import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../providers/customer_capabilities_provider.dart';
import '../../providers/network_state_provider.dart';
import '../../navigation/customer_routes.dart';
import '../../vibe/vibe_icon.dart';
import '../../vibe/vibe_page_parts.dart';
import '../../vibe/vibe_tokens.dart';

/// Conexão (`PG.conexao` do layout aprovado): a rede do celular com o
/// atalho para verificar, os testes e as ferramentas avançadas.
class ConnectionHubPage extends ConsumerStatefulWidget {
  final ValueChanged<String> onNavigate;
  const ConnectionHubPage({super.key, required this.onNavigate});

  @override
  ConsumerState<ConnectionHubPage> createState() => _ConnectionHubPageState();
}

class _ConnectionHubPageState extends ConsumerState<ConnectionHubPage> {
  bool _advanced = false;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configurationProvider).providerConfig;
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final network = ref.watch(networkStateProvider);
    final wifiAvailable =
        ref.watch(wifiManagementAvailableProvider).valueOrNull == true;
    bool can(String route) =>
        config == null || CustomerRoutes.enabled(config, route);
    final go = widget.onNavigate;
    final (icon, tone, title, description) = switch (network.status) {
      NetworkConnectionStatus.wifi => (
          'wifi',
          VibeTone.ok,
          'Seu celular está no Wi-Fi',
          'Verifique o sinal e o acesso à internet de casa.'
        ),
      NetworkConnectionStatus.mobileData => (
          'cell',
          VibeTone.warning,
          'Seu celular está nos dados móveis',
          'Conecte ao Wi-Fi de casa para verificar a sua fibra.'
        ),
      NetworkConnectionStatus.ethernet => (
          'wifi',
          VibeTone.ok,
          'Conectado por cabo',
          'Confira como está a conexão deste aparelho.'
        ),
      NetworkConnectionStatus.disconnected => (
          'alert',
          VibeTone.bad,
          'Seu celular está sem rede',
          'Confira o Wi-Fi ou os dados do celular.'
        ),
      NetworkConnectionStatus.unknown => (
          'wifi',
          VibeTone.ok,
          'Verifique sua conexão',
          'Confira a rede deste aparelho e os testes disponíveis.'
        ),
    };
    final tests = <Widget>[
      if (can('internet_usage'))
        VibeRow(
            icon: 'g-chart',
            title: 'Consumo',
            subtitle: 'Uso dos últimos meses',
            onTap: () => go('internet_usage')),
      if (can('speed_test'))
        VibeRow(
            icon: 'gauge',
            title: 'Teste de velocidade',
            subtitle: 'Download e upload',
            onTap: () => go('speed_test')),
      if (can('history'))
        VibeRow(
            icon: 'clock',
            title: 'Histórico de verificações',
            subtitle: 'Resultados salvos neste aparelho',
            onTap: () => go('history')),
      if (wifiAvailable && can('wifi'))
        VibeRow(
            icon: 'router',
            title: 'Minha rede Wi-Fi',
            subtitle: 'Nome, senha e frequência',
            onTap: () => go('wifi')),
    ];
    final tools = <Widget>[
      if (can('ping'))
        VibeRow(
            icon: 'pulse',
            title: 'Teste de ping',
            subtitle: 'Latência e perda de pacotes',
            onTap: () => go('ping')),
      if (can('trace_route'))
        VibeRow(
            icon: 'g-route',
            title: 'Rota da rede',
            subtitle: 'Traceroute pelo servidor',
            onTap: () => go('trace_route')),
      if (can('my_ip'))
        VibeRow(
            icon: 'globe',
            title: 'Meu IP',
            subtitle: 'IP público e localização',
            onTap: () => go('my_ip')),
    ];
    final t = VibeTokens.of(context);
    return VibePageScaffold(
      title: 'Conexão',
      subtitle:
          user?.plano.trim().isNotEmpty == true ? user!.plano.trim() : null,
      children: [
        VibeCard(
          main: true,
          child: Column(children: [
            VibeStatusCircle(icon: icon, tone: tone),
            const SizedBox(height: 8),
            VibeBigText(title, center: true),
            const SizedBox(height: 8),
            VibeNote(description, paragraph: true, center: true),
            if (can('network_diagnostic')) ...[
              const SizedBox(height: 8),
              VibePageButton(
                  label: 'Verificar conexão',
                  icon: 'bolt',
                  onPressed: () => go('network_diagnostic')),
            ],
          ]),
        ),
        if (tests.isNotEmpty) VibeCard(child: VibeRows(children: tests)),
        if (tools.isNotEmpty)
          VibeCard(
            child: VibeRows(children: [
              VibeRow(
                icon: 'gear',
                plainIcon: true,
                title: 'Ferramentas avançadas',
                subtitle: 'Ping, rota da rede e Meu IP',
                trailing: RotatedBox(
                  quarterTurns: _advanced ? 2 : 0,
                  child: VibeIcon('chevd', size: 16, color: t.ink),
                ),
                onTap: () => setState(() => _advanced = !_advanced),
              ),
              if (_advanced) ...tools,
            ]),
          ),
      ],
    );
  }
}
