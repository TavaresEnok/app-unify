import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/tr069_service.dart';
import '../vibe/vibe_icon.dart';
import '../vibe/vibe_page_parts.dart';
import '../vibe/vibe_text.dart';
import '../vibe/vibe_tokens.dart';

/// Cartão "Seu equipamento": a fibra (sinal e se está no ar) e o roteador
/// gerenciado, com a hora da leitura. Usado na tela do Wi-Fi e em Conexão.
///
/// Com [loading] e sem dados, desenha o mesmo cartão com os valores
/// cobertos, para nada pular quando a resposta chega.
class EquipmentStatusCard extends StatelessWidget {
  const EquipmentStatusCard({
    super.key,
    this.overview,
    this.loading = false,
    this.failed = false,
    this.showRouter = true,
    this.hostsCount,
  });

  final Tr069Overview? overview;
  final bool loading;

  /// A consulta falhou: diz que o status está indisponível.
  final bool failed;
  final bool showRouter;

  /// Aparelhos conectados (quando a lista veio separada do status).
  final int? hostsCount;

  static const _sample = Tr069Overview(
    online: true,
    driver: 'sgp',
    manufacturer: 'Roteador',
    model: 'Modelo',
    firmware: 'V0.0.0',
    lanBottleneck100Mbps: false,
    wifiNetworks: [],
    hostsCount: 0,
    fiber: Tr069Fiber(online: true, rxPowerDbm: -19.5),
  );

  static String dbm(double value) =>
      '${value.toStringAsFixed(1).replaceAll('.', ',')} dBm';

  static String _time(DateTime when) {
    final local = when.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    return sameDay
        ? DateFormat('HH:mm').format(local)
        : DateFormat('dd/MM HH:mm').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final redacted = loading && overview == null;
    final data = overview ?? (redacted ? _sample : null);
    final fiber = data?.fiber;
    final rows = <Widget>[];

    // Fibra
    if (failed && data == null) {
      rows.add(_line(t,
          icon: 'pulse',
          title: 'Fibra',
          detail:
              'Status da fibra indisponível agora. Tente de novo em instantes.',
          redacted: false));
    } else if (fiber == null) {
      rows.add(_line(t,
          icon: 'pulse',
          title: 'Fibra',
          detail: 'Status da fibra indisponível',
          redacted: redacted));
    } else {
      final signal = fiber.rxPowerDbm == null
          ? null
          : 'Sinal ${dbm(fiber.rxPowerDbm!)}'
              '${fiber.signalLabel.isEmpty ? '' : ' (${fiber.signalLabel})'}';
      final details = <String>[
        if (fiber.online == false)
          'Sua fibra está sem sinal agora. Verifique se o equipamento está ligado na tomada.'
        else if (signal != null)
          signal,
        if (fiber.online != false && fiber.onlineSince != null)
          'Conectada desde ${_time(fiber.onlineSince!)}',
        if (fiber.online == false && fiber.lastDownCause != null)
          'Motivo informado: ${fiber.lastDownCause}',
      ];
      rows.add(_line(t,
          icon: 'pulse',
          title: 'Fibra',
          chip: switch (fiber.online) {
            true => (VibeTone.ok, 'Online'),
            false => (VibeTone.bad, 'Sem sinal'),
            null => null,
          },
          warn: fiber.online != false && fiber.signalWeak
              ? 'Sinal fraco: se a internet oscilar, fale com o suporte.'
              : null,
          detail: details.isEmpty ? 'Sem leitura do sinal' : details.join('\n'),
          redacted: redacted));
    }

    // Roteador
    if (showRouter && data != null && data.hasRouter) {
      final name = [data.manufacturer, data.model]
          .where((s) => s.trim().isNotEmpty)
          .join(' ');
      final hosts = hostsCount ?? data.hosts?.length;
      final details = <String>[
        if (data.firmware.isNotEmpty) 'Firmware ${data.firmware}',
        if (hosts != null && hosts > 0)
          hosts == 1 ? '1 aparelho conectado' : '$hosts aparelhos conectados',
        if (data.snapshotAt != null)
          'Dados de ${_time(data.snapshotAt!)}'
        else if (data.online == null)
          'Dados da última leitura do roteador',
      ];
      rows.add(_line(t,
          icon: 'router',
          title: name.isEmpty ? 'Roteador' : 'Roteador $name',
          chip: switch (data.online) {
            true => (VibeTone.ok, 'Online'),
            false => (VibeTone.bad, 'Fora do ar'),
            null => null,
          },
          detail: details.join(' · '),
          redacted: redacted));
    }

    return Semantics(
      container: true,
      label: redacted ? 'Consultando seu equipamento' : null,
      liveRegion: redacted,
      child: VibeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 2),
              child: VibeLabel('Seu equipamento'),
            ),
            VibeRows(children: rows),
          ],
        ),
      ),
    );
  }

  Widget _line(
    VibeTokens t, {
    required String icon,
    required String title,
    required String detail,
    required bool redacted,
    (VibeTone, String)? chip,
    String? warn,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: VibeIcon(icon, size: 20, color: t.mut),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: vibeText(t, 14, 700, height: 1.3)),
                if (detail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: VibeRedact(
                      redacted: redacted,
                      child: Text(detail,
                          style: vibeText(t, 12.5, 500,
                              color: t.mut, height: 1.4)),
                    ),
                  ),
                if (warn != null && !redacted)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(warn,
                        style:
                            vibeText(t, 12.5, 600, color: t.wa, height: 1.4)),
                  ),
              ],
            ),
          ),
          if (chip != null) ...[
            const SizedBox(width: 8),
            VibeRedact(
              redacted: redacted,
              block: true,
              radius: 12,
              child: VibePageChip(tone: chip.$1, label: chip.$2),
            ),
          ],
        ],
      ),
    );
  }
}
