import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/connectivity_provider.dart';
import '../services/meu_ip_service.dart';
import '../utils/app_formatters.dart';
import '../vibe/vibe_page_parts.dart';
import '../vibe/vibe_text.dart';
import '../vibe/vibe_tokens.dart';

/// Meu IP (`PG.ip` do layout aprovado): o IP público em destaque e os dados
/// de localização, com os códigos da consulta traduzidos para leitura.
class MeuIpPage extends ConsumerStatefulWidget {
  /// Nome do provedor de internet como o assinante o reconhece.
  static String organization(Object? org) => _MeuIpPageState.organization(org);

  const MeuIpPage({super.key});

  @override
  ConsumerState<MeuIpPage> createState() => _MeuIpPageState();
}

class _MeuIpPageState extends ConsumerState<MeuIpPage> {
  final _service = MeuIpService();
  late Future<Map<String, dynamic>> _ipFuture;

  @override
  void initState() {
    super.initState();
    _ipFuture = _service.fetchIpInfo();
  }

  void _retry() => setState(() => _ipFuture = _service.fetchIpInfo());

  static const _states = {
    'Acre': 'AC',
    'Alagoas': 'AL',
    'Amapá': 'AP',
    'Amazonas': 'AM',
    'Bahia': 'BA',
    'Ceará': 'CE',
    'Distrito Federal': 'DF',
    'Federal District': 'DF',
    'Espírito Santo': 'ES',
    'Goiás': 'GO',
    'Maranhão': 'MA',
    'Mato Grosso': 'MT',
    'Mato Grosso do Sul': 'MS',
    'Minas Gerais': 'MG',
    'Pará': 'PA',
    'Paraíba': 'PB',
    'Paraná': 'PR',
    'Pernambuco': 'PE',
    'Piauí': 'PI',
    'Rio de Janeiro': 'RJ',
    'Rio Grande do Norte': 'RN',
    'Rio Grande do Sul': 'RS',
    'Rondônia': 'RO',
    'Roraima': 'RR',
    'Santa Catarina': 'SC',
    'São Paulo': 'SP',
    'Sao Paulo': 'SP',
    'Sergipe': 'SE',
    'Tocantins': 'TO',
  };

  static const _zones = {
    'America/Sao_Paulo': 'UTC−3 (Brasília)',
    'America/Bahia': 'UTC−3 (Brasília)',
    'America/Fortaleza': 'UTC−3 (Brasília)',
    'America/Recife': 'UTC−3 (Brasília)',
    'America/Maceio': 'UTC−3 (Brasília)',
    'America/Belem': 'UTC−3 (Brasília)',
    'America/Araguaina': 'UTC−3 (Brasília)',
    'America/Santarem': 'UTC−3 (Brasília)',
    'America/Manaus': 'UTC−4 (Manaus)',
    'America/Cuiaba': 'UTC−4 (Cuiabá)',
    'America/Campo_Grande': 'UTC−4 (Campo Grande)',
    'America/Porto_Velho': 'UTC−4 (Porto Velho)',
    'America/Boa_Vista': 'UTC−4 (Boa Vista)',
    'America/Rio_Branco': 'UTC−5 (Rio Branco)',
    'America/Noronha': 'UTC−2 (Fernando de Noronha)',
  };

  static String location(Object? city, Object? region) {
    final c = city?.toString().trim() ?? '',
        r = region?.toString().trim() ?? '';
    final uf = _states[r];
    if (c.isEmpty) return r;
    if (uf != null) return '$c, $uf';
    return r.isEmpty || r == c ? c : '$c, $r';
  }

  static String country(Object? code) {
    final value = code?.toString().trim() ?? '';
    return value.toUpperCase() == 'BR' ? 'Brasil' : value;
  }

  /// "AS264000 Vibe Telecom" → "Vibe Telecom".
  /// "AS264000 FLASH NET TELECOMUNICACOES LTDA - ME" → "Flash Net
  /// Telecomunicacoes": sem número de sistema autônomo nem sufixo societário.
  static String organization(Object? org) {
    var value =
        (org?.toString() ?? '').replaceFirst(RegExp(r'^AS\d+\s+'), '').trim();
    final legal = RegExp(r'[\s,.-]+(LTDA|ME|EPP|EIRELI|S\.?\s?A\.?|MEI)\.?$',
        caseSensitive: false);
    while (legal.hasMatch(value)) {
      value = value.replaceFirst(legal, '').trim();
    }
    return AppFormatters.label(value);
  }

  static String timezone(Object? zone) {
    final value = zone?.toString().trim() ?? '';
    return _zones[value] ?? value.replaceAll('_', ' ').replaceAll('/', ' / ');
  }

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final network = ref.watch(connectivityStatusProvider).valueOrNull;
    final navigator = Navigator.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _ipFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final data = snapshot.data;
        final ip = data?['ip']?.toString() ?? '';
        final List<Widget> children;
        if (loading) {
          children = const [
            VibeLoading(blocks: 2, label: 'Consultando seu IP')
          ];
        } else if (snapshot.hasError || data == null) {
          children = [
            VibeCard(
              child: VibeEmpty(
                icon: 'alert',
                title: 'Não foi possível consultar',
                text: network == ConnectivityResult.none
                    ? 'O celular está sem internet.'
                    : 'Tente de novo em instantes.',
                action: VibePageButton(
                    label: 'Tentar de novo',
                    small: true,
                    expand: false,
                    onPressed: _retry),
              ),
            ),
          ];
        } else {
          String shown(String value) => value.isEmpty ? 'Não informado' : value;
          children = [
            VibeCard(
              main: true,
              child: Column(children: [
                const VibeLabel('IP público'),
                const SizedBox(height: 8),
                FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SelectableText(shown(ip),
                        maxLines: 1,
                        style: vibeText(t, 28, 800, letterSpacingEm: -.01))),
              ]),
            ),
            VibeCard(
              child: VibeKvList([
                VibeKv('Localização aproximada',
                    shown(location(data['city'], data['region']))),
                VibeKv('País', shown(country(data['country']))),
                VibeKv('Provedor', shown(organization(data['org']))),
                VibeKv('Fuso horário', shown(timezone(data['timezone']))),
              ]),
            ),
            if (ip.isNotEmpty)
              VibeTwo(
                VibePageButton(
                    label: 'Copiar IP',
                    icon: 'copy',
                    ghost: true,
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: ip));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('IP copiado.')));
                      }
                    }),
                VibePageButton(
                    label: 'Atualizar',
                    icon: 'g-refresh',
                    ghost: true,
                    onPressed: _retry),
              )
            else
              VibePageButton(
                  label: 'Atualizar',
                  icon: 'g-refresh',
                  ghost: true,
                  onPressed: _retry),
          ];
        }
        return VibePageScaffold(
          title: 'Meu IP',
          subtitle: switch (network) {
            ConnectivityResult.wifi => t.wifi,
            ConnectivityResult.mobile => 'Dados móveis',
            ConnectivityResult.ethernet => 'Rede cabeada',
            ConnectivityResult.none => 'Sem rede',
            _ => 'IP público e localização',
          },
          onBack: navigator.canPop() ? () => navigator.maybePop() : null,
          children: children,
        );
      },
    );
  }
}
